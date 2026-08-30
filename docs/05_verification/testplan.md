# Verification Test Plan

## Implemented scenarios

| ID | Behavior | Stimulus | Expected state sequence / result | Test | Status |
|---|---|---|---|---|---|
| DIR-01 | Nominal initialization | Readiness + trigger; ordered completion pulses; RDI active | RESET -> SBINIT -> MBINIT -> MBTRAIN -> LINKINIT -> ACTIVE | Directed test; `nominal_test` | Pass |
| DIR-02 | SPEEDIDLE retrain | Retrain request, `RETRAIN_SPEEDIDLE`, completion | ACTIVE -> PHYRETRAIN -> MBTRAIN/`SPEEDIDLE` | Directed test; `recovery_test` | Pass |
| DIR-03 | Fatal-error recovery | Fatal error + handshake; sideband idle; no escalation | Non-RESET -> TRAINERROR -> RESET | Directed test; `recovery_test` | Pass |
| UVM-01 | SBINIT timeout | Start training; withhold completion until timeout | SBINIT -> TRAINERROR -> RESET | `timeout_test` | Pass |
| UVM-02 | L1 exit | Request L1, then PM exit | ACTIVE -> L1L2 -> MBTRAIN/`SPEEDIDLE` | `pm_test` | Pass |
| SB-DIR-01 | Sequencer protocol controls | Backpressure, response, timeout, mismatch, abort | Request held; success/retry/error/abort resolve as specified | `tb_ucie_sb_sequencer` | Pass |
| SB-UVM-01 | Integrated SBINIT success | Accept request and return `SBINIT_DONE_RESP` | SBINIT -> MBINIT without `phase_done_i` | `sb_success_test` | Pass |
| SB-UVM-02 | Integrated bounded retry | Accept request, withhold response for one sequencer timeout, accept retry, return response | Exactly two accepted requests, one retry, then SBINIT -> MBINIT | `sb_retry_test` | Pass |
| SB-UVM-03 | Integrated wrong response | Accept request and return `SB_MSG_NOP` | Protocol error; SBINIT -> TRAINERROR -> RESET | `sb_error_test` | Pass |
| SB-UVM-04 | Integrated retry exhaustion | Accept initial request and retry; return no response | One retry, protocol error, SBINIT -> TRAINERROR -> RESET | `sb_exhaust_test` | Pass |
| SB-RAND-01 | Seeded randomized sideband campaign | Random outcome plus 1-3 cycle transmit/response delays; 40 trials per seed | Predictor counters match monitor; every outcome hit; no illegal transition | `sb_random_test`, seeds 101/202/303/404/505 | Pass |

“Pass” reflects the fresh August 28, 2026 Questa runs described in [questa.md](../06_results/questa.md).

## Planned scenarios required for stronger confidence

| ID | Missing evidence | Expected focus |
|---|---|---|
| PLAN-01 | L2 exit | ACTIVE -> L1L2 -> RESET |
| PLAN-02 | `RETRAIN_TXSELFCAL` | PHYRETRAIN -> MBTRAIN/`TXSELFCAL` |
| PLAN-03 | `RETRAIN_REPAIR` | PHYRETRAIN -> MBTRAIN/`REPAIR` |
| PLAN-04 | Stall timing | Stall restarts the counter and blocks MBINIT progress |
| PLAN-05 | Timeout matrix | Each eligible top-level state and each substate reaches TRAINERROR at the intended boundary |
| PLAN-06 | Fatal-error matrix | Every non-RESET state with handshake/escalation variations |
| PLAN-07 | Simultaneous ACTIVE requests | Verify retrain priority over PM entry |
| PLAN-08 | Functional coverage | Cross top-level transitions, substates, retrain targets, timeout origins, and recovery outcomes |

Future sideband tests must distinguish the implemented transaction-level interface from physical packet behavior. Framing, CRC, credits, repair, and broader message scenarios should not be modeled as DUT functionality until corresponding RTL exists.
