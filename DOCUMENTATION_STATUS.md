# Documentation Status

Last audited: **August 27, 2026**

## Completed

- Repository landing page, navigation, scope, and private-reference policy.
- UCIe 2.0 reference identity and implementation/compliance boundary.
- Current architecture, state hierarchy, transitions, signal groups, timers, and pseudocode.
- RTL module hierarchy and algorithm-to-SystemVerilog mapping.
- Directed test, UVM topology, assertions, scenario table, and traceability.
- Fresh Questa evidence and existing Quartus resource/timing summaries.
- v0.1 milestone page, roadmap, and changelog.

## Incomplete documentation or evidence

| Gap | Current status | Needed evidence |
|---|---|---|
| L2 exit verification | RTL path exists; no dedicated UVM test | Test stimulus, scoreboard observation, and passing log |
| Retrain targets | `SPEEDIDLE` tested; `TXSELFCAL` and `REPAIR` untested in UVM | Two scenarios and expected entry checks |
| MBINIT/MBTRAIN substate coverage | Ordered progression exercised indirectly | Functional covergroups and coverage report |
| Timeout breadth | SBINIT timeout tested | Tests for every eligible state/substate |
| Stall behavior | RTL implemented | Directed/UVM test proving timeout restart |
| Sideband functionality | Abstract `phase_done_i` only | RTL sequencer, protocol-specific tests, and updated architecture |
| Cadence flow | No files or reports found | Scripts, constraints, library/corner identity, and real reports |
| Power data | No report found | Tool setup, assumptions, activity source, and result |
| Board-level timing | Internal clock paths are constrained; I/O delays and exact pin assignments are absent | Board interface timing and pin constraints |
| License | Not selected | Repository owner decision and a committed license file |

## Files requiring manual review

- `docs/journal_plan.md` is a research plan, not a record of completed experiments.
- Legacy root-level Quartus project files and generated `db/` content remain on disk but are ignored; remove them only after confirming they are no longer needed.
- Generated simulator logs are intentionally ignored. Re-run the scripts to reproduce them.

## Link and claim checks

- Relative documentation links are checked as part of repository validation.
- Specification statements should continue to be reviewed against the private Revision 2.0, Version 1.0 reference.
- The phrases “UCIe compliant” and “complete PHY” are not supported by the current evidence.
