# Technical Consistency Check

Status: **pass for pre-submission draft; submission gaps remain**.

- [x] LTSM is expanded as Link Training State Machine; PCIe “LTSSM” is not used.
- [x] Implemented baseline is UCIe Specification Revision 2.0, Version 1.0.
- [x] UCIe 3.0 appears only as later/current context, not as an implementation claim.
- [x] Nine top states, six MBINIT substates, and thirteen MBTRAIN substates match `ucie_ltsm_pkg.sv`.
- [x] DATATRAINCENTER1 sequence matches RTL: START response, PATTERN, END response, then DATATRAINVREF.
- [x] Failed pattern retries without END.
- [x] LFSR width, lane count, polynomial, accepted-sample progression, threshold rule, and saturation match RTL.
- [x] Error-cause priority, retention, bounded entry, and protected clear match `ucie_error_manager.sv`.
- [x] CSR addresses include the v1.0 phase register at 0x0A and control at 0x10.
- [x] Production verification fixes the abstract CENTER1 bypass to zero.
- [x] Core map and failed fit are not mixed with successful wrapper fit.
- [x] Wrapper timing is qualified as internal-clock only.
- [x] No ASIC, PPA, BER, eye, electrical, hardware, interoperability, signoff, or compliance claim appears.
- [x] Private specification content is neither copied nor tracked.

Open before submission: author metadata, native coverage/code coverage,
independent reproduction, a stronger comparative experiment, and physical or
ASIC evidence as described in `../TVLSI_READINESS_GAP.md`.
