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
- [`rtl/ucie_ltsm.sv`](../../rtl/ucie_ltsm.sv)

## Checked constraint

`clk_i` is constrained to 12.500 ns, or 80 MHz. The RTL default `CLK_HZ` is also 80 MHz, so its microsecond-to-tick conversion matches this project configuration. Testbenches override `CLK_HZ` because they generate a 100 MHz clock.

## Resource utilization

From the latest fitter summary available during the repository audit:

| Resource | Used | Device total |
|---|---:|---:|
| Logic elements | 152 | 24,624 |
| Combinational functions | 152 | 24,624 |
| Dedicated logic registers | 48 | 24,624 |
| Total registers | 48 | - |
| Pins | 35 | 151 |
| Memory bits | 0 | 608,256 |
| 9-bit multipliers | 0 | 132 |
| PLLs | 0 | 4 |

## Timing

| Corner/check | Result |
|---|---:|
| Slow 1200 mV, 85 C setup slack | +1.441 ns |
| Slow 1200 mV, 85 C hold slack | +0.453 ns |
| Slow 1200 mV, 0 C setup slack | +2.175 ns |
| Fast 1200 mV, 0 C setup slack | +7.724 ns |
| Design-wide TNS | 0.000 ns |
| Slow 1200 mV, 85 C Fmax | 90.42 MHz |
| Slow 1200 mV, 0 C Fmax | 96.85 MHz |

Positive slack supports the checked 80 MHz internal clock paths. Quartus reports that setup and hold analysis are not fully constrained because interface delays are absent, and the fitter reports no exact pin assignments. This is therefore an RTL implementation check, not board-level timing signoff. The Fmax values are Quartus estimates for this device and build; they are not ASIC results or a UCIe link-rate claim.

Selected source reports are retained as compact `*.summary` files in `quartus/output_files/`. Generated databases, bitstreams, and bulky reports are ignored.
