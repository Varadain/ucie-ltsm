# Questa Results

Freshly rerun on **August 28, 2026** using Questa Intel Starter FPGA Edition 2023.3.

## Directed test

Command:

```powershell
& 'C:\intelFPGA_lite\questa_fse\win64\vsim.exe' -c -do scripts/run_questa.do
```

Observed result:

- SystemVerilog compilation: 0 errors, 0 warnings.
- Simulation: `PASS: nominal training, retrain, and error recovery`.
- Simulator summary: 0 errors; one `-assertdebug` accessibility warning.
- No assertion failure was reported.

## Directed waveform evidence

The release figures are generated from a VCD captured during the same self-checking directed scenario:

```powershell
& 'C:\intelFPGA_lite\questa_fse\win64\vsim.exe' -c -do scripts/capture_directed_waveform.do
python scripts/render_waveforms.py
```

![Nominal v0.1 link training waveform](../../assets/waveforms/v0.1-basic-ltssm/nominal-training.svg)

The nominal figure shows RESET residency followed by SBINIT, all six MBINIT substates, all thirteen MBTRAIN substates, LINKINIT, and ACTIVE. Because the directed test deasserts and reasserts `phase_done_i` in the same simulation timestamp between back-to-back operations, the VCD renders it as one continuous high interval across each ordered substate run; the enum buses retain every registered substate boundary.

![v0.1 retrain and fatal-error recovery waveform](../../assets/waveforms/v0.1-basic-ltssm/retrain-error-recovery.svg)

The second figure retains the final MBTRAIN context, then shows LINKINIT/ACTIVE, an ACTIVE-to-PHYRETRAIN request, `MBTRAIN.SPEEDIDLE` re-entry, fatal-error handshake, TRAINERROR, and RESET. Short substate labels are expanded in the [asset README](../../assets/README.md).

### Signal and functionality pointers

Signal names inside the SVG figures are clickable. This table provides the same links when a Markdown renderer displays SVGs as non-interactive images.

| Waveform label | Function in v0.1 | Detailed explanation |
|---|---|---|
| `LTSM state` | Registered top-level controller state | [`state_o`](../02_ltssm/signals.md#wave-state-output) |
| `MBINIT substate` | Ordered mainband-initialization step, shown only during MBINIT | [`mbinit_state_o`](../02_ltssm/signals.md#wave-mbinit-output) |
| `MBTRAIN substate` | Ordered mainband-training step, shown only during MBTRAIN | [`mbtrain_state_o`](../02_ltssm/signals.md#wave-mbtrain-output) |
| `phase_done_i` | Abstract completion of the active modeled operation | [Completion behavior](../02_ltssm/signals.md#wave-phase-done) |
| `rdi_active_i` | LINKINIT-to-ACTIVE confirmation | [RDI active confirmation](../02_ltssm/signals.md#wave-rdi-active) |
| `link_up_o` | High only while the controller is ACTIVE | [Link-up status](../02_ltssm/signals.md#wave-link-up) |
| `retrain_req_i` | Requests ACTIVE-to-PHYRETRAIN entry | [Retrain request](../02_ltssm/signals.md#wave-retrain-request) |
| `fatal_error_i` | Requests the global fatal-error path | [Fatal error](../02_ltssm/signals.md#wave-fatal-error) |
| `error_handshake_done_i` | Qualifies entry into TRAINERROR outside SBINIT | [Error handshake](../02_ltssm/signals.md#wave-error-handshake) |

The intermediate VCD under `build/waves/` is ignored. The capture script, standard-library renderer, and reviewed SVG outputs are versioned so the figures remain reproducible without committing a bulky waveform database.

## UVM regression

Command:

```powershell
.\scripts\run_uvm_regression.ps1
```

| Test | Top-level transitions | Illegal transitions | Observed flags | UVM errors / fatals |
|---|---:|---:|---|---|
| `nominal_test` | 5 | 0 | active=1 | 0 / 0 |
| `timeout_test` | 3 | 0 | trainerror=1 | 0 / 0 |
| `recovery_test` | 9 | 0 | active=1, retrain=1, trainerror=1 | 0 / 0 |
| `pm_test` | 7 | 0 | active=1, pm=1 | 0 / 0 |
| `sb_success_test` | 2 | 0 | accepted requests=1, successful SBINIT exits=1 | 0 / 0 |
| `sb_retry_test` | 2 | 0 | accepted requests=2, retries=1, successful SBINIT exits=1 | 0 / 0 |
| `sb_error_test` | 3 | 0 | accepted requests=1, protocol errors=1, trainerror=1 | 0 / 0 |
| `sb_exhaust_test` | 3 | 0 | accepted requests=2, retries=1, protocol errors=1, trainerror=1 | 0 / 0 |

The regression script completed with `PASS: all 8 UVM tests`. Each test ran in a fresh simulator invocation.

## Sideband sequencer directed test

Command:

```powershell
& 'C:\intelFPGA_lite\questa_fse\win64\vsim.exe' -c -do scripts/run_sb_directed.do
```

Observed result: `PASS: sideband backpressure, success, retry, exhaustion, mismatch, and abort`.
The test also runs assertions that the request remains stable under transmit backpressure,
a retry reissues transmit-valid, and completion follows the expected response.

### Sideband waveform evidence

The reviewed v0.2 figures are generated from the same standalone directed test:

```powershell
& 'C:\intelFPGA_lite\questa_fse\win64\vsim.exe' -c -do scripts/capture_sideband_waveform.do
python scripts/render_sideband_waveforms.py
```

![v0.2 sideband success and bounded retry](../../assets/waveforms/v0.2-sideband/success-bounded-retry.svg)

The first figure proves that transmit valid and the request remain presented while ready is low, then separates request acceptance from the expected response. Its second transaction shows one response timeout, one retry pulse, a retransmitted request, and successful completion.

![v0.2 sideband exhaustion, mismatch, and abort](../../assets/waveforms/v0.2-sideband/exhaustion-mismatch-abort.svg)

The second figure shows the terminal paths: retry-budget exhaustion, rejection of an unexpected `NOP` response, and abort cancellation of an outstanding request without a completion or protocol-error pulse.

<a id="v02-sideband-signal-pointers"></a>
### v0.2 sideband signal pointers

Signal labels inside the SVGs are clickable. These normal Markdown links provide the same explanation when SVG interaction is disabled.

| Waveform label | Function | Detailed explanation |
|---|---|---|
| `start_i` | Launches one sequencer transaction | [Sequencer start](../02_ltssm/signals.md#wave-sb-start) |
| `abort_i` | Cancels an outstanding transaction | [Sequencer abort](../02_ltssm/signals.md#wave-sb-abort) |
| `sb_tx_valid_o` | Presents a stable outbound request | [Transmit valid](../02_ltssm/signals.md#wave-sb-tx-valid) |
| `sb_tx_ready_i` | Accepts the outbound request | [Transmit ready](../02_ltssm/signals.md#wave-sb-tx-ready) |
| `sb_tx_message_o` | Carries `SBINIT_DONE_REQ` | [Transmit message](../02_ltssm/signals.md#wave-sb-tx-message) |
| `sb_rx_valid_i` | Marks a received response as valid | [Receive valid](../02_ltssm/signals.md#wave-sb-rx-valid) |
| `sb_rx_message_i` | Carries the expected or malformed response | [Receive message](../02_ltssm/signals.md#wave-sb-rx-message) |
| `sb_busy_o` | Covers SEND and WAIT residence | [Busy status](../02_ltssm/signals.md#wave-sb-busy) |
| `sb_retry_o` | Marks a bounded retransmission | [Retry indication](../02_ltssm/signals.md#wave-sb-retry) |
| `completion pulse` | Reports the expected response | [Internal completion](../02_ltssm/signals.md#wave-sb-done) |
| `sb_protocol_error_o` | Reports wrong response or exhausted retries | [Protocol error](../02_ltssm/signals.md#wave-sb-protocol-error) |

## Interpretation

These runs support the named controller scenarios. Feature-event counters provide scenario evidence,
but are not a merged UCDB functional-coverage closure report. The runs do not provide electrical
compliance, random-stimulus closure, or proof of all UCIe 2.0 requirements.
