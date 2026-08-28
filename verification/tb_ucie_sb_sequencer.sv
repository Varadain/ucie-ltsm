`timescale 1ns/1ps
module tb_ucie_sb_sequencer;
  import ucie_ltsm_pkg::*;
  logic clk=0, rst_n=0, start, abort, tx_valid, tx_ready, rx_valid;
  logic busy, done, protocol_error, retry;
  sb_msg_e request, expected_response, tx_message, rx_message;
  always #5 clk=~clk;

  ucie_sb_sequencer #(.RESPONSE_TIMEOUT_CYCLES(4),.MAX_RETRIES(1)) dut(.*,
    .clk_i(clk),.rst_ni(rst_n),.start_i(start),.abort_i(abort),
    .request_i(request),.expected_response_i(expected_response),
    .tx_valid_o(tx_valid),.tx_message_o(tx_message),.tx_ready_i(tx_ready),
    .rx_valid_i(rx_valid),.rx_message_i(rx_message),.busy_o(busy),
    .done_o(done),.protocol_error_o(protocol_error),.retry_o(retry));

  task automatic launch();
    start=1; @(posedge clk); #1 start=0; wait(tx_valid);
    if(tx_message!=SB_MSG_SBINIT_DONE_REQ) $fatal(1,"Request was not latched");
  endtask
  task automatic accept_tx(); tx_ready=1; @(posedge clk); #1 tx_ready=0; endtask
  task automatic respond(input sb_msg_e msg);
    rx_message=msg; rx_valid=1; @(posedge clk); #1 rx_valid=0; rx_message=SB_MSG_NOP;
  endtask

  property p_hold_request; @(posedge clk) disable iff(!rst_n) tx_valid && !tx_ready |=> tx_valid && $stable(tx_message); endproperty
  property p_retry_reissues; @(posedge clk) disable iff(!rst_n) retry |-> tx_valid; endproperty
  property p_done_after_expected; @(posedge clk) disable iff(!rst_n) done |-> $past(rx_valid && rx_message==expected_response); endproperty
  ap_hold_request: assert property(p_hold_request);
  ap_retry_reissues: assert property(p_retry_reissues);
  ap_done_after_expected: assert property(p_done_after_expected);

  initial begin
    start=0; abort=0; tx_ready=0; rx_valid=0; rx_message=SB_MSG_NOP;
    request=SB_MSG_SBINIT_DONE_REQ; expected_response=SB_MSG_SBINIT_DONE_RESP;
    repeat(3) @(posedge clk); rst_n=1;

    // Backpressure then successful response.
    launch(); repeat(2) @(posedge clk); if(!tx_valid) $fatal(1,"tx_valid dropped under backpressure");
    accept_tx(); repeat(2) @(posedge clk); respond(SB_MSG_SBINIT_DONE_RESP);
    if(!done) $fatal(1,"Expected success pulse"); @(posedge clk);

    // One timeout retry, then successful response.
    launch(); accept_tx(); wait(retry); if(!tx_valid) $fatal(1,"Retry did not reissue request");
    accept_tx(); respond(SB_MSG_SBINIT_DONE_RESP); if(!done) $fatal(1,"Retry did not complete"); @(posedge clk);

    // Exhaust the one-retry budget.
    launch(); accept_tx(); wait(retry); accept_tx(); wait(protocol_error); @(posedge clk);

    // Unexpected response must produce a protocol error.
    launch(); accept_tx(); respond(SB_MSG_NOP); if(!protocol_error) $fatal(1,"Wrong response accepted"); @(posedge clk);

    // Abort returns an outstanding transaction to idle without completion/error.
    launch(); abort=1; @(posedge clk); #1 abort=0;
    if(busy || done || protocol_error) $fatal(1,"Abort did not cleanly cancel transaction");
    $display("PASS: sideband backpressure, success, retry, exhaustion, mismatch, and abort");
    $finish;
  end
endmodule
