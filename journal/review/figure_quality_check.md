# Figure Quality Check

Status: **pass after four review passes**.

1. **Original-artwork pass:** inspected the initial scope and RTL hierarchy
   exports at full resolution. Replaced the oversized yellow scope block,
   corrected the aspect ratios, and redrew both figures with individually
   labelled modules and explicit boundary semantics.
2. **Regenerated-asset pass:** reinspected the corrected scope/hierarchy,
   release-gate graphic, and all three color-coded Questa waveforms at original
   resolution. Corrected hierarchy arrow directions and removed crossing
   connectors from the release-gate graphic.
3. **Structural pass:** parsed all nine `.drawio` sources and twelve SVGs,
   checked canvas bounds, pairwise node overlap, text vertical capacity,
   arrow-point bounds, aspect-preserving PNG dimensions, and nonblank renders
   with `tools/qa_figures.py`.
4. **Compiled-PDF pass:** rasterized and reviewed all eleven manuscript pages.
   Removed section-level float barriers that caused sparse pages, flushed all
   graphics before the bibliography, balanced the final reference columns, and
   retained the release-gate overview as a supplementary figure rather than an
   otherwise isolated full-width manuscript float. Captions, labels, tables,
   waveforms, and two-column text remain separated and legible.

Final inventory: nine editable draw.io sources, twelve SVGs, twelve publication
PDFs, and twelve PNG previews. The three waveform figures additionally retain
their committed VCD sources and deterministic renderer scripts; eleven figures
are embedded in the manuscript and the release-gate overview is supplementary.
No text/box overlap, mixed labels, clipped content, or ambiguous arrow direction
remains. Color meaning is duplicated by text and line style for grayscale
readability.
