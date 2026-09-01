# Figure Quality Check

Status: **pass after four review passes**.

1. **Initial PNG pass:** inspected all eight 1600×900 exports. Corrected a
   duplicate Fig. 1 title, a boundary-touching input label, ambiguous state-flow
   return arrows, and a bidirectional-looking recovery path.
2. **Regenerated critical-figure pass:** reinspected scope, LTSM, LFSR, and
   recovery figures at original resolution. Replaced overlapping state-flow
   edge labels with separately positioned labels.
3. **Structural pass:** parsed all eight `.drawio` and SVG files, checked canvas
   bounds, pairwise node overlap, text vertical capacity, arrow-point bounds,
   PNG dimensions, and nonblank renders with `tools/qa_figures.py`.
4. **Compiled-PDF pass:** rasterized every manuscript page. Corrected the
   TRAINERROR arrow direction, promoted detailed figures to double-column
   width, separated the verification qualification line from its caption, and
   removed a redundant implementation figure from the paper when it stranded
   on an otherwise empty page. The figure remains in the supplementary asset
   package.

Final inventory: eight editable draw.io sources, eight SVGs, eight vector PDFs,
and eight PNG previews. No text/box overlap, mixed labels, clipped content, or
ambiguous arrow direction remains. Color meaning is duplicated by text and
line style for grayscale readability.
