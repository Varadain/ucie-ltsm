# Reference Audit

## Audit policy

- Prefer DOI-resolved publisher records, standards bodies, and official tool
  documentation.
- Cite the UCIe revision actually implemented; mention later revisions only as
  context.
- Do not cite search snippets, aggregators, tutorials, forum posts, or the
  private specification path.
- Do not reproduce specification figures. Project figures are original
  diagrams drawn from the implemented architecture; specification-derived
  terminology is cited.
- Recheck title, author order, venue, year, volume/issue/pages, and DOI before
  submission. Entries marked **metadata check required** must not survive into
  final submission unchanged.

## Entry status

| BibTeX key | Identity check | Source quality | Intended use | Status |
|---|---|---|---|---|
| `ucie20` | Official Consortium title/revision/date checked | Primary normative | Implemented baseline and exclusions | Checked; public landing-page URL only |
| `ucie30` | Official Consortium release page checked | Primary normative | Current-version context only | Checked |
| `sharma2022ucie` | DOI 10.1109/TCPMT.2022.3207195 | Peer-reviewed IEEE | UCIe architecture/context | Checked |
| `sharma2024memory` | DOI 10.1109/MC.2023.3318769 | Peer-reviewed IEEE | Memory/storage motivation | Checked |
| `li2020chiplet` | DOI 10.3390/electronics9040670 | Peer-reviewed journal | Chiplet integration background | Checked |
| `lau2021chiplets` | DOI 10.4071/imaps.1542066 | Peer-reviewed journal | Packaging context | Checked |
| `son2023thermal` | DOI 10.1109/EDAPS58880.2023.10468234 | Peer-reviewed IEEE conference | Physical limitations | Checked |
| `chang2022fpga` | DOI 10.1109/CSTIC55103.2022.9856833 | Peer-reviewed IEEE conference | FPGA verification context | Checked |
| `nature2024ucie3d` | DOI 10.1038/s41928-024-01126-y; publisher author/page record checked | Peer-reviewed journal | Hardware comparison context | Checked |
| `ieee1800_2` | DOI 10.1109/IEEESTD.2020.9195920 | IEEE standard | UVM definition | Checked |
| `cadenceIntelUcie` | Official vendor page | Vendor technical report | Industry context only | Checked; no performance claim |
| `vamsi2025unified` | DVCon Europe proceedings PDF; title and four authors checked | Industry conference proceedings | Verification-related comparison | Checked; no numerical comparison |
| `quartusUG` | Official Intel/Altera document ID 683236 | Primary vendor documentation | Tool-report interpretation | Checked for compilation-flow terminology; align edition before submission |

## Permission note

All manuscript figures are original. The architecture figures are not tracings
or visual copies of UCIe specification figures. If a future revision adapts a
published graphic, its caption must say “adapted from,” cite the source, and
record the permission basis here before distribution.
