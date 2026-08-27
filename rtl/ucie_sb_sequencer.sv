module ucie_sb_sequencer #(
  parameter int unsigned RESPONSE_TIMEOUT_CYCLES = 256,
  parameter int unsigned MAX_RETRIES             = 1
) (
  input  logic clk_i,
  input  logic rst_ni,

  input  logic                    start_i,
  input  logic                    abort_i,
  input  ucie_ltsm_pkg::sb_msg_e  request_i,
  input  ucie_ltsm_pkg::sb_msg_e  expected_response_i,

  output logic                    tx_valid_o,
  output ucie_ltsm_pkg::sb_msg_e  tx_message_o,
  input  logic                    tx_ready_i,

  input  logic                    rx_valid_i,
  input  ucie_ltsm_pkg::sb_msg_e  rx_message_i,

  output logic busy_o,
  output logic done_o,
  output logic protocol_error_o,
  output logic retry_o
);
  import ucie_ltsm_pkg::*;

  typedef enum logic [1:0] {SEQ_IDLE, SEQ_SEND, SEQ_WAIT, SEQ_ERROR} seq_state_e;
  localparam int unsigned TIMEOUT_LIMIT = (RESPONSE_TIMEOUT_CYCLES < 1) ? 1 : RESPONSE_TIMEOUT_CYCLES;
  localparam int unsigned TIMER_W = (TIMEOUT_LIMIT <= 1) ? 1 : $clog2(TIMEOUT_LIMIT);
  localparam int unsigned RETRY_W = (MAX_RETRIES < 1) ? 1 : $clog2(MAX_RETRIES + 1);

  seq_state_e state_q;
  sb_msg_e request_q, expected_response_q;
  logic [TIMER_W-1:0] timer_q;
  logic [RETRY_W-1:0] retry_count_q;

  assign tx_valid_o = (state_q == SEQ_SEND);
  assign tx_message_o = request_q;
  assign busy_o = (state_q == SEQ_SEND) || (state_q == SEQ_WAIT);

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q             <= SEQ_IDLE;
      request_q           <= SB_MSG_NOP;
      expected_response_q <= SB_MSG_NOP;
      timer_q             <= '0;
      retry_count_q       <= '0;
      done_o              <= 1'b0;
      protocol_error_o    <= 1'b0;
      retry_o             <= 1'b0;
    end else begin
      done_o           <= 1'b0;
      protocol_error_o <= 1'b0;
      retry_o          <= 1'b0;

      if (abort_i) begin
        state_q       <= SEQ_IDLE;
        timer_q       <= '0;
        retry_count_q <= '0;
      end else unique case (state_q)
        SEQ_IDLE: if (start_i) begin
          request_q           <= request_i;
          expected_response_q <= expected_response_i;
          timer_q             <= '0;
          retry_count_q       <= '0;
          state_q             <= SEQ_SEND;
        end

        SEQ_SEND: if (tx_ready_i) begin
          timer_q <= '0;
          state_q <= SEQ_WAIT;
        end

        SEQ_WAIT: begin
          if (rx_valid_i) begin
            if (rx_message_i == expected_response_q) begin
              done_o  <= 1'b1;
              state_q <= SEQ_IDLE;
            end else begin
              protocol_error_o <= 1'b1;
              state_q          <= SEQ_ERROR;
            end
          end else if (timer_q == TIMEOUT_LIMIT-1) begin
            timer_q <= '0;
            if (retry_count_q < MAX_RETRIES) begin
              retry_count_q <= retry_count_q + 1'b1;
              retry_o       <= 1'b1;
              state_q       <= SEQ_SEND;
            end else begin
              protocol_error_o <= 1'b1;
              state_q          <= SEQ_ERROR;
            end
          end else begin
            timer_q <= timer_q + 1'b1;
          end
        end

        default: state_q <= SEQ_IDLE;
      endcase
    end
  end
endmodule
