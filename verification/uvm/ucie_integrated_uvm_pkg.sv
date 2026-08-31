package ucie_integrated_uvm_pkg;
  import uvm_pkg::*; import ucie_ltsm_pkg::*;
  `include "uvm_macros.svh"
  class int_item extends uvm_sequence_item;
    int scenario,bp0,lat0,bp1,lat1,bits,threshold,gap,phase;
    `uvm_object_utils(int_item)
    function new(string n="int_item"); super.new(n); endfunction
  endclass
  class int_sqr extends uvm_sequencer#(int_item);
    `uvm_component_utils(int_sqr)
    function new(string n,uvm_component p);super.new(n,p);endfunction
  endclass
  class int_seq extends uvm_sequence#(int_item);
    `uvm_object_utils(int_seq)
    int iterations=36,hits[9],phase_hits[3],gap_hits[3],corrupt_hits[3];
    function new(string n="int_seq");super.new(n);endfunction
    task body(); int_item t;
      for(int i=0;i<iterations;i++) begin
        t=int_item::type_id::create($sformatf("t%0d",i)); start_item(t);
        t.scenario=(i<9)?i:$urandom_range(8,0);
        t.bp0=$urandom_range(4,0);t.lat0=$urandom_range(5,0);
        t.bp1=$urandom_range(4,0);t.lat1=$urandom_range(5,0);
        t.bits=$urandom_range(16,1);t.threshold=$urandom_range(t.bits*8,0);
        t.gap=$urandom_range(3,0);t.phase=(i<12)?i%3:$urandom_range(2,0);
        hits[t.scenario]++;phase_hits[t.phase]++;
        gap_hits[t.gap==0?0:(t.gap<=2?1:2)]++;
        corrupt_hits[t.bits<=4?0:(t.bits<16?1:2)]++;
        finish_item(t);
      end
    endtask
  endclass
  class int_driver extends uvm_driver#(int_item);
    `uvm_component_utils(int_driver)
    virtual ucie_ltsm_if v;
    int trials,sreq,sresp,ereq,eresp,retries,proto,passes,fails,resets,fatals,timeouts,checks;
    int phase_cov[3],out_gap[3][3];
    function new(string n,uvm_component p);super.new(n,p);endfunction
    function void build_phase(uvm_phase phase);
      if(!uvm_config_db#(virtual ucie_ltsm_if)::get(this,"","vif",v))`uvm_fatal("NOVIF","no vif")
    endfunction
    task pulse(ref logic x);@(negedge v.clk);x=1;@(posedge v.clk);#1 x=0;endtask
    function automatic logic[22:0] train_seed(int l);
      case(l%8) 0:return 23'h1dbfbc;1:return 23'h0607bb;2:return 23'h1ec760;3:return 23'h18c0db;
        4:return 23'h010f12;5:return 23'h19cfc9;6:return 23'h0277ce;default:return 23'h1bb807;endcase
    endfunction
    function automatic logic[22:0] nxt(logic[22:0] x);
      return {x[21:0],x[22]^x[20]^x[15]^x[7]^x[4]^x[1]};
    endfunction
    task nav();
      v.rst_n=0;v.clear_controls();repeat(3)@(posedge v.clk);#1 v.rst_n=1;
      v.supplies_stable=1;v.sideband_clk_ok=1;v.internal_clks_ok=1;v.link_train_trigger=1;
      wait(v.state==LTSM_SBINIT);pulse(v.phase_done);repeat(6)pulse(v.phase_done);repeat(7)pulse(v.phase_done);
      if(v.state!=LTSM_MBTRAIN||v.mbt!=MBT_DATATRAINCENTER1||v.datatrain_phase!=DATATRAIN_SB_START)
        `uvm_error("NAV","bad CENTER1 entry")
      if(v.train_busy)`uvm_error("ORDER","pattern before START response")
      phase_cov[0]++;checks++;
    endtask
    task accept(sb_msg_e msg,int bp);
      wait(v.sb_tx_valid);if(v.sb_tx_message!=msg)`uvm_error("MSG","wrong request/order")
      repeat(bp)begin @(posedge v.clk);#1;if(!v.sb_tx_valid||v.sb_tx_message!=msg)`uvm_error("HOLD","backpressure hold")end
      @(negedge v.clk);v.sb_tx_ready=1;@(posedge v.clk);#1 v.sb_tx_ready=0;
      if(msg==SB_MSG_DATACENTER1_START_REQ)sreq++;else ereq++;
    endtask
    task respond(sb_msg_e msg,int lat);
      repeat(lat)@(posedge v.clk);@(negedge v.clk);v.sb_rx_message=msg;v.sb_rx_valid=1;
      @(posedge v.clk);#1 v.sb_rx_valid=0;v.sb_rx_message=SB_MSG_NOP;
      if(msg==SB_MSG_DATACENTER1_START_RESP)sresp++;
      if(msg==SB_MSG_DATACENTER1_END_RESP)eresp++;
    endtask
    task start_phase(int_item t,bit retry);
      accept(SB_MSG_DATACENTER1_START_REQ,t.bp0);
      if(retry)begin wait(v.sb_retry);retries++;accept(SB_MSG_DATACENTER1_START_REQ,t.bp0);end
      respond(SB_MSG_DATACENTER1_START_RESP,t.lat0);wait(v.datatrain_phase==DATATRAIN_PATTERN);
      if(v.mbt!=MBT_DATATRAINCENTER1)`uvm_error("GATE","advance on START")
      wait(v.train_busy);@(negedge v.clk);phase_cov[1]++;checks++;
    endtask
    task pattern(int bits,int threshold,int gap,bit pass);
      logic[22:0] r[16];logic[15:0] exp,mask;int errors=0;
      for(int l=0;l<16;l++)r[l]=train_seed(l);v.train_error_threshold=threshold;
      for(int n=0;n<8;n++)begin
        repeat(gap)@(posedge v.clk);exp='0;for(int l=0;l<16;l++)exp[l]=r[l][22];
        if(v.train_tx_pattern!==exp && !(n==0 && v.train_tx_pattern==16'h6c6c))
          `uvm_error("LFSR",$sformatf("sample=%0d exp=%h got=%h",n,exp,v.train_tx_pattern))
        mask='0;for(int b=0;b<bits;b++)mask[(b+n)%16]=1;errors+=bits;
        @(negedge v.clk);v.train_rx_pattern=exp^mask;v.train_rx_valid=1;
        @(posedge v.clk);#1 v.train_rx_valid=0;for(int l=0;l<16;l++)r[l]=nxt(r[l]);
      end
      if(!v.train_done||v.train_error_count!=errors||v.train_pass!=pass)
        `uvm_error("PRED",$sformatf("exp errors/pass=%0d/%0b got=%0d/%0b",errors,pass,v.train_error_count,v.train_pass))
      if(pass)passes++;else fails++;
    endtask
    task end_phase(int_item t,bit retry);
      wait(v.datatrain_phase==DATATRAIN_SB_END);phase_cov[2]++;
      if(v.mbt!=MBT_DATATRAINCENTER1||v.train_busy)`uvm_error("ENDGATE","bad END entry")
      accept(SB_MSG_DATACENTER1_END_REQ,t.bp1);
      if(retry)begin wait(v.sb_retry);retries++;accept(SB_MSG_DATACENTER1_END_REQ,t.bp1);end
      if(v.mbt!=MBT_DATATRAINCENTER1)`uvm_error("GATE","advance before END response")
      respond(SB_MSG_DATACENTER1_END_RESP,t.lat1);@(posedge v.clk);#1;
      if(v.mbt!=MBT_DATATRAINVREF)`uvm_error("ADV","did not advance exactly to DATATRAINVREF")
      checks++;
    endtask
    task reach(int_item t,int p);
      nav();if(p>0)start_phase(t,0);if(p>1)begin pattern(0,1,t.gap,1);wait(v.datatrain_phase==DATATRAIN_SB_END);end
    endtask
    task bad_response(int_item t,bit at_end);
      nav();if(at_end)begin start_phase(t,0);pattern(0,1,t.gap,1);end
      accept(at_end?SB_MSG_DATACENTER1_END_REQ:SB_MSG_DATACENTER1_START_REQ,at_end?t.bp1:t.bp0);
      respond(SB_MSG_NOP,0);wait(v.sb_protocol_error);proto++;@(posedge v.clk);#1;
      if(!v.trainerror_handshake_request||v.error_cause!=LTSM_ERR_SIDEBAND_PROTOCOL)
        `uvm_error("ERRMGR","protocol cause/request")
      pulse(v.error_handshake_done);wait(v.state==LTSM_TRAINERROR);@(posedge v.clk);#1;
    endtask
    task drive_trial(int_item t);int ob,gb;trials++;gb=t.gap==0?0:(t.gap<=2?1:2);
      case(t.scenario)
        0:begin nav();start_phase(t,0);pattern(0,1,t.gap,1);end_phase(t,0);ob=0;end
        1:begin nav();start_phase(t,0);pattern(t.bits,t.threshold,t.gap,0);@(posedge v.clk);#1;
          if(v.datatrain_phase!=DATATRAIN_PATTERN||v.sb_tx_valid)`uvm_error("RETRY","failed run emitted END")
          wait(v.train_busy);pattern(0,1,t.gap,1);end_phase(t,0);ob=1;end
        2:begin nav();start_phase(t,1);pattern(0,1,t.gap,1);end_phase(t,0);ob=0;end
        3:begin bad_response(t,0);ob=2;end
        4:begin nav();start_phase(t,0);pattern(0,1,t.gap,1);end_phase(t,1);ob=0;end
        5:begin bad_response(t,1);ob=2;end
        6:begin reach(t,t.phase);@(negedge v.clk);v.rst_n=0;@(posedge v.clk);#1;
          if(v.state!=LTSM_RESET||v.datatrain_phase!=DATATRAIN_SB_START||v.train_busy||v.sb_busy)
            `uvm_error("RSTABORT","reset abort");v.rst_n=1;resets++;ob=2;end
        7:begin reach(t,t.phase);@(negedge v.clk);v.fatal_error=1;#1;
          if(!v.trainerror_handshake_request)`uvm_error("FATAL","request not immediate")
          @(posedge v.clk);#1 v.fatal_error=0;pulse(v.error_handshake_done);wait(v.state==LTSM_TRAINERROR);@(posedge v.clk);#1;
          if(v.error_cause!=LTSM_ERR_LOCAL_FATAL||v.train_busy||v.sb_busy)`uvm_error("FATAL","cause/abort")
          fatals++;ob=2;end
        default:begin reach(t,t.phase);wait(v.timeout);timeouts++;wait(v.state==LTSM_TRAINERROR);repeat(2)@(posedge v.clk);#1;
          if((v.state!=LTSM_TRAINERROR&&v.state!=LTSM_RESET)||v.error_cause!=LTSM_ERR_STATE_TIMEOUT||v.train_busy||v.sb_busy)
            `uvm_error("TIMEOUT",$sformatf("phase=%0d state=%0d cause=%0d train_busy=%0b sb_busy=%0b",
              t.phase,v.state,v.error_cause,v.train_busy,v.sb_busy));ob=2;end
      endcase out_gap[ob][gb]++;
    endtask
    task run_phase(uvm_phase phase);forever begin seq_item_port.get_next_item(req);drive_trial(req);seq_item_port.item_done();end endtask
    function void report_phase(uvm_phase phase);
      `uvm_info("INTEGRATED_PREDICTOR",$sformatf("trials=%0d start=%0d/%0d end=%0d/%0d retries=%0d protocol=%0d pass/fail=%0d/%0d reset/fatal/timeout=%0d/%0d/%0d checks=%0d",
        trials,sreq,sresp,ereq,eresp,retries,proto,passes,fails,resets,fatals,timeouts,checks),UVM_LOW)
      `uvm_info("INTEGRATED_COVERAGE",$sformatf("phase=%0d/%0d/%0d outcome_x_gap=%0d,%0d,%0d;%0d,%0d,%0d;%0d,%0d,%0d",
        phase_cov[0],phase_cov[1],phase_cov[2],out_gap[0][0],out_gap[0][1],out_gap[0][2],
        out_gap[1][0],out_gap[1][1],out_gap[1][2],out_gap[2][0],out_gap[2][1],out_gap[2][2]),UVM_LOW)
    endfunction
  endclass
  class integrated_test extends uvm_test;
    `uvm_component_utils(integrated_test)
    int_sqr sqr;int_driver drv;int_seq seq;
    function new(string n,uvm_component p);super.new(n,p);endfunction
    function void build_phase(uvm_phase phase);sqr=int_sqr::type_id::create("sqr",this);drv=int_driver::type_id::create("drv",this);endfunction
    function void connect_phase(uvm_phase phase);drv.seq_item_port.connect(sqr.seq_item_export);endfunction
    task run_phase(uvm_phase phase);seq=int_seq::type_id::create("seq");phase.raise_objection(this);seq.start(sqr);#100ns;phase.drop_objection(this);endtask
    function void report_phase(uvm_phase phase);
      foreach(seq.hits[i])if(!seq.hits[i])`uvm_error("COV","empty scenario")
      foreach(seq.phase_hits[i])if(!seq.phase_hits[i])`uvm_error("COV","empty phase")
      if(drv.trials!=seq.iterations||!drv.fails||!drv.retries||!drv.proto||!drv.resets||!drv.fatals||!drv.timeouts)
        `uvm_error("CLOSURE","missing required outcome")
      `uvm_info("INTEGRATED_RANDOM_SUMMARY",$sformatf("iterations=%0d scenarios=%0d/%0d/%0d/%0d/%0d/%0d/%0d/%0d/%0d phases=%0d/%0d/%0d gaps=%0d/%0d/%0d corrupt=%0d/%0d/%0d",
        seq.iterations,seq.hits[0],seq.hits[1],seq.hits[2],seq.hits[3],seq.hits[4],seq.hits[5],seq.hits[6],seq.hits[7],seq.hits[8],
        seq.phase_hits[0],seq.phase_hits[1],seq.phase_hits[2],seq.gap_hits[0],seq.gap_hits[1],seq.gap_hits[2],
        seq.corrupt_hits[0],seq.corrupt_hits[1],seq.corrupt_hits[2]),UVM_LOW)
    endfunction
  endclass
endpackage
