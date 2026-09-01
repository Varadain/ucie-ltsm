# Project Evidence Matrix

Evidence classes used below are: **source** (committed implementation),
**executable** (reproducible test/build script), **observed** (committed tool
output), and **interpretive** (documentation derived from the first three).

| Claim area | Implemented artifact | Verification or report | Evidence class | Publication use | Qualification |
|---|---|---|---|---|---|
| Top-level LTSM control | `rtl/ucie_ltsm.sv`, `rtl/ucie_ltsm_pkg.sv` | directed controller test; nine deterministic UVM tests; SVA | source + executable | Architecture and state-flow description | Several physical procedures use `phase_done_i` abstraction |
| Sideband transaction engine | `rtl/ucie_sb_sequencer.sv` | directed success/retry/exhaust/mismatch/abort tests; randomized sideband campaign | source + executable | Explain ready/valid stability, matching, retry, and abort | Message set is intentionally small; no complete packet layer |
| DATATRAINCENTER1 integration | controller plus sideband and LFSR engines | production integrated UVM, five seeds, 180 trials; integrated SVA | source + executable + observed | Primary case study | One training phase, not the complete PHY training flow |
| LFSR checker/training engine | `rtl/ucie_lfsr_training_engine.sv` | independent 23-bit lane predictor; directed polynomial, gap, threshold, abort, default-count, saturation tests | source + executable | Demonstrate independent value prediction and strict threshold | Test configuration uses eight accepted samples; RTL default is 4096 |
| Retained error recovery | `rtl/ucie_error_manager.sv` | directed plus 180-trial recovery campaign; SVA; CSR checks | source + executable | Error attribution, retention, and protected clear | Cause priority is a project design choice within the modeled boundary |
| FPGA observability | `rtl/ucie_ltsm_fpga_wrapper.sv` | wrapper-directed test and CSR phase read | source + executable | Practical pin reduction and software-visible diagnostics | Compact project is not a board design |
| Production randomized verification | `verification/uvm/ucie_integrated_uvm_pkg.sv` | seeds 1701/1802/1903/2004/2105, 36 trials each | executable + observed | Scenario and cross-bin results | Starter license prevents native constrained-random/UCDB coverage; seeded `$urandom_range` and explicit counters are used |
| Preserved regression | verification testbenches and PowerShell/Questa scripts | 9 deterministic tests; 200 sideband, 160 training, 180 recovery, and 180 integrated trials | executable + observed | Regression scale and zero-error statement | “Pass” applies to the committed campaigns, not exhaustive behavior |
| Core synthesis | `quartus/ucie_ltsm.qpf/.qsf` | `quartus/output_files/ucie_ltsm.map.summary` | observed | Report mapped logic/register/pin demand | Mapping succeeds, but fitting fails at 151/151 pins |
| Compact-wrapper implementation | `quartus/ucie_ltsm_fpga.qpf/.qsf` | wrapper map/fit/STA summaries | observed | FPGA resource and internal timing result | No physical pin locations or external I/O delays; internal-clock result only |
| Reproducibility | `scripts/` plus committed source/reports | documented tool versions and fixed seeds | source + executable + observed | Artifact availability statement | Proprietary tools still require local installation/licensing |

## Audited quantitative facts

- Synthesizable RTL: 6 SystemVerilog files, 663 physical lines in the audited
  checkout.
- Verification RTL/UVM: 11 SystemVerilog files, 1,429 physical lines.
- Automation: 18 PowerShell/Questa/Tcl files, 329 physical lines.
- Integrated campaign: 180 trials across five fixed seeds and all nine scenario
  classes, with zero UVM errors/fatals in the accepted seed logs.
- Preserved randomized campaigns: 200 sideband + 160 training + 180 recovery +
  180 integrated trials, in addition to nine deterministic UVM tests and the
  module-directed suites.
- Compact wrapper: 824/24,624 logic elements (3%), 505 registers, 119/151 pins
  (79%), and zero virtual pins on a Cyclone 10 LP 10CL025YU256C8G.
- Wrapper internal timing at an 80-MHz, 12.5-ns clock constraint: worst reported
  setup slack +1.013 ns and hold slack +0.179 ns across the committed corners;
  the reports show zero negative slack.
- Wide core top: mapping reports 763 logic elements, 505 registers, and 151
  pins; fitting fails because all 151 device pins are demanded. This is a
  negative implementation result and must not be presented as a successful fit.

Counts are descriptive repository metrics, not measures of design quality or
coverage completeness.
