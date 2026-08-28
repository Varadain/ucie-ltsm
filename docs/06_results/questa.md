# Questa Results

Freshly rerun on **August 28, 2026** using Questa Intel Starter FPGA Edition 2023.3.

## Directed test

Command:

```powershell
& 'C:\intelFPGA_lite\questa_fse\win64\vsim.exe' -c -do scripts/run_questa.do
```

Observed result:

- SystemVerilog compilation: 0 errors, 0 warnings.
- Simulation: `PASS: nominal training, retrain, and error recovery`.
- Simulator summary: 0 errors; one `-assertdebug` accessibility warning.
- No assertion failure was reported.

## Directed waveform evidence

The release figures are generated from a VCD captured during the same self-checking directed scenario:

```powershell
& 'C:\intelFPGA_lite\questa_fse\win64\vsim.exe' -c -do scripts/capture_directed_waveform.do
python scripts/render_waveforms.py
```

![Nominal v0.1 link training waveform](../../assets/waveforms/v0.1-basic-ltssm/nominal-training.svg)

The nominal figure shows RESET residency followed by SBINIT, all six MBINIT substates, all thirteen MBTRAIN substates, LINKINIT, and ACTIVE. Because the directed test deasserts and reasserts `phase_done_i` in the same simulation timestamp between back-to-back operations, the VCD renders it as one continuous high interval across each ordered substate run; the enum buses retain every registered substate boundary.

![v0.1 retrain and fatal-error recovery waveform](../../assets/waveforms/v0.1-basic-ltssm/retrain-error-recovery.svg)

The second figure retains the final MBTRAIN context, then shows LINKINIT/ACTIVE, an ACTIVE-to-PHYRETRAIN request, `MBTRAIN.SPEEDIDLE` re-entry, fatal-error handshake, TRAINERROR, and RESET. Short substate labels are expanded in the [asset README](../../assets/README.md).

The intermediate VCD under `build/waves/` is ignored. The capture script, standard-library renderer, and reviewed SVG outputs are versioned so the figures remain reproducible without committing a bulky waveform database.

## UVM regression

Command:

```powershell
.\scripts\run_uvm_regression.ps1
```

| Test | Top-level transitions | Illegal transitions | Observed flags | UVM errors / fatals |
|---|---:|---:|---|---|
| `nominal_test` | 5 | 0 | active=1 | 0 / 0 |
| `timeout_test` | 3 | 0 | trainerror=1 | 0 / 0 |
| `recovery_test` | 9 | 0 | active=1, retrain=1, trainerror=1 | 0 / 0 |
| `pm_test` | 7 | 0 | active=1, pm=1 | 0 / 0 |

The regression script completed with `PASS: all 4 UVM tests`.

## Interpretation

These runs support the named controller scenarios. They do not provide full functional coverage, electrical compliance, random-stimulus closure, or proof of all UCIe 2.0 requirements.
