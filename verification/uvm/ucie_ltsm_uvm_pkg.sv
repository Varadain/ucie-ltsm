package ucie_ltsm_uvm_pkg;
  import uvm_pkg::*;
  import ucie_ltsm_pkg::*;
  `include "uvm_macros.svh"

  typedef enum {OP_RESET, OP_START, OP_DONE, OP_RDI_ACTIVE, OP_RETRAIN, OP_FATAL,
                OP_STALL, OP_WAIT_TIMEOUT, OP_L1_EXIT, OP_L2_EXIT,
                OP_SB_SUCCESS, OP_SB_RETRY_SUCCESS, OP_SB_BAD_RESPONSE,
                OP_SB_EXHAUST_RETRIES, OP_TRAIN_TRIAL, OP_RECOVERY_TRIAL,
                OP_RECOVERY_CLOSURE} ltsm_op_e;

  class ltsm_item extends uvm_sequence_item;
    rand ltsm_op_e op;
    rand retrain_target_e retrain_target;
    rand int unsigned cycles;
    rand int unsigned response_cycles;
    int unsigned train_scenario;
    int unsigned error_bits;
    int unsigned threshold;
    int unsigned abort_sample;
    int unsigned recovery_scenario, recovery_origin, pulse_cycles, ack_cycles;
    bit recovery_escalated, recovery_idle;
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
    int train_trials, train_passes, train_failures, train_aborts, train_timeouts;
    int train_retries, clean_samples, corrupt_samples, gap_cycles;
    int cov_scenario[4], cov_error[4], cov_gap[3], cov_threshold[2], cov_scenario_gap[4][3];
    int recovery_trials, recovery_entries, recovery_timeouts, recovery_delayed;
    int recovery_sb, recovery_residency, recovery_simultaneous;
    int rec_cov_scenario[6], rec_cov_origin[7], rec_cov_pulse[2], rec_cov_ack[3];
    int rec_cov_scenario_origin[6][7];
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if(!uvm_config_db#(virtual ucie_ltsm_if)::get(this,"","vif",vif))
        `uvm_fatal("NOVIF","LTSM virtual interface not configured")
    endfunction
    task pulse(ref logic sig); sig=1; @(posedge vif.clk); #1 sig=0; endtask
    function automatic logic [22:0] train_seed(input int lane);
      case(lane%8)
        0: return 23'h1dbfbc; 1: return 23'h0607bb; 2: return 23'h1ec760; 3: return 23'h18c0db;
        4: return 23'h010f12; 5: return 23'h19cfc9; 6: return 23'h0277ce; default: return 23'h1bb807;
      endcase
    endfunction
    function automatic logic [22:0] train_next(input logic [22:0] v);
      return {v[21:0],v[22]^v[20]^v[15]^v[7]^v[4]^v[1]};
    endfunction
    task goto_train_center1();
      vif.supplies_stable=1; vif.sideband_clk_ok=1; vif.internal_clks_ok=1;
      vif.link_train_trigger=1; wait(vif.state==LTSM_SBINIT);
      pulse(vif.phase_done);
      repeat(6) pulse(vif.phase_done);
      repeat(7) pulse(vif.phase_done);
      if(vif.state!=LTSM_MBTRAIN || vif.mbt!=MBT_DATATRAINCENTER1)
        `uvm_error("TRAIN_NAV","Failed to reach DATATRAINCENTER1")
      wait(vif.train_busy && vif.state==LTSM_MBTRAIN && vif.mbt==MBT_DATATRAINCENTER1); #1;
    endtask
    task goto_recovery_origin(input int origin);
      vif.supplies_stable=1; vif.sideband_clk_ok=1; vif.internal_clks_ok=1;
      vif.link_train_trigger=1; wait(vif.state==LTSM_SBINIT);
      if(origin==0) return;
      pulse(vif.phase_done); if(origin==1) return;
      repeat(6) pulse(vif.phase_done); if(origin==2) return;
      repeat(13) pulse(vif.phase_done); if(origin==3) return;
      pulse(vif.rdi_active); if(origin==4) return;
      if(origin==5) begin pulse(vif.retrain_req); return; end
      vif.pm_l1_req=1; @(posedge vif.clk); #1; vif.pm_l1_req=0;
    endtask
    task finish_recovery(input ltsm_error_cause_e expected);
      wait(vif.state==LTSM_TRAINERROR); #1; recovery_entries++;
      if(vif.error_pending) `uvm_error("REC_PENDING","Pending not cleared on TRAINERROR entry")
      if(vif.error_cause!=expected || vif.error_event_count!=1)
        `uvm_error("REC_PRED",$sformatf("expected cause/count=%0d/1 observed=%0d/%0d",
          expected,vif.error_cause,vif.error_event_count))
      vif.clear_error_log=1; @(posedge vif.clk); #1; vif.clear_error_log=0;
      if(vif.error_cause!=expected || vif.error_event_count!=1)
        `uvm_error("REC_CLEAR","Clear changed log in TRAINERROR")
      repeat(2) @(posedge vif.clk); #1;
      vif.error_escalated=0; vif.sideband_tx_idle=1;
      wait(vif.state==LTSM_RESET); #1;
      vif.clear_error_log=1; @(posedge vif.clk); #1; vif.clear_error_log=0;
      if(vif.error_cause!=LTSM_ERR_NONE || vif.error_event_count!=0)
        `uvm_error("REC_CLEAR","Allowed clear did not clear retained log")
    endtask
    task drive_recovery(ltsm_item tr);
      ltsm_error_cause_e expected=LTSM_ERR_LOCAL_FATAL;
      `uvm_info("REC_TRIAL",$sformatf("scenario=%0d origin=%0d pulse=%0d ack=%0d",
        tr.recovery_scenario,tr.recovery_origin,tr.pulse_cycles,tr.ack_cycles),UVM_MEDIUM)
      recovery_trials++; rec_cov_scenario[tr.recovery_scenario]++;
      rec_cov_origin[tr.recovery_origin]++; rec_cov_scenario_origin[tr.recovery_scenario][tr.recovery_origin]++;
      rec_cov_pulse[tr.pulse_cycles>1]++;
      rec_cov_ack[(tr.recovery_scenario==1)?2:((tr.ack_cycles==0)?0:1)]++;
      goto_recovery_origin(tr.recovery_origin);
      vif.sideband_tx_idle=tr.recovery_idle; vif.error_escalated=tr.recovery_escalated;
      case(tr.recovery_scenario)
        0,4: begin
          @(negedge vif.clk); vif.fatal_error=1; #1;
          if(!vif.trainerror_handshake_request) `uvm_error("REC_REQ","Handshake request not immediate")
          repeat(tr.pulse_cycles) @(posedge vif.clk); #1; vif.fatal_error=0;
          if(!vif.error_pending || !vif.trainerror_handshake_request)
            `uvm_error("REC_SHORT","Short/held fatal was not retained pending")
          vif.clear_error_log=1; @(posedge vif.clk); #1; vif.clear_error_log=0;
          repeat(tr.ack_cycles) begin
            if(!vif.trainerror_handshake_request) `uvm_error("REC_REQ","Request dropped before ack")
            @(posedge vif.clk);
          end
          vif.error_handshake_done=1; @(posedge vif.clk); #1; vif.error_handshake_done=0;
          recovery_delayed++; if(tr.recovery_scenario==4) recovery_residency++;
        end
        1: begin
          pulse(vif.fatal_error); wait(vif.error_handshake_timeout); recovery_timeouts++;
        end
        2: begin wait(vif.timeout); expected=LTSM_ERR_STATE_TIMEOUT; end
        3: begin
          if(vif.state!=LTSM_SBINIT) `uvm_error("REC_SB","SB scenario outside SBINIT")
          wait(vif.sb_tx_valid); @(negedge vif.clk); vif.sb_tx_ready=1;
          @(posedge vif.clk); #1 vif.sb_tx_ready=0;
          @(negedge vif.clk); vif.sb_rx_message=SB_MSG_NOP; vif.sb_rx_valid=1;
          @(posedge vif.clk); #1 vif.sb_rx_valid=0;
          expected=LTSM_ERR_SIDEBAND_PROTOCOL; recovery_sb++;
          if(vif.trainerror_handshake_request) `uvm_error("REC_SB","SBINIT incorrectly requested handshake")
        end
        default: begin
          wait(vif.timeout); vif.fatal_error=1; #1;
          expected=LTSM_ERR_STATE_TIMEOUT; recovery_simultaneous++;
          @(posedge vif.clk); #1 vif.fatal_error=0;
        end
      endcase
      finish_recovery(expected);
    endtask
    task drive_train_attempt(input int error_bits, input int threshold, input int gap,
                             input int abort_sample, input bit expect_pass);
      logic [22:0] ref_lfsr[16]; logic [15:0] expected, mask;
      int expected_errors=0;
      for(int l=0;l<16;l++) ref_lfsr[l]=train_seed(l);
      vif.train_error_threshold=threshold;
      for(int n=0;n<8;n++) begin
        repeat(gap) begin @(posedge vif.clk); gap_cycles++; end
        if(abort_sample==n) begin
          pulse(vif.phase_done); train_aborts++;
          repeat(2) @(posedge vif.clk); #1;
          if(vif.train_busy || vif.train_done || vif.train_pass || vif.train_error_count)
            `uvm_error("TRAIN_ABORT","Training engine not cleared after leaving DATATRAINCENTER1")
          return;
        end
        for(int l=0;l<16;l++) expected[l]=ref_lfsr[l][22];
        if(vif.train_tx_pattern!==expected)
          `uvm_error("TRAIN_LFSR",$sformatf("sample=%0d expected=%h got=%h",n,expected,vif.train_tx_pattern))
        mask='0;
        for(int b=0;b<error_bits;b++) mask[(b+n)%16]=1'b1;
        expected_errors+=error_bits;
        if(error_bits==0) clean_samples++; else corrupt_samples++;
        @(negedge vif.clk); vif.train_rx_pattern=expected^mask; vif.train_rx_valid=1;
        @(posedge vif.clk); #1; vif.train_rx_valid=0;
        for(int l=0;l<16;l++) ref_lfsr[l]=train_next(ref_lfsr[l]);
      end
      if(!vif.train_done || vif.train_error_count!=expected_errors || vif.train_pass!=expect_pass)
        `uvm_error("TRAIN_RESULT",$sformatf("expected errors/pass=%0d/%0b observed=%0d/%0b done=%0b",
          expected_errors,expect_pass,vif.train_error_count,vif.train_pass,vif.train_done))
      if(expect_pass) train_passes++; else train_failures++;
      @(posedge vif.clk); #1;
    endtask
    task drive(ltsm_item tr);
      case(tr.op)
        OP_RESET: begin
          vif.rst_n=0; vif.clear_controls();
          repeat(3) @(posedge vif.clk); #1 vif.rst_n=1;
          @(posedge vif.clk); #1;
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
        OP_TRAIN_TRIAL: begin
          train_trials++;
          cov_scenario[tr.train_scenario]++;
          if(tr.error_bits==0) cov_error[0]++;
          else if(tr.error_bits<=4) cov_error[1]++;
          else if(tr.error_bits<16) cov_error[2]++;
          else cov_error[3]++;
          if(tr.cycles==0) begin cov_gap[0]++; cov_scenario_gap[tr.train_scenario][0]++; end
          else if(tr.cycles<=2) begin cov_gap[1]++; cov_scenario_gap[tr.train_scenario][1]++; end
          else begin cov_gap[2]++; cov_scenario_gap[tr.train_scenario][2]++; end
          cov_threshold[tr.threshold==tr.error_bits*8]++;
          goto_train_center1();
          case(tr.train_scenario)
            0: begin
              drive_train_attempt(tr.error_bits,tr.threshold,tr.cycles,-1,1);
              if(vif.mbt!=MBT_DATATRAINVREF) `uvm_error("TRAIN_ADVANCE","Passing run did not advance")
            end
            1: begin
              drive_train_attempt(tr.error_bits,tr.threshold,tr.cycles,-1,0);
              if(vif.mbt!=MBT_DATATRAINCENTER1) `uvm_error("TRAIN_RESIDE","Failed run left center1")
              train_retries++; wait(vif.train_busy); #1;
              drive_train_attempt(0,1,tr.response_cycles,-1,1);
              if(vif.mbt!=MBT_DATATRAINVREF) `uvm_error("TRAIN_RETRY","Retry pass did not advance")
            end
            2: drive_train_attempt(tr.error_bits,tr.threshold,tr.cycles,tr.abort_sample,0);
            default: begin
              wait(vif.timeout); train_timeouts++;
              @(posedge vif.clk); #1;
              if(vif.state!=LTSM_TRAINERROR) `uvm_error("TRAIN_TIMEOUT","LTSM timeout did not enter TRAINERROR")
              @(posedge vif.clk); #1;
              if(vif.train_busy) `uvm_error("TRAIN_TIMEOUT","Engine remained busy after timeout abort")
            end
          endcase
        end
        OP_RECOVERY_TRIAL: drive_recovery(tr);
        OP_RECOVERY_CLOSURE: begin
          // L2 exit and all retrain targets close pre-v0.4 planned gaps.
          goto_recovery_origin(4); vif.pm_l2_req=1; @(posedge vif.clk); #1;
          vif.pm_exit=1; @(posedge vif.clk); #1; vif.pm_exit=0; vif.pm_l2_req=0;
          if(vif.state!=LTSM_RESET) `uvm_error("REC_CLOSE","L2 exit did not reset")
          for(int rt=0;rt<3;rt++) begin
            vif.rst_n=0; vif.clear_controls(); repeat(3) @(posedge vif.clk); #1 vif.rst_n=1;
            goto_recovery_origin(4); vif.retrain_target=retrain_target_e'(rt);
            pulse(vif.retrain_req); pulse(vif.phase_done);
            if(vif.state!=LTSM_MBTRAIN) `uvm_error("REC_CLOSE","Retrain did not enter MBTRAIN")
            case(rt)
              0: if(vif.mbt!=MBT_TXSELFCAL) `uvm_error("REC_CLOSE","TXSELFCAL target mismatch")
              1: if(vif.mbt!=MBT_SPEEDIDLE) `uvm_error("REC_CLOSE","SPEEDIDLE target mismatch")
              2: if(vif.mbt!=MBT_REPAIR) `uvm_error("REC_CLOSE","REPAIR target mismatch")
            endcase
          end
        end
      endcase
    endtask
    task run_phase(uvm_phase phase);
      forever begin seq_item_port.get_next_item(req); drive(req); seq_item_port.item_done(); end
    endtask
    function void report_phase(uvm_phase phase);
      `uvm_info("TRAIN_COVERAGE",$sformatf("trials=%0d pass=%0d fail=%0d retry=%0d abort=%0d timeout=%0d clean_samples=%0d corrupt_samples=%0d gap_cycles=%0d",
        train_trials,train_passes,train_failures,train_retries,train_aborts,train_timeouts,
        clean_samples,corrupt_samples,gap_cycles),UVM_LOW)
      `uvm_info("TRAIN_FUNC_COVERAGE",$sformatf("scenario=%0d/%0d/%0d/%0d error_bins=%0d/%0d/%0d/%0d gap_bins=%0d/%0d/%0d threshold_away/equal=%0d/%0d scenario_x_gap=%0d,%0d,%0d;%0d,%0d,%0d;%0d,%0d,%0d;%0d,%0d,%0d",
        cov_scenario[0],cov_scenario[1],cov_scenario[2],cov_scenario[3],
        cov_error[0],cov_error[1],cov_error[2],cov_error[3],cov_gap[0],cov_gap[1],cov_gap[2],
        cov_threshold[0],cov_threshold[1],
        cov_scenario_gap[0][0],cov_scenario_gap[0][1],cov_scenario_gap[0][2],
        cov_scenario_gap[1][0],cov_scenario_gap[1][1],cov_scenario_gap[1][2],
        cov_scenario_gap[2][0],cov_scenario_gap[2][1],cov_scenario_gap[2][2],
        cov_scenario_gap[3][0],cov_scenario_gap[3][1],cov_scenario_gap[3][2]),UVM_LOW)
      `uvm_info("RECOVERY_COVERAGE",$sformatf("trials=%0d entries=%0d delayed=%0d manager_timeout=%0d sbinit=%0d residency=%0d simultaneous=%0d scenario=%0d/%0d/%0d/%0d/%0d/%0d origin=%0d/%0d/%0d/%0d/%0d/%0d/%0d pulse_short/held=%0d/%0d ack_zero/delayed/missing=%0d/%0d/%0d",
        recovery_trials,recovery_entries,recovery_delayed,recovery_timeouts,recovery_sb,recovery_residency,recovery_simultaneous,
        rec_cov_scenario[0],rec_cov_scenario[1],rec_cov_scenario[2],rec_cov_scenario[3],rec_cov_scenario[4],rec_cov_scenario[5],
        rec_cov_origin[0],rec_cov_origin[1],rec_cov_origin[2],rec_cov_origin[3],rec_cov_origin[4],rec_cov_origin[5],rec_cov_origin[6],
        rec_cov_pulse[0],rec_cov_pulse[1],rec_cov_ack[0],rec_cov_ack[1],rec_cov_ack[2]),UVM_LOW)
      `uvm_info("RECOVERY_CROSS",$sformatf("scenario_x_origin=%0d,%0d,%0d,%0d,%0d,%0d,%0d;%0d,%0d,%0d,%0d,%0d,%0d,%0d;%0d,%0d,%0d,%0d,%0d,%0d,%0d;%0d,%0d,%0d,%0d,%0d,%0d,%0d;%0d,%0d,%0d,%0d,%0d,%0d,%0d;%0d,%0d,%0d,%0d,%0d,%0d,%0d",
        rec_cov_scenario_origin[0][0],rec_cov_scenario_origin[0][1],rec_cov_scenario_origin[0][2],rec_cov_scenario_origin[0][3],rec_cov_scenario_origin[0][4],rec_cov_scenario_origin[0][5],rec_cov_scenario_origin[0][6],
        rec_cov_scenario_origin[1][0],rec_cov_scenario_origin[1][1],rec_cov_scenario_origin[1][2],rec_cov_scenario_origin[1][3],rec_cov_scenario_origin[1][4],rec_cov_scenario_origin[1][5],rec_cov_scenario_origin[1][6],
        rec_cov_scenario_origin[2][0],rec_cov_scenario_origin[2][1],rec_cov_scenario_origin[2][2],rec_cov_scenario_origin[2][3],rec_cov_scenario_origin[2][4],rec_cov_scenario_origin[2][5],rec_cov_scenario_origin[2][6],
        rec_cov_scenario_origin[3][0],rec_cov_scenario_origin[3][1],rec_cov_scenario_origin[3][2],rec_cov_scenario_origin[3][3],rec_cov_scenario_origin[3][4],rec_cov_scenario_origin[3][5],rec_cov_scenario_origin[3][6],
        rec_cov_scenario_origin[4][0],rec_cov_scenario_origin[4][1],rec_cov_scenario_origin[4][2],rec_cov_scenario_origin[4][3],rec_cov_scenario_origin[4][4],rec_cov_scenario_origin[4][5],rec_cov_scenario_origin[4][6],
        rec_cov_scenario_origin[5][0],rec_cov_scenario_origin[5][1],rec_cov_scenario_origin[5][2],rec_cov_scenario_origin[5][3],rec_cov_scenario_origin[5][4],rec_cov_scenario_origin[5][5],rec_cov_scenario_origin[5][6]),UVM_LOW)
    endfunction
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
  class datatrain_random_seq extends ltsm_base_seq;
    `uvm_object_utils(datatrain_random_seq)
    int iterations=32;
    int scenario_hits[4];
    function new(string name="datatrain_random_seq"); super.new(name); endfunction
    task body();
      ltsm_item t; int scenario, total_errors;
      for(int i=0;i<iterations;i++) begin
        send(OP_RESET);
        scenario=(i<4)?i:$urandom_range(3,0);
        scenario_hits[scenario]++;
        t=ltsm_item::type_id::create($sformatf("random_train_%0d",i)); start_item(t);
        t.op=OP_TRAIN_TRIAL; t.train_scenario=scenario;
        t.cycles=$urandom_range(3,0); t.response_cycles=$urandom_range(3,0);
        t.error_bits=(scenario==0)?$urandom_range(3,0):$urandom_range(16,1);
        total_errors=t.error_bits*8;
        t.threshold=(scenario==0)?$urandom_range(16'hfffe,total_errors+1):
                    $urandom_range(total_errors,0);
        t.abort_sample=$urandom_range(7,0);
        finish_item(t);
      end
    endtask
  endclass
  class recovery_random_seq extends ltsm_base_seq;
    `uvm_object_utils(recovery_random_seq)
    int iterations=36; int scenario_hits[6], origin_hits[7];
    function new(string name="recovery_random_seq"); super.new(name); endfunction
    task body();
      ltsm_item t; int scenario,origin;
      for(int i=0;i<iterations;i++) begin
        send(OP_RESET);
        if(i<7) begin
          origin=i;
          case(i) 0:scenario=3; 1:scenario=2; 2:scenario=5; 3:scenario=2;
                  4:scenario=0; 5:scenario=2; default:scenario=4; endcase
        end else if(i==7) begin scenario=1; origin=4; end
        else begin
          scenario=$urandom_range(5,0);
          if(scenario==3) origin=0;
          else if(scenario==1) origin=4;
          else if(scenario inside {2,5}) origin=$urandom_range(3,1);
          else origin=$urandom_range(6,1);
        end
        scenario_hits[scenario]++; origin_hits[origin]++;
        t=ltsm_item::type_id::create($sformatf("random_recovery_%0d",i)); start_item(t);
        t.op=OP_RECOVERY_TRIAL; t.recovery_scenario=scenario; t.recovery_origin=origin;
        t.pulse_cycles=$urandom_range(4,1); t.ack_cycles=$urandom_range(8,0);
        t.recovery_escalated=(scenario==4)?$urandom_range(1,0):0;
        t.recovery_idle=(scenario==4)?!t.recovery_escalated:0;
        finish_item(t);
      end
    endtask
  endclass
  class recovery_closure_seq extends ltsm_base_seq;
    `uvm_object_utils(recovery_closure_seq)
    function new(string name="recovery_closure_seq"); super.new(name); endfunction
    task body(); send(OP_RESET); send(OP_RECOVERY_CLOSURE); endtask
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
  class datatrain_random_test extends ltsm_base_test;
    `uvm_component_utils(datatrain_random_test)
    datatrain_random_seq s;
    function new(string name,uvm_component parent); super.new(name,parent); endfunction
    task run_phase(uvm_phase phase);
      s=datatrain_random_seq::type_id::create("s");
      phase.raise_objection(this); s.start(env.agent.sqr); #100ns; phase.drop_objection(this);
    endtask
    function void report_phase(uvm_phase phase);
      foreach(s.scenario_hits[i]) if(s.scenario_hits[i]==0)
        `uvm_error("TRAIN_RANDCOV",$sformatf("Training scenario %0d was not exercised",i))
      if(env.agent.drv.train_trials!=s.iterations || env.agent.drv.train_passes==0 ||
         env.agent.drv.train_failures==0 || env.agent.drv.train_retries==0 ||
         env.agent.drv.train_aborts==0 || env.agent.drv.train_timeouts==0)
        `uvm_error("TRAIN_RANDPRED","Required randomized training outcomes were not observed")
      `uvm_info("TRAIN_RANDSUMMARY",$sformatf("iterations=%0d scenario_hits pass/retry/abort/timeout=%0d/%0d/%0d/%0d",
        s.iterations,s.scenario_hits[0],s.scenario_hits[1],s.scenario_hits[2],s.scenario_hits[3]),UVM_LOW)
    endfunction
  endclass
  class recovery_random_test extends ltsm_base_test;
    `uvm_component_utils(recovery_random_test)
    recovery_random_seq s;
    function new(string name,uvm_component parent); super.new(name,parent); endfunction
    task run_phase(uvm_phase phase);
      s=recovery_random_seq::type_id::create("s");
      phase.raise_objection(this); s.start(env.agent.sqr); #100ns; phase.drop_objection(this);
    endtask
    function void report_phase(uvm_phase phase);
      foreach(s.scenario_hits[i]) if(!s.scenario_hits[i]) `uvm_error("REC_COV","Missing recovery scenario")
      foreach(s.origin_hits[i]) if(!s.origin_hits[i]) `uvm_error("REC_COV","Missing recovery origin")
      if(env.agent.drv.recovery_trials!=s.iterations || env.agent.drv.recovery_entries!=s.iterations)
        `uvm_error("REC_PRED","Recovery trial/entry count mismatch")
      `uvm_info("RECOVERY_SUMMARY",$sformatf("iterations=%0d scenario=%0d/%0d/%0d/%0d/%0d/%0d origin=%0d/%0d/%0d/%0d/%0d/%0d/%0d",
        s.iterations,s.scenario_hits[0],s.scenario_hits[1],s.scenario_hits[2],s.scenario_hits[3],s.scenario_hits[4],s.scenario_hits[5],
        s.origin_hits[0],s.origin_hits[1],s.origin_hits[2],s.origin_hits[3],s.origin_hits[4],s.origin_hits[5],s.origin_hits[6]),UVM_LOW)
    endfunction
  endclass
  class recovery_closure_test extends ltsm_base_test;
    `uvm_component_utils(recovery_closure_test)
    function new(string name,uvm_component parent); super.new(name,parent); endfunction
    task run_phase(uvm_phase phase);
      recovery_closure_seq s=recovery_closure_seq::type_id::create("s");
      phase.raise_objection(this); s.start(env.agent.sqr); #50ns; phase.drop_objection(this);
    endtask
  endclass
endpackage
