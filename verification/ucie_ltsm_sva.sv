module ucie_ltsm_sva (
  input logic clk_i, rst_ni,
  input ucie_ltsm_pkg::ltsm_state_e state_i,
  input logic timeout_i, link_up_i, fatal_error_i
);
  import ucie_ltsm_pkg::*;
  default clocking cb @(posedge clk_i); endclocking
  default disable iff (!rst_ni);

  ap_link_up_only_active: assert property (link_up_i |-> state_i == LTSM_ACTIVE);
  ap_timeout_to_error: assert property (timeout_i |=> state_i == LTSM_TRAINERROR);
  ap_no_reset_direct_active: assert property (state_i == LTSM_RESET |=> state_i != LTSM_ACTIVE);
  ap_known_state: assert property (!$isunknown(state_i));
  cp_reaches_active: cover property (state_i == LTSM_RESET ##[1:$] state_i == LTSM_ACTIVE);
endmodule
