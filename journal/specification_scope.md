# Specification and Implementation Scope

## Normative reference

The design was derived from *UCIe Specification Revision 2.0, Version 1.0*,
dated 6 August 2024. The specification copy is kept under
`references_private/` and is intentionally excluded from the public repository.
No figure, table, screenshot, or normative text from that copy is reproduced in
this paper package.

UCIe 3.0 is the current Consortium release as of this audit (September 2026),
but it is not the implemented baseline. The manuscript must always attach a
revision number to specification-derived claims.

## Implemented digital-control boundary

The synthesizable SystemVerilog design contains:

- nine top-level LTSM states: RESET, SBINIT, MBINIT, MBTRAIN, LINKINIT,
  ACTIVE, PHYRETRAIN, TRAINERROR, and L1/L2;
- six MBINIT and thirteen MBTRAIN substates represented in the package;
- a state/substate residency timer and TRAINERROR routing;
- nominal initialization, ACTIVE entry, low-power routing, retraining, and
  recovery routing at the controller boundary;
- a ready/valid sideband sequencer with message matching, timeout, retry, and
  abort behavior;
- an integrated DATATRAINCENTER1 sequence in production mode:
  START request/response, per-lane LFSR pattern measurement, optional failed
  pattern retry, END request/response, then DATATRAINVREF advancement;
- a 16-lane, 23-bit per-lane LFSR training engine with accepted-sample
  progression, a strict error threshold, and saturating error accumulation;
- a retained error manager with fixed cause priority, bounded TRAINERROR entry,
  protected clear, and saturating event count; and
- a compact byte-addressed FPGA CSR wrapper exposing controller status without
  exporting every diagnostic signal to package pins.

## Abstracted behavior

Most MBINIT, MBTRAIN, and PHYRETRAIN operations remain represented by the
external `phase_done_i` abstraction. The following are therefore controller
sequencing points rather than complete UCIe procedures:

- clock/data calibration other than the implemented LFSR phase;
- lane discovery, repair, reversal, deskew, and full training-pattern content;
- parameter negotiation and all specification-defined sideband packet formats;
- mainband datapath initialization and transfer;
- protocol-layer and die-to-die adapter operations; and
- complete reset, power-management, and retraining semantics across two dies.

Simulation parameters shorten millisecond-scale behavior for tractable tests.
Those reductions validate ordering and bounded behavior, not wall-clock
conformance to physical link timing.

## Explicitly excluded evidence

The repository does not provide evidence for:

- analog/transceiver or package-channel implementation;
- eye diagrams, jitter, voltage margin, channel loss, BER, lane rate, bandwidth,
  bandwidth density, latency, or energy per bit;
- two-die interoperability or official UCIe compliance testing;
- a complete UCIe PHY, adapter, protocol stack, manageability stack, or flit path;
- CDC/RDC signoff, DFT, equivalence checking, formal proof, or safety
  certification;
- ASIC synthesis, place-and-route, area, power, PVT timing, or signoff; or
- FPGA board pinout, external I/O delays, hardware execution, or board-level
  timing closure.

## Terminology discipline

LTSM means **Link Training State Machine** in this project. “LTSSM” is a PCIe
term and must not be substituted. “UCIe-derived” or “UCIe 2.0 control subset”
is acceptable; “UCIe-compliant implementation” is not supported by the
available evidence.
