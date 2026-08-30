# Behavioral Algorithm and Pseudocode

## Problem

Link bring-up is a sequence of dependent operations. Later work must not start before earlier work completes, and a controller must recover when an eligible operation never finishes. The LTSM turns those requirements into an ordered control algorithm.

## Basic idea

The design stores three pieces of progress:

- a top-level state;
- an MBINIT substate; and
- an MBTRAIN substate.

One saturating counter measures RESET residence or the time spent in an eligible state/substate. A separate bounded sequencer performs the v0.2 SBINIT-done transaction. Version 0.3 adds a 16-lane, 23-bit LFSR training engine for `DATATRAINCENTER1`; external handshakes still abstract the remaining physical and training work.

## Behavioral flow

```mermaid
flowchart TD
    A[Clock edge] --> B{Reset asserted?}
    B -- yes --> C[Set RESET, PARAM,<br/>VALVREF, timer=0]
    B -- no --> D[Register next state/substates]
    D --> E{State/substate changed<br/>or stall asserted?}
    E -- yes --> F[Restart timer]
    E -- no --> G[Increment timer until saturated]

    H[Combinational decision] --> I{Accepted fatal error?}
    I -- yes --> J[Select TRAINERROR]
    I -- no --> K{Eligible timeout?}
    K -- yes --> J
    K -- no --> L[Apply current-state transition rules]
```

## Beginner-readable pseudocode

```text
on reset:
    top_state      = RESET
    mbinit_state   = PARAM
    mbtrain_state  = VALVREF
    timer          = 0

on each clock:
    save the selected next states

    if the top state changed,
       or an MBINIT/MBTRAIN substate changed,
       or stall is asserted:
        timer = 0
    else if timer is not saturated:
        timer = timer + 1

to choose the next state:
    keep every state unchanged by default

    if fatal_error or sideband_protocol_error is asserted outside RESET:
        if current state is SBINIT,
           or the error handshake completed,
           or timeout is active:
            go to TRAINERROR
    else if an eligible timeout is active:
        go to TRAINERROR
    else:
        case current top state:
            RESET:
                initialize both substates
                if minimum time and every readiness condition are satisfied:
                    go to SBINIT

            SBINIT:
                if the sideband response completed,
                   or the compatibility phase_done input is asserted:
                    go to MBINIT at PARAM

            MBINIT:
                if phase is done and not stalled:
                    advance to the next MBINIT substate
                    after REPAIRMB, go to MBTRAIN at VALVREF

            MBTRAIN:
                if phase is done,
                   or DATATRAINCENTER1 reports done and pass:
                    advance to the next MBTRAIN substate
                    after REPAIR, go to LINKINIT

            LINKINIT:
                if RDI is active:
                    go to ACTIVE

            ACTIVE:
                if retraining is requested:
                    go to PHYRETRAIN
                else if L1 or L2 is requested:
                    go to L1L2

            PHYRETRAIN:
                if phase is done:
                    go to MBTRAIN at the selected retrain target

            TRAINERROR:
                if error is not escalated and sideband transmit is idle:
                    go to RESET

            L1L2:
                if power-management exit is requested:
                    if the L2 request is still asserted:
                        go to RESET
                    else:
                        go to MBTRAIN at SPEEDIDLE

sideband sequencer:
    on start, latch SBINIT_DONE_REQ and expected SBINIT_DONE_RESP
    hold transmit-valid and the request until transmit-ready
    wait for a valid response
    if it matches, pulse done
    if it is wrong, pulse protocol_error
    if response timeout expires and retries remain, pulse retry and resend
    if the retry budget is exhausted, pulse protocol_error
    if abort is asserted, clear the outstanding transaction

DATATRAINCENTER1 LFSR engine:
    on start:
        load 16 lane LFSRs from eight seeds repeated modulo eight
        clear sample count and saturated error count

    while busy:
        drive each transmit-pattern bit from its lane LFSR
        only when receive-valid is asserted:
            compare the received pattern with the expected pattern
            add the mismatch popcount with 16-bit saturation
            advance every 23-bit LFSR once
            count one accepted sample

    on the configured final accepted sample:
        pulse done
        pass only when accumulated error count is strictly below threshold

    on abort or reset:
        clear busy, result, count, and lane state
```

## Mapping to RTL concepts

| Algorithm idea | SystemVerilog mechanism |
|---|---|
| Remember progress | `state_q`, `mbi_q`, and `mbt_q` registers in `always_ff` |
| Select the next step | Defaults plus `unique case` in `always_comb` |
| Measure residence | Saturating `timer_q` register |
| Restart per operation | `state_changed`, `substate_changed`, or `stall_i` |
| Express status | Continuous assignments for `timeout_o`, `link_up_o`, and physical-control outputs |
| Encode legal labels | Enumerated types in `ucie_ltsm_pkg` |
| Sequence SBINIT exchange | `ucie_sb_sequencer` registered SEND/WAIT/error control |
| Bound response waiting | Sequencer timer and retry-count registers |
| Generate per-lane training pattern | Sixteen `lane_lfsr_q` registers and the `lfsr_next` function |
| Count received mismatches | `bit_errors` popcount plus a saturating 16-bit accumulator |
| Decide training result | Strict `accumulated_errors < error_threshold_i` comparison |

The next page explains the source organization: [RTL guide](../04_rtl/README.md).
