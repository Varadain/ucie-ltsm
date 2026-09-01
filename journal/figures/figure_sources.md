# Figure Sources and Rights Ledger

All figures in this package are original project diagrams generated from
committed RTL, verification source, scripts, and tool summaries. They do not
contain screenshots, copied shapes, or traced geometry from the private UCIe
specification. UCIe-defined terminology is used as technical nomenclature and
is cited in the manuscript.

| Figure | Editable source | Evidence basis | Rights / adaptation status |
|---|---|---|---|
| 1. Scope boundary | `source/fig01_scope.drawio` | `rtl/`, `specification_scope.md` | Original; no adaptation |
| 2. RTL architecture | `source/fig02_rtl_architecture.drawio` | RTL module interfaces | Original; no adaptation |
| 3. Hierarchical control flow | `source/fig03_ltsm_flow.drawio` | `ucie_ltsm_pkg.sv`, `ucie_ltsm.sv` | Original project view; standard terminology cited |
| 4. Integrated CENTER1 sequence | `source/fig04_integrated_sequence.drawio` | controller, sequencer, LFSR RTL and predictor | Original; no adaptation |
| 5. LFSR measurement engine | `source/fig05_lfsr_engine.drawio` | `ucie_lfsr_training_engine.sv` | Original; no adaptation |
| 6. Retained recovery flow | `source/fig06_error_recovery.drawio` | `ucie_error_manager.sv`, SVA, CSR wrapper | Original; no adaptation |
| 7. Verification architecture | `source/fig07_verification.drawio` | UVM packages, SVA, regression scripts | Original; no adaptation |
| 8. FPGA implementation evidence | `source/fig08_fpga_results.drawio` | committed Quartus map/fit/STA summaries | Original data graphic; no adaptation |

Each source has matching `svg/`, `pdf/`, and `png/` exports. The publication
uses vector PDF. PNG is only for visual review and web preview.

Visual convention: pale gold (`#F7E396`) marks the implemented control path;
blue marks verification or external stimulus; green marks accepted/pass paths;
red marks negative/error paths; gray/dashed regions are abstracted or excluded.
Text labels and line styles duplicate color meaning so figures remain readable
in grayscale.
