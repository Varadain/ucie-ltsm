# Timers and Counters

## Parameters

| Parameter | Default | Purpose |
|---|---:|---|
| `CLK_HZ` | 80,000,000 | Frequency used to convert microseconds to clock ticks; matches the checked Quartus constraint |
| `RESET_MIN_US` | 4,000 | Minimum RESET residence |
| `TIMEOUT_US` | 8,000 | Timeout for eligible states/substates |
| `DATATRAIN_SAMPLE_COUNT` | 4,096 | Number of accepted receive samples in one DATATRAINCENTER1 LFSR attempt |

The RTL calculates:

```text
RESET_TICKS_RAW   = CLK_HZ * RESET_MIN_US / 1,000,000
TIMEOUT_TICKS_RAW = CLK_HZ * TIMEOUT_US   / 1,000,000
```

Each value is clamped to at least one tick. `TIMER_W` is sized for the larger count, and the counter saturates instead of wrapping.

The separate LFSR engine sample counter is sized from `DATATRAIN_SAMPLE_COUNT` and advances only when the engine is busy and `train_rx_valid_i` accepts a sample. Its 16-bit error counter adds the per-sample mismatch popcount and saturates at `16'hffff`.

The v0.4 error manager has a separate pending-handshake timer bounded by `TIMEOUT_TICKS`. It begins with an accepted non-immediate event and causes TRAINERROR entry if acknowledgment does not arrive. Its retained 16-bit event counter increments once per accepted event and saturates at `16'hffff`; the FPGA wrapper exposes that counter as low/high bytes at `0x05`/`0x06`.

## Counter restart rules

`timer_q` becomes zero when:

- the top-level next state differs from the current state;
- either substate next value differs from its current value; or
- `stall_i` is high.

Otherwise it increments until all bits are one.

## Timeout eligibility

Timeout is disabled in:

- `LTSM_RESET` - RESET uses the minimum-residence comparison instead;
- `LTSM_ACTIVE`;
- `LTSM_L1L2`; and
- `LTSM_TRAINERROR`.

It is enabled in SBINIT, MBINIT, MBTRAIN, LINKINIT, and PHYRETRAIN. When `timeout_o` becomes true, next-state logic selects TRAINERROR.

## Simulation parameters

The controller, UVM, and wrapper testbench tops instantiate the RTL with reduced RESET/timeout parameters so tests finish quickly. The UVM integration also sets `DATATRAIN_SAMPLE_COUNT=8` to exercise many attempts; the focused directed engine test retains the 4096 default and proves completion/saturation. These overrides change simulation duration, not the default synthesis parameters.

## Known verification gap

The deterministic `timeout_test` demonstrates SBINIT timeout, and the recovery campaign distributes state-timeout events across all seven eligible origin categories. It does not individually close every MBINIT/MBTRAIN substate timeout boundary. Stall-driven restart is implemented but does not yet have a dedicated passing scenario.
