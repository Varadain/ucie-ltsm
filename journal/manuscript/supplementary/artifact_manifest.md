# Supplementary Artifact Manifest

The public artifact is the repository at
<https://github.com/Varadain/ucie-ltsm>. A final paper must identify an immutable
release tag or archival DOI rather than a moving branch.

## Implementation

- `rtl/ucie_ltsm_pkg.sv`
- `rtl/ucie_ltsm.sv`
- `rtl/ucie_sb_sequencer.sv`
- `rtl/ucie_lfsr_training_engine.sv`
- `rtl/ucie_error_manager.sv`
- `rtl/ucie_ltsm_fpga_wrapper.sv`

## Verification

- directed testbenches under `verification/`
- UVM packages and top modules under `verification/uvm/`
- concurrent assertions in `verification/ucie_ltsm_sva.sv`
- fixed-seed regression scripts under `scripts/`
- verification plan in `docs/05_verification/testplan.md`
- VCD-backed reviewed captures under `build/waves/`
- waveform renderers under `scripts/render_*waveforms.py`
- signal definitions and waveform-anchor guide in `docs/02_ltssm/signals.md`

## FPGA evidence

- core project and SDC under `quartus/`
- core map/fit/STA summaries under `quartus/output_files/`
- wrapper map/fit/STA summaries under `quartus/output_files_wrapper/`

## Publication evidence

- `journal/result_traceability.md`
- machine-readable tables under `journal/tables/`
- editable diagram sources under `journal/figures/source/`
- matched SVG/PDF/PNG exports under `journal/figures/`
- review checklists under `journal/review/`

The private UCIe specification file under `references_private/` is not part of
the artifact and must never be added to a release.
