`timescale 1ns/1ps
module tb_ucie_lfsr_training_engine;
  logic clk=0, rst_n=0, start, abort, rx_valid;
  logic [15:0] threshold, rx_pattern;
  logic tx_valid, busy, done, pass;
  logic [15:0] tx_pattern, errors;
  logic start4096, rx_valid4096, busy4096, done4096, pass4096;
  logic [15:0] tx4096, rx4096, errors4096;
  always #5 clk=~clk;

  ucie_lfsr_training_engine #(.SAMPLE_COUNT(8)) dut (.*,
    .clk_i(clk),.rst_ni(rst_n),.start_i(start),.abort_i(abort),
    .error_threshold_i(threshold),.tx_valid_o(tx_valid),.tx_pattern_o(tx_pattern),
    .rx_valid_i(rx_valid),.rx_pattern_i(rx_pattern),.busy_o(busy),.done_o(done),
    .pass_o(pass),.error_count_o(errors));
  ucie_lfsr_training_engine dut4096 (
    .clk_i(clk),.rst_ni(rst_n),.start_i(start4096),.abort_i(1'b0),
    .error_threshold_i(16'hffff),.tx_valid_o(),.tx_pattern_o(tx4096),
    .rx_valid_i(rx_valid4096),.rx_pattern_i(rx4096),.busy_o(busy4096),
    .done_o(done4096),.pass_o(pass4096),.error_count_o(errors4096));

  function automatic logic [22:0] seed(input int lane);
    case(lane%8)
      0: seed=23'h1dbfbc; 1: seed=23'h0607bb; 2: seed=23'h1ec760; 3: seed=23'h18c0db;
      4: seed=23'h010f12; 5: seed=23'h19cfc9; 6: seed=23'h0277ce; default: seed=23'h1bb807;
    endcase
  endfunction
  function automatic logic [22:0] next_lfsr(input logic [22:0] v);
    return {v[21:0],v[22]^v[20]^v[15]^v[7]^v[4]^v[1]};
  endfunction
  task automatic run8(input logic [15:0] mask, input int gap, input int exp_errors, input bit exp_pass);
    logic [22:0] ref_lfsr[16]; logic [15:0] expected;
    for(int l=0;l<16;l++) ref_lfsr[l]=seed(l);
    threshold=exp_pass ? exp_errors+1 : exp_errors;
    start=1; @(posedge clk); #1 start=0;
    for(int n=0;n<8;n++) begin
      repeat(gap) @(posedge clk);
      for(int l=0;l<16;l++) expected[l]=ref_lfsr[l][22];
      if(tx_pattern!==expected) $fatal(1,"LFSR mismatch sample=%0d expected=%h got=%h",n,expected,tx_pattern);
      rx_pattern=expected^mask; rx_valid=1; @(posedge clk); #1 rx_valid=0;
      for(int l=0;l<16;l++) ref_lfsr[l]=next_lfsr(ref_lfsr[l]);
    end
    if(!done || errors!=exp_errors || pass!=exp_pass)
      $fatal(1,"Result mismatch done=%b errors=%0d pass=%b",done,errors,pass);
    @(posedge clk); #1; if(done) $fatal(1,"done must pulse once");
  endtask
  initial begin
    start=0; abort=0; rx_valid=0; rx_pattern=0; threshold=1;
    start4096=0; rx_valid4096=0; rx4096=0;
    repeat(3) @(posedge clk); rst_n=1;
    run8(16'h0000,2,0,1);                 // clean, gaps, lane seeds and polynomial
    run8(16'h0001,0,8,0);                 // strict equality fails
    run8(16'h0001,1,8,1);                 // threshold one greater passes
    start=1; @(posedge clk); #1 start=0; repeat(2) @(posedge clk);
    abort=1; @(posedge clk); #1 abort=0;
    if(busy || done || pass || errors) $fatal(1,"abort did not clear engine");
    start4096=1; @(posedge clk); #1 start4096=0; rx_valid4096=1;
    repeat(4096) begin rx4096=~tx4096; @(posedge clk); #1; end
    rx_valid4096=0;
    if(!done4096 || errors4096!=16'hffff || pass4096)
      $fatal(1,"4096-sample saturation/default proof failed: done=%b errors=%h pass=%b",done4096,errors4096,pass4096);
    $display("PASS: LFSR seeds/polynomial, gaps, strict threshold, abort, and 4096-sample saturation");
    $finish;
  end
endmodule
