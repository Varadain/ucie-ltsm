# Journal Paper Workspace

This directory is the publication workspace for the UCIe Link Training State
Machine (LTSM) project. The primary target is *IEEE Transactions on Very Large
Scale Integration (VLSI) Systems* (TVLSI). The package is deliberately more
conservative than the project README: every quantitative statement in the
manuscript must resolve to committed source, a reproducible script, or a tool
report through `result_traceability.md`.

## Working title

**A Specification-Traceable RTL and Verification Framework for a UCIe 2.0
Link-Training Control Subset**

The title says “control subset” because the repository implements a digital
LTSM controller, integrated sideband sequencing, one LFSR training phase,
retained error handling, and an FPGA CSR wrapper. It does not implement or
measure the analog PHY, mainband datapath, complete protocol/adapter stack,
electrical channel, BER, or interoperability/compliance behavior.

## Package map

- `project_evidence_matrix.md` — what exists and the evidence class of each item.
- `specification_scope.md` — implemented, abstracted, and excluded behavior.
- `novelty_audit.md` — defensible contribution and novelty risks.
- `literature_review_matrix.md` — related work and its use in the paper.
- `reference_audit.md` — bibliographic and source-quality checks.
- `result_traceability.md` — manuscript result to repository evidence mapping.
- `target_journal_rules.md` — current TVLSI/IEEE preparation requirements.
- `TVLSI_READINESS_GAP.md` — work still required before submission.
- `manuscript/` — IEEEtran LaTeX source and compiled paper.
- `figures/source/` — editable diagrams.net (`.drawio`) sources.
- `figures/svg/`, `figures/pdf/`, `figures/png/` — publication and review exports.
- `figures/figure_sources.md` — provenance and permission status for every figure.
- `tables/` — machine-readable result tables used by the manuscript.
- `review/` — technical, claim, citation, figure, and journal-compliance audits.

## Rebuild

From the repository root:

```powershell
python .\journal\tools\build_figures.py
Push-Location .\journal\manuscript
pdflatex -interaction=nonstopmode -halt-on-error main.tex
bibtex main
pdflatex -interaction=nonstopmode -halt-on-error main.tex
pdflatex -interaction=nonstopmode -halt-on-error main.tex
Pop-Location
```

The figure builder generates editable draw.io sources and matched SVG, PDF,
and PNG exports. The LaTeX build embeds PDF vector figures. `latexmk` may be
used when Perl is installed; the explicit sequence above works with the audited
MiKTeX installation. Rebuilds must not read from or write into
`references_private/`.

## Submission status

This is a technically grounded pre-submission draft, not a submission-ready
paper. Author names, affiliations, ORCIDs, research-ethics acknowledgments,
and a final venue-fit decision remain author-owned items. The largest technical
gap is the absence of ASIC PPA, native functional/code-coverage closure, and a
board/electrical experiment; see `TVLSI_READINESS_GAP.md`.
