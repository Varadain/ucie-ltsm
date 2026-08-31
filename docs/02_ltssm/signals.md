# Signal Map

The core signal names below match [`ucie_ltsm.sv`](../../rtl/ucie_ltsm.sv). The final section documents the additional compact interface in [`ucie_ltsm_fpga_wrapper.sv`](../../rtl/ucie_ltsm_fpga_wrapper.sv).

## Inputs

| Signal | Meaning in this implementation | Used in |
|---|---|---|
| `clk_i` | Controller clock | All sequential behavior |
| `rst_ni` | Asynchronous active-low reset | Forces RESET and initial substates |
| `supplies_stable_i` | Abstract supply-stability indication | RESET exit |
| `sideband_clk_ok_i` | Abstract sideband-clock readiness | RESET exit and `sideband_enable_o` |
| `internal_clks_ok_i` | Abstract internal-clock readiness | RESET exit |
| `firmware_reset_i` | Holds link training in RESET while asserted | RESET exit |
| `link_train_trigger_i` | Requests training after readiness is met | RESET exit |
| `phase_done_i` | Compatibility completion path for SBINIT and abstract completion of MBINIT, MBTRAIN, or PHYRETRAIN operations | SBINIT, MBINIT, MBTRAIN, PHYRETRAIN |
| `stall_i` | Restarts the timer; also blocks MBINIT substate progress while asserted | Timer and MBINIT |
| `fatal_error_i` | Presents a local-fatal event to the v0.4 error manager outside RESET/TRAINERROR | Error acceptance and handshake |
| `error_handshake_done_i` | Acknowledges a pending non-SBINIT error request | Error handshake |
| `clear_error_log_i` | Requests clearing retained cause/count; ignored while pending or in TRAINERROR | Error log control |
| `error_escalated_i` | Holds TRAINERROR while set | TRAINERROR exit |
| `sideband_tx_idle_i` | Allows TRAINERROR to return to RESET | TRAINERROR exit |
| `rdi_active_i` | Abstract confirmation that link initialization reached active | LINKINIT exit |
| `retrain_req_i` | Requests retraining from ACTIVE | ACTIVE exit |
| `retrain_target_i` | Selects `TXSELFCAL`, `SPEEDIDLE`, or `REPAIR` re-entry | PHYRETRAIN exit |
| `pm_l1_req_i` | Requests entry to combined L1/L2 state | ACTIVE and L1 exit selection |
| `pm_l2_req_i` | Requests L2 behavior | ACTIVE and L2 exit selection |
| `pm_exit_i` | Requests exit from L1L2 | L1L2 exit |
| `sb_tx_ready_i` | Accepts the sequencer's currently presented request | SBINIT sideband SEND state |
| `sb_rx_valid_i` | Marks `sb_rx_message_i` as a received response | SBINIT sideband WAIT state |
| `sb_rx_message_i` | Transaction-level response value checked against `SB_MSG_SBINIT_DONE_RESP` | SBINIT sideband WAIT state |
| `train_rx_valid_i` | Marks `train_rx_pattern_i` as an accepted training sample while the engine is busy | `MBT_DATATRAINCENTER1` |
| `train_rx_pattern_i` | Sixteen received lane bits compared against the generated expected pattern | `MBT_DATATRAINCENTER1` |
| `train_error_threshold_i` | Strict pass threshold; equality fails | End of each training attempt |

## Outputs

| Signal | Implemented behavior |
|---|---|
| `state_o` | Current top-level state register |
| `mbinit_state_o` | Current MBINIT substate register; retains its last value outside MBINIT except when RESET logic reinitializes it |
| `mbtrain_state_o` | Current MBTRAIN substate register; set on RESET, MBINIT completion, retrain, and L1 exit as defined by the RTL |
| `timeout_o` | High when an eligible state/substate reaches the timeout count |
| `link_up_o` | High only in `LTSM_ACTIVE` |
| `mainband_tristate_o` | High in RESET, SBINIT, TRAINERROR, and L1L2 |
| `sideband_enable_o` | High outside RESET; in RESET it follows `sideband_clk_ok_i` |
| `sb_tx_valid_o` | Held high while the sequencer presents a request and waits for `sb_tx_ready_i` |
| `sb_tx_message_o` | Latched request value; v0.2 emits `SB_MSG_SBINIT_DONE_REQ` |
| `sb_busy_o` | High while the sequencer is sending a request or waiting for its response |
| `sb_retry_o` | One-cycle indication that a response timeout caused a bounded retransmission |
| `sb_protocol_error_o` | One-cycle indication for an unexpected response or exhausted retry budget |
| `train_tx_valid_o` | High while the training engine is busy and `train_tx_pattern_o` is active |
| `train_tx_pattern_o` | Sixteen generated lane bits from the current 23-bit LFSR states |
| `train_busy_o` | High from accepted start through the configured final accepted sample |
| `train_done_o` | One-cycle pulse after the configured final accepted sample |
| `train_pass_o` | Result level for the completed attempt; high only when the error count is strictly below threshold |
| `train_error_count_o` | Saturating 16-bit count of received-versus-expected bit mismatches |
| `error_pending_o` | High while one accepted recovery event awaits TRAINERROR entry |
| `trainerror_handshake_request_o` | Immediate and persistent request for a pending non-SBINIT local/sideband fault |
| `error_handshake_timeout_o` | High when a pending error reaches the configured missing-acknowledgment bound |
| `error_cause_o` | Retained v0.4 cause: none, state timeout, sideband protocol, or local fatal |
| `error_event_count_o` | Saturating 16-bit count incremented once per accepted recovery event |

<a id="waveform-signal-guide"></a>
## Waveform signal guide

The release waveform labels link to the anchors below. Colors distinguish traces and registered state intervals; the text labels remain authoritative, so color is never the only indication of meaning.

<a id="wave-state-output"></a>
### LTSM state (`state_o`)

The registered top-level controller state. Each named state has a stable color in both figures: RESET, SBINIT, MBINIT, MBTRAIN, LINKINIT, ACTIVE, PHYRETRAIN, and TRAINERROR.

<a id="wave-mbinit-output"></a>
### MBINIT substate (`mbinit_state_o`)

The current ordered mainband-initialization substate. The waveform shows `PARAM`, `CAL`, clock/valid repair, reversal, and mainband repair only while the top-level state is MBINIT; it is rendered gray outside MBINIT even though the register retains a value.

<a id="wave-mbtrain-output"></a>
### MBTRAIN substate (`mbtrain_state_o`)

The current ordered mainband-training substate, including Vref, calibration, training-center, deskew, link-speed, and repair steps. The waveform renders it gray outside MBTRAIN. Short figure labels are expanded in the [release asset guide](../../assets/README.md).

<a id="wave-phase-done"></a>
### Completion (`phase_done_i`)

Compatibility confirmation for SBINIT and the abstract confirmation for currently modeled MBINIT, MBTRAIN, or PHYRETRAIN operations. Normal v0.2 sideband completion uses the sequencer's matched response instead. In the legacy directed test, back-to-back completion tasks deassert and reassert it in the same timestamp, so it can appear continuously high while the registered substate bands still show each advance.

<a id="wave-rdi-active"></a>
### RDI active confirmation (`rdi_active_i`)

Abstract confirmation used to leave LINKINIT and enter ACTIVE. The full RDI controller remains outside the current scope.

<a id="wave-link-up"></a>
### Link-up status (`link_up_o`)

A Moore-style status output asserted only while the registered top-level state is ACTIVE.

<a id="wave-retrain-request"></a>
### Retrain request (`retrain_req_i`)

Requests ACTIVE to enter PHYRETRAIN. After the modeled retrain operation completes, `retrain_target_i` selects the MBTRAIN re-entry substate; the directed recovery waveform uses SPEEDIDLE.

<a id="wave-fatal-error"></a>
### Fatal error (`fatal_error_i`)

Requests the global error path outside RESET. For states other than SBINIT, the controller waits for the modeled error handshake or timeout before entering TRAINERROR.

<a id="wave-error-handshake"></a>
### Error handshake complete (`error_handshake_done_i`)

Qualifies fatal-error entry into TRAINERROR outside SBINIT. The recovery waveform asserts it with `fatal_error_i`, then shows TRAINERROR returning to RESET when the remaining recovery conditions allow exit.

### v0.2 sideband waveform signals

The sideband release figures come from the standalone sequencer test. `start_i`, `abort_i`, and `done_o` are internal sequencer connections in the integrated LTSM; the remaining names are public `ucie_ltsm` ports.

<a id="wave-sb-start"></a>
#### Sequencer start (`start_i`)

One-cycle launch request. Inside `ucie_ltsm`, SBINIT asserts the equivalent internal start condition when the sequencer is idle and the previous completion pulse is not active.

<a id="wave-sb-abort"></a>
#### Sequencer abort (`abort_i`)

Cancels the current request, clears timer/retry state, and returns the sequencer to idle. The integrated controller asserts it whenever the registered top-level state is not SBINIT.

<a id="wave-sb-tx-valid"></a>
#### Transmit valid (`sb_tx_valid_o`)

Indicates that `sb_tx_message_o` contains a request. It remains asserted, and the message remains stable, until `sb_tx_ready_i` accepts the transfer.

<a id="wave-sb-tx-ready"></a>
#### Transmit ready (`sb_tx_ready_i`)

Acceptance from the external sideband channel model. A clock edge with both valid and ready high completes the outbound transfer and starts the response wait.

<a id="wave-sb-tx-message"></a>
#### Transmit message (`sb_tx_message_o`)

The latched transaction-level request. Version 0.2 integrates only `SB_MSG_SBINIT_DONE_REQ` (`8'h01`).

<a id="wave-sb-rx-valid"></a>
#### Receive valid (`sb_rx_valid_i`)

Indicates that `sb_rx_message_i` is available for comparison during the response-wait state.

<a id="wave-sb-rx-message"></a>
#### Receive message (`sb_rx_message_i`)

The transaction-level response. `SB_MSG_SBINIT_DONE_RESP` (`8'h02`) completes the exchange; any other valid value produces a protocol error.

<a id="wave-sb-busy"></a>
#### Sequencer busy (`sb_busy_o`)

High while the sequencer is holding a request for acceptance or waiting for a response. It is low in idle and after terminal error.

<a id="wave-sb-retry"></a>
#### Retry indication (`sb_retry_o`)

One-cycle pulse when a response timeout expires but the configured retry budget still permits retransmission. The next SEND interval re-presents the latched request.

<a id="wave-sb-done"></a>
#### Completion pulse (`done_o`, internal)

One-cycle sequencer pulse following an accepted expected response. Inside `ucie_ltsm`, it enables the SBINIT-to-MBINIT transition.

<a id="wave-sb-protocol-error"></a>
#### Protocol error (`sb_protocol_error_o`)

One-cycle pulse caused by an unexpected valid response or exhausted retry budget. In SBINIT, the LTSM gives this error the same global priority as a fatal error and selects TRAINERROR.

<a id="v03-training-signal-guide"></a>
### v0.3 DATATRAINCENTER1 waveform signals

The v0.3 release waveforms come from the self-checking LFSR engine test. The integrated public names use the `train_` prefix; `start_i` and `abort_i` are internal engine controls driven by `ucie_ltsm`.

<a id="wave-train-start"></a>
#### Training start (`start_i`, internal)

Starts a new attempt when the registered LTSM state/substate is `MBTRAIN.DATATRAINCENTER1` and the engine is idle. It reloads all lane seeds and clears the counters/result.

<a id="wave-train-abort"></a>
#### Training abort (`abort_i`, internal)

Clears busy, done, pass, lane state, sample count, and error count after reset or any exit from `DATATRAINCENTER1`.

<a id="wave-train-busy"></a>
#### Training busy (`train_busy_o`)

Indicates that an attempt is active. The engine drives a valid expected pattern while busy.

<a id="wave-train-tx-valid"></a>
#### Training transmit valid (`train_tx_valid_o`)

Equals the engine's busy state and qualifies the generated 16-bit transmit pattern.

<a id="wave-train-tx-pattern"></a>
#### Training transmit pattern (`train_tx_pattern_o`)

The current most-significant bit from each of sixteen 23-bit lane LFSRs. The eight defined lane seeds repeat modulo eight across the sixteen lanes.

<a id="wave-train-rx-valid"></a>
#### Training receive valid (`train_rx_valid_i`)

Accepts one received sample. The lane LFSRs, sample count, and error count advance only on a busy cycle with this input asserted; low cycles model legal receive gaps.

<a id="wave-train-rx-pattern"></a>
#### Training receive pattern (`train_rx_pattern_i`)

The behavioral channel's sixteen received lane bits. Verification uses a clean copy or an independently chosen corruption mask.

<a id="wave-train-threshold"></a>
#### Training error threshold (`train_error_threshold_i`)

Configures the strict end-of-attempt comparison. A count equal to the threshold fails; only a smaller count passes.

<a id="wave-train-error-count"></a>
#### Training error count (`train_error_count_o`)

The accumulated popcount of `received XOR expected`, saturated at `16'hffff` instead of wrapping.

<a id="wave-train-done"></a>
#### Training done (`train_done_o`)

One-cycle pulse after the configured final accepted sample. It is never asserted while busy.

<a id="wave-train-pass"></a>
#### Training pass (`train_pass_o`)

Completion result for the latest attempt. In the integrated LTSM, `done && pass` advances to `DATATRAINVREF`; failure remains in `DATATRAINCENTER1` for another attempt.

<a id="v04-error-recovery-signal-guide"></a>
### v0.4 error-recovery waveform signals

The v0.4 release waveforms come from the self-checking focused error-manager test. Names ending in `_o` are the manager outputs used or exposed by `ucie_ltsm`; `state_i` in the focused test corresponds to the integrated registered `state_o`.

<a id="wave-error-local-fatal"></a>
#### Local fatal error (`local_fatal_error_i` / integrated `fatal_error_i`)

An eligible local-fatal level is accepted once while no event is pending. A one-cycle pulse is retained through `pending_o`; a held level is not counted again until the pending event has cleared.

<a id="wave-error-sideband"></a>
#### Sideband protocol error (`sideband_protocol_error_i`)

The sideband sequencer raises this for an unexpected response or retry exhaustion. In SBINIT it causes immediate TRAINERROR entry without asserting the external error handshake request.

<a id="wave-error-state-timeout"></a>
#### State timeout (`state_timeout_i`)

The LTSM timer's timeout indication. It has the highest retained-cause priority and requests immediate TRAINERROR entry.

<a id="wave-error-handshake-done"></a>
#### Error handshake acknowledgment (`handshake_done_i` / integrated `error_handshake_done_i`)

Completes a pending non-SBINIT recovery handshake. If acknowledgment is absent, the manager's bounded timer requests TRAINERROR instead.

<a id="wave-error-clear"></a>
#### Clear retained log (`clear_log_i` / integrated `clear_error_log_i`)

Clears cause/count only when no event is pending and the current state is not TRAINERROR. Pulses during pending or TRAINERROR residency are intentionally ignored.

<a id="wave-error-pending"></a>
#### Pending event (`pending_o` / integrated `error_pending_o`)

Registered evidence that one accepted event awaits TRAINERROR entry. It clears on entry or RESET.

<a id="wave-error-handshake-request"></a>
#### TRAINERROR handshake request (`handshake_request_o` / integrated `trainerror_handshake_request_o`)

Asserts combinationally with an eligible local/sideband fault outside SBINIT and remains asserted while that event is pending.

<a id="wave-error-handshake-timeout"></a>
#### Error handshake timeout (`handshake_timeout_o`)

Marks the exact configured manager-timer boundary for a missing acknowledgment. It participates directly in the TRAINERROR entry decision.

<a id="wave-error-enter-trainerror"></a>
#### TRAINERROR entry request (`enter_trainerror_o`, internal)

Global next-state request produced for an immediate cause/state, a completed handshake, or the manager timeout.

<a id="wave-error-state"></a>
#### Error-manager state context (`state_i`)

The registered LTSM state supplied to the manager. It determines eligibility, SBINIT immediate behavior, TRAINERROR log protection, and RESET pending clear.

<a id="wave-error-cause"></a>
#### Retained error cause (`cause_o` / integrated `error_cause_o`)

Captures exactly one accepted event using state-timeout over sideband-protocol over local-fatal priority and remains stable during TRAINERROR.

<a id="wave-error-count"></a>
#### Retained event count (`event_count_o` / integrated `error_event_count_o`)

Increments once per accepted event, ignores a held/repeated level while pending, and saturates at `16'hffff`.

<a id="v04-fpga-csr-signal-guide"></a>
### v0.4 FPGA CSR waveform signals

The wrapper waveform comes from `tb_ucie_ltsm_fpga_wrapper`. It shows both external CSR transactions and selected internal core state so the protected-clear behavior is directly visible. The wrapper's full [CSR map](../06_results/fpga_csr_wrapper.md#csr-map) is normative for this project.

<a id="wave-csr-fatal"></a>
#### Wrapper fatal input (`fatal_error_i`)

The one-cycle external event presented to the unchanged core. It becomes an accepted local-fatal event and is retained after the pulse ends.

<a id="wave-csr-request"></a>
#### Internal handshake request (`handshake_request`)

The wrapper-internal instance connection corresponding to the core's `trainerror_handshake_request_o`. It proves the compact boundary does not change the immediate/persistent request behavior.

<a id="wave-csr-pending"></a>
#### Internal pending event (`error_pending`)

The core's registered pending status before TRAINERROR entry. It is also readable as CSR status bit 0.

<a id="wave-csr-ack"></a>
#### Wrapper handshake acknowledgment (`error_handshake_done_i`)

Acknowledges the pending fatal event so the controller enters TRAINERROR. A missing acknowledgment instead uses the error manager's bound.

<a id="wave-csr-state"></a>
#### Internal LTSM state (`state`)

The wide core diagnostic is kept inside the wrapper and returned in CSR `0x00`. The plotted interval shows ACTIVE, TRAINERROR, and RESET.

<a id="wave-csr-cause"></a>
#### Internal retained cause (`error_cause`)

The retained three-bit cause exposed at CSR `0x04`; the waveform shows `LOCAL FATAL` surviving TRAINERROR and its attempted clear.

<a id="wave-csr-count"></a>
#### Internal retained event count (`error_event_count`)

The 16-bit saturating count exposed as low/high bytes at CSR `0x05`/`0x06`.

<a id="wave-csr-valid"></a>
#### CSR valid (`csr_valid_i`)

Qualifies one read or write request. The wrapper is a single-cycle combinational interface with no queued transactions.

<a id="wave-csr-write"></a>
#### CSR write (`csr_write_i`)

Low selects a read; high selects a write. Only `0x10` with write data bit 0 set has a side effect.

<a id="wave-csr-address"></a>
#### CSR address (`csr_addr_i[4:0]`)

Selects the byte register. Defined status addresses are `0x00`-`0x09`, control is `0x10`, and undefined reads such as `0x1f` return zero.

<a id="wave-csr-read-data"></a>
#### CSR read data (`csr_rdata_o[7:0]`)

Combinational read response while valid and not writing. The waveform includes state/status/cause/count values and zero for an invalid address.

<a id="wave-csr-ready"></a>
#### CSR ready (`csr_ready_o`)

Equals `csr_valid_i`, acknowledging the request in the same cycle. There is no wait-state or backpressure mechanism in this compact interface.

<a id="wave-csr-clear"></a>
#### Internal CSR clear request (`clear_error_log`)

High only for a valid write to `0x10` with `csr_wdata_i[0]` set. The core ignores this pulse in TRAINERROR and accepts it after recovery reaches RESET, as shown by the retained cause/count.

## Integration warning

Names such as `supplies_stable_i` and `phase_done_i` describe architectural intent, but their producers are not included. A future top-level integration must define synchronization, pulse/level semantics, and clock-domain behavior before connecting external blocks.

See the [project glossary](../glossary.md) for abbreviation long forms and related verification/synthesis terminology.
