# Questa Results

Freshly rerun on **August 27, 2026** using Questa Intel Starter FPGA Edition 2023.3.

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
