# Repository Audit and Migration Map

Audit date: **August 27, 2026**

The workspace was not a Git repository when inspected. The table records the disposition used for the initial publishable baseline. Generated or uncertain files were retained on disk; no technical material was deleted.

| Existing path/category | Purpose | Git disposition | Repository location / documentation |
|---|---|---|---|
| `rtl/ucie_ltsm_pkg.sv` | Shared state/retrain types | Include unchanged | Same path; [RTL guide](04_rtl/README.md) |
| `rtl/ucie_ltsm.sv` | Synthesizable controller | Include; default clock corrected to match checked constraint | Same path; [RTL guide](04_rtl/README.md) |
| `verification/tb_ucie_ltsm.sv` | Self-checking directed test | Include unchanged | Same path; [verification](05_verification/README.md) |
| `verification/ucie_ltsm_sva.sv` | Assertions and cover property | Include unchanged | Same path; [verification](05_verification/README.md) |
| `verification/uvm/*.sv` | UVM interface, package, and testbench top | Include unchanged | Same paths; [verification](05_verification/README.md) |
| `scripts/run_questa.do` | Directed compile/run flow | Include unchanged | Same path; [Questa results](06_results/questa.md) |
| `scripts/run_uvm.do` | Per-test UVM compile/run flow | Include unchanged | Same path; [Questa results](06_results/questa.md) |
| `scripts/run_uvm_regression.ps1` | Four-test UVM regression | Include unchanged | Same path; [Questa results](06_results/questa.md) |
| `quartus/*.qpf`, `*.qsf`, `*.sdc` | Reproducible Cyclone 10 LP project and clock constraint | Include | Same paths; [Quartus results](06_results/quartus.md) |
| `quartus/output_files/*.summary` | Compact fit, timing, and synthesis evidence | Include | Same paths; [Quartus results](06_results/quartus.md) |
| `quartus/db/`, `quartus/incremental_db/`, other `output_files/` | Generated Quartus databases, reports, and programming data | Ignore; retain locally | Reproducible from the Quartus project |
| Root `db/`, root `ucie_ltsm.q*`, root Quartus reports | Legacy/duplicate Quartus project output | Ignore; retain pending manual review | Tracked in [documentation status](../DOCUMENTATION_STATUS.md) |
| `verification/uvm/logs/`, `verification/directed_run.log`, `transcript` | Generated Questa logs | Ignore; retain locally | Results summarized in [Questa results](06_results/questa.md) |
| `work/`, `vish_stacktrace.vstf` | Generated Questa library/diagnostic data | Ignore; retain locally | Recreated by simulation scripts |
| UCIe specification PDF and extracted text | Private reference material | Ignore; moved without content changes | `references_private/` |
| `docs/requirements_traceability.md` | Existing specification-to-implementation matrix | Include | Same path |
| `docs/journal_plan.md` | Proposed research plan | Include with explicit “plan” status | Same path; manual-review note in documentation status |

## Not found during inspection

- Cadence scripts, constraints, libraries, or reports.
- Waveform databases or selected publishable waveform images.
- Functional coverage reports.
- Power reports.
- A license decision.

Directories for those items were not created because no corresponding implementation or evidence exists yet.
