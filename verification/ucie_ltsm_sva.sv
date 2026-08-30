module ucie_ltsm_sva (
  input logic clk_i, rst_ni,
  input ucie_ltsm_pkg::ltsm_state_e state_i,
  input ucie_ltsm_pkg::mbtrain_state_e mbtrain_state_i,
  input logic timeout_i, link_up_i, fatal_error_i,
  input logic train_rx_valid_i, train_busy_i, train_done_i, train_pass_i,
  input logic [15:0] train_error_count_i, train_error_threshold_i
);
  import ucie_ltsm_pkg::*;
  default clocking cb @(posedge clk_i); endclocking
  default disable iff (!rst_ni);

  ap_link_up_only_active: assert property (link_up_i |-> state_i == LTSM_ACTIVE);
  ap_timeout_to_error: assert property (timeout_i |=> state_i == LTSM_TRAINERROR);
  ap_no_reset_direct_active: assert property (state_i == LTSM_RESET |=> state_i != LTSM_ACTIVE);
  ap_known_state: assert property (!$isunknown(state_i));
  ap_training_only_center1: assert property
    (train_busy_i |-> (state_i == LTSM_MBTRAIN && mbtrain_state_i == MBT_DATATRAINCENTER1) ||
                      ($past(state_i) == LTSM_MBTRAIN &&
                       $past(mbtrain_state_i) == MBT_DATATRAINCENTER1));
  ap_done_is_pulse: assert property (train_done_i |=> !train_done_i);
  ap_done_not_busy: assert property (train_done_i |-> !train_busy_i);
  ap_pass_is_strict: assert property
    (train_done_i && train_pass_i |-> train_error_count_i < train_error_threshold_i);
  ap_fail_at_threshold: assert property
    (train_done_i && train_error_count_i >= train_error_threshold_i |-> !train_pass_i);
  ap_hold_without_sample: assert property
    (train_busy_i && !train_rx_valid_i |=> !train_busy_i ||
       train_error_count_i == $past(train_error_count_i));
  cp_reaches_active: cover property (state_i == LTSM_RESET ##[1:$] state_i == LTSM_ACTIVE);
  cp_training_pass: cover property (train_done_i && train_pass_i);
  cp_training_fail: cover property (train_done_i && !train_pass_i);
endmodule
