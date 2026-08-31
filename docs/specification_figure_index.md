# Specification Figure and Section Reference Index

This index connects the repository's original diagrams to the manual locations used as design references. It does not reproduce specification artwork, tables, page images, or wording. The private local PDF remains under `references_private/` and is intentionally excluded from Git.

Reference edition: *UCIe Specification Revision 2.0, Version 1.0*, August 6, 2024. Obtain an authorized copy from the [UCIe Consortium specification page](https://www.uciexpress.org/specifications).

The page numbers below are the numbered PDF pages printed in that edition. For a local authorized copy, open:

```text
references_private/UCIe_Specification_rev2p0_ver1p0_final_2024Aug06_public_clean (website requests).pdf
```

## Diagram 1: project LTSM scope

[![Original project LTSM scope diagram](../assets/diagrams/specification-reference/project-ltsm-scope.svg)](../assets/diagrams/specification-reference/project-ltsm-scope.svg)

| Reference locator | Page | How it informed the original diagram |
|---|---:|---|
| Section 4.5.3, Link Training State Machine | 129-170 | Names and high-level purposes of the top-level states |
| Table 4-6, State Definitions for Initialization | 129 | State vocabulary and initialization roles |
| Figure 4-33, Link Training State Machine | 130 | Nominal ordering and the existence of retrain, power-management, and error return paths |
| Sections 4.5.3.1-4.5.3.9 | 131-170 | Per-state behavior used to annotate the project's implemented and abstracted boundaries |

This is not a redraw of Figure 4-33. It uses a horizontal implementation-depth layout, repository-specific color semantics, RTL signal names, and the verified retained-error behavior. The exact project behavior is documented in the [LTSM guide](02_ltssm/README.md) and [requirements traceability matrix](requirements_traceability.md).

## Diagram 2: training scope map

[![Original MBINIT and MBTRAIN scope map](../assets/diagrams/specification-reference/training-scope-map.svg)](../assets/diagrams/specification-reference/training-scope-map.svg)

| Reference locator | Page | How it informed the original diagram |
|---|---:|---|
| Section 4.5.3.3, MBINIT | 135-154 | Ordered MBINIT state vocabulary |
| Figure 4-34, MBINIT: Mainband Initialization and Repair Flow | 136 | Six-state MBINIT order |
| Section 4.5.3.4, MBTRAIN | 154-166 | Ordered MBTRAIN state vocabulary |
| Figure 4-41, Mainband Training | 155 | Relationship between early training, centering, later training, retrain, and link initialization |
| Section 4.5.3.4.8, MBTRAIN.DATATRAINCENTER1 | 159-160 | Location of the integrated digital training operation within MBTRAIN |

The project diagram deliberately groups states by implementation depth rather than copying the specification topology. In the current RTL, state ordering is implemented for all shown substates; only DATATRAINCENTER1 has the integrated production transaction and pattern path. Other physical operations still use the documented `phase_done_i` abstraction.

## Diagram 3: integrated DATATRAINCENTER1 order

[![Original integrated DATATRAINCENTER1 ordering diagram](../assets/diagrams/specification-reference/integrated-datatrain-order.svg)](../assets/diagrams/specification-reference/integrated-datatrain-order.svg)

| Reference locator | Page | How it informed the original diagram |
|---|---:|---|
| Section 4.4.1, LFSR pattern | 119 | Continuous-mode LFSR pattern source referenced by training |
| Section 4.5.3.4.8, MBTRAIN.DATATRAINCENTER1 | 159-160 | START, digital pattern work, result decision, and END ordering |
| Table 7-9, LTSM-related message encodings | 264 | DATATRAINCENTER1 START/END request and response message identities |
| Section 4.5.3.8, TRAINERROR | 169-170 | Error-state transition and sideband-handshake context |

The diagram is based primarily on the checked RTL in `rtl/ucie_ltsm.sv`, `rtl/ucie_sb_sequencer.sv`, `rtl/ucie_lfsr_training_engine.sv`, and `rtl/ucie_error_manager.sv`. It therefore shows project-specific retry, gating, retained-event, and abort behavior instead of presenting itself as a normative protocol figure. See the [v1.0 verification result](06_results/v1.0_integrated_training.md) for the independent message-order predictor and production-mode campaign.

## Citation and redistribution boundary

- These SVGs are original repository-native vector drawings. They contain no embedded raster images or copied specification artwork.
- Figure numbers, section numbers, titles, and page locators are used only to help an authorized reader navigate the cited edition.
- The repository does not redistribute the specification PDF, extracted text, screenshots, figures, or tables.
- The diagrams describe a final academic digital-control/FPGA implementation scope. They do not establish analog PHY validation, BER, electrical signoff, ASIC PPA, official interoperability, or UCIe compliance.
