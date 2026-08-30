# Release Evidence Assets

This directory contains small, reviewed artifacts intended for GitHub display. Raw simulator databases, VCD files, and Quartus build databases remain generated and ignored.

## v0.2 randomized UVM evidence

The SVGs under [`diagrams/v0.2-random-uvm`](diagrams/v0.2-random-uvm/) document the verification-only `v0.2-random-uvm` update:

- [`random-regression-summary.svg`](diagrams/v0.2-random-uvm/random-regression-summary.svg) shows all five seed distributions, aggregate predictor-checked event totals, and zero-error verdicts.
- [`random-verification-flow.svg`](diagrams/v0.2-random-uvm/random-verification-flow.svg) shows the seed/domain controls, reset-aware UVM drive path, unchanged v0.2 DUT, passive monitor, assertions, predictor, and end-of-test comparator.

Both figures link to the [randomized campaign explanation](../docs/05_verification/sideband_sequencer.md#randomized-campaign) and [measured Questa results](../docs/06_results/questa.md#seeded-randomized-regression). The existing v0.2 waveform, RTL connection, Quartus, and netlist artifacts remain applicable because this update changes verification code only.

## v0.2 sideband waveforms

The SVGs under [`waveforms/v0.2-sideband`](waveforms/v0.2-sideband/) are rendered from the standalone sequencer test's Questa VCD:

```powershell
& 'C:\intelFPGA_lite\questa_fse\win64\vsim.exe' -c -do scripts/capture_sideband_waveform.do
python scripts/render_sideband_waveforms.py
```

- [`success-bounded-retry.svg`](waveforms/v0.2-sideband/success-bounded-retry.svg) shows request stability under backpressure, expected-response completion, a response timeout, one retry, and successful completion.
- [`exhaustion-mismatch-abort.svg`](waveforms/v0.2-sideband/exhaustion-mismatch-abort.svg) shows retry-budget exhaustion, wrong-response rejection, and cancellation of an outstanding request.

The waveform bus labels `DONE_REQ` and `DONE_RESP` abbreviate the RTL enum labels `SB_MSG_SBINIT_DONE_REQ` and `SB_MSG_SBINIT_DONE_RESP` so short response windows remain legible.

Every underlined signal name links to the [canonical signal/function guide](../docs/02_ltssm/signals.md#waveform-signal-guide). The [Questa page](../docs/06_results/questa.md#v02-sideband-signal-pointers) provides normal Markdown fallback links.

## v0.2 connection diagrams

The SVGs under [`diagrams/v0.2-sideband`](diagrams/v0.2-sideband/) describe only implemented connections:

- the `ucie_ltsm`/`ucie_sb_sequencer` control and ready/valid integration; and
- the eight-test UVM environment, sideband event monitoring, scoreboard, SVA, and standalone sequencer test.

Their scope boxes explicitly exclude physical sideband framing, CRC, credits, repair, and the broader UCIe message set.

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
