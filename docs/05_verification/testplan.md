# Verification Test Plan

## Implemented scenarios

| ID | Behavior | Stimulus | Expected state sequence / result | Test | Status |
|---|---|---|---|---|---|
| DIR-01 | Nominal initialization | Readiness + trigger; ordered completion pulses; RDI active | RESET -> SBINIT -> MBINIT -> MBTRAIN -> LINKINIT -> ACTIVE | Directed test; `nominal_test` | Pass |
| DIR-02 | SPEEDIDLE retrain | Retrain request, `RETRAIN_SPEEDIDLE`, completion | ACTIVE -> PHYRETRAIN -> MBTRAIN/`SPEEDIDLE` | Directed test; `recovery_test` | Pass |
| DIR-03 | Fatal-error recovery | Fatal error + handshake; sideband idle; no escalation | Non-RESET -> TRAINERROR -> RESET | Directed test; `recovery_test` | Pass |
| UVM-01 | SBINIT timeout | Start training; withhold completion until timeout | SBINIT -> TRAINERROR -> RESET | `timeout_test` | Pass |
| UVM-02 | L1 exit | Request L1, then PM exit | ACTIVE -> L1L2 -> MBTRAIN/`SPEEDIDLE` | `pm_test` | Pass |

“Pass” reflects the fresh August 27, 2026 Questa runs described in [questa.md](../06_results/questa.md).

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

Future tests must reflect the implemented interface at that milestone. They should not model sideband packets before a sideband engine exists.
