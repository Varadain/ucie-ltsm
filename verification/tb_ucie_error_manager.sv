`timescale 1ns/1ps
module tb_ucie_error_manager;
  import ucie_ltsm_pkg::*;
  logic clk=0,rst_n=0,state_timeout,sb_error,fatal,ack,clear;
  logic pending,request,hs_timeout,enter;
  ltsm_state_e state;
  ltsm_error_cause_e cause;
  logic [15:0] count;
  always #5 clk=~clk;
  ucie_error_manager #(.HANDSHAKE_TIMEOUT_CYCLES(4)) dut(
    .clk_i(clk),.rst_ni(rst_n),.state_i(state),.state_timeout_i(state_timeout),
    .sideband_protocol_error_i(sb_error),.local_fatal_error_i(fatal),
    .handshake_done_i(ack),.clear_log_i(clear),.pending_o(pending),
    .handshake_request_o(request),.handshake_timeout_o(hs_timeout),
    .enter_trainerror_o(enter),.cause_o(cause),.event_count_o(count));
  task automatic step; @(posedge clk); #1; endtask
  task automatic clear_inputs; state_timeout=0;sb_error=0;fatal=0;ack=0;clear=0; endtask
  task automatic accept(input ltsm_error_cause_e exp,input bit to,input bit sb,input bit lf);
    state_timeout=to;sb_error=sb;fatal=lf; #1;
    if(lf && state!=LTSM_SBINIT && !request) $fatal(1,"request not immediate");
    step(); clear_inputs();
    if(cause!=exp) $fatal(1,"cause priority mismatch expected=%0d got=%0d",exp,cause);
  endtask
  initial begin
    clear_inputs(); state=LTSM_ACTIVE; repeat(3) step(); rst_n=1; step();
    fatal=1; #1; if(!request) $fatal(1,"short fatal not immediately requested");
    step(); fatal=0; if(!pending||!request||count!=1) $fatal(1,"short fault not retained");
    clear=1; step(); clear=0; if(cause!=LTSM_ERR_LOCAL_FATAL||count!=1) $fatal(1,"clear changed pending log");
    repeat(2) begin if(!request) $fatal(1,"request dropped while pending"); step(); end
    ack=1; #1; if(!enter) $fatal(1,"delayed ack did not request TRAINERROR"); step(); ack=0;
    state=LTSM_TRAINERROR; clear=1; step(); clear=0;
    if(cause!=LTSM_ERR_LOCAL_FATAL||count!=1||pending) $fatal(1,"TRAINERROR retention/clear rule failed");
    state=LTSM_RESET; step(); state=LTSM_ACTIVE; clear=1; step(); clear=0;
    if(cause!=LTSM_ERR_NONE||count!=0) $fatal(1,"allowed clear failed");

    // Held input is accepted once, then manager timeout forces entry at the bound.
    fatal=1; step(); if(count!=1) $fatal(1,"held event not accepted");
    repeat(3) begin step(); if(count!=1) $fatal(1,"held event counted twice"); end
    if(!hs_timeout||!enter) $fatal(1,"missing ack timeout bound failed");
    fatal=0; state=LTSM_TRAINERROR; step(); state=LTSM_RESET; step();

    // SBINIT bypasses handshake. Simultaneous causes retain timeout priority.
    state=LTSM_SBINIT; sb_error=1; #1;
    if(!enter||request) $fatal(1,"SBINIT protocol error did not bypass handshake");
    step(); clear_inputs(); if(cause!=LTSM_ERR_SIDEBAND_PROTOCOL) $fatal(1,"SB cause lost");
    state=LTSM_RESET; step(); state=LTSM_MBINIT;
    accept(LTSM_ERR_STATE_TIMEOUT,1,1,1);
    if(!enter) $fatal(1,"state timeout not immediate");
    state=LTSM_TRAINERROR; step(); state=LTSM_RESET; step();

    // Saturation: one accepted immediate timeout event per recovery iteration.
    rst_n=0; step(); rst_n=1; state=LTSM_MBINIT;
    for(int i=0;i<65536;i++) begin
      state_timeout=1; step(); state_timeout=0; state=LTSM_TRAINERROR; step();
      state=LTSM_RESET; step(); state=LTSM_MBINIT;
    end
    if(count!=16'hffff) $fatal(1,"event counter did not saturate: %h",count);
    $display("PASS: error retention, priority, handshake bound, clear rules, and saturation");
    $finish;
  end
endmodule
