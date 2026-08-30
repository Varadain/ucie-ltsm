package ucie_ltsm_uvm_pkg;
  import uvm_pkg::*;
  import ucie_ltsm_pkg::*;
  `include "uvm_macros.svh"

  typedef enum {OP_RESET, OP_START, OP_DONE, OP_RDI_ACTIVE, OP_RETRAIN, OP_FATAL,
                OP_STALL, OP_WAIT_TIMEOUT, OP_L1_EXIT, OP_L2_EXIT,
                OP_SB_SUCCESS, OP_SB_RETRY_SUCCESS, OP_SB_BAD_RESPONSE,
                OP_SB_EXHAUST_RETRIES} ltsm_op_e;

  class ltsm_item extends uvm_sequence_item;
    rand ltsm_op_e op;
    rand retrain_target_e retrain_target;
    rand int unsigned cycles;
    rand int unsigned response_cycles;
    constraint c_cycles { cycles inside {[1:50]}; }
    constraint c_response_cycles { response_cycles inside {[1:50]}; }
    `uvm_object_utils(ltsm_item)
    function new(string name="ltsm_item"); super.new(name); endfunction
  endclass

  class ltsm_sequencer extends uvm_sequencer #(ltsm_item);
    `uvm_component_utils(ltsm_sequencer)
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
  endclass

  class ltsm_driver extends uvm_driver #(ltsm_item);
    `uvm_component_utils(ltsm_driver)
    virtual ucie_ltsm_if vif;
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if(!uvm_config_db#(virtual ucie_ltsm_if)::get(this,"","vif",vif))
        `uvm_fatal("NOVIF","LTSM virtual interface not configured")
    endfunction
    task pulse(ref logic sig); sig=1; @(posedge vif.clk); #1 sig=0; endtask
    task drive(ltsm_item tr);
      case(tr.op)
        OP_RESET: begin
          vif.rst_n=0; vif.clear_controls();
          repeat(3) @(posedge vif.clk); #1 vif.rst_n=1;
        end
        OP_START: begin
          vif.supplies_stable=1; vif.sideband_clk_ok=1; vif.internal_clks_ok=1;
          vif.link_train_trigger=1;
          wait(vif.state==LTSM_SBINIT);
        end
        OP_DONE: pulse(vif.phase_done);
        OP_RDI_ACTIVE: pulse(vif.rdi_active);
        OP_RETRAIN: begin
          vif.retrain_target=tr.retrain_target; pulse(vif.retrain_req);
        end
        OP_FATAL: begin
          vif.error_handshake_done=1; pulse(vif.fatal_error);
          vif.error_handshake_done=0;
        end
        OP_STALL: begin
          vif.stall=1; repeat(tr.cycles) @(posedge vif.clk); #1 vif.stall=0;
        end
        OP_WAIT_TIMEOUT: wait(vif.timeout);
        OP_L1_EXIT: begin
          vif.pm_l1_req=1; @(posedge vif.clk); #1; vif.pm_exit=1;
          @(posedge vif.clk); #1; vif.pm_exit=0; vif.pm_l1_req=0;
        end
        OP_L2_EXIT: begin
          vif.pm_l2_req=1; @(posedge vif.clk); #1; vif.pm_exit=1;
          @(posedge vif.clk); #1; vif.pm_exit=0; vif.pm_l2_req=0;
        end
        OP_SB_SUCCESS: begin
          wait(vif.sb_tx_valid); repeat(tr.cycles) @(posedge vif.clk);
          @(negedge vif.clk); vif.sb_tx_ready=1;
          @(posedge vif.clk); #1 vif.sb_tx_ready=0;
          repeat(tr.response_cycles) @(posedge vif.clk);
          vif.sb_rx_message=SB_MSG_SBINIT_DONE_RESP; vif.sb_rx_valid=1;
          @(posedge vif.clk); #1 vif.sb_rx_valid=0; vif.sb_rx_message=SB_MSG_NOP;
          wait(vif.state==LTSM_MBINIT); #2;
        end
        OP_SB_RETRY_SUCCESS: begin
          wait(vif.sb_tx_valid); repeat(tr.cycles) @(posedge vif.clk);
          @(negedge vif.clk); vif.sb_tx_ready=1;
          @(posedge vif.clk); #1 vif.sb_tx_ready=0;
          wait(vif.sb_retry); wait(vif.sb_tx_valid);
          repeat(tr.cycles) @(posedge vif.clk);
          @(negedge vif.clk); vif.sb_tx_ready=1;
          @(posedge vif.clk); #1 vif.sb_tx_ready=0;
          repeat(tr.response_cycles) @(posedge vif.clk);
          @(negedge vif.clk);
          vif.sb_rx_message=SB_MSG_SBINIT_DONE_RESP; vif.sb_rx_valid=1;
          @(posedge vif.clk); #1 vif.sb_rx_valid=0; vif.sb_rx_message=SB_MSG_NOP;
          wait(vif.state==LTSM_MBINIT); #2;
        end
        OP_SB_BAD_RESPONSE: begin
          wait(vif.sb_tx_valid); repeat(tr.cycles) @(posedge vif.clk);
          @(negedge vif.clk); vif.sb_tx_ready=1;
          @(posedge vif.clk); #1 vif.sb_tx_ready=0;
          repeat(tr.response_cycles) @(posedge vif.clk);
          @(negedge vif.clk);
          vif.sb_rx_message=SB_MSG_NOP; vif.sb_rx_valid=1;
          @(posedge vif.clk); #1 vif.sb_rx_valid=0;
          wait(vif.sb_protocol_error); repeat(2) @(posedge vif.clk);
        end
        OP_SB_EXHAUST_RETRIES: begin
          wait(vif.sb_tx_valid); repeat(tr.cycles) @(posedge vif.clk);
          @(negedge vif.clk); vif.sb_tx_ready=1;
          @(posedge vif.clk); #1 vif.sb_tx_ready=0;
          wait(vif.sb_retry); wait(vif.sb_tx_valid);
          repeat(tr.cycles) @(posedge vif.clk);
          @(negedge vif.clk); vif.sb_tx_ready=1;
          @(posedge vif.clk); #1 vif.sb_tx_ready=0;
          wait(vif.sb_protocol_error); repeat(2) @(posedge vif.clk);
        end
      endcase
    endtask
    task run_phase(uvm_phase phase);
      forever begin seq_item_port.get_next_item(req); drive(req); seq_item_port.item_done(); end
    endtask
  endclass

  class state_sample extends uvm_sequence_item;
    ltsm_state_e previous, current;
    mbinit_state_e mbi;
    mbtrain_state_e mbt;
    `uvm_object_utils(state_sample)
    function new(string name="state_sample"); super.new(name); endfunction
  endclass

  class ltsm_monitor extends uvm_monitor;
    `uvm_component_utils(ltsm_monitor)
    virtual ucie_ltsm_if vif;
    uvm_analysis_port #(state_sample) ap;
    int sb_requests, sb_responses, sb_retries, sb_errors;
    function new(string name, uvm_component parent); super.new(name,parent); ap=new("ap",this); endfunction
    function void build_phase(uvm_phase phase);
      if(!uvm_config_db#(virtual ucie_ltsm_if)::get(this,"","vif",vif))
        `uvm_fatal("NOVIF","Monitor interface not configured")
    endfunction
    task run_phase(uvm_phase phase);
      fork
        begin
          forever begin
            @(posedge vif.clk);
            if(vif.rst_n && vif.sb_tx_valid && vif.sb_tx_ready) sb_requests++;
            if(vif.rst_n && vif.sb_retry) sb_retries++;
            if(vif.rst_n && vif.sb_protocol_error) sb_errors++;
          end
        end
        begin
          ltsm_state_e last; state_sample s;
          wait(vif.rst_n===1'b1); @(posedge vif.clk); #1; last=vif.state;
          forever begin
            @(posedge vif.clk); #1;
            if(!vif.rst_n) begin
              wait(vif.rst_n); @(posedge vif.clk); #1; last=vif.state;
              continue;
            end
            if(vif.state != last) begin
              if(last==LTSM_SBINIT && vif.state==LTSM_MBINIT) sb_responses++;
              s=state_sample::type_id::create("s");
              s.previous=last; s.current=vif.state; s.mbi=vif.mbi; s.mbt=vif.mbt;
              ap.write(s); last=vif.state;
            end
          end
        end
      join
    endtask
    function void report_phase(uvm_phase phase);
      `uvm_info("SB_COVERAGE",$sformatf("accepted_requests=%0d expected_responses=%0d retries=%0d protocol_errors=%0d",
                sb_requests,sb_responses,sb_retries,sb_errors),UVM_LOW)
    endfunction
  endclass

  class ltsm_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(ltsm_scoreboard)
    uvm_analysis_imp #(state_sample,ltsm_scoreboard) imp;
    int transitions, illegal;
    bit saw_active, saw_trainerror, saw_retrain, saw_l1l2;
    function new(string name, uvm_component parent); super.new(name,parent); imp=new("imp",this); endfunction
    function bit legal(ltsm_state_e a,b);
      if(b==LTSM_TRAINERROR && a!=LTSM_RESET) return 1;
      case(a)
        LTSM_RESET:      return b==LTSM_SBINIT;
        LTSM_SBINIT:     return b==LTSM_MBINIT;
        LTSM_MBINIT:     return b==LTSM_MBTRAIN;
        LTSM_MBTRAIN:    return b==LTSM_LINKINIT;
        LTSM_LINKINIT:   return b==LTSM_ACTIVE;
        LTSM_ACTIVE:     return b inside {LTSM_PHYRETRAIN,LTSM_L1L2};
        LTSM_PHYRETRAIN: return b==LTSM_MBTRAIN;
        LTSM_TRAINERROR: return b==LTSM_RESET;
        LTSM_L1L2:      return b inside {LTSM_MBTRAIN,LTSM_RESET};
        default:         return 0;
      endcase
    endfunction
    function void write(state_sample s);
      transitions++;
      if(!legal(s.previous,s.current)) begin
        illegal++; `uvm_error("BADTRANS",$sformatf("Illegal LTSM transition %0d -> %0d",s.previous,s.current))
      end
      saw_active |= s.current==LTSM_ACTIVE; saw_trainerror |= s.current==LTSM_TRAINERROR;
      saw_retrain |= s.current==LTSM_PHYRETRAIN; saw_l1l2 |= s.current==LTSM_L1L2;
      `uvm_info("TRANS",$sformatf("LTSM %0d -> %0d",s.previous,s.current),UVM_MEDIUM)
    endfunction
    function void report_phase(uvm_phase phase);
      `uvm_info("SCOREBOARD",$sformatf("transitions=%0d illegal=%0d active=%0b trainerror=%0b retrain=%0b pm=%0b",
                transitions,illegal,saw_active,saw_trainerror,saw_retrain,saw_l1l2),UVM_LOW)
      if(illegal) `uvm_error("SCOREBOARD","Illegal transitions observed")
    endfunction
  endclass

  class ltsm_agent extends uvm_agent;
    `uvm_component_utils(ltsm_agent)
    ltsm_sequencer sqr; ltsm_driver drv; ltsm_monitor mon;
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    function void build_phase(uvm_phase phase);
      sqr=ltsm_sequencer::type_id::create("sqr",this);
      drv=ltsm_driver::type_id::create("drv",this);
      mon=ltsm_monitor::type_id::create("mon",this);
    endfunction
    function void connect_phase(uvm_phase phase); drv.seq_item_port.connect(sqr.seq_item_export); endfunction
  endclass

  class ltsm_env extends uvm_env;
    `uvm_component_utils(ltsm_env)
    ltsm_agent agent; ltsm_scoreboard sb;
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    function void build_phase(uvm_phase phase);
      agent=ltsm_agent::type_id::create("agent",this); sb=ltsm_scoreboard::type_id::create("sb",this);
    endfunction
    function void connect_phase(uvm_phase phase); agent.mon.ap.connect(sb.imp); endfunction
  endclass

  class ltsm_base_seq extends uvm_sequence #(ltsm_item);
    `uvm_object_utils(ltsm_base_seq)
    function new(string name="ltsm_base_seq"); super.new(name); endfunction
    task send(ltsm_op_e op, retrain_target_e rt=RETRAIN_TXSELFCAL, int n=1);
      ltsm_item t=ltsm_item::type_id::create("t"); start_item(t); t.op=op; t.retrain_target=rt; t.cycles=n; t.response_cycles=n; finish_item(t);
    endtask
    task train_to_active();
      send(OP_START);
      send(OP_DONE); repeat(6) send(OP_DONE); repeat(13) send(OP_DONE); send(OP_RDI_ACTIVE);
    endtask
  endclass

  class nominal_seq extends ltsm_base_seq;
    `uvm_object_utils(nominal_seq)
    function new(string name="nominal_seq"); super.new(name); endfunction
    task body(); train_to_active(); endtask
  endclass
  class timeout_seq extends ltsm_base_seq;
    `uvm_object_utils(timeout_seq)
    function new(string name="timeout_seq"); super.new(name); endfunction
    task body(); send(OP_START); send(OP_WAIT_TIMEOUT); endtask
  endclass
  class recovery_seq extends ltsm_base_seq;
    `uvm_object_utils(recovery_seq)
    function new(string name="recovery_seq"); super.new(name); endfunction
    task body();
      train_to_active(); send(OP_RETRAIN,RETRAIN_SPEEDIDLE); send(OP_DONE); send(OP_FATAL);
    endtask
  endclass
  class pm_seq extends ltsm_base_seq;
    `uvm_object_utils(pm_seq)
    function new(string name="pm_seq"); super.new(name); endfunction
    task body(); train_to_active(); send(OP_L1_EXIT); endtask
  endclass
  class sb_success_seq extends ltsm_base_seq;
    `uvm_object_utils(sb_success_seq)
    function new(string name="sb_success_seq"); super.new(name); endfunction
    task body(); send(OP_START); send(OP_SB_SUCCESS); endtask
  endclass
  class sb_retry_seq extends ltsm_base_seq;
    `uvm_object_utils(sb_retry_seq)
    function new(string name="sb_retry_seq"); super.new(name); endfunction
    task body(); send(OP_START); send(OP_SB_RETRY_SUCCESS); endtask
  endclass
  class sb_error_seq extends ltsm_base_seq;
    `uvm_object_utils(sb_error_seq)
    function new(string name="sb_error_seq"); super.new(name); endfunction
    task body(); send(OP_START); send(OP_SB_BAD_RESPONSE); endtask
  endclass
  class sb_exhaust_seq extends ltsm_base_seq;
    `uvm_object_utils(sb_exhaust_seq)
    function new(string name="sb_exhaust_seq"); super.new(name); endfunction
    task body(); send(OP_START); send(OP_SB_EXHAUST_RETRIES); endtask
  endclass
  class sb_random_seq extends ltsm_base_seq;
    `uvm_object_utils(sb_random_seq)
    int iterations=40;
    int expected_requests, expected_successes, expected_retries, expected_errors;
    int scenario_hits[4];
    function new(string name="sb_random_seq"); super.new(name); endfunction
    task body();
      ltsm_item t;
      int scenario;
      for(int i=0;i<iterations;i++) begin
        send(OP_RESET); send(OP_START);
        // Guarantee the four outcomes once, then select them randomly.
        scenario = (i<4) ? i : $urandom_range(3,0);
        scenario_hits[scenario]++;
        t=ltsm_item::type_id::create($sformatf("random_sb_%0d",i));
        start_item(t);
        // Questa Starter does not license class randomize(); use the seeded
        // simulator PRNG while explicitly constraining the legal latency domain.
        t.cycles=$urandom_range(3,1);
        t.response_cycles=$urandom_range(3,1);
        case(scenario)
          0: begin t.op=OP_SB_SUCCESS; expected_requests++; expected_successes++; end
          1: begin t.op=OP_SB_RETRY_SUCCESS; expected_requests+=2; expected_retries++; expected_successes++; end
          2: begin t.op=OP_SB_BAD_RESPONSE; expected_requests++; expected_errors++; end
          3: begin t.op=OP_SB_EXHAUST_RETRIES; expected_requests+=2; expected_retries++; expected_errors++; end
        endcase
        finish_item(t);
      end
    endtask
  endclass

  class ltsm_base_test extends uvm_test;
    `uvm_component_utils(ltsm_base_test)
    ltsm_env env;
    function new(string name,uvm_component parent); super.new(name,parent); endfunction
    function void build_phase(uvm_phase phase); env=ltsm_env::type_id::create("env",this); endfunction
  endclass
  class nominal_test extends ltsm_base_test;
    `uvm_component_utils(nominal_test)
    function new(string name,uvm_component parent); super.new(name,parent); endfunction
    task run_phase(uvm_phase phase); nominal_seq s=nominal_seq::type_id::create("s"); phase.raise_objection(this); s.start(env.agent.sqr); #50ns; phase.drop_objection(this); endtask
    function void report_phase(uvm_phase phase); if(!env.sb.saw_active) `uvm_error("COVERAGE","ACTIVE not reached") endfunction
  endclass
  class timeout_test extends ltsm_base_test;
    `uvm_component_utils(timeout_test)
    function new(string name,uvm_component parent); super.new(name,parent); endfunction
    task run_phase(uvm_phase phase); timeout_seq s=timeout_seq::type_id::create("s"); phase.raise_objection(this); s.start(env.agent.sqr); #50ns; phase.drop_objection(this); endtask
    function void report_phase(uvm_phase phase); if(!env.sb.saw_trainerror) `uvm_error("COVERAGE","Timeout did not reach TRAINERROR") endfunction
  endclass
  class recovery_test extends ltsm_base_test;
    `uvm_component_utils(recovery_test)
    function new(string name,uvm_component parent); super.new(name,parent); endfunction
    task run_phase(uvm_phase phase); recovery_seq s=recovery_seq::type_id::create("s"); phase.raise_objection(this); s.start(env.agent.sqr); #50ns; phase.drop_objection(this); endtask
    function void report_phase(uvm_phase phase); if(!env.sb.saw_retrain || !env.sb.saw_trainerror) `uvm_error("COVERAGE","Retrain/error path incomplete") endfunction
  endclass
  class pm_test extends ltsm_base_test;
    `uvm_component_utils(pm_test)
    function new(string name,uvm_component parent); super.new(name,parent); endfunction
    task run_phase(uvm_phase phase); pm_seq s=pm_seq::type_id::create("s"); phase.raise_objection(this); s.start(env.agent.sqr); #50ns; phase.drop_objection(this); endtask
    function void report_phase(uvm_phase phase); if(!env.sb.saw_l1l2) `uvm_error("COVERAGE","L1/L2 not reached") endfunction
  endclass
  class sb_success_test extends ltsm_base_test;
    `uvm_component_utils(sb_success_test)
    function new(string name,uvm_component parent); super.new(name,parent); endfunction
    task run_phase(uvm_phase phase); sb_success_seq s=sb_success_seq::type_id::create("s"); phase.raise_objection(this); s.start(env.agent.sqr); #50ns; phase.drop_objection(this); endtask
    function void report_phase(uvm_phase phase);
      if(env.agent.mon.sb_requests!=1 || env.agent.mon.sb_responses!=1 || env.sb.transitions<2)
        `uvm_error("SB_SUCCESS","Expected one accepted request/response and SBINIT exit")
    endfunction
  endclass
  class sb_retry_test extends ltsm_base_test;
    `uvm_component_utils(sb_retry_test)
    function new(string name,uvm_component parent); super.new(name,parent); endfunction
    task run_phase(uvm_phase phase); sb_retry_seq s=sb_retry_seq::type_id::create("s"); phase.raise_objection(this); s.start(env.agent.sqr); #50ns; phase.drop_objection(this); endtask
    function void report_phase(uvm_phase phase);
      if(env.agent.mon.sb_requests!=2 || env.agent.mon.sb_retries!=1 || env.agent.mon.sb_responses!=1)
        `uvm_error("SB_RETRY","Expected exactly one retry followed by success")
    endfunction
  endclass
  class sb_error_test extends ltsm_base_test;
    `uvm_component_utils(sb_error_test)
    function new(string name,uvm_component parent); super.new(name,parent); endfunction
    task run_phase(uvm_phase phase); sb_error_seq s=sb_error_seq::type_id::create("s"); phase.raise_objection(this); s.start(env.agent.sqr); #50ns; phase.drop_objection(this); endtask
    function void report_phase(uvm_phase phase);
      if(env.agent.mon.sb_errors!=1 || !env.sb.saw_trainerror)
        `uvm_error("SB_ERROR","Wrong response did not cause protocol error and TRAINERROR")
    endfunction
  endclass
  class sb_exhaust_test extends ltsm_base_test;
    `uvm_component_utils(sb_exhaust_test)
    function new(string name,uvm_component parent); super.new(name,parent); endfunction
    task run_phase(uvm_phase phase); sb_exhaust_seq s=sb_exhaust_seq::type_id::create("s"); phase.raise_objection(this); s.start(env.agent.sqr); #50ns; phase.drop_objection(this); endtask
    function void report_phase(uvm_phase phase);
      if(env.agent.mon.sb_requests!=2 || env.agent.mon.sb_retries!=1 ||
         env.agent.mon.sb_errors!=1 || !env.sb.saw_trainerror)
        `uvm_error("SB_EXHAUST","Retry exhaustion did not produce the bounded error path")
    endfunction
  endclass
  class sb_random_test extends ltsm_base_test;
    `uvm_component_utils(sb_random_test)
    sb_random_seq s;
    function new(string name,uvm_component parent); super.new(name,parent); endfunction
    task run_phase(uvm_phase phase);
      s=sb_random_seq::type_id::create("s");
      phase.raise_objection(this); s.start(env.agent.sqr); #100ns; phase.drop_objection(this);
    endtask
    function void report_phase(uvm_phase phase);
      foreach(s.scenario_hits[i]) if(s.scenario_hits[i]==0)
        `uvm_error("RANDCOV",$sformatf("Random scenario %0d was not exercised",i))
      if(env.agent.mon.sb_requests!=s.expected_requests ||
         env.agent.mon.sb_responses!=s.expected_successes ||
         env.agent.mon.sb_retries!=s.expected_retries ||
         env.agent.mon.sb_errors!=s.expected_errors)
        `uvm_error("RANDPRED",$sformatf("predicted req/success/retry/error=%0d/%0d/%0d/%0d observed=%0d/%0d/%0d/%0d",
          s.expected_requests,s.expected_successes,s.expected_retries,s.expected_errors,
          env.agent.mon.sb_requests,env.agent.mon.sb_responses,
          env.agent.mon.sb_retries,env.agent.mon.sb_errors))
      `uvm_info("RANDSUMMARY",$sformatf("iterations=%0d scenario hits=%0d/%0d/%0d/%0d",
        s.iterations,s.scenario_hits[0],s.scenario_hits[1],s.scenario_hits[2],s.scenario_hits[3]),UVM_LOW)
    endfunction
  endclass
endpackage
