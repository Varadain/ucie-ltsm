`timescale 1ns/1ps
module tb_ucie_ltsm_uvm;
  import uvm_pkg::*;
  import ucie_ltsm_pkg::*;
  import ucie_ltsm_uvm_pkg::*;
  logic clk=0;
  logic sb_tx_valid, sb_busy, sb_protocol_error, sb_retry;
  sb_msg_e sb_tx_message;
  always #5 clk=~clk;
  ucie_ltsm_if intf(clk);
  ucie_ltsm #(.CLK_HZ(100_000_000),.RESET_MIN_US(1),.TIMEOUT_US(2)) dut(
    .clk_i(clk),.rst_ni(intf.rst_n),.supplies_stable_i(intf.supplies_stable),
    .sideband_clk_ok_i(intf.sideband_clk_ok),.internal_clks_ok_i(intf.internal_clks_ok),
    .firmware_reset_i(intf.firmware_reset),.link_train_trigger_i(intf.link_train_trigger),
    .phase_done_i(intf.phase_done),.stall_i(intf.stall),.fatal_error_i(intf.fatal_error),
    .error_handshake_done_i(intf.error_handshake_done),.error_escalated_i(intf.error_escalated),
    .sideband_tx_idle_i(intf.sideband_tx_idle),.rdi_active_i(intf.rdi_active),
    .retrain_req_i(intf.retrain_req),.retrain_target_i(intf.retrain_target),
    .pm_l1_req_i(intf.pm_l1_req),.pm_l2_req_i(intf.pm_l2_req),.pm_exit_i(intf.pm_exit),
    .sb_tx_valid_o(sb_tx_valid),.sb_tx_message_o(sb_tx_message),.sb_tx_ready_i(1'b0),
    .sb_rx_valid_i(1'b0),.sb_rx_message_i(SB_MSG_NOP),.sb_busy_o(sb_busy),
    .sb_protocol_error_o(sb_protocol_error),.sb_retry_o(sb_retry),
    .state_o(intf.state),.mbinit_state_o(intf.mbi),.mbtrain_state_o(intf.mbt),
    .timeout_o(intf.timeout),.link_up_o(intf.link_up),
    .mainband_tristate_o(intf.mainband_tristate),.sideband_enable_o(intf.sideband_enable));
  ucie_ltsm_sva sva(.clk_i(clk),.rst_ni(intf.rst_n),.state_i(intf.state),
                    .timeout_i(intf.timeout),.link_up_i(intf.link_up),.fatal_error_i(intf.fatal_error));
  initial begin
    intf.rst_n=0; intf.clear_controls(); repeat(3) @(posedge clk); #1 intf.rst_n=1;
  end
  initial begin
    uvm_config_db#(virtual ucie_ltsm_if)::set(null,"uvm_test_top.env.agent.*","vif",intf);
    run_test();
  end
endmodule
