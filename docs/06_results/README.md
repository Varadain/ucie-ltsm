# Results

Only observed tool output is reported here.

| Flow | Tool/configuration | Latest available result | Detail |
|---|---|---|---|
| Directed simulation | Questa Intel Starter FPGA Edition 2023.3 | Controller, sideband, LFSR, error-manager, and FPGA-wrapper suites pass | [Questa](questa.md) |
| UVM regression | Questa 2023.3, bundled UVM 1.1d | Nine tests pass; zero UVM errors/fatals | [Questa](questa.md) |
| Seeded randomized UVM | Questa 2023.3, bundled UVM 1.1d | Five seeds / 200 trials pass; predictor totals match; zero errors/fatals/illegal transitions | [Questa](questa.md#seeded-randomized-regression) |
| DATATRAINCENTER1 randomized UVM | Questa 2023.3, bundled UVM 1.1d | Five seeds / 160 trials pass; independent LFSR/count matches; all explicit bins/crosses hit | [v0.3 results](datatrain_lfsr.md) |
| Recovery randomized UVM | Questa 2023.3, bundled UVM 1.1d | Five seeds / 180 trials pass; exact predictor agreement and all required explicit bins/crosses | [v0.4 recovery](error_recovery.md) |
| FPGA CSR wrapper | Questa 2023.3 | Directed CSR/state/error/clear test passes | [Wrapper verification](fpga_csr_wrapper.md) |
| FPGA implementation | Quartus Prime 23.1std.1, Cyclone 10 LP | v0.4 wrapper fit: 804 LEs, 499 registers, 119 pins, zero virtual pins; positive internal 80 MHz timing | [Quartus](quartus.md) |
| Functional netlists | Quartus EDA Netlist Writer 23.1std.1 | Fitted wrapper and core-only views retained with SHA-256 provenance | [Netlists](../../synthesis/quartus/netlists/v0.4-error-recovery/README.md) |
| Cadence ASIC flow | No scripts or reports found | No result available | [Documentation status](../../DOCUMENTATION_STATUS.md) |
| Power analysis | No report found | No result available | [Documentation status](../../DOCUMENTATION_STATUS.md) |

Generated raw simulator logs, VCDs, and large Quartus databases are ignored. The commands, reviewed waveform SVGs, functional netlist, and selected compact Quartus summaries remain available for reproduction.
