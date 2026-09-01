# Result Traceability

This ledger is the mandatory source of truth for numerical statements in the
manuscript. “Direct” means copied from a committed tool summary or accepted
test log. “Derived” means arithmetic over direct evidence and is shown here so
it can be independently recalculated.

| ID | Result used in paper | Value | Evidence | Derivation / caveat |
|---|---|---:|---|---|
| R-01 | Integrated randomized trials | 180 | `scripts/run_integrated_random_regression.ps1`; `docs/06_results/v1.0_integrated_training.md` | 5 seeds × 36 trials |
| R-02 | Integrated seeds | 1701, 1802, 1903, 2004, 2105 | same as R-01 | Fixed reproducibility set |
| R-03 | Integrated scenario hits 0–8 | 18, 20, 17, 16, 23, 19, 20, 18, 29 | accepted per-seed integrated logs summarized in `docs/06_results/v1.0_integrated_training.md` | Sum = 180; classes are nominal, failed-pattern retry/pass, START retry, malformed START, END retry, malformed END, reset abort, fatal abort, state-timeout abort |
| R-04 | START req/resp observations | 173 / 140 | accepted integrated seed summaries | Derived sum over five seeds; fewer responses are expected under retry, malformed response, or abort scenarios |
| R-05 | END req/resp observations | 120 / 78 | accepted integrated seed summaries | Derived sum over five seeds; END is suppressed on failed/aborted paths |
| R-06 | Pattern pass/fail observations | 121 / 20 | accepted integrated seed summaries | Derived sum over five seeds; a failed pattern can retry |
| R-07 | Sideband retry observations | 40 | accepted integrated seed summaries | Derived sum |
| R-08 | Protocol-error observations | 35 | accepted integrated seed summaries | Derived sum |
| R-09 | Reset/fatal/timeout aborts | 20 / 18 / 29 | accepted integrated seed summaries | Derived sum |
| R-10 | Predictor checks | 398 | accepted integrated seed summaries | Derived sum of per-seed independent predictor checks |
| R-11 | Production-mode gate | bypass = 0 | `verification/uvm/tb_ucie_integrated_uvm.sv` | Direct parameter setting |
| R-12 | Deterministic UVM suite | 9 tests | `scripts/run_uvm_regression.ps1`; result documentation | All pass in preserved gate |
| R-13 | Randomized campaign totals | 200 / 160 / 180 / 180 | sideband/training/recovery/integrated regression scripts and result documents | Trials, not unique temporal traces; fixed-seed pseudo-random generation |
| R-14 | Verification outcome | 0 UVM errors, 0 UVM fatals, no reported assertion failures | accepted campaign logs and `docs/06_results/v1.0_integrated_training.md` | Excludes ignored ad-hoc `debug.log`; not a proof of exhaustiveness |
| R-15 | Wrapper FPGA device | Cyclone 10 LP 10CL025YU256C8G | `quartus/output_files_wrapper/ucie_ltsm_fpga.fit.summary` | Direct |
| R-16 | Wrapper fit | successful | same as R-15 | Quartus Prime Lite 23.1std.1 |
| R-17 | Wrapper resources | 824 LEs; 505 registers; 119 pins | same as R-15 | 3% LEs and 79% pins as reported by Quartus |
| R-18 | Wrapper internal setup/hold slack | +1.013 ns / +0.179 ns worst | `quartus/output_files_wrapper/ucie_ltsm_fpga.sta.summary` | Minimum across reported corners; 12.5-ns clock constraint; no external I/O delays |
| R-19 | Core mapping | 763 LEs; 505 registers; 151 pins | `quartus/output_files/ucie_ltsm.map.summary` | Direct mapping result |
| R-20 | Core fit | failed | `quartus/output_files/ucie_ltsm.fit.summary` | Pin demand is 151/151; do not use core STA as successful-fit timing evidence |

## Audit rule

No number may enter the abstract, conclusion, results section, table, figure, or
caption unless it has an ID in this file. Any regenerated report must update
this ledger and trigger a claim/evidence review.
