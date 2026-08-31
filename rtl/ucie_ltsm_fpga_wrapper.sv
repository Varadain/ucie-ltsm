module ucie_ltsm_fpga_wrapper #(
  parameter int unsigned CLK_HZ = 80_000_000,
  parameter int unsigned RESET_MIN_US = 4_000,
  parameter int unsigned TIMEOUT_US = 8_000,
  parameter int unsigned SB_RESPONSE_TIMEOUT_CYCLES = 256,
  parameter int unsigned SB_MAX_RETRIES = 1,
  parameter int unsigned DATATRAIN_SAMPLE_COUNT = 4096
) (
  input logic clk_i, rst_ni,
  input logic supplies_stable_i, sideband_clk_ok_i, internal_clks_ok_i,
  input logic firmware_reset_i, link_train_trigger_i, phase_done_i, stall_i,
  input logic fatal_error_i, error_handshake_done_i, error_escalated_i,
  input logic sideband_tx_idle_i, rdi_active_i, retrain_req_i,
  input ucie_ltsm_pkg::retrain_target_e retrain_target_i,
  input logic pm_l1_req_i, pm_l2_req_i, pm_exit_i,

  output logic sb_tx_valid_o,
  output ucie_ltsm_pkg::sb_msg_e sb_tx_message_o,
  input logic sb_tx_ready_i, sb_rx_valid_i,
  input ucie_ltsm_pkg::sb_msg_e sb_rx_message_i,
  output logic sb_busy_o, sb_protocol_error_o, sb_retry_o,

  output logic train_tx_valid_o,
  output logic [15:0] train_tx_pattern_o,
  input logic train_rx_valid_i,
  input logic [15:0] train_rx_pattern_i, train_error_threshold_i,
  output logic train_busy_o, train_done_o, train_pass_o,

  input logic csr_valid_i, csr_write_i,
  input logic [4:0] csr_addr_i,
  input logic [7:0] csr_wdata_i,
  output logic [7:0] csr_rdata_o,
  output logic csr_ready_o
);
  import ucie_ltsm_pkg::*;

  localparam logic [4:0] CSR_STATE       = 5'h00;
  localparam logic [4:0] CSR_MBINIT      = 5'h01;
  localparam logic [4:0] CSR_MBTRAIN     = 5'h02;
  localparam logic [4:0] CSR_STATUS      = 5'h03;
  localparam logic [4:0] CSR_ERROR_CAUSE = 5'h04;
  localparam logic [4:0] CSR_EVENT_LO    = 5'h05;
  localparam logic [4:0] CSR_EVENT_HI    = 5'h06;
  localparam logic [4:0] CSR_TRAIN_LO    = 5'h07;
  localparam logic [4:0] CSR_TRAIN_HI    = 5'h08;
  localparam logic [4:0] CSR_VERSION     = 5'h09;
  localparam logic [4:0] CSR_CONTROL     = 5'h10;

  ltsm_state_e state;
  mbinit_state_e mbinit_state;
  mbtrain_state_e mbtrain_state;
  ltsm_error_cause_e error_cause;
  logic timeout, link_up, mainband_tristate, sideband_enable;
  logic error_pending, handshake_request, handshake_timeout;
  logic [15:0] error_event_count, train_error_count;
  logic clear_error_log;

  assign csr_ready_o = csr_valid_i;
  assign clear_error_log = csr_valid_i && csr_write_i &&
                           (csr_addr_i == CSR_CONTROL) && csr_wdata_i[0];

  always_comb begin
    csr_rdata_o = 8'h00;
    if (csr_valid_i && !csr_write_i) begin
      unique case (csr_addr_i)
        CSR_STATE:       csr_rdata_o = {4'h0,state};
        CSR_MBINIT:      csr_rdata_o = {5'h0,mbinit_state};
        CSR_MBTRAIN:     csr_rdata_o = {4'h0,mbtrain_state};
        CSR_STATUS:      csr_rdata_o = {1'b0,sideband_enable,mainband_tristate,
                                        link_up,timeout,handshake_timeout,
                                        handshake_request,error_pending};
        CSR_ERROR_CAUSE: csr_rdata_o = {5'h0,error_cause};
        CSR_EVENT_LO:    csr_rdata_o = error_event_count[7:0];
        CSR_EVENT_HI:    csr_rdata_o = error_event_count[15:8];
        CSR_TRAIN_LO:    csr_rdata_o = train_error_count[7:0];
        CSR_TRAIN_HI:    csr_rdata_o = train_error_count[15:8];
        CSR_VERSION:     csr_rdata_o = 8'h04;
        default:         csr_rdata_o = 8'h00;
      endcase
    end
  end

  ucie_ltsm #(
    .CLK_HZ(CLK_HZ), .RESET_MIN_US(RESET_MIN_US), .TIMEOUT_US(TIMEOUT_US),
    .SB_RESPONSE_TIMEOUT_CYCLES(SB_RESPONSE_TIMEOUT_CYCLES),
    .SB_MAX_RETRIES(SB_MAX_RETRIES),
    .DATATRAIN_SAMPLE_COUNT(DATATRAIN_SAMPLE_COUNT)
  ) u_ltsm (
    .clk_i(clk_i), .rst_ni(rst_ni), .supplies_stable_i(supplies_stable_i),
    .sideband_clk_ok_i(sideband_clk_ok_i), .internal_clks_ok_i(internal_clks_ok_i),
    .firmware_reset_i(firmware_reset_i), .link_train_trigger_i(link_train_trigger_i),
    .phase_done_i(phase_done_i), .stall_i(stall_i), .fatal_error_i(fatal_error_i),
    .error_handshake_done_i(error_handshake_done_i), .error_escalated_i(error_escalated_i),
    .sideband_tx_idle_i(sideband_tx_idle_i), .rdi_active_i(rdi_active_i),
    .retrain_req_i(retrain_req_i), .retrain_target_i(retrain_target_i),
    .pm_l1_req_i(pm_l1_req_i), .pm_l2_req_i(pm_l2_req_i), .pm_exit_i(pm_exit_i),
    .clear_error_log_i(clear_error_log),
    .sb_tx_valid_o(sb_tx_valid_o), .sb_tx_message_o(sb_tx_message_o),
    .sb_tx_ready_i(sb_tx_ready_i), .sb_rx_valid_i(sb_rx_valid_i),
    .sb_rx_message_i(sb_rx_message_i), .sb_busy_o(sb_busy_o),
    .sb_protocol_error_o(sb_protocol_error_o), .sb_retry_o(sb_retry_o),
    .train_tx_valid_o(train_tx_valid_o), .train_tx_pattern_o(train_tx_pattern_o),
    .train_rx_valid_i(train_rx_valid_i), .train_rx_pattern_i(train_rx_pattern_i),
    .train_error_threshold_i(train_error_threshold_i), .train_busy_o(train_busy_o),
    .train_done_o(train_done_o), .train_pass_o(train_pass_o),
    .train_error_count_o(train_error_count), .error_pending_o(error_pending),
    .trainerror_handshake_request_o(handshake_request),
    .error_handshake_timeout_o(handshake_timeout), .error_cause_o(error_cause),
    .error_event_count_o(error_event_count), .state_o(state),
    .mbinit_state_o(mbinit_state), .mbtrain_state_o(mbtrain_state),
    .timeout_o(timeout), .link_up_o(link_up),
    .mainband_tristate_o(mainband_tristate), .sideband_enable_o(sideband_enable)
  );
endmodule
