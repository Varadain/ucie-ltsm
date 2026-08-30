module ucie_error_manager #(
  parameter int unsigned HANDSHAKE_TIMEOUT_CYCLES = 1
) (
  input  logic clk_i,
  input  logic rst_ni,
  input  ucie_ltsm_pkg::ltsm_state_e state_i,
  input  logic state_timeout_i,
  input  logic sideband_protocol_error_i,
  input  logic local_fatal_error_i,
  input  logic handshake_done_i,
  input  logic clear_log_i,
  output logic pending_o,
  output logic handshake_request_o,
  output logic handshake_timeout_o,
  output logic enter_trainerror_o,
  output ucie_ltsm_pkg::ltsm_error_cause_e cause_o,
  output logic [15:0] event_count_o
);
  import ucie_ltsm_pkg::*;
  localparam int unsigned TIMEOUT_LIMIT = (HANDSHAKE_TIMEOUT_CYCLES < 1) ? 1 : HANDSHAKE_TIMEOUT_CYCLES;
  localparam int unsigned TIMER_W = (TIMEOUT_LIMIT <= 1) ? 1 : $clog2(TIMEOUT_LIMIT);
  logic [TIMER_W-1:0] handshake_timer_q;
  logic eligible_state, new_fault, accept_event;

  assign eligible_state = (state_i != LTSM_RESET) && (state_i != LTSM_TRAINERROR);
  assign new_fault = state_timeout_i || sideband_protocol_error_i || local_fatal_error_i;
  assign accept_event = eligible_state && !pending_o && new_fault;
  assign handshake_timeout_o = pending_o && (handshake_timer_q == TIMEOUT_LIMIT-1);
  assign handshake_request_o = eligible_state && (state_i != LTSM_SBINIT) &&
                               (pending_o || sideband_protocol_error_i || local_fatal_error_i);
  assign enter_trainerror_o = eligible_state &&
                              (state_timeout_i || handshake_timeout_o ||
                               ((pending_o || sideband_protocol_error_i || local_fatal_error_i) &&
                                ((state_i == LTSM_SBINIT) || handshake_done_i)));

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      pending_o          <= 1'b0;
      handshake_timer_q  <= '0;
      cause_o            <= LTSM_ERR_NONE;
      event_count_o      <= '0;
    end else begin
      if (state_i == LTSM_RESET || enter_trainerror_o) begin
        pending_o         <= 1'b0;
        handshake_timer_q <= '0;
      end else if (accept_event) begin
        pending_o         <= 1'b1;
        handshake_timer_q <= '0;
      end else if (pending_o && !handshake_timeout_o) begin
        handshake_timer_q <= handshake_timer_q + 1'b1;
      end

      if (accept_event) begin
        if (state_timeout_i) cause_o <= LTSM_ERR_STATE_TIMEOUT;
        else if (sideband_protocol_error_i) cause_o <= LTSM_ERR_SIDEBAND_PROTOCOL;
        else cause_o <= LTSM_ERR_LOCAL_FATAL;
        if (event_count_o != 16'hffff) event_count_o <= event_count_o + 1'b1;
      end else if (clear_log_i && !pending_o && (state_i != LTSM_TRAINERROR)) begin
        cause_o       <= LTSM_ERR_NONE;
        event_count_o <= '0;
      end
    end
  end
endmodule
