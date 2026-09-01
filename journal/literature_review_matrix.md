# Literature Review Matrix

The search emphasized primary standards/consortium material and peer-reviewed
IEEE/ACM/Nature literature. Vendor white papers are used only to describe
industry verification context, never to establish superiority.

| Key | Source and year | Focus | Evidence type | Relation to this work | Gap retained by this work |
|---|---|---|---|---|---|
| `ucie20` | UCIe Consortium, Specification 2.0 (2024) | Normative architecture and behavior | Industry specification | Baseline for names, sequencing, and scope | Private normative copy cannot be redistributed; implementation covers only a subset |
| `sharma2022ucie` | Sharma *et al.*, TCPMT (2022) | UCIe 1.0 architecture, circuit, channel, and packaging rationale | Peer-reviewed invited paper | Establishes ecosystem and architectural context | Does not present this open RTL/UVM artifact or retained CSR/error case study |
| `sharma2024memory` | Sharma and Coughlin, *Computer* (2024) | UCIe for memory/storage and longer-reach composition | Peer-reviewed overview | Motivates interoperable chiplet connectivity | System use case, not RTL control verification |
| `li2020chiplet` | Li *et al.*, *Electronics* (2020) | Chiplet heterogeneous integration status/challenges | Peer-reviewed review | Broader disaggregation motivation | Predates UCIe and does not address the LTSM case |
| `lau2021chiplets` | Lau, JMEP (2021) | Packaging, bridges, hybrid bonding | Peer-reviewed review | Distinguishes package integration from digital-control evidence | No UCIe controller or verification flow |
| `son2023thermal` | Son *et al.*, EDAPS (2023) | UCIe-A signal-integrity and thermal effects | Peer-reviewed conference paper | Shows physical/channel dimension outside this project | Reinforces that RTL simulation cannot imply electrical validation |
| `nature2024ucie3d` | Nature Electronics article (2024) | 3-D SiP implementation with UCIe | Peer-reviewed hardware study | Contrasts physical implementation evidence with this FPGA-only controller study | Not an open control-focused verification framework |
| `chang2022fpga` | Chang *et al.*, CSTIC (2022) | FPGA verification platform for high-speed interface IP | Peer-reviewed conference paper | Supports FPGA-based interface verification context | Targets high-speed measurement/platform behavior rather than this state-control subset |
| `accelleraUVM` | IEEE Std 1800.2-2020 | Universal Verification Methodology | Standard | Basis for class-based environment terminology | The used Starter tool license limits native randomization/coverage features |
| `cadenceIntelUcie` | Intel/Cadence white paper (2024) | UCIe PHY simulation interoperability and LTSM stepping | Vendor technical report | Industry comparison point for end-to-end model/VIP use | Proprietary environment; not evidence for this implementation |
| `dvconUcie2025` | DVCon Europe paper (2025) | Unified UVM testbench with UCIe-specific sequences | Industry conference proceedings | Nearest verification-oriented public comparison | Different DUT, scope, tools, and coverage; no fair numerical comparison is claimed |
| `quartusUG` | Intel Quartus Prime user documentation | Synthesis, fitter, and timing interpretation | Vendor primary documentation | Defines report terminology and constraint limitations | Tool report is not hardware or ASIC evidence |

## Synthesis

The literature supports three boundaries. First, UCIe is a layered die-to-die
standard whose physical, adapter, protocol, and software dimensions cannot be
collapsed into an RTL state-controller claim. Second, peer-reviewed UCIe work
contains strong circuit, channel, package, and system evidence, so a digital
controller paper must distinguish itself through transparency, traceability,
and negative verification rather than simulated throughput claims. Third,
public verification reports often describe commercial VIP or proprietary
platforms; the repository’s strongest value is the auditable connection from
requirement to RTL, independent predictor, assertion, fixed-seed result, and
FPGA report.
