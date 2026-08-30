# DATATRAINCENTER1 LFSR Verification

## Scope

This checkpoint verifies design commit `c052615dab54d0b4ab4ea19df78e0454ddbd36b6` against stable baseline `v0.2-random-uvm` / `61f0d23d01568e5c9c9dd1b83d1e40cea1db729a`. The RTL delta adds a 16-lane, 23-bit LFSR training engine and integrates it into `MBT_DATATRAINCENTER1`.

The integration UVM instance reduces `DATATRAIN_SAMPLE_COUNT` to eight so many attempts and timing combinations can be exercised. A separate directed instance retains the default 4096 samples and drives 16 errors per sample, proving completion on sample 4096 and saturation at `16'hffff`.

## Reference model and checks

The directed test and UVM driver contain an independent implementation of the eight lane seeds repeated modulo eight and the polynomial progression `X^23 + X^21 + X^16 + X^8 + X^5 + X^2 + 1`. Every transmitted 16-bit sample is compared before the receive sample is accepted. Expected bit errors are calculated independently from the injected rotating corruption mask.

Checks cover receive-valid gaps, clean and corrupted samples, error positions and counts, zero/equality/above-count threshold behavior, strict `error_count < threshold`, result pulses, counter saturation, successful advance to `DATATRAINVREF`, failed-run residency and automatic repeat, phase-driven abort, reset, and the existing LTSM timeout.

## Randomized campaign

Questa Intel Starter FPGA Edition 2023.3 cannot check out the `svverification` feature required for class `randomize()` and covergroups. The campaign therefore uses seeded `$urandom_range` over explicit legal domains and an explicit functional-coverage bin/cross model reported in each UVM log. No native UCDB coverage percentage is claimed.

| Seed | Pass scenario | Fail/retry | Abort | Timeout | Completed passes | Failed attempts |
|---:|---:|---:|---:|---:|---:|---:|
| 701 | 9 | 7 | 9 | 7 | 16 | 7 |
| 802 | 10 | 7 | 9 | 6 | 17 | 7 |
| 903 | 11 | 6 | 7 | 8 | 17 | 6 |
| 1004 | 9 | 6 | 10 | 7 | 15 | 6 |
| 1105 | 8 | 6 | 9 | 9 | 14 | 6 |
| Total | 47 | 32 | 44 | 37 | 79 | 32 |

Across 160 trials, the reference model checked 368 clean and 654 corrupted accepted samples with 1,768 receive-gap cycles. All scenario bins, error-count bins (clean, 1-4, 5-15, and 16 lanes), gap bins (0, 1-2, and 3 cycles), threshold equality/away bins, and all 12 scenario-by-gap cross bins were hit. Aggregate bin counts were:

- scenarios: `47/32/44/37`;
- error bins: `14/64/76/6`;
- gap bins: `28/78/54`;
- threshold away/equality: `155/5`; and
- scenario-by-gap cross: `7/25/15; 11/10/11; 5/25/14; 5/18/14`.

Every seed completed with zero UVM errors/fatals, zero illegal LTSM transitions, and no assertion failure.

## Commands and preserved regression

```powershell
vsim -c -do scripts/run_lfsr_directed.do
.\scripts\run_datatrain_random_regression.ps1
.\scripts\run_uvm_regression.ps1
.\scripts\run_random_regression.ps1
vsim -c -do scripts/run_questa.do
vsim -c -do scripts/run_sb_directed.do
```

The LFSR directed test, all eight deterministic UVM tests, five seeded sideband runs (200 transactions), the base directed test, and sideband directed test passed in fresh simulator invocations. The only directed-flow warning was Questa `vsim-8492` stating that `-assertdebug` found no accessible objects; it did not affect compilation, assertions, or results.

Quartus Prime Lite 23.1std.1 full compilation also passed for Cyclone 10 LP `10CL025YU256C8G`: 698 logic elements, 465 registers, and 126 pins. The 80 MHz clock met analyzed timing with worst setup slack `+0.744 ns`, worst hold slack `+0.178 ns`, and zero setup/hold TNS. These are FPGA implementation results, not ASIC or PHY link-rate evidence. Quartus reported 15 warnings, notably unconstrained I/O paths/incomplete pin assignments, 126 pins without exact locations, constant sideband message bits, unspecified processor count, and the unavailable LogicLock subscription feature. Timing is therefore not fully constrained despite the positive clock-domain slacks.

## Remaining gaps

- Native covergroup/UCDB coverage is unavailable under the installed Starter license; explicit sampled bin reports are used instead.
- The randomized integration campaign uses eight samples for throughput; the 4096 default is proven in a focused directed run rather than across all randomized scenarios.
- `phase_done_i` remains an architectural bypass for all MBTRAIN substates, including DATATRAINCENTER1; the abort scenario verifies that the engine clears after this externally forced exit.
- This is transaction-level digital training. Analog channel behavior, jitter, equalization, physical lane repair, and BER confidence intervals are outside the current RTL model.
- No reviewed/versioned netlist or waveform figure was requested or produced; raw Quartus and simulator databases remain ignored.
