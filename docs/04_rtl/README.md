# RTL Implementation

## Module hierarchy

```mermaid
flowchart TD
    PKG[rtl/ucie_ltsm_pkg.sv<br/>state and message types] --> DUT[rtl/ucie_ltsm.sv<br/>hierarchical controller]
    PKG --> WRAP[rtl/ucie_ltsm_fpga_wrapper.sv<br/>compact FPGA CSR boundary]
    WRAP --> DUT
    PKG --> SEQ[rtl/ucie_sb_sequencer.sv<br/>bounded request/response engine]
    DUT --> TRAIN[rtl/ucie_lfsr_training_engine.sv<br/>16-lane LFSR training engine]
    DUT --> ERR[rtl/ucie_error_manager.sv<br/>retained cause/count and handshake]
    DUT --> SEQ
    DUT --> STATE[Top-level state register]
    DUT --> MBI[MBINIT substate register]
    DUT --> MBT[MBTRAIN substate register]
    DUT --> TIMER[Saturating timer]
    DUT --> OUT[Combinational outputs]
```

There are five synthesizable modules and one package. Version 0.2 added the bounded SBINIT transaction sequencer, version 0.3 added one digital LFSR training engine, and version 0.4 adds retained/classified TRAINERROR handling plus a separate compact FPGA CSR wrapper. No physical sideband, RDI controller, standards-defined DVSEC, analog calibration, or analog-PHY module exists.

![v0.4 RTL connection diagram](../../assets/diagrams/v0.4-error-recovery/rtl-connections.svg)

The diagram shows the error-source, pending/handshake, fixed-priority cause, saturating event-count, and TRAINERROR entry paths. Earlier training and sideband diagrams remain available in the [v0.3](../versions/v0.3_advanced_training.md) and [v0.2](../versions/v0.2_sideband.md) milestone pages.

![v0.4 FPGA CSR wrapper connection diagram](../../assets/diagrams/v0.4-error-recovery/fpga-csr-wrapper.svg)

The wrapper diagram separates the unchanged reusable core, internal diagnostic buses, byte CSR decoder, physical interface, and qualified FPGA boundary.

## `ucie_ltsm_pkg.sv`

[`rtl/ucie_ltsm_pkg.sv`](../../rtl/ucie_ltsm_pkg.sv) defines:

- `ltsm_state_e`: nine explicit 4-bit top-level encodings;
- `mbinit_state_e`: six ordered 3-bit labels;
- `mbtrain_state_e`: thirteen ordered 4-bit labels; and
- `retrain_target_e`: the three modeled retrain destinations; and
- `sb_msg_e`: `NOP`, `SBINIT_DONE_REQ`, and `SBINIT_DONE_RESP` transaction labels; and
- `ltsm_error_cause_e`: none, state timeout, sideband protocol, and local fatal retained causes.

The names are the contract shared by RTL and verification.

## `ucie_ltsm.sv`

[`rtl/ucie_ltsm.sv`](../../rtl/ucie_ltsm.sv) contains four main implementation parts.

### 1. Parameter conversion and engine integration

`CLK_HZ`, `RESET_MIN_US`, and `TIMEOUT_US` are converted into tick counts. The checked default `CLK_HZ` is 80 MHz so it matches the Quartus 12.5 ns constraint. The testbenches override it to 100 MHz for their 10 ns clock. `SB_RESPONSE_TIMEOUT_CYCLES` and `SB_MAX_RETRIES` configure the sideband sequencer; `DATATRAIN_SAMPLE_COUNT` configures the LFSR engine and defaults to 4096 accepted samples. The error manager reuses `TIMEOUT_TICKS` as its missing-acknowledgment bound.

### 2. Continuous status logic

Continuous assignments compare current and next state, enable timeout only in selected states, and derive `link_up_o`, `mainband_tristate_o`, and `sideband_enable_o`.

### 3. Sequential state and timer registers

The `always_ff` block performs asynchronous reset, registers next-state decisions, restarts the timer on a state/substate change or stall, and otherwise increments it with saturation.

### 4. Combinational next-state logic

The `always_comb` block starts with hold-current-state defaults. It gives `enter_trainerror` from the error manager global priority, then applies the normal state-specific transition rules.

SBINIT accepts either the compatibility `phase_done_i` path or the sequencer completion pulse. An asserted sideband protocol error is classified by the error manager and drives immediate TRAINERROR entry without a handshake. Leaving SBINIT asserts the sequencer's internal abort input.

In `MBT_DATATRAINCENTER1`, a training completion advances to `MBT_DATATRAINVREF` only when `train_done_o && train_pass_o`. A failed completion remains in the same substate and starts a new attempt after the one-cycle result pulse. `phase_done_i` remains a compatibility bypass and aborts the engine after leaving the substate.

## `ucie_sb_sequencer.sv`

[`rtl/ucie_sb_sequencer.sv`](../../rtl/ucie_sb_sequencer.sv) implements a small registered transaction machine:

- IDLE latches the requested and expected message labels;
- SEND holds transmit valid and the request until ready;
- WAIT matches the response and counts a response timeout;
- a remaining retry returns to SEND and pulses `retry_o`; and
- an unexpected response or exhausted budget pulses `protocol_error_o` and enters the terminal error condition.

`abort_i` clears an outstanding transaction when the parent LTSM is no longer in SBINIT. The module is transaction-level control logic; it does not serialize a physical sideband packet.

<a id="v03-datatraincenter1-training-engine"></a>
## `ucie_lfsr_training_engine.sv`

[`rtl/ucie_lfsr_training_engine.sv`](../../rtl/ucie_lfsr_training_engine.sv) implements the v0.3 digital training operation:

- sixteen 23-bit lane LFSRs initialized from eight seeds repeated modulo eight;
- Fibonacci feedback for `X^23 + X^21 + X^16 + X^8 + X^5 + X^2 + 1`;
- a 16-bit transmit pattern formed from the lane-state most-significant bits;
- state advance only when a receive sample is valid;
- mismatch popcount and a 16-bit saturating error accumulator;
- a configurable accepted-sample count, defaulting to 4096; and
- one-cycle `done_o` with `pass_o` true only for strict `error_count < error_threshold_i`.

This is synthesizable digital pattern/control logic. It does not create analog waveforms, train voltage or phase, estimate BER, or model a physical channel.

<a id="v04-error-manager"></a>
## `ucie_error_manager.sv`

[`rtl/ucie_error_manager.sv`](../../rtl/ucie_error_manager.sv) implements the v0.4 digital recovery operation:

- accepts a new fault only outside RESET/TRAINERROR and only while no earlier event is pending;
- retains one-cycle and held fault levels through a registered pending bit;
- applies fixed cause priority: state timeout, sideband protocol, then local fatal;
- enters TRAINERROR immediately for a state timeout or an SBINIT protocol error;
- otherwise asserts `handshake_request_o` immediately and keeps it asserted until acknowledgment or the bounded manager timeout;
- clears pending state on TRAINERROR entry or RESET;
- increments one saturating 16-bit event counter per accepted event; and
- ignores `clear_log_i` while pending or in TRAINERROR, while allowing a clear in other states.

`cause_o` and `event_count_o` remain ordinary diagnostic state at the reusable core boundary. The optional FPGA wrapper maps them into its compact CSR. The manager timeout is tied to the LTSM timeout parameter; in timeout-enabled states, the already-running state timer can preempt a later-arriving local fault.

<a id="v04-fpga-csr-wrapper"></a>
## `ucie_ltsm_fpga_wrapper.sv`

[`rtl/ucie_ltsm_fpga_wrapper.sv`](../../rtl/ucie_ltsm_fpga_wrapper.sv) instantiates `ucie_ltsm` without modifying its behavior. It passes the functional control, sideband, and training interfaces through, keeps the wide state/error/training diagnostics inside the wrapper, and exposes selected bytes through a combinational CSR decoder:

| Address | Access | Value |
|---:|---|---|
| `0x00` | RO | LTSM state |
| `0x01` | RO | MBINIT substate |
| `0x02` | RO | MBTRAIN substate |
| `0x03` | RO | `{0, sideband_enable, mainband_tristate, link_up, timeout, handshake_timeout, handshake_request, error_pending}` |
| `0x04` | RO | Retained error cause |
| `0x05`-`0x06` | RO | Error event count, low byte then high byte |
| `0x07`-`0x08` | RO | Training error count, low byte then high byte |
| `0x09` | RO | Wrapper version `0x04` |
| `0x10` | WO | Bit 0 requests the core's protected error-log clear |

`csr_ready_o` equals `csr_valid_i`, undefined reads return zero, and writes outside `0x10` are acknowledged without side effects. This intentionally small interface reduces the selected FPGA top from 149 to 119 physical pins with zero virtual pins. It is an FPGA implementation/debug boundary, not a complete UCIe management-register architecture.

## Design choices visible in the source

- Hierarchical substates avoid flattening every MBINIT/MBTRAIN step into the top-level enum.
- `phase_done_i` deliberately separates control sequencing from physical-operation implementation.
- The new ready/valid sequencer replaces that abstraction only for the normal SBINIT-done exchange; the compatibility bypass remains.
- The v0.3 engine replaces the abstraction only for a successful `DATATRAINCENTER1` result; the compatibility bypass remains for integration and abort testing.
- The v0.4 manager separates event acceptance/retention from the LTSM's state-transition logic, so short pulses and simultaneous-cause priority are explicit and testable.
- Retained error history survives ordinary TRAINERROR-to-RESET recovery until an allowed clear or asynchronous reset.
- The FPGA wrapper is separate from `ucie_ltsm`, so pin reduction and CSR visibility do not alter the reusable controller interface or its verification checkpoint.
- Counter saturation avoids wraparound after a long residence.
- Outputs are Moore-style functions of the registered top-level state, except `sideband_enable_o`, which can also reflect sideband clock readiness while in RESET.

## Integration cautions

- External asynchronous inputs would require synchronization in a real clock-domain integration; synchronization is outside this module.
- The completion and request inputs are treated as levels sampled by next-state logic. Their producing blocks must define pulse width and deassertion behavior.
- The two power-management requests share one `LTSM_L1L2` encoding; the still-asserted `pm_l2_req_i` selects the RESET exit.
- The current controller exposes control intent, not a complete UCIe physical interface.
- Sideband inputs must be synchronous to `clk_i` or synchronized externally, and the external channel must define ready/valid stability rules compatible with this interface.
