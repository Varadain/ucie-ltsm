# Project Architecture

## Purpose

`ucie_ltsm` is a control-plane model. It sequences the top-level UCIe 2.0 LTSM states and the ordered MBINIT/MBTRAIN substates, controls a timer, and exposes a small set of status outputs.

It does not send sideband packets or perform calibration itself. Instead, other blocks are represented by explicit inputs such as `phase_done_i`, `rdi_active_i`, and `error_handshake_done_i`.

## Current component boundary

```mermaid
flowchart TB
    subgraph Implemented
        PKG[ucie_ltsm_pkg<br/>state and retrain types]
        FSM[ucie_ltsm<br/>state, substate, timer, outputs]
        PKG --> FSM
    end

    ENV[External controls and abstract engines] -->|completion, error, PM, retrain| FSM
    FSM -->|state and control status| ENV

    subgraph Not_yet_implemented[Not yet implemented]
        SB[Sideband packet engine]
        TRAIN[Calibration / pattern / repair engines]
        RDI[RDI controller]
        CSR[DVSEC / CSR / error logging]
        APHY[Analog PHY controls]
    end

    Not_yet_implemented -. future integration .-> ENV
```

## Control flow

1. RESET remains active until the minimum residence time and every required readiness input are satisfied.
2. SBINIT, MBINIT, and MBTRAIN advance when the abstract operation reports completion.
3. LINKINIT waits for `rdi_active_i` before entering ACTIVE.
4. ACTIVE can request PHY retraining or enter the combined L1/L2 power-management state.
5. Eligible states time out into TRAINERROR; fatal-error handling can also enter TRAINERROR.
6. TRAINERROR returns to RESET when escalation is clear and the sideband transmitter is idle.

## Interface groups

| Group | Signals | Role |
|---|---|---|
| Clock/reset | `clk_i`, `rst_ni` | Sequential timing and asynchronous active-low reset |
| Reset release | `supplies_stable_i`, `sideband_clk_ok_i`, `internal_clks_ok_i`, `firmware_reset_i`, `link_train_trigger_i` | Gate the RESET-to-SBINIT transition after minimum residence |
| Abstract progress | `phase_done_i`, `stall_i`, `rdi_active_i` | Advance a phase, restart its timer, or complete LINKINIT |
| Error control | `fatal_error_i`, `error_handshake_done_i`, `error_escalated_i`, `sideband_tx_idle_i` | Enter and leave TRAINERROR |
| Retrain | `retrain_req_i`, `retrain_target_i` | Select the MBTRAIN re-entry point after PHYRETRAIN |
| Power management | `pm_l1_req_i`, `pm_l2_req_i`, `pm_exit_i` | Enter L1L2 and choose the L1 or L2 exit path |
| State/status | `state_o`, `mbinit_state_o`, `mbtrain_state_o`, `timeout_o`, `link_up_o` | Expose internal progress and link status |
| Physical controls | `mainband_tristate_o`, `sideband_enable_o` | Coarse control outputs derived from the top-level state |

The exact signal behavior is documented in [signals.md](../02_ltssm/signals.md). The synthesizable implementation is in [`rtl/ucie_ltsm.sv`](../../rtl/ucie_ltsm.sv).
