interface ucie_ltsm_if(input logic clk);
  import ucie_ltsm_pkg::*;
  logic rst_n;
  logic supplies_stable, sideband_clk_ok, internal_clks_ok, firmware_reset;
  logic link_train_trigger, phase_done, stall, fatal_error, error_handshake_done;
  logic error_escalated, sideband_tx_idle, rdi_active, retrain_req;
  retrain_target_e retrain_target;
  logic pm_l1_req, pm_l2_req, pm_exit;
  ltsm_state_e state;
  mbinit_state_e mbi;
  mbtrain_state_e mbt;
  logic timeout, link_up, mainband_tristate, sideband_enable;

  task automatic clear_controls();
    supplies_stable=0; sideband_clk_ok=0; internal_clks_ok=0; firmware_reset=0;
    link_train_trigger=0; phase_done=0; stall=0; fatal_error=0;
    error_handshake_done=0; error_escalated=0; sideband_tx_idle=1;
    rdi_active=0; retrain_req=0; retrain_target=RETRAIN_TXSELFCAL;
    pm_l1_req=0; pm_l2_req=0; pm_exit=0;
  endtask
endinterface
