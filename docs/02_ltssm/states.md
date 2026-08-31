# States and Transitions

This page describes the checked RTL, not every behavior in the UCIe specification.

## Top-level states

| State | Purpose and actions | Entry | Exit | Timer/error behavior | Current test evidence |
|---|---|---|---|---|---|
| `LTSM_RESET` | Initializes MBINIT to `PARAM`, MBTRAIN to `VALVREF`; holds mainband tristated. | Asynchronous reset, L2 exit, TRAINERROR recovery, or default recovery | After minimum RESET time, stable supplies, sideband/internal clocks ready, firmware reset clear, and link-training trigger set | No timeout; minimum-residence counter still runs | Directed/nominal flows; TRAINERROR return in recovery tests; L2 exit in `recovery_closure_test` |
| `LTSM_SBINIT` | Starts and supervises the bounded SBINIT-done request/response; sideband enabled and mainband tristated | RESET readiness condition | Expected response or compatibility `phase_done_i` -> MBINIT/`PARAM` | Eligible for LTSM timeout; wrong response or exhausted sequencer retries enters TRAINERROR | Nominal/timeout tests plus sideband success, retry, malformed-response, and exhaustion tests |
| `LTSM_MBINIT` | Advances the six ordered mainband-initialization labels | SBINIT completion | A non-stalled `phase_done_i` advances a substate; completion of `REPAIRMB` -> MBTRAIN/`VALVREF` | Timer restarts for every substate and while stalled; eligible for timeout | Ordered path exercised by directed and nominal UVM tests; no per-substate coverage report |
| `LTSM_MBTRAIN` | Advances the thirteen ordered mainband-training labels and runs the v0.3 digital LFSR operation in `DATATRAINCENTER1` | MBINIT completion, retrain completion, or L1 exit | `phase_done_i` advances a substate; `DATATRAINCENTER1` also advances on `train_done_o && train_pass_o`; completion of `REPAIR` -> LINKINIT | Timer restarts for every substate; eligible for timeout | Full ordered path, SPEEDIDLE re-entry, and five-seed DATATRAINCENTER1 pass/fail/retry/abort/timeout campaign |
| `LTSM_LINKINIT` | Waits for the external RDI/link-initialization result | MBTRAIN completion | `rdi_active_i` -> ACTIVE | Eligible for timeout | Directed and `nominal_test` |
| `LTSM_ACTIVE` | Declares the modeled link up | LINKINIT completion | Retrain request -> PHYRETRAIN; otherwise PM request -> L1L2 | No timeout; accepted fatal error can enter TRAINERROR | Directed and `nominal_test`; retrain and PM UVM tests |
| `LTSM_PHYRETRAIN` | Chooses the MBTRAIN restart target | ACTIVE retrain request | `phase_done_i` -> MBTRAIN at `TXSELFCAL`, `SPEEDIDLE`, or `REPAIR` | Eligible for timeout | All three targets in `recovery_closure_test`; SPEEDIDLE also in directed/`recovery_test` |
| `LTSM_TRAINERROR` | Holds error state while preserving the classified log until recovery conditions allow RESET | Immediate state-timeout/SBINIT-protocol decision or acknowledged/bounded pending fault | `!error_escalated_i && sideband_tx_idle_i` -> RESET | No LTSM timeout; mainband tristated; clear ignored during residency | Directed tests, deterministic timeout/recovery, five-seed 180-trial recovery campaign, and wrapper protected-clear test |
| `LTSM_L1L2` | Represents the combined low-power state | ACTIVE PM request | On `pm_exit_i`: L2 request -> RESET; otherwise -> MBTRAIN/`SPEEDIDLE` | No timeout; mainband tristated | L1 exit in `pm_test`; L2 exit in `recovery_closure_test` |

## MBINIT substates

| Order | RTL name | Implemented transition |
|---:|---|---|
| 1 | `MBI_PARAM` | `phase_done_i && !stall_i` -> `MBI_CAL` |
| 2 | `MBI_CAL` | -> `MBI_REPAIRCLK` |
| 3 | `MBI_REPAIRCLK` | -> `MBI_REPAIRVAL` |
| 4 | `MBI_REPAIRVAL` | -> `MBI_REVERSALMB` |
| 5 | `MBI_REVERSALMB` | -> `MBI_REPAIRMB` |
| 6 | `MBI_REPAIRMB` | -> top-level `LTSM_MBTRAIN`, `MBT_VALVREF` |

The table does not claim that parameter exchange, calibration, repair, or reversal algorithms are implemented. Only their control labels and ordering are present.

## MBTRAIN substates

Each `phase_done_i` advances one step. `MBT_DATATRAINCENTER1` additionally advances automatically when the v0.3 engine reports `done && pass`; failure remains in the same substate and starts another attempt.

| Order | RTL name | Next |
|---:|---|---|
| 1 | `MBT_VALVREF` | `MBT_DATAVREF` |
| 2 | `MBT_DATAVREF` | `MBT_SPEEDIDLE` |
| 3 | `MBT_SPEEDIDLE` | `MBT_TXSELFCAL` |
| 4 | `MBT_TXSELFCAL` | `MBT_RXCLKCAL` |
| 5 | `MBT_RXCLKCAL` | `MBT_VALTRAINCENTER` |
| 6 | `MBT_VALTRAINCENTER` | `MBT_VALTRAINVREF` |
| 7 | `MBT_VALTRAINVREF` | `MBT_DATATRAINCENTER1` |
| 8 | `MBT_DATATRAINCENTER1` | `phase_done_i` compatibility bypass or successful LFSR result -> `MBT_DATATRAINVREF`; failed result -> repeat in place |
| 9 | `MBT_DATATRAINVREF` | `MBT_RXDESKEW` |
| 10 | `MBT_RXDESKEW` | `MBT_DATATRAINCENTER2` |
| 11 | `MBT_DATATRAINCENTER2` | `MBT_LINKSPEED` |
| 12 | `MBT_LINKSPEED` | `MBT_REPAIR` |
| 13 | `MBT_REPAIR` | top-level `LTSM_LINKINIT` |

## Transition priority

The combinational logic applies priority in this order:

1. The error manager's TRAINERROR request: immediate state timeout/SBINIT protocol error, acknowledged pending event, or expired manager bound.
2. Normal state-specific progress.

Within ACTIVE, retraining has priority over a simultaneous power-management request. Within L1L2, `pm_l2_req_i` selects RESET when `pm_exit_i` is asserted; otherwise the exit returns to MBTRAIN/`SPEEDIDLE`.
