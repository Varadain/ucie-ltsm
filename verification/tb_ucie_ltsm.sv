`timescale 1ns/1ps
module tb_ucie_ltsm;
  import ucie_ltsm_pkg::*;
  logic clk = 0, rst_n = 0;
  logic supplies_stable, sideband_clk_ok, internal_clks_ok, firmware_reset;
  logic link_train_trigger, phase_done, stall, fatal_error, error_handshake_done;
  logic error_escalated, sideband_tx_idle, rdi_active, retrain_req;
  retrain_target_e retrain_target;
  logic pm_l1_req, pm_l2_req, pm_exit;
  ltsm_state_e state;
  mbinit_state_e mbi;
  mbtrain_state_e mbt;
  logic timeout, link_up, mainband_tristate, sideband_enable;
  logic sb_tx_valid_o, sb_tx_ready_i, sb_rx_valid_i;
  logic sb_busy_o, sb_protocol_error_o, sb_retry_o;
  sb_msg_e sb_tx_message_o, sb_rx_message_i;

  always #5 clk = ~clk;
  ucie_ltsm #(.CLK_HZ(100_000_000), .RESET_MIN_US(1), .TIMEOUT_US(2)) dut (.*,
    .clk_i(clk), .rst_ni(rst_n), .state_o(state), .mbinit_state_o(mbi),
    .mbtrain_state_o(mbt), .timeout_o(timeout), .link_up_o(link_up),
    .mainband_tristate_o(mainband_tristate), .sideband_enable_o(sideband_enable),
    .supplies_stable_i(supplies_stable), .sideband_clk_ok_i(sideband_clk_ok),
    .internal_clks_ok_i(internal_clks_ok), .firmware_reset_i(firmware_reset),
    .link_train_trigger_i(link_train_trigger), .phase_done_i(phase_done), .stall_i(stall),
    .fatal_error_i(fatal_error), .error_handshake_done_i(error_handshake_done),
    .error_escalated_i(error_escalated), .sideband_tx_idle_i(sideband_tx_idle),
    .rdi_active_i(rdi_active), .retrain_req_i(retrain_req), .retrain_target_i(retrain_target),
    .pm_l1_req_i(pm_l1_req), .pm_l2_req_i(pm_l2_req), .pm_exit_i(pm_exit));
  ucie_ltsm_sva sva(.clk_i(clk), .rst_ni(rst_n), .state_i(state),
                    .timeout_i(timeout), .link_up_i(link_up), .fatal_error_i(fatal_error));

  task automatic pulse_done; begin phase_done=1; @(posedge clk); #1 phase_done=0; end endtask
  task automatic expect_state(input ltsm_state_e exp); begin
    if (state !== exp) $fatal(1, "Expected state %0d, got %0d", exp, state);
  end endtask

  initial begin
    supplies_stable=0; sideband_clk_ok=0; internal_clks_ok=0; firmware_reset=0;
    link_train_trigger=0; phase_done=0; stall=0; fatal_error=0; error_handshake_done=0;
    error_escalated=0; sideband_tx_idle=1; rdi_active=0; retrain_req=0;
    retrain_target=RETRAIN_TXSELFCAL; pm_l1_req=0; pm_l2_req=0; pm_exit=0;
    sb_tx_ready_i=0; sb_rx_valid_i=0; sb_rx_message_i=SB_MSG_NOP;
    repeat(3) @(posedge clk); rst_n=1;
    supplies_stable=1; sideband_clk_ok=1; internal_clks_ok=1; link_train_trigger=1;
    wait(state==LTSM_SBINIT); pulse_done(); expect_state(LTSM_MBINIT);
    repeat(6) pulse_done(); expect_state(LTSM_MBTRAIN);
    repeat(13) pulse_done(); expect_state(LTSM_LINKINIT);
    rdi_active=1; @(posedge clk); #1 expect_state(LTSM_ACTIVE); rdi_active=0;

    retrain_req=1; @(posedge clk); #1 retrain_req=0; expect_state(LTSM_PHYRETRAIN);
    retrain_target=RETRAIN_SPEEDIDLE; pulse_done(); expect_state(LTSM_MBTRAIN);
    if (mbt != MBT_SPEEDIDLE) $fatal(1,"Wrong retrain target");

    fatal_error=1; error_handshake_done=1; @(posedge clk); #1 fatal_error=0;
    error_handshake_done=0; expect_state(LTSM_TRAINERROR);
    @(posedge clk); #1 expect_state(LTSM_RESET);
    $display("PASS: nominal training, retrain, and error recovery");
    $finish;
  end
endmodule
