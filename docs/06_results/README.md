# Results

Only observed tool output is reported here.

| Flow | Tool/configuration | Latest available result | Detail |
|---|---|---|---|
| Directed simulation | Questa Intel Starter FPGA Edition 2023.3 | Pass; zero compile/simulation errors | [Questa](questa.md) |
| UVM regression | Questa 2023.3, bundled UVM 1.1d | Eight tests pass; zero UVM errors/fatals | [Questa](questa.md) |
| Seeded randomized UVM | Questa 2023.3, bundled UVM 1.1d | Five seeds / 200 trials pass; predictor totals match; zero errors/fatals/illegal transitions | [Questa](questa.md#seeded-randomized-regression) |
| FPGA implementation | Quartus Prime 23.1std.1, Cyclone 10 LP | Fit successful; internal clock timing positive at 80 MHz; I/O timing incomplete | [Quartus](quartus.md) |
| Functional netlist | Quartus EDA Netlist Writer 23.1std.1 | Generated Verilog netlist retained with v0.2 | [Netlist](../../synthesis/quartus/netlists/v0.2-sideband/README.md) |
| Cadence ASIC flow | No scripts or reports found | No result available | [Documentation status](../../DOCUMENTATION_STATUS.md) |
| Power analysis | No report found | No result available | [Documentation status](../../DOCUMENTATION_STATUS.md) |

Generated raw simulator logs, VCDs, and large Quartus databases are ignored. The commands, reviewed waveform SVGs, functional netlist, and selected compact Quartus summaries remain available for reproduction.
