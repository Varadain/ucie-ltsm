# Release Evidence Assets

This directory contains small, reviewed artifacts intended for GitHub display. Raw simulator databases, VCD files, and Quartus build databases remain generated and ignored.

## v0.1 waveforms

The SVGs under [`waveforms/v0.1-basic-ltssm`](waveforms/v0.1-basic-ltssm/) are rendered from the VCD produced by the self-checking directed test:

```powershell
& 'C:\intelFPGA_lite\questa_fse\win64\vsim.exe' -c -do scripts/capture_directed_waveform.do
python scripts/render_waveforms.py
```

The renderer itself uses only the Python standard library. Short labels keep all fixed-duration substates legible:

Every signal label in the SVG links to the [waveform signal guide](../docs/02_ltssm/signals.md#waveform-signal-guide), which explains its function and the v0.1 abstraction boundary. The [Questa results page](../docs/06_results/questa.md#signal-and-functionality-pointers) repeats those links in a normal Markdown table for renderers that disable SVG interaction.

| Short label | RTL enum suffix |
|---|---|
| `RCLK`, `RVAL`, `REVMB`, `RMB` | `REPAIRCLK`, `REPAIRVAL`, `REVERSALMB`, `REPAIRMB` |
| `VVREF`, `DVREF`, `SPDIDL` | `VALVREF`, `DATAVREF`, `SPEEDIDLE` |
| `TXCAL`, `RXCAL` | `TXSELFCAL`, `RXCLKCAL` |
| `VTC`, `VTVREF` | `VALTRAINCENTER`, `VALTRAINVREF` |
| `DTC1`, `DTVREF`, `RXDSK`, `DTC2` | `DATATRAINCENTER1`, `DATATRAINVREF`, `RXDESKEW`, `DATATRAINCENTER2` |
| `LSPD` | `LINKSPEED` |

## v0.1 connection diagrams

The SVGs under [`diagrams/v0.1-basic-ltssm`](diagrams/v0.1-basic-ltssm/) are repository-native vector drawings based on:

- the public ports and control partitions in `rtl/ucie_ltsm.sv`;
- the enumerations in `rtl/ucie_ltsm_pkg.sv`; and
- the actual topology in `verification/uvm/ucie_ltsm_uvm_pkg.sv` and `verification/uvm/tb_ucie_ltsm_uvm.sv`.

The diagrams intentionally mark the v0.1 abstraction boundary and do not depict planned blocks as implemented.
