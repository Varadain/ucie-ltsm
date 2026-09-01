# Reproduction Notes

## Simulation

Required environment: Questa Intel FPGA Starter Edition 2023.3 and PowerShell.
From the repository root, run the committed scripts for the directed tests and
the deterministic, sideband, training, recovery, and integrated campaigns. The
production integrated command is:

```powershell
.\scripts\run_integrated_random_regression.ps1
```

The expected fixed seeds are 1701, 1802, 1903, 2004, and 2105 with 36 trials
per seed. The top fixes the abstract training bypass to zero.

## FPGA

Required environment: Quartus Prime Lite 23.1std.1. Compile both projects to
retain the negative core fit and positive wrapper fit:

```powershell
Push-Location .\quartus
quartus_sh --flow compile ucie_ltsm
quartus_sh --flow compile ucie_ltsm_fpga
Pop-Location
```

The core command is expected to fail fitting because of pin demand. The wrapper
is expected to fit. Differences in Quartus build, operating system, device
database, or warning policy must be recorded rather than silently replacing
the committed summaries.

## Paper

```powershell
python .\journal\tools\build_figures.py
python .\journal\tools\qa_figures.py
Push-Location .\journal\manuscript
pdflatex -interaction=nonstopmode -halt-on-error main.tex
bibtex main
pdflatex -interaction=nonstopmode -halt-on-error main.tex
pdflatex -interaction=nonstopmode -halt-on-error main.tex
Pop-Location
```

`latexmk` is an equivalent convenience wrapper when its Perl dependency is
available.
