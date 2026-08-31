`timescale 1ns/1ps
module tb_ucie_integrated_uvm;
  import uvm_pkg::*;import ucie_ltsm_pkg::*;import ucie_integrated_uvm_pkg::*;
  logic clk=0;always #5 clk=~clk;ucie_ltsm_if intf(clk);
  ucie_ltsm #(.CLK_HZ(100_000_000),.RESET_MIN_US(1),.TIMEOUT_US(1),
    .SB_RESPONSE_TIMEOUT_CYCLES(8),.SB_MAX_RETRIES(1),
    .DATATRAIN_SAMPLE_COUNT(8),.ALLOW_ABSTRACT_DATATRAIN_BYPASS(1'b0)) dut(
    .clk_i(clk),.rst_ni(intf.rst_n),.supplies_stable_i(intf.supplies_stable),
    .sideband_clk_ok_i(intf.sideband_clk_ok),.internal_clks_ok_i(intf.internal_clks_ok),
    .firmware_reset_i(intf.firmware_reset),.link_train_trigger_i(intf.link_train_trigger),
    .phase_done_i(intf.phase_done),.stall_i(intf.stall),.fatal_error_i(intf.fatal_error),
    .error_handshake_done_i(intf.error_handshake_done),.error_escalated_i(intf.error_escalated),
    .sideband_tx_idle_i(intf.sideband_tx_idle),.rdi_active_i(intf.rdi_active),
    .retrain_req_i(intf.retrain_req),.retrain_target_i(intf.retrain_target),
    .pm_l1_req_i(intf.pm_l1_req),.pm_l2_req_i(intf.pm_l2_req),.pm_exit_i(intf.pm_exit),
    .clear_error_log_i(intf.clear_error_log),.sb_tx_valid_o(intf.sb_tx_valid),
    .sb_tx_message_o(intf.sb_tx_message),.sb_tx_ready_i(intf.sb_tx_ready),
    .sb_rx_valid_i(intf.sb_rx_valid),.sb_rx_message_i(intf.sb_rx_message),.sb_busy_o(intf.sb_busy),
    .sb_protocol_error_o(intf.sb_protocol_error),.sb_retry_o(intf.sb_retry),
    .train_tx_valid_o(intf.train_tx_valid),.train_tx_pattern_o(intf.train_tx_pattern),
    .train_rx_valid_i(intf.train_rx_valid),.train_rx_pattern_i(intf.train_rx_pattern),
    .train_error_threshold_i(intf.train_error_threshold),.train_busy_o(intf.train_busy),
    .train_done_o(intf.train_done),.train_pass_o(intf.train_pass),
    .train_error_count_o(intf.train_error_count),.datatrain_phase_o(intf.datatrain_phase),
    .error_pending_o(intf.error_pending),.trainerror_handshake_request_o(intf.trainerror_handshake_request),
    .error_handshake_timeout_o(intf.error_handshake_timeout),.error_cause_o(intf.error_cause),
    .error_event_count_o(intf.error_event_count),.state_o(intf.state),.mbinit_state_o(intf.mbi),
    .mbtrain_state_o(intf.mbt),.timeout_o(intf.timeout),.link_up_o(intf.link_up),
    .mainband_tristate_o(intf.mainband_tristate),.sideband_enable_o(intf.sideband_enable));
  ucie_ltsm_sva sva(.clk_i(clk),.rst_ni(intf.rst_n),.state_i(intf.state),.mbtrain_state_i(intf.mbt),
    .datatrain_phase_i(intf.datatrain_phase),.sb_tx_valid_i(intf.sb_tx_valid),.sb_tx_ready_i(intf.sb_tx_ready),
    .sb_tx_message_i(intf.sb_tx_message),.sb_rx_valid_i(intf.sb_rx_valid),.sb_rx_message_i(intf.sb_rx_message),
    .timeout_i(intf.timeout),.link_up_i(intf.link_up),.fatal_error_i(intf.fatal_error),
    .train_rx_valid_i(intf.train_rx_valid),.train_busy_i(intf.train_busy),.train_done_i(intf.train_done),
    .train_pass_i(intf.train_pass),.train_error_count_i(intf.train_error_count),
    .train_error_threshold_i(intf.train_error_threshold),.error_pending_i(intf.error_pending),
    .handshake_request_i(intf.trainerror_handshake_request),.handshake_timeout_i(intf.error_handshake_timeout),
    .handshake_done_i(intf.error_handshake_done),.clear_error_log_i(intf.clear_error_log),
    .error_cause_i(intf.error_cause),.error_event_count_i(intf.error_event_count));
  initial begin intf.rst_n=0;intf.clear_controls();end
  initial begin uvm_config_db#(virtual ucie_ltsm_if)::set(null,"uvm_test_top.drv","vif",intf);
    run_test("integrated_test");end
endmodule
