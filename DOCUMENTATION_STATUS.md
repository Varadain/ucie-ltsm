# Documentation Status

Last audited: **August 30, 2026**

## Completed

- Repository landing page, navigation, scope, and private-reference policy.
- Canonical project glossary with abbreviation long forms, state/substate expansions, signal conventions, verification terms, synthesis/timing terms, and units.
- UCIe 2.0 reference identity and implementation/compliance boundary.
- Current architecture, state hierarchy, transitions, sideband/training signals, timers, LFSR algorithm, and pseudocode.
- RTL module hierarchy and algorithm-to-SystemVerilog mapping.
- Directed test, UVM topology, assertions, scenario table, and traceability.
- Fresh legacy/sideband/LFSR directed evidence, eight-test deterministic UVM evidence, preserved five-seed sideband evidence, five-seed DATATRAINCENTER1 evidence, and fresh Quartus resource/timing summaries.
- Reviewed Questa-derived waveform figures, RTL/UVM connection diagrams, and a Quartus functional netlist for v0.1.
- Reviewed v0.2 sideband waveform figures, updated RTL/verification connection diagrams, and a Quartus functional netlist.
- v0.1, v0.2, v0.2 randomized-verification, and v0.3 advanced-training milestone pages, roadmap, and changelog.
- Reviewed randomized seed/outcome and verification-flow figures with no text/box overlap or clipping.
- Reviewed v0.3 colorful waveform figures, RTL/verification connection diagrams, and Quartus functional netlist with SHA-256 provenance.

## Incomplete documentation or evidence

| Gap | Current status | Needed evidence |
|---|---|---|
| L2 exit verification | RTL path exists; no dedicated UVM test | Test stimulus, scoreboard observation, and passing log |
| Retrain targets | `SPEEDIDLE` tested; `TXSELFCAL` and `REPAIR` untested in UVM | Two scenarios and expected entry checks |
| MBINIT/MBTRAIN substate coverage | DATATRAINCENTER1 has explicit scenario/error/gap/threshold coverage; other substates are exercised indirectly | Native or explicit coverage across every substate and transition |
| Timeout breadth | SBINIT timeout tested | Tests for every eligible state/substate |
| Stall behavior | RTL implemented | Directed/UVM test proving timeout restart |
| Sideband breadth | Bounded SBINIT-done transaction verified with seeded 1-3 cycle latency and four randomized outcomes | Physical framing/CRC/credits, wider message set, partner responder, bit-level corruption, and coverage closure |
| Remaining training operations | DATATRAINCENTER1 has one digital LFSR engine | Physical pattern transport, calibration/search algorithms, repair, and channel/electrical evidence |
| Cadence flow | No files or reports found | Scripts, constraints, library/corner identity, and real reports |
| Power data | No report found | Tool setup, assumptions, activity source, and result |
| Board-level timing | Internal clock paths are constrained; I/O delays and exact pin assignments are absent | Board interface timing and pin constraints |
| License | Not selected | Repository owner decision and a committed license file |

## Files requiring manual review

- `docs/journal_plan.md` is a research plan, not a record of completed experiments.
- Legacy root-level Quartus project files and generated `db/` content remain on disk but are ignored; remove them only after confirming they are no longer needed.
- Generated simulator logs are intentionally ignored. Re-run the scripts to reproduce them.
- Raw VCDs and Quartus databases are intentionally ignored; reviewed SVG waveforms and the release functional netlist are retained under `assets/` and `synthesis/`.
- `phase_done_i` remains a compatibility bypass for SBINIT and DATATRAINCENTER1 and the abstraction for other training operations; decide when to restrict or remove the bypass.

## Link and claim checks

- Relative documentation links are checked as part of repository validation.
- Specification statements should continue to be reviewed against the private Revision 2.0, Version 1.0 reference.
- The phrases “UCIe compliant” and “complete PHY” are not supported by the current evidence.
