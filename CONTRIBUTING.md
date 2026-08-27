# Contributing

This project evolves in small, evidence-backed milestones. Changes should preserve the connection between explanation, RTL, verification, and measured results.

## Development model

- Keep `main` at the latest stable, reproducible milestone.
- Use `feature/<name>` for RTL features, `verification/<name>` for verification work, and `docs/<topic>` for documentation-only changes.
- Do not create permanent `v1`, `v2`, or `final2` branches. Preserve stable snapshots with annotated Git tags and GitHub Releases.
- Do not duplicate the RTL tree inside version directories.

## Before opening a change

1. Identify the exact behavior being added or corrected.
2. Keep module, signal, state, package, and file names stable unless a technical reason requires a rename.
3. Update the relevant algorithm, RTL, verification, traceability, version, changelog, and roadmap documentation.
4. Run the directed test and the UVM regression.
5. Check every changed relative link and filename.

## Verification expectations

A change is not described as verified merely because it compiles. Document the stimulus, expected behavior, pass condition, test name, and observed result. If a tool or environment is unavailable, mark the evidence as missing.

## Private references

Do not commit UCIe specification PDFs, extracted specification text, copied tables, screenshots, or figures. Keep local reference material in `references_private/`, which is ignored. Public documentation should paraphrase concepts, cite the specification revision and section, and use original diagrams.

## Commit and release style

Use short, imperative commit subjects, for example:

```text
docs: document v0.1 LTSM architecture and evidence
verify: add L2 power-management scenario
feat: integrate sideband completion sequencer
```

A release is appropriate only when the milestone's required tests pass and its limitations are recorded.
