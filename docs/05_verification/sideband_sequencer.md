# Bounded SBINIT Sideband Sequencer Verification

## What changed

The v0.2 design checkpoint adds a small transaction sequencer to SBINIT. On entry to SBINIT,
the controller launches `SB_MSG_SBINIT_DONE_REQ`. The sequencer holds `sb_tx_valid_o` and the
request value until `sb_tx_ready_i` accepts it, then waits for
`SB_MSG_SBINIT_DONE_RESP`.

If the response arrives, `sb_done` advances the LTSM to MBINIT. If no response arrives within
`SB_RESPONSE_TIMEOUT_CYCLES`, the sequencer reissues the request up to
`SB_MAX_RETRIES`. A wrong response or exhausted retry budget raises a one-cycle protocol-error
indication; in SBINIT this drives the LTSM to TRAINERROR. Leaving SBINIT asserts the internal abort
and cancels any outstanding transaction.

The existing `phase_done_i` path is retained. It is a backward-compatible test/abstraction path and
can advance SBINIT even if the sideband transaction is incomplete.

## Verification mapping

| Behavior | Evidence |
|---|---|
| Transmit backpressure | Directed assertion checks valid/message stability until ready |
| Expected response | Directed and UVM success scenarios |
| Bounded retry | Directed and `sb_retry_test`; exactly two accepted requests and one retry |
| Wrong response | Directed and `sb_error_test`; protocol error and TRAINERROR observed |
| Retry exhaustion | Directed and `sb_exhaust_test`; one retry then protocol error/TRAINERROR |
| Random timing/outcome combinations | Five seeded `sb_random_test` runs, 200 total transactions |
| Abort | Directed cancellation scenario |
| Legacy compatibility | Existing directed test plus four pre-feature UVM tests |
| Synthesizability/timing | Quartus 23.1 full compile at an 80 MHz constraint |

## Review findings and limits

- The sequencer implements only the SBINIT-done request/response pair, not physical sideband
  detection, repair, framing, CRC, credits, or the full message set.
- `phase_done_i` can bypass the sideband handshake and should eventually be restricted to a debug or
  abstraction configuration.
- Event counters demonstrate that the intended feature scenarios occurred. A merged UCDB report with
  covergroups and code/assertion coverage is still missing, so no coverage percentage is claimed.
- Interface timing is unconstrained in Quartus; the positive 80 MHz slack is not board signoff.

## Randomized campaign

`sb_random_test` resets the DUT between transactions and randomly selects success, retry-success,
wrong-response, or retry-exhaustion. Transmit backpressure and response delay are independently
selected from the explicit legal domain of one through three cycles. The first four iterations force
one occurrence of every outcome; the remaining 36 use the seeded simulator PRNG.

Questa Starter does not license SystemVerilog class `randomize()`, so this campaign uses reproducible
`$urandom_range` selections rather than class constraints. The legal domains are enforced explicitly,
and the UVM sequence predicts accepted requests, successful exits, retries, and errors. The passive
monitor must match all four predicted totals.
