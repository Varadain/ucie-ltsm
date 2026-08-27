# Timers and Counters

## Parameters

| Parameter | Default | Purpose |
|---|---:|---|
| `CLK_HZ` | 80,000,000 | Frequency used to convert microseconds to clock ticks; matches the checked Quartus constraint |
| `RESET_MIN_US` | 4,000 | Minimum RESET residence |
| `TIMEOUT_US` | 8,000 | Timeout for eligible states/substates |

The RTL calculates:

```text
RESET_TICKS_RAW   = CLK_HZ * RESET_MIN_US / 1,000,000
TIMEOUT_TICKS_RAW = CLK_HZ * TIMEOUT_US   / 1,000,000
```

Each value is clamped to at least one tick. `TIMER_W` is sized for the larger count, and the counter saturates instead of wrapping.

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

Both testbench tops instantiate the RTL with `RESET_MIN_US=1` and `TIMEOUT_US=2` so a test finishes quickly. This changes simulation duration, not the default synthesis parameters.

## Known verification gap

The UVM `timeout_test` demonstrates a timeout while residing in SBINIT. It does not prove every eligible top-level state and every MBINIT/MBTRAIN substate. Stall-driven restart is implemented but does not yet have a dedicated passing scenario.
