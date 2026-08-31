# Changelog

All notable project milestones are documented here. Source snapshots are preserved by Git tags rather than duplicated version folders.

## v0.4-error-recovery - Retained TRAINERROR and FPGA CSR Wrapper

### Added

- Synthesizable `ucie_error_manager` with eligible-event acceptance, one-event retention, persistent/bounded handshake, fixed state-timeout/sideband/local-fatal cause priority, protected clear, and a saturating 16-bit event counter.
- Integrated error cause/count/pending/handshake diagnostics and immediate versus acknowledged/bounded TRAINERROR entry without removing prior sideband or DATATRAINCENTER1 behavior.
- Five-seed recovery campaign with 180 trials, independent prediction, recovery SVA, explicit sampled scenario/origin/pulse/ack bins and legal crosses, plus focused boundary/saturation proof.
- `recovery_closure_test` for the L2 exit and all TXSELFCAL/SPEEDIDLE/REPAIR retrain targets, bringing the deterministic UVM regression to nine tests.
- Separate `ucie_ltsm_fpga_wrapper` and Quartus project. The wrapper leaves `ucie_ltsm` unchanged, internalizes wide diagnostics, and exposes a byte CSR at `0x00`-`0x10`.
- Self-checking CSR wrapper test for version/state/status, retained cause/count, protected and allowed clear, same-cycle ready, and invalid reads.
- Three colorful Questa-derived waveforms, recovery RTL/verification diagrams, a wrapper connection diagram, and hyperlinkable signal/terminology definitions.
- Versioned fitted-wrapper and core-only functional netlists with SHA-256 provenance and distinct implementation claims.

### Verification and implementation

- Five of five recovery seeds passed: all 180 events entered TRAINERROR with exact predicted cause/count, timing, residency, and release.
- Aggregate recovery scenarios: 36 delayed acknowledgments, 30 missing acknowledgments, 32 state timeouts, 32 SBINIT protocol errors, 25 residency checks, and 25 simultaneous-cause priority checks.
- Preserved nine deterministic UVM tests, five sideband seeds / 200 transactions, five training seeds / 160 trials, and all controller/sideband/LFSR/error directed suites passed.
- Wrapper directed simulation passed with zero compilation/simulation errors.
- Quartus 23.1 full wrapper compilation passed on Cyclone 10 LP: 804 logic elements, 499 registers, 119 physical pins, zero virtual pins, `+0.624 ns` worst setup slack, `+0.178 ns` worst hold slack, and zero setup/hold TNS at 80 MHz.
- Zero UVM errors/fatals, illegal transitions, assertion failures, or predictor mismatches were reported by the release gate.

### Known limitations

- This is digital training control, retained error recovery, and a compact FPGA CSR boundary—not a complete analog/electrical PHY or UCIe compliance result.
- The byte CSR is project-specific and is not a standards-defined DVSEC, management transport, firmware stack, or interrupt architecture.
- The reusable 149-pin core top does not fit the selected package; fit/timing claims apply to the 119-pin wrapper.
- Board pin locations and external I/O delays are absent, so positive timing qualifies internal 80 MHz paths only.
- Native covergroup/UCDB percentages remain unavailable under the Starter license; explicit sampled coverage is reported instead.
- CDC hardening, analog/channel fault injection, BER/interoperability evidence, ASIC PPA, and power evidence remain absent.

## v0.3-advanced-training - DATATRAINCENTER1 Digital LFSR Training

### Added

- Synthesizable `ucie_lfsr_training_engine` with sixteen 23-bit lane LFSRs, eight seeds repeated modulo eight, accepted-sample progression, and a 16-bit generated pattern.
- Mismatch popcount, 16-bit saturating error accumulation, configurable accepted-sample count, and strict `error_count < threshold` result.
- `ucie_ltsm` integration in `MBT_DATATRAINCENTER1`; successful completion advances to `DATATRAINVREF`, failure repeats in place, and reset/substate exit aborts cleanly.
- Focused directed test for seeds, polynomial, gaps, equality, abort, default 4096 samples, and `16'hffff` saturation.
- Five-seed randomized UVM campaign with an independent reference model, training SVA, and explicit sampled functional-coverage bins/crosses.
- Colorful pattern and threshold/abort waveform SVGs, RTL/verification connection diagrams, reviewed Quartus functional netlist, and a project-wide glossary.

### Verification

- Five of five DATATRAINCENTER1 seeds passed: 160 trials covering 47 direct passes, 32 fail/retry cases, 44 aborts, and 37 LTSM timeouts.
- The independent model checked 368 clean samples, 654 corrupted samples, 1,768 receive-gap cycles, every lane/polynomial step, exact/saturated counts, and strict results.
- All required outcome, error, gap, threshold, and twelve scenario-by-gap bins/crosses were hit.
- Zero UVM errors/fatals, zero illegal top-level transitions, zero assertion failures, and zero DUT/reference mismatches.
- Preserved 8/8 deterministic UVM tests, 5/5 v0.2 sideband seeds, and all three directed suites passed independently.
- Quartus 23.1 full compilation passed with 698 logic elements, 465 registers, +0.744 ns worst setup slack at 80 MHz, +0.178 ns worst hold slack across corners, and zero setup/hold TNS.

### Known limitations

- This is digital training control, not an analog/electrical PHY, BER qualification, or UCIe compliance result.
- The randomized campaign uses eight accepted samples per attempt; the default 4096 behavior is proven in a focused directed test.
- Questa Starter cannot license class `randomize()` or native covergroups; seeded legal domains and explicit sampled coverage are used without a UCDB percentage claim.
- External FPGA I/O timing/pins remain incomplete, and no ASIC area/power/timing evidence is present.

## v0.2-random-uvm - Seeded Randomized Verification

### Added

- `sb_random_test` and `sb_random_seq` for repeatable constrained-domain sideband verification.
- Five fixed simulator seeds with 40 reset-isolated transactions per seed.
- Independent one-to-three-cycle transmit-backpressure and response-delay selection.
- A cumulative reference predictor checked against passive monitor totals for requests, successful exits, retries, and protocol errors.
- A reproducible PowerShell campaign and two reviewed randomized-verification SVG figures.

### Verification

- Five of five seeds passed; all four legal outcomes were exercised by every seed.
- 200 randomized transactions produced 290 accepted requests, 93 successful SBINIT exits, 90 retries, and 107 protocol errors, exactly matching the predictor.
- Zero UVM errors, zero UVM fatals, zero illegal top-level transitions, and zero predictor mismatches.
- The preserved eight-test deterministic UVM regression and both directed suites passed after the driver/monitor race hardening.

### Preserved

- No synthesizable RTL, interface, state encoding, timing constraint, or netlist content changed.
- The `v0.2-sideband` waveform, connection, Quartus, and functional-netlist evidence remains the implementation baseline.

### Known limitations

- Questa Starter does not license class `randomize()`; explicit legal domains are sampled with seeded `$urandom_range`.
- No UCDB, functional covergroup percentage, code/assertion coverage closure, or randomized bit-level corruption campaign is claimed.

## v0.2 - Sideband Integration

### Added

- Synthesizable `ucie_sb_sequencer` with ready/valid transmit handling, response matching, configurable timeout, bounded retry, abort, completion, and protocol-error outputs.
- Transaction-level `SB_MSG_SBINIT_DONE_REQ` and `SB_MSG_SBINIT_DONE_RESP` message labels.
- Integrated SBINIT completion through the sideband sequencer, with error escalation into TRAINERROR.
- Standalone sequencer test covering backpressure, success, retry, retry exhaustion, unexpected response, and abort.
- Four UVM scenarios for integrated sideband success, retry, malformed response, and retry exhaustion.
- Color-coded sideband waveform figures with clickable links to signal/function descriptions.
- v0.2 RTL and verification connection diagrams and a Quartus functional Verilog netlist.

### Modified

- `ucie_ltsm` now exposes the ready/valid sideband channel and observable sequencer status.
- Questa, UVM, and Quartus source lists now compile `ucie_sb_sequencer.sv`.
- The UVM monitor and scoreboard record sideband request, response, retry, and protocol-error events.
- Architecture, algorithm, RTL, verification, result, roadmap, and traceability documentation now explain the v0.2 delta.

### Preserved

- All v0.1 state encodings, MBINIT/MBTRAIN ordering, timeout, retrain, power-management, and recovery behavior.
- `phase_done_i` remains available for compatibility and for later unimplemented training-operation engines.
- The four v0.1 UVM scenarios remain in the regression and pass unchanged.

### Verification

- Legacy directed Questa scenario: pass at 1276 ns.
- Sideband-directed Questa scenario: pass at 376 ns; no assertion failures.
- Eight-test UVM regression: pass with zero errors, zero fatals, and zero illegal transitions.
- Quartus 23.1 full compilation: successful; 196 logic elements, 66 registers, +1.617 ns slow-85 C setup slack, and 0.000 ns TNS at the checked 80 MHz constraint.
- Both waveforms and both connection diagrams received four-pass structural and rendered visual review.

### Known limitations

- Only the SBINIT-done message pair is modeled; encodings are internal transaction-level labels, not a complete physical packet format.
- Physical sideband detection/repair, framing, CRC, credits, and remote-request responder behavior are absent.
- `phase_done_i` can bypass the SBINIT exchange.
- No merged UCDB coverage closure, randomized corruption campaign, fully constrained FPGA I/O timing, or Cadence evidence exists.

## v0.1 - Basic LTSM

### Added

- Synthesizable `ucie_ltsm` controller and shared state package.
- Nine top-level states, six MBINIT substates, and thirteen MBTRAIN substates.
- Parameterized RESET residence and eligible-state timeout behavior.
- Retrain, fatal-error recovery, and L1/L2 exit control paths.
- Directed testbench, SystemVerilog assertions, UVM environment, and Quartus project.
- Beginner-oriented architecture, algorithm, RTL, verification, results, and version documentation.
- Questa-derived nominal and retrain/error waveform SVGs with reproducible capture/render scripts.
- Color-distinct waveform traces and substate bands with clickable signal/function documentation.
- RTL and verification connection diagrams based on the implemented source topology.
- Quartus functional Verilog simulation netlist with a reproducible export script and scope notes.

### Modified

- Repository metadata and navigation were expanded from a short project note into a progressive engineering record.
- Private specification material was moved under ignored `references_private/` storage.
- The default `CLK_HZ` parameter was aligned with the Quartus project's 80 MHz constraint so the synthesized default produces the intended 4 ms and 8 ms intervals.

### Preserved

- RTL module, package, signal, state, and parameter names.
- Existing Questa and Quartus source paths and commands.
- State encodings, transition logic, ports, and simulation overrides.

### Verification

- Fresh directed Questa run passed on August 28, 2026.
- Fresh UVM regression passed all four tests with zero UVM errors and zero UVM fatals on August 28, 2026.
- Fresh Quartus 23.1 build reports successful fitting and positive internal clock timing slack at the checked 80 MHz constraint; external I/O timing is not fully constrained.
- Release evidence was visually reviewed at full and reduced render sizes; waveform and connection-diagram labels are separated and unclipped.

### Known limitations

- Sideband transport, concrete training operations, RDI, register blocks, and analog PHY behavior are abstracted or absent.
- L2 exit and two retrain targets are not covered by the current UVM suite.
- Per-substate functional coverage and Cadence implementation evidence are absent.
