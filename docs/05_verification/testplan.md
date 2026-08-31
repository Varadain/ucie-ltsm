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
| DT-DIR-01 | LFSR engine algorithm and boundaries | Independent lane seed/polynomial model, receive gaps, clean/corrupt samples, threshold equality, abort, 4096 all-error samples | All 16 lane outputs match; strict threshold behavior; abort clears; error counter saturates at 16'hffff on the 4096th sample | `tb_ucie_lfsr_training_engine` | Pass |
| DT-RAND-01 | Seeded DATATRAINCENTER1 campaign | 32 trials/seed with randomized gaps, corruption count/location, threshold, outcome, abort point, and repeat attempt | Predictor matches patterns/count/result; pass advances; failure retries in place; abort clears; timeout reaches TRAINERROR | `datatrain_random_test`, seeds 701/802/903/1004/1105 | Pass |
| DT-SVA-01 | Training integration invariants | All v0.3 directed and UVM stimulus | Busy is confined to CENTER1 plus the defined abort cycle; done pulses and is not busy; pass uses strict threshold; counts hold without accepted samples | `ucie_ltsm_sva` | Pass |
| ER-DIR-01 | Error-manager retention and boundaries | Short/held faults, delayed/missing acknowledgement, simultaneous causes, clear timing, 65,536 accepted events | Request/pending persistence, timeout bound, priority, retained log, ignored clear and saturated counter match the reference expectations | `tb_ucie_error_manager` | Pass |
| ER-RAND-01 | Integrated seeded recovery campaign | 36 trials/seed across seven origins, six recovery scenarios, randomized pulse/ack/residency controls | Cause/count predictor matches; all events enter TRAINERROR; pending clears; retained log and release behavior are exact | `recovery_random_test`, seeds 1201/1302/1403/1504/1605 | Pass |
| ER-CLOSE-01 | Prior recovery gaps | L2 exit and TXSELFCAL/SPEEDIDLE/REPAIR retrain targets | L2 returns RESET; each retrain target selects the required MBTRAIN substate | `recovery_closure_test` | Pass |
| ER-SVA-01 | Error handshake and retention invariants | Directed, deterministic and randomized recovery regressions | Fatal requests immediately, pending holds request, manager timeout enters TRAINERROR, pending clears and TRAINERROR log is stable | `ucie_ltsm_sva` | Pass |

“Pass” reflects the fresh deterministic and randomized regression reruns through August 31, 2026, described in [questa.md](../06_results/questa.md), [datatrain_lfsr.md](../06_results/datatrain_lfsr.md), and [error_recovery.md](../06_results/error_recovery.md).

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
