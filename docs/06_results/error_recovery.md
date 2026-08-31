# Retained and Classified TRAINERROR Verification

## Scope

This checkpoint verifies design commit `1637c42ab327c14613726907a2ca45aa77b8fc4b` against stable v0.3 commit `62a6cdd45eb95a6ef36a67f07aa4b120b862133b`. The delta adds `ucie_error_manager`, retained error cause/count outputs, a pending handshake, a bounded missing-acknowledgement path, and controlled log clearing.

The independent predictor implements the specified priority: state timeout, sideband protocol error, then local fatal error. It checks the expected cause and count after every integrated event. The focused directed test additionally drives 65,536 accepted events to prove one increment per event and saturation at `16'hffff`.

## Seeded randomized campaign

Questa Intel Starter FPGA Edition 2023.3 cannot license class `randomize()` or covergroups. Five reproducible seeds therefore use `$urandom_range` within explicit legal domains and report sampled bins/crosses without claiming a UCDB percentage.

| Seed | Delayed fatal | Missing ack | State timeout | SBINIT protocol | Residency | Simultaneous | Total |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1201 | 5 | 8 | 9 | 7 | 3 | 4 | 36 |
| 1302 | 10 | 5 | 6 | 4 | 7 | 4 | 36 |
| 1403 | 6 | 4 | 8 | 8 | 4 | 6 | 36 |
| 1504 | 9 | 7 | 4 | 7 | 3 | 6 | 36 |
| 1605 | 6 | 6 | 5 | 6 | 8 | 5 | 36 |
| Total | 36 | 30 | 32 | 32 | 25 | 25 | 180 |

All 180 events entered TRAINERROR with exact predicted cause/count and zero UVM errors, fatals, illegal transitions, or assertion failures. Aggregate explicit coverage was:

- scenario bins: `36/30/32/32/25/25`;
- origin bins for SBINIT, MBINIT, MBTRAIN, LINKINIT, ACTIVE, PHYRETRAIN and L1L2: `32/28/21/29/47/13/10`;
- one-cycle/multi-cycle fault pulses: `47/133`;
- zero-latency/delayed/missing acknowledgements: `18/132/30`;
- manager-timeout entries: 30;
- SBINIT immediate entries: 32;
- escalated/sideband-idle residency trials: 25; and
- simultaneous timeout-plus-fatal priority trials: 25.

The legal scenario/origin cross was sampled and reported per seed in `RECOVERY_CROSS`. Local fatal and residency covered eligible post-SBINIT origins; missing acknowledgement used ACTIVE so the independently running state timeout could not preempt the manager timeout; state-timeout and simultaneous cases covered timeout-enabled origins; sideband protocol cases originated in SBINIT.

## Assertions and directed proof

SVA checks immediate fatal handshake request, request persistence while pending, manager-timeout transition, pending clear on TRAINERROR entry, stable retained logs during TRAINERROR, and ignored clear while pending. Existing LTSM and training assertions remained enabled.

The focused directed test verifies short-pulse retention, held-signal de-duplication, fixed cause priority, immediate SBINIT/state-timeout behavior, exact four-cycle manager timeout, allowed/ignored clear windows, reset behavior, and counter saturation. `recovery_closure_test` also passes L2 exit and all TXSELFCAL, SPEEDIDLE and REPAIR retrain targets.

## Commands and results

```powershell
vsim -c -do scripts/run_error_directed.do
.\scripts\run_recovery_random_regression.ps1
.\scripts\run_uvm_regression.ps1
.\scripts\run_random_regression.ps1
.\scripts\run_datatrain_random_regression.ps1
vsim -c -do scripts/run_questa.do
vsim -c -do scripts/run_sb_directed.do
vsim -c -do scripts/run_lfsr_directed.do
quartus_sh --flow compile ucie_ltsm
```

All four directed suites, all nine deterministic UVM tests, five recovery seeds, five preserved sideband seeds, and five preserved training seeds passed in fresh invocations. Questa repeatedly warned that stale optimized designs were locked and could not be deleted; each requested top was recompiled and the simulations completed successfully. Directed flows also emitted benign `vsim-8492` warnings for `-assertdebug` with no accessible optimized objects.

Quartus Prime Lite 23.1std.1 analysis and synthesis passed, but full compilation did not: the Cyclone 10 LP `10CL025YU256C8G` fitter requires 147 general-purpose 2.5 V I/O pins while only 144 are available. The failure is caused by exposing the growing controller interface as physical FPGA pins, not by a synthesis error. No timing result is claimed for v0.4. A later implementation checkpoint must use a larger package or an FPGA wrapper/virtual-pin strategy before timing evidence is valid.

## Remaining gaps

- Native covergroup/UCDB coverage remains unavailable with the installed Starter license.
- The digital controller model does not cover analog channel faults, CDC/metastability injection, physical packet corruption, or software log servicing.
- Manager timeout is tied to the LTSM timeout parameter. In timeout-enabled states, a fault arriving after state entry can be preempted by the state timeout; the manager-timeout proof therefore uses ACTIVE plus the focused manager test.
- Quartus fitting and timing are blocked by top-level package pin capacity.
- No reviewed waveform figure or versioned netlist was requested or produced; raw simulator and Quartus databases remain ignored.
