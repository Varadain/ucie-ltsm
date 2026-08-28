# Quartus Results

The checked project uses Quartus Prime 23.1std.1 Lite Edition and targets Cyclone 10 LP device `10CL025YU256C8G`.

## Reproduce

```powershell
Push-Location quartus
& 'C:\intelFPGA_lite\23.1std\quartus\bin64\quartus_sh.exe' --flow compile ucie_ltsm
Pop-Location
```

Source inputs:

- [`quartus/ucie_ltsm.qpf`](../../quartus/ucie_ltsm.qpf)
- [`quartus/ucie_ltsm.qsf`](../../quartus/ucie_ltsm.qsf)
- [`quartus/ucie_ltsm.sdc`](../../quartus/ucie_ltsm.sdc)
- [`rtl/ucie_ltsm_pkg.sv`](../../rtl/ucie_ltsm_pkg.sv)
- [`rtl/ucie_sb_sequencer.sv`](../../rtl/ucie_sb_sequencer.sv)
- [`rtl/ucie_ltsm.sv`](../../rtl/ucie_ltsm.sv)

## Checked constraint

`clk_i` is constrained to 12.500 ns, or 80 MHz. The RTL default `CLK_HZ` is also 80 MHz, so its microsecond-to-tick conversion matches this project configuration. Testbenches override `CLK_HZ` because they generate a 100 MHz clock.

## Resource utilization

From the v0.2 sideband-sequencer verification build:

| Resource | Used | Device total |
|---|---:|---:|
| Logic elements | 196 | 24,624 |
| Combinational functions | 196 | 24,624 |
| Dedicated logic registers | 66 | 24,624 |
| Total registers | 66 | - |
| Pins | 57 | 151 |
| Memory bits | 0 | 608,256 |
| 9-bit multipliers | 0 | 132 |
| PLLs | 0 | 4 |

## Timing

| Corner/check | Result |
|---|---:|
| Slow 1200 mV, 85 C setup slack | +1.617 ns |
| Slow 1200 mV, 85 C hold slack | +0.455 ns |
| Slow 1200 mV, 0 C setup slack | +2.348 ns |
| Fast 1200 mV, 0 C setup slack | +7.859 ns |
| Design-wide TNS | 0.000 ns |

Positive slack supports the checked 80 MHz internal register-to-register paths. Quartus reports that
setup and hold analysis are not fully constrained because interface delays are absent, and the fitter
reports no exact pin assignments. Constant upper bits on `sb_tx_message_o` are expected because this
checkpoint implements only message values `8'h00` through `8'h02`. This is an RTL implementation
check, not board-level timing signoff, ASIC evidence, or a UCIe link-rate claim.

Selected source reports are retained as compact `*.summary` files in `quartus/output_files/`. Generated databases, bitstreams, and bulky reports are ignored.

## Functional netlist evidence

The v0.2 evidence pack retains the Quartus functional Verilog simulation netlist for the integrated LTSM and sideband sequencer:

- [`synthesis/quartus/netlists/v0.2-sideband/ucie_ltsm.vo`](../../synthesis/quartus/netlists/v0.2-sideband/ucie_ltsm.vo)
- [generation metadata and limitations](../../synthesis/quartus/netlists/v0.2-sideband/README.md)

Regenerate it from the repository root:

```powershell
.\scripts\export_quartus_netlist.ps1 -Version v0.2-sideband
```

The exporter runs a full Quartus compile and the 23.1 EDA Netlist Writer in functional Verilog mode. The `.vo` file contains Intel device primitives for the checked Cyclone 10 LP target and is intended for Questa Intel FPGA with matching simulation libraries. It is not editable RTL, an ASIC standard-cell netlist, a programming image, or board-level signoff evidence.

![v0.2 RTL connection diagram](../../assets/diagrams/v0.2-sideband/rtl-connections.svg)
