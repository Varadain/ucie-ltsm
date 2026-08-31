module ucie_ltsm_sva (
  input logic clk_i, rst_ni,
  input ucie_ltsm_pkg::ltsm_state_e state_i,
  input ucie_ltsm_pkg::mbtrain_state_e mbtrain_state_i,
  input logic timeout_i, link_up_i, fatal_error_i,
  input logic train_rx_valid_i, train_busy_i, train_done_i, train_pass_i,
  input logic [15:0] train_error_count_i, train_error_threshold_i,
  input logic error_pending_i, handshake_request_i, handshake_timeout_i,
  input logic handshake_done_i, clear_error_log_i,
  input ucie_ltsm_pkg::ltsm_error_cause_e error_cause_i,
  input logic [15:0] error_event_count_i
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
  ap_fatal_requests_handshake: assert property
    (fatal_error_i && state_i!=LTSM_RESET && state_i!=LTSM_SBINIT && state_i!=LTSM_TRAINERROR
      |-> handshake_request_i);
  ap_pending_holds_request: assert property
    (error_pending_i && state_i!=LTSM_SBINIT |-> handshake_request_i);
  ap_handshake_timeout_enters_error: assert property
    (handshake_timeout_i |=> state_i==LTSM_TRAINERROR);
  ap_pending_clears_on_error: assert property
    ($rose(state_i==LTSM_TRAINERROR) |-> !error_pending_i);
  ap_log_stable_in_trainerror: assert property
    (state_i==LTSM_TRAINERROR && $past(state_i)==LTSM_TRAINERROR |->
       $stable(error_cause_i) && $stable(error_event_count_i));
  ap_clear_ignored_pending: assert property
    (clear_error_log_i && error_pending_i |=> error_event_count_i==$past(error_event_count_i));
  cp_handshake_delayed: cover property (handshake_request_i ##[1:200] handshake_done_i);
  cp_handshake_timeout: cover property (handshake_timeout_i);
endmodule
