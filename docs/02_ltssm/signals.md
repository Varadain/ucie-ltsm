# Signal Map

All signal names below match [`ucie_ltsm.sv`](../../rtl/ucie_ltsm.sv).

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
| `fatal_error_i` | Requests transition toward TRAINERROR outside RESET | Global error priority |
| `error_handshake_done_i` | Allows a fatal error outside SBINIT to enter TRAINERROR | Global error priority |
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

## Integration warning

Names such as `supplies_stable_i` and `phase_done_i` describe architectural intent, but their producers are not included. A future top-level integration must define synchronization, pulse/level semantics, and clock-domain behavior before connecting external blocks.
