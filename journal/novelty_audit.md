# Novelty Audit

## Candidate contribution

The defensible contribution is not a new UCIe state machine. The state and
training concepts originate in the standard. The repository instead offers an
open, inspectable **implementation-and-evidence pattern** for a bounded
UCIe-derived control problem:

1. a modular synthesizable controller that joins top-level/substate sequencing,
   a retrying sideband engine, a per-lane LFSR training engine, retained error
   attribution, and a compact diagnostic wrapper;
2. production-path DATATRAINCENTER1 ordering whose advance is guarded by both
   independently checked pattern acceptance and the closing END response; and
3. a specification-traceable verification campaign that combines directed
   corner tests, assertion invariants, an independent message-order/LFSR
   predictor, explicit scenario/cross counters, preserved multi-seed
   regressions, and qualified FPGA implementation evidence.

This is best framed as a reproducible academic digital-control case study and
reference framework. It is not a new PHY architecture, new coding polynomial,
new verification methodology, or full UCIe implementation.

## What appears distinct in the audited literature

Published UCIe work is concentrated in specification architecture, package and
channel behavior, transceiver circuits, system/application studies, and
commercial verification flows. Public descriptions of an end-to-end,
source-available RTL control subset coupled to an independent UVM predictor,
negative training/recovery scenarios, retained diagnostics, and a practical
FPGA pin-reduction wrapper are sparse. That scarcity supports the case-study
value, but absence from a finite search is not proof of uniqueness.

## Novelty risks

- The state sequence, names, sideband role, and LFSR concept are
  specification-derived and cannot be claimed as inventions.
- UVM scoreboards, SVA, fixed-seed regressions, and CSR wrappers are established
  techniques. Their value lies in the combined traceable application, not in
  the techniques individually.
- Most training substates are abstracted, which weakens any architecture claim
  beyond the integrated CENTER1 case.
- FPGA resource counts are device- and configuration-specific and cannot
  establish superiority without a matched baseline.
- No ASIC PPA, hardware, BER, interoperability, native coverage database, code
  coverage, formal proof, or fault-injection campaign is available.

## Venue-fit judgment

The present result is a credible M.Tech-level reproducibility artifact and a
useful technical paper draft. It is **not yet strong enough for a confident
TVLSI regular-paper submission**. TVLSI normally expects a clear circuit/system
innovation with deeper quantitative comparison and implementation evidence.
The current package can become a submission foundation if the gaps in
`TVLSI_READINESS_GAP.md` are addressed. A design-and-verification conference,
education/reproducibility venue, or shorter application-focused article may be
a better fit if those experiments cannot be added.

## Claim language

Use: “implements,” “checks,” “observed in the committed campaigns,” “fits the
selected FPGA wrapper project,” “UCIe 2.0-derived,” and “control subset.”

Avoid: “first,” “complete,” “fully verified,” “silicon-ready,” “production
ready,” “compliant,” “interoperable,” “signoff,” and all unmeasured PPA,
electrical, or performance claims.
