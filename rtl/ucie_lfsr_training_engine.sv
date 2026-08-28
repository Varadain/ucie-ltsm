module ucie_lfsr_training_engine #(
  parameter int unsigned SAMPLE_COUNT = 4096
) (
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        start_i,
  input  logic        abort_i,
  input  logic [15:0] error_threshold_i,
  output logic        tx_valid_o,
  output logic [15:0] tx_pattern_o,
  input  logic        rx_valid_i,
  input  logic [15:0] rx_pattern_i,
  output logic        busy_o,
  output logic        done_o,
  output logic        pass_o,
  output logic [15:0] error_count_o
);
  localparam int unsigned COUNT_LIMIT = (SAMPLE_COUNT < 1) ? 1 : SAMPLE_COUNT;
  localparam int unsigned COUNT_W = (COUNT_LIMIT <= 1) ? 1 : $clog2(COUNT_LIMIT);
  logic [22:0] lane_lfsr_q [0:15];
  logic [COUNT_W-1:0] sample_count_q;

  function automatic logic [22:0] lane_seed(input int unsigned lane);
    case (lane % 8)
      0: lane_seed = 23'h1dbfbc;
      1: lane_seed = 23'h0607bb;
      2: lane_seed = 23'h1ec760;
      3: lane_seed = 23'h18c0db;
      4: lane_seed = 23'h010f12;
      5: lane_seed = 23'h19cfc9;
      6: lane_seed = 23'h0277ce;
      default: lane_seed = 23'h1bb807;
    endcase
  endfunction

  // Fibonacci realization of G(X)=X^23+X^21+X^16+X^8+X^5+X^2+1.
  function automatic logic [22:0] lfsr_next(input logic [22:0] value);
    lfsr_next = {value[21:0], value[22] ^ value[20] ^ value[15] ^
                              value[7] ^ value[4] ^ value[1]};
  endfunction

  function automatic logic [4:0] bit_errors(input logic [15:0] difference);
    logic [4:0] count;
    int unsigned index;
    begin
      count = '0;
      for (index = 0; index < 16; index++) count = count + difference[index];
      return count;
    end
  endfunction

  assign tx_valid_o = busy_o;
  always_comb begin
    for (int unsigned lane = 0; lane < 16; lane++)
      tx_pattern_o[lane] = lane_lfsr_q[lane][22];
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    logic [16:0] accumulated_errors;
    int unsigned lane;
    if (!rst_ni) begin
      for (lane = 0; lane < 16; lane++) lane_lfsr_q[lane] <= lane_seed(lane);
      sample_count_q <= '0;
      busy_o <= 1'b0;
      done_o <= 1'b0;
      pass_o <= 1'b0;
      error_count_o <= '0;
    end else begin
      done_o <= 1'b0;
      if (abort_i) begin
        for (lane = 0; lane < 16; lane++) lane_lfsr_q[lane] <= lane_seed(lane);
        sample_count_q <= '0;
        busy_o <= 1'b0;
        pass_o <= 1'b0;
        error_count_o <= '0;
      end else if (start_i && !busy_o) begin
        for (lane = 0; lane < 16; lane++) lane_lfsr_q[lane] <= lane_seed(lane);
        sample_count_q <= '0;
        busy_o <= 1'b1;
        pass_o <= 1'b0;
        error_count_o <= '0;
      end else if (busy_o && rx_valid_i) begin
        accumulated_errors = {1'b0, error_count_o} + bit_errors(rx_pattern_i ^ tx_pattern_o);
        error_count_o <= accumulated_errors[16] ? 16'hffff : accumulated_errors[15:0];
        for (lane = 0; lane < 16; lane++) lane_lfsr_q[lane] <= lfsr_next(lane_lfsr_q[lane]);
        if (sample_count_q == COUNT_LIMIT-1) begin
          sample_count_q <= '0;
          busy_o <= 1'b0;
          done_o <= 1'b1;
          pass_o <= !accumulated_errors[16] &&
                    (accumulated_errors[15:0] < error_threshold_i);
        end else begin
          sample_count_q <= sample_count_q + 1'b1;
        end
      end
    end
  end
endmodule
