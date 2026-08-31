# Documentation Status

Last audited: **August 31, 2026**

## Completed

- Repository landing page, navigation, scope, and private-reference policy.
- Canonical project glossary with abbreviation long forms, state/substate expansions, signal conventions, verification terms, synthesis/timing terms, and units.
- UCIe 2.0 reference identity and implementation/compliance boundary.
- Original system/package, layer-boundary, module-configuration, LTSM, training-scope, and integrated-message-order diagrams with a figure/section/table/page locator index; no copied specification artwork.
- Current architecture, state hierarchy, transitions, sideband/training/error/CSR signals, timers, LFSR/recovery algorithms, and pseudocode.
- RTL module hierarchy and algorithm-to-SystemVerilog mapping.
- Directed test, UVM topology, assertions, scenario table, and traceability.
- Fresh controller/sideband/LFSR/error/CSR-wrapper directed evidence, nine-test deterministic UVM evidence, five-seed sideband/training/recovery evidence, and qualified wrapper Quartus resource/timing summaries.
- Reviewed Questa-derived waveform figures, RTL/UVM connection diagrams, and a Quartus functional netlist for v0.1.
- Reviewed v0.2 sideband waveform figures, updated RTL/verification connection diagrams, and a Quartus functional netlist.
- v0.1, v0.2, v0.2 randomized-verification, v0.3 advanced-training, and v0.4 recovery/wrapper milestone pages, roadmap, and changelog.
- Reviewed randomized seed/outcome and verification-flow figures with no text/box overlap or clipping.
- Reviewed v0.3 colorful waveform figures, RTL/verification connection diagrams, and Quartus functional netlist with SHA-256 provenance.
- Reviewed v0.4 colorful recovery/CSR waveform figures, recovery RTL/verification and FPGA-wrapper diagrams, and two claim-qualified functional netlists with SHA-256 provenance.
- L2 exit and all three retrain targets closed by `recovery_closure_test`.
- Compact FPGA CSR map, status-bit layout, implementation scope, warnings, and 119-pin/zero-virtual-pin fit documented.

## Incomplete documentation or evidence

| Gap | Current status | Needed evidence |
|---|---|---|
| MBINIT/MBTRAIN substate coverage | DATATRAINCENTER1 has explicit scenario/error/gap/threshold coverage; other substates are exercised indirectly | Native or explicit coverage across every substate and transition |
| Timeout breadth | SBINIT deterministic timeout and randomized recovery origins tested; not every individual substate boundary is isolated | Tests for every eligible top-level state/substate boundary |
| Stall behavior | RTL implemented | Directed/UVM test proving timeout restart |
| Sideband breadth | Bounded SBINIT-done transaction verified with seeded 1-3 cycle latency and four randomized outcomes | Physical framing/CRC/credits, wider message set, partner responder, bit-level corruption, and coverage closure |
| Remaining training operations | DATATRAINCENTER1 has one digital LFSR engine | Physical pattern transport, calibration/search algorithms, repair, and channel/electrical evidence |
| Cadence flow | No files or reports found | Scripts, constraints, library/corner identity, and real reports |
| Power data | No report found | Tool setup, assumptions, activity source, and result |
| Board-level timing | The 119-pin wrapper fits with positive internal 80 MHz timing; I/O delays and exact pin assignments are absent | Board interface timing and pin constraints |
| License | Not selected | Repository owner decision and a committed license file |

## Files requiring manual review

- `docs/journal_plan.md` is a research plan, not a record of completed experiments.
- Legacy root-level Quartus project files and generated `db/` content remain on disk but are ignored; remove them only after confirming they are no longer needed.
- Generated simulator logs are intentionally ignored. Re-run the scripts to reproduce them.
- Raw VCDs and Quartus databases are intentionally ignored; reviewed SVG waveforms and release functional netlists are retained under `assets/` and `synthesis/`.
- `phase_done_i` remains a compatibility bypass for SBINIT and DATATRAINCENTER1 and the abstraction for other training operations; decide when to restrict or remove the bypass.

## Link and claim checks

- Relative documentation links are checked as part of repository validation.
- Specification statements should continue to be reviewed against the private Revision 2.0, Version 1.0 reference.
- The phrases “UCIe compliant” and “complete PHY” are not supported by the current evidence.
