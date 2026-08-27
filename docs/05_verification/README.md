# Verification

The project uses a self-checking directed test first, followed by a reusable UVM environment. Assertions run alongside both testbench tops.

## Verification flow

```mermaid
flowchart LR
    REQ[Implemented behavior] --> DIR[Directed scenario]
    REQ --> UVM[UVM sequences]
    DIR --> DUT[ucie_ltsm]
    UVM --> DUT
    DUT --> SVA[SystemVerilog assertions]
    DUT --> MON[UVM monitor]
    MON --> SB[Transition scoreboard]
    SVA --> RESULT[Pass / failure evidence]
    SB --> RESULT
```

## Directed verification

[`verification/tb_ucie_ltsm.sv`](../../verification/tb_ucie_ltsm.sv) performs one deterministic scenario:

1. Apply reset and readiness inputs.
2. Reach SBINIT, pulse completion into MBINIT, then advance six MBINIT and thirteen MBTRAIN operations.
3. Assert RDI active and require ACTIVE.
4. Request PHY retraining and require MBTRAIN/`SPEEDIDLE` re-entry.
5. Inject a fatal error with the error handshake complete.
6. Require TRAINERROR and then RESET.

Every explicit checkpoint uses `$fatal` on mismatch. The pass condition is the final message `PASS: nominal training, retrain, and error recovery` with no earlier fatal error.

## UVM architecture

```mermaid
flowchart TB
    TEST[UVM test] --> SEQ[Scenario sequence]
    SEQ --> SQR[Sequencer]
    SQR --> DRV[Driver]
    DRV --> IF[ucie_ltsm_if]
    IF --> DUT[ucie_ltsm]
    DUT --> IF
    IF --> MON[Passive monitor]
    MON -->|state_sample| SB[Scoreboard]
```

All UVM classes are currently collected in [`verification/uvm/ucie_ltsm_uvm_pkg.sv`](../../verification/uvm/ucie_ltsm_uvm_pkg.sv). This is compact for the current scale; the repository does not pretend they are already split into separate component files.

Implemented UVM components:

- operation sequence item and sequencer;
- driver for start, completion, timeout wait, retrain, fatal-error, stall, and PM operations;
- passive top-level-state transition monitor;
- scoreboard that rejects transitions outside the modeled top-level graph;
- agent and environment;
- nominal, timeout, recovery, and PM sequences/tests.

## Current UVM scenarios

| Test | Objective | Key expected observation | Fresh result |
|---|---|---|---|
| `nominal_test` | Initialize from RESET to ACTIVE | Scoreboard sees ACTIVE and no illegal transition | Pass |
| `timeout_test` | Leave SBINIT through timeout | Scoreboard sees TRAINERROR | Pass |
| `recovery_test` | Exercise retrain, SPEEDIDLE re-entry, and fatal-error recovery | Scoreboard sees PHYRETRAIN and TRAINERROR | Pass |
| `pm_test` | Exercise L1 entry and exit | Scoreboard sees L1L2; RTL returns through MBTRAIN | Pass |

See [testplan.md](testplan.md) for exact coverage and missing scenarios.

## Assertions and cover property

[`verification/ucie_ltsm_sva.sv`](../../verification/ucie_ltsm_sva.sv) contains:

| Property | Checks |
|---|---|
| `ap_link_up_only_active` | `link_up_i` implies ACTIVE in the same sampled cycle |
| `ap_timeout_to_error` | A timeout is followed by TRAINERROR |
| `ap_no_reset_direct_active` | RESET cannot transition directly to ACTIVE |
| `ap_known_state` | The top-level state has no unknown bits |
| `cp_reaches_active` | Covers eventual RESET-to-ACTIVE reachability in a run |

## Coverage boundary

There are no functional covergroups and no checked-in UCDB/coverage report. The scoreboard records only top-level transitions. It does not prove every MBINIT/MBTRAIN substate, every timeout location, all retrain targets, or every error combination.
