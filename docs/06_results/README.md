# Results

Only observed tool output is reported here.

| Flow | Tool/configuration | Latest available result | Detail |
|---|---|---|---|
| Directed simulation | Questa Intel Starter FPGA Edition 2023.3 | Pass; zero compile/simulation errors | [Questa](questa.md) |
| UVM regression | Questa 2023.3, bundled UVM 1.1d | Eight tests pass; zero UVM errors/fatals | [Questa](questa.md) |
| Seeded randomized UVM | Questa 2023.3, bundled UVM 1.1d | Five seeds / 200 trials pass; predictor totals match; zero errors/fatals/illegal transitions | [Questa](questa.md#seeded-randomized-regression) |
| DATATRAINCENTER1 randomized UVM | Questa 2023.3, bundled UVM 1.1d | Five seeds / 160 trials pass; independent LFSR/count matches; all explicit bins/crosses hit | [v0.3 results](datatrain_lfsr.md) |
| FPGA implementation | Quartus Prime 23.1std.1, Cyclone 10 LP | v0.3 fit successful: 698 LEs, 465 registers; internal clock timing positive at 80 MHz; I/O timing incomplete | [Quartus](quartus.md) |
| Functional netlist | Quartus EDA Netlist Writer 23.1std.1 | v0.3 reviewed Verilog netlist retained with SHA-256 provenance | [Netlist](../../synthesis/quartus/netlists/v0.3-advanced-training/README.md) |
| Cadence ASIC flow | No scripts or reports found | No result available | [Documentation status](../../DOCUMENTATION_STATUS.md) |
| Power analysis | No report found | No result available | [Documentation status](../../DOCUMENTATION_STATUS.md) |

Generated raw simulator logs, VCDs, and large Quartus databases are ignored. The commands, reviewed waveform SVGs, functional netlist, and selected compact Quartus summaries remain available for reproduction.
