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
| Retrain resolves to TXSELFCAL, SPEEDIDLE, or REPAIR | Tables 4-10 through 4-12 | Implemented and SPEEDIDLE path tested |
| TRAINERROR handshake/timeout and return to RESET | 4.5.3.8 | Abstract handshake implemented; recovery tested |
| L1 exits to MBTRAIN.SPEEDIDLE; L2 exits to RESET | 4.5.3.9 | Implemented; L1 path covered in UVM, L2 test pending |
| SBINIT completion coordination | 4.5.3.2 | Bounded transaction-level request/response implemented; success, retry, malformed response, exhaustion, and abort tested; physical packet format not implemented |

## UVM verification status

The reusable UVM agent drives abstract LTSM operations and the passive monitor sends observed
top-level state transitions to a scoreboard. The scoreboard rejects transitions outside Figure 4-33.
The UVM regression currently passes eight tests with zero UVM errors/fatals:

- Nominal RESET-to-ACTIVE initialization.
- SBINIT residency timeout through TRAINERROR and RESET.
- ACTIVE-to-PHYRETRAIN, SPEEDIDLE selection, and fatal-error recovery.
- ACTIVE-to-L1/L2 and L1 exit to MBTRAIN.SPEEDIDLE.
- SBINIT completion through an expected sideband response.
- Response timeout followed by one retry and successful completion.
- Unexpected-response error entry through TRAINERROR.
- Retry-budget exhaustion through TRAINERROR.

The `v0.2-random-uvm` verification update additionally runs five repeatable seeds and 200 reset-isolated sideband trials. It explicitly samples all four legal outcome categories and independent one-to-three-cycle transmit/response delays, and requires cumulative predicted request/success/retry/error totals to match the passive monitor exactly. This is constrained-domain randomized evidence, not a functional-coverage closure claim.

The existing SVA module runs alongside UVM. Detailed functional covergroups for all MBINIT and
MBTRAIN substates are a subsequent verification milestone.

## Deliberately abstracted components

The present controller does not claim full protocol compliance. Version 0.2 replaces the normal SBINIT-done abstraction with one internal transaction-level request/response pair. `phase_done_i` remains a compatibility bypass in SBINIT and still represents the unimplemented work in MBINIT, MBTRAIN, and PHYRETRAIN. Remaining components include:

1. Physical sideband detection, repair, framing, CRC, credits, partner-request response, and the broader normative message set.
2. Pattern generation/checking and calibration control for Section 4.5.1.
3. Package-specific repair/degrade algorithms for MBINIT and MBTRAIN.
4. RDI state and stall handshakes from Chapter 10.
5. DVSEC/control/status registers and error logging from Chapter 9.
