# Journal Paper Plan

## Working title

**Specification-Traceable Design and Assertion-Based Verification of a Portable UCIe 2.0 Link Training State Machine**

## Research question

Can a technology-neutral, hierarchical UCIe 2.0 LTSM controller be designed so that protocol progress, timeout recovery, power-management exits, and runtime retraining are verifiable at RTL and portable from FPGA prototyping to an ASIC flow?

## Proposed contribution

- A synthesizable hierarchical SystemVerilog LTSM matching UCIe 2.0 top-level, MBINIT, and MBTRAIN state structure.
- A requirements-to-assertions traceability method.
- Parameterized timing that preserves protocol values in hardware while allowing simulation acceleration.
- Comparative FPGA and ASIC synthesis results for area, frequency, and power.
- Fault-injection results for timeout, illegal progress, failed handshakes, retraining, and L1/L2 recovery.

## Methodology

1. Derive normative requirements from Sections 4.5, 7.4, 9.5, and 10.1 of the UCIe 2.0 specification.
2. Partition the implementation into LTSM controller, sideband sequencer, training-operation engine, RDI controller, and CSR/error block.
3. Verify directed scenarios in Questa, then add constrained-random event sequences, assertions, functional coverage, and mutation/fault injection.
4. Synthesize the portable RTL in Quartus and report logic/register use and Fmax.
5. Run the same RTL through Cadence Genus, Conformal LEC, and Innovus using an identified standard-cell library and PVT corner; report area, WNS, dynamic/leakage power, and post-layout equivalence.

## Required experiments before submission

| Experiment | Metrics |
|---|---|
| Nominal link initialization | State/substate coverage, cycles to ACTIVE |
| Timeout in every eligible state/substate | Recovery correctness, assertion pass rate |
| Repeated Stall in MBINIT.PARAM | No premature timeout; timeout restarts |
| Fatal error from every non-RESET state | TRAINERROR handshake and recovery |
| Three retrain resolutions | Correct MBTRAIN entry and return to ACTIVE |
| L1 and L2 entry/exit | Correct SPEEDIDLE/RESET path |
| Randomized sideband latency | Functional coverage and liveness bounds |
| FPGA synthesis | ALMs/LEs, registers, Fmax, power estimate |
| ASIC synthesis and P&R | Cell area, WNS/TNS, power, congestion, LEC |

## Paper structure

1. Introduction and motivation
2. UCIe link-training background and related work
3. Requirement extraction and architecture
4. SystemVerilog implementation
5. Assertion-based and scenario-based verification
6. FPGA and ASIC implementation results
7. Limitations and future work
8. Conclusion

## Publication caution

Use “UCIe 2.0 specification-aligned” or “UCIe LTSM controller” rather than “UCIe compliant.” Compliance requires electrical PHY behavior, complete protocol integration, and official compliance testing that are outside the current RTL controller scope.
