`timescale 1ns/1ps
module tb_ucie_ltsm_fpga_wrapper;
  import ucie_ltsm_pkg::*;
  logic clk_i=0,rst_ni=0;
  logic supplies_stable_i,sideband_clk_ok_i,internal_clks_ok_i,firmware_reset_i;
  logic link_train_trigger_i,phase_done_i,stall_i,fatal_error_i,error_handshake_done_i;
  logic error_escalated_i,sideband_tx_idle_i,rdi_active_i,retrain_req_i;
  retrain_target_e retrain_target_i;
  logic pm_l1_req_i,pm_l2_req_i,pm_exit_i;
  logic sb_tx_valid_o,sb_tx_ready_i,sb_rx_valid_i,sb_busy_o,sb_protocol_error_o,sb_retry_o;
  sb_msg_e sb_tx_message_o,sb_rx_message_i;
  logic train_tx_valid_o,train_rx_valid_i,train_busy_o,train_done_o,train_pass_o;
  logic [15:0] train_tx_pattern_o,train_rx_pattern_i,train_error_threshold_i;
  logic csr_valid_i,csr_write_i,csr_ready_o;
  logic [4:0] csr_addr_i; logic [7:0] csr_wdata_i,csr_rdata_o;
  always #5 clk_i=~clk_i;

  ucie_ltsm_fpga_wrapper #(.CLK_HZ(100_000_000),.RESET_MIN_US(1),.TIMEOUT_US(2),
    .SB_RESPONSE_TIMEOUT_CYCLES(8),.DATATRAIN_SAMPLE_COUNT(8)) dut(.*);

  task automatic pulse(ref logic signal); signal=1; @(posedge clk_i); #1 signal=0; endtask
  task automatic csr_read(input logic[4:0] addr,input logic[7:0] expected);
    @(negedge clk_i); csr_addr_i=addr;csr_write_i=0;csr_valid_i=1;#1;
    if(!csr_ready_o||csr_rdata_o!==expected)
      $fatal(1,"CSR read %h expected %h got %h ready=%b",addr,expected,csr_rdata_o,csr_ready_o);
    @(posedge clk_i);#1;csr_valid_i=0;
  endtask
  task automatic csr_clear;
    @(negedge clk_i);csr_addr_i=5'h10;csr_wdata_i=1;csr_write_i=1;csr_valid_i=1;
    @(posedge clk_i);#1;csr_valid_i=0;csr_write_i=0;csr_wdata_i=0;
  endtask
  initial begin
    supplies_stable_i=0;sideband_clk_ok_i=0;internal_clks_ok_i=0;firmware_reset_i=0;
    link_train_trigger_i=0;phase_done_i=0;stall_i=0;fatal_error_i=0;error_handshake_done_i=0;
    error_escalated_i=0;sideband_tx_idle_i=1;rdi_active_i=0;retrain_req_i=0;
    retrain_target_i=RETRAIN_TXSELFCAL;pm_l1_req_i=0;pm_l2_req_i=0;pm_exit_i=0;
    sb_tx_ready_i=0;sb_rx_valid_i=0;sb_rx_message_i=SB_MSG_NOP;
    train_rx_valid_i=0;train_rx_pattern_i=0;train_error_threshold_i=1;
    csr_valid_i=0;csr_write_i=0;csr_addr_i=0;csr_wdata_i=0;
    repeat(3) @(posedge clk_i);#1;rst_ni=1;
    csr_read(5'h09,8'h04); csr_read(5'h00,8'h00);

    supplies_stable_i=1;sideband_clk_ok_i=1;internal_clks_ok_i=1;link_train_trigger_i=1;
    wait(dut.state==LTSM_SBINIT);pulse(phase_done_i);repeat(6)pulse(phase_done_i);
    repeat(13)pulse(phase_done_i);pulse(rdi_active_i);
    if(dut.state!=LTSM_ACTIVE)$fatal(1,"Wrapper failed to reach ACTIVE");
    csr_read(5'h00,8'h05); csr_read(5'h03,8'h50);

    sideband_tx_idle_i=0;@(negedge clk_i);fatal_error_i=1;#1;
    if(!dut.handshake_request)$fatal(1,"Immediate handshake request hidden by wrapper");
    @(posedge clk_i);#1;fatal_error_i=0;
    csr_read(5'h03,8'h53); csr_read(5'h04,8'h03);
    csr_read(5'h05,8'h01); csr_read(5'h06,8'h00);
    error_handshake_done_i=1;@(posedge clk_i);#1;error_handshake_done_i=0;
    wait(dut.state==LTSM_TRAINERROR);csr_clear;
    csr_read(5'h04,8'h03);csr_read(5'h05,8'h01);
    sideband_tx_idle_i=1;wait(dut.state==LTSM_RESET);csr_clear;
    csr_read(5'h04,8'h00);csr_read(5'h05,8'h00);csr_read(5'h1f,8'h00);
    $display("PASS: FPGA wrapper CSR state, status, retained error, protected clear, and release");
    $finish;
  end
endmodule
