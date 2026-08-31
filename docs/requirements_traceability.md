# UCIe 2.0 LTSM Requirements Traceability

Source: *UCIe Specification Revision 2.0, Version 1.0*, August 6, 2024.

| Requirement | Spec location | RTL/verification status |
|---|---|---|
| Nine top-level LTSM states | Table 4-6, Figure 4-33 | Implemented in `ucie_ltsm_pkg.sv`; nominal path tested |
| RESET residence at least 4 ms | 4.5.3.1 | Parameterized counter; reduced to 1 us in simulation |
| Exit RESET only after stability, clocks, firmware release and trigger | 4.5.3.1 | Implemented as explicit inputs |
| 8 ms timeout per state/substate except RESET, ACTIVE, L1/L2, TRAINERROR | 4.5 introduction | Parameterized counter and assertion |
| Stall message resets timeout | 4.5 introduction, 4.5.3.3.1.2 | Implemented through `stall_i` |
| MBINIT order: PARAM through REPAIRMB | Figure 4-34 | Implemented and nominally tested |
| MBTRAIN has thirteen ordered substates | 4.5.3.4.1-4.5.3.4.13 | Implemented and nominally tested |
| LINKINIT waits for RDI Active | 4.5.3.5 and 10.1.6 | Implemented through `rdi_active_i` |
| Retrain resolves to TXSELFCAL, SPEEDIDLE, or REPAIR | Tables 4-10 through 4-12 | Implemented; all three targets checked by `recovery_closure_test` |
| TRAINERROR handshake/timeout, retained cause/count, and return to RESET | 4.5.3.8 | Immediate/acknowledged/bounded entry, fixed cause priority, protected log, residency, and release checked in directed and five-seed recovery tests |
| L1 exits to MBTRAIN.SPEEDIDLE; L2 exits to RESET | 4.5.3.9 | Implemented; L1 path covered in `pm_test`, L2 path in `recovery_closure_test` |
| SBINIT completion coordination | 4.5.3.2 | Bounded transaction-level request/response implemented; success, retry, malformed response, exhaustion, and abort tested; physical packet format not implemented |
| DATATRAINCENTER1 digital training pattern control | 4.5.1 and 4.5.3.4.8 | Sixteen 23-bit lane LFSRs, eight seeds repeated modulo eight, accepted-sample progression, saturating error count, and strict threshold result implemented; independently checked in directed and five-seed UVM tests |
| Compact FPGA observability boundary | Project implementation requirement; not a UCIe compliance item | `ucie_ltsm_fpga_wrapper` maps selected diagnostics to byte CSR `0x00`-`0x10`; directed read/clear test and 119-pin Quartus fit pass |

## UVM verification status

The reusable UVM agent drives abstract LTSM operations and the passive monitor sends observed
top-level state transitions to a scoreboard. The scoreboard rejects transitions outside Figure 4-33.
The deterministic UVM regression currently passes nine tests with zero UVM errors/fatals:

- Nominal RESET-to-ACTIVE initialization.
- SBINIT residency timeout through TRAINERROR and RESET.
- ACTIVE-to-PHYRETRAIN, SPEEDIDLE selection, and fatal-error recovery.
- ACTIVE-to-L1/L2 and L1 exit to MBTRAIN.SPEEDIDLE.
- SBINIT completion through an expected sideband response.
- Response timeout followed by one retry and successful completion.
- Unexpected-response error entry through TRAINERROR.
- Retry-budget exhaustion through TRAINERROR.
- L2 exit and all three retrain-target selections.

The `v0.2-random-uvm` verification update additionally runs five repeatable seeds and 200 reset-isolated sideband trials. It explicitly samples all four legal outcome categories and independent one-to-three-cycle transmit/response delays, and requires cumulative predicted request/success/retry/error totals to match the passive monitor exactly. This is constrained-domain randomized evidence, not a functional-coverage closure claim.

Version 0.3 additionally runs five repeatable DATATRAINCENTER1 seeds and 160 reset-isolated trials. The reference model independently checks all sixteen pattern bits for every accepted sample, lane-seed initialization, every polynomial step, corruption masks, exact/saturated error counts, strict threshold behavior, pass/retry/abort/timeout outcomes, and the successful `DATATRAINVREF` transition. Explicit coverage reports hit every required outcome, error, gap, threshold, and scenario-by-gap bin/cross. The installed Starter license cannot produce native covergroup/UCDB percentages, so no such percentage is claimed.

Version 0.4 adds five repeatable recovery seeds and 180 reset-isolated trials across six scenarios and seven originating-state categories. An independent predictor checks accepted-event cause/count, entry timing, TRAINERROR residency, protected clearing, and release. Required scenario/origin/pulse/ack bins and legal crosses are hit. A focused directed test proves exact manager bounds, held-level de-duplication, simultaneous-cause priority, and 16-bit saturation; the wrapper test proves the CSR visibility and clear policy.

The existing SVA module runs alongside UVM and includes DATATRAINCENTER1 busy/done/threshold/no-sample invariants plus v0.4 immediate/persistent error request, timeout entry, pending clear, and TRAINERROR log-stability properties. Native functional covergroups for all MBINIT/MBTRAIN substates remain a subsequent verification milestone.

## Deliberately abstracted components

The present controller does not claim full protocol compliance. Version 0.2 replaces the normal SBINIT-done abstraction with one internal transaction-level request/response pair. Version 0.3 implements one digital pattern/result operation for `DATATRAINCENTER1`. Version 0.4 adds retained digital recovery state and a compact project-specific FPGA CSR; it is not a standards-defined management architecture. `phase_done_i` remains a compatibility bypass and still represents the unimplemented work in the other MBINIT, MBTRAIN, and PHYRETRAIN operations. Remaining components include:

1. Physical sideband detection, repair, framing, CRC, credits, partner-request response, and the broader normative message set.
2. Physical pattern transport, analog calibration, Vref/phase search, equalization, channel effects, BER qualification, and the remaining Section 4.5.1 operations.
3. Package-specific repair/degrade algorithms for MBINIT and MBTRAIN.
4. RDI state and stall handshakes from Chapter 10.
5. Standards-defined DVSEC/control/status architecture, management transport, interrupts, and software servicing from Chapter 9.
