# Changelog

All notable project milestones are documented here. Source snapshots are preserved by Git tags rather than duplicated version folders.

## v0.1 - Basic LTSM

### Added

- Synthesizable `ucie_ltsm` controller and shared state package.
- Nine top-level states, six MBINIT substates, and thirteen MBTRAIN substates.
- Parameterized RESET residence and eligible-state timeout behavior.
- Retrain, fatal-error recovery, and L1/L2 exit control paths.
- Directed testbench, SystemVerilog assertions, UVM environment, and Quartus project.
- Beginner-oriented architecture, algorithm, RTL, verification, results, and version documentation.
- Questa-derived nominal and retrain/error waveform SVGs with reproducible capture/render scripts.
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
