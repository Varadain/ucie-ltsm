# Release Evidence Assets

This directory contains small, reviewed artifacts intended for GitHub display. Raw simulator databases, VCD files, and Quartus build databases remain generated and ignored.

## Original specification-reference diagrams

The three SVGs under [`diagrams/specification-reference`](diagrams/specification-reference/) are original repository-native drawings informed by the private UCIe 2.0 reference and the checked project RTL:

- [`project-ltsm-scope.svg`](diagrams/specification-reference/project-ltsm-scope.svg) maps the nominal, power-management, retrain, and retained-error paths to this project's implementation depth.
- [`training-scope-map.svg`](diagrams/specification-reference/training-scope-map.svg) shows all ordered MBINIT/MBTRAIN states while distinguishing the integrated DATATRAINCENTER1 path from abstracted physical operations.
- [`integrated-datatrain-order.svg`](diagrams/specification-reference/integrated-datatrain-order.svg) shows the verified START, PATTERN, END, retry, advance, abort, and TRAINERROR ordering.

The [specification figure and section index](../docs/specification_figure_index.md) records the manual figure, section, table, and page locators used for each drawing. No specification page image, copied figure, table, extracted text, or embedded raster content is published.

## v0.4 retained recovery and FPGA CSR evidence

The three SVGs under [`waveforms/v0.4-error-recovery`](waveforms/v0.4-error-recovery/) are rendered from self-checking Questa VCDs:

```powershell
& 'C:\intelFPGA_lite\questa_fse\win64\vsim.exe' -c -do scripts/capture_error_waveform.do
& 'C:\intelFPGA_lite\questa_fse\win64\vsim.exe' -c -do scripts/capture_fpga_wrapper_waveform.do
python scripts/render_error_waveforms.py
```

- [`retained-handshake.svg`](waveforms/v0.4-error-recovery/retained-handshake.svg) shows a one-cycle local-fatal event, persistent pending/request state, ignored pending clear, bounded entry, and retained log.
- [`timeout-and-priority.svg`](waveforms/v0.4-error-recovery/timeout-and-priority.svg) shows held-level de-duplication, manager timeout, immediate SBINIT-protocol entry, and simultaneous-cause priority.
- [`fpga-csr-read-clear.svg`](waveforms/v0.4-error-recovery/fpga-csr-read-clear.svg) shows CSR state/status/cause/count reads, an ignored TRAINERROR clear, a successful RESET clear, and a zero invalid-address read.

Every plotted signal label links to the [v0.4 signal/function guides](../docs/02_ltssm/signals.md#v04-error-recovery-signal-guide). The three diagrams under [`diagrams/v0.4-error-recovery`](diagrams/v0.4-error-recovery/) distinguish the recovery RTL path, independent randomized verification/checking path, and the compact FPGA CSR implementation boundary.

All six v0.4 figures are original repository-native SVGs. They were checked repeatedly at full resolution, reduced GitHub width, and enlarged detail, plus a structural bounds/link/text pass. Boxes, arrows, labels, and text remain separated and unclipped; no raster content or private reference material is embedded.

## v0.3 DATATRAINCENTER1 evidence

The two SVGs under [`waveforms/v0.3-advanced-training`](waveforms/v0.3-advanced-training/) are rendered from the self-checking LFSR engine test's Questa VCD:

```powershell
& 'C:\intelFPGA_lite\questa_fse\win64\vsim.exe' -c -do scripts/capture_datatrain_waveform.do
python scripts/render_datatrain_waveforms.py
```

- [`pattern-progression.svg`](waveforms/v0.3-advanced-training/pattern-progression.svg) shows the generated/received 16-bit patterns, two-cycle receive gaps, eight accepted samples, zero accumulated errors, and the done/pass result.
- [`threshold-and-abort.svg`](waveforms/v0.3-advanced-training/threshold-and-abort.svg) shows a clean pass, strict equality failure, threshold-above-count pass, and abort clearing.

Every colored waveform signal label links to the [v0.3 signal/function guide](../docs/02_ltssm/signals.md#v03-training-signal-guide). The diagrams under [`diagrams/v0.3-advanced-training`](diagrams/v0.3-advanced-training/) show the implemented LTSM/LFSR integration and the verification/reference/SVA/coverage connections. Their scope notes explicitly exclude analog PHY behavior, BER signoff, and a full UCIe compliance claim.

All four figures were rendered and checked at full size, reduced GitHub display size, and enlarged detail views. A structural pass also checked the SVG bounds, links, labels, and absence of embedded raster/private content.

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
