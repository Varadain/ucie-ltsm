# Signal Map

All signal names below match [`ucie_ltsm.sv`](../../rtl/ucie_ltsm.sv).

## Inputs

| Signal | Meaning in this implementation | Used in |
|---|---|---|
| `clk_i` | Controller clock | All sequential behavior |
| `rst_ni` | Asynchronous active-low reset | Forces RESET and initial substates |
| `supplies_stable_i` | Abstract supply-stability indication | RESET exit |
| `sideband_clk_ok_i` | Abstract sideband-clock readiness | RESET exit and `sideband_enable_o` |
| `internal_clks_ok_i` | Abstract internal-clock readiness | RESET exit |
| `firmware_reset_i` | Holds link training in RESET while asserted | RESET exit |
| `link_train_trigger_i` | Requests training after readiness is met | RESET exit |
| `phase_done_i` | Abstract completion of the current initialization/training/retrain operation | SBINIT, MBINIT, MBTRAIN, PHYRETRAIN |
| `stall_i` | Restarts the timer; also blocks MBINIT substate progress while asserted | Timer and MBINIT |
| `fatal_error_i` | Requests transition toward TRAINERROR outside RESET | Global error priority |
| `error_handshake_done_i` | Allows a fatal error outside SBINIT to enter TRAINERROR | Global error priority |
| `error_escalated_i` | Holds TRAINERROR while set | TRAINERROR exit |
| `sideband_tx_idle_i` | Allows TRAINERROR to return to RESET | TRAINERROR exit |
| `rdi_active_i` | Abstract confirmation that link initialization reached active | LINKINIT exit |
| `retrain_req_i` | Requests retraining from ACTIVE | ACTIVE exit |
| `retrain_target_i` | Selects `TXSELFCAL`, `SPEEDIDLE`, or `REPAIR` re-entry | PHYRETRAIN exit |
| `pm_l1_req_i` | Requests entry to combined L1/L2 state | ACTIVE and L1 exit selection |
| `pm_l2_req_i` | Requests L2 behavior | ACTIVE and L2 exit selection |
| `pm_exit_i` | Requests exit from L1L2 | L1L2 exit |

## Outputs

| Signal | Implemented behavior |
|---|---|
| `state_o` | Current top-level state register |
| `mbinit_state_o` | Current MBINIT substate register; retains its last value outside MBINIT except when RESET logic reinitializes it |
| `mbtrain_state_o` | Current MBTRAIN substate register; set on RESET, MBINIT completion, retrain, and L1 exit as defined by the RTL |
| `timeout_o` | High when an eligible state/substate reaches the timeout count |
| `link_up_o` | High only in `LTSM_ACTIVE` |
| `mainband_tristate_o` | High in RESET, SBINIT, TRAINERROR, and L1L2 |
| `sideband_enable_o` | High outside RESET; in RESET it follows `sideband_clk_ok_i` |

## Integration warning

Names such as `supplies_stable_i` and `phase_done_i` describe architectural intent, but their producers are not included. A future top-level integration must define synchronization, pulse/level semantics, and clock-domain behavior before connecting external blocks.
