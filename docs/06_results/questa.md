# Questa Results

Freshly rerun on **August 27-28, 2026** using Questa Intel Starter FPGA Edition 2023.3.

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
| `sb_success_test` | 2 | 0 | accepted requests=1, successful SBINIT exits=1 | 0 / 0 |
| `sb_retry_test` | 2 | 0 | accepted requests=2, retries=1, successful SBINIT exits=1 | 0 / 0 |
| `sb_error_test` | 3 | 0 | accepted requests=1, protocol errors=1, trainerror=1 | 0 / 0 |
| `sb_exhaust_test` | 3 | 0 | accepted requests=2, retries=1, protocol errors=1, trainerror=1 | 0 / 0 |

The regression script completed with `PASS: all 8 UVM tests`. Each test ran in a fresh simulator invocation.

## Sideband sequencer directed test

Command:

```powershell
& 'C:\intelFPGA_lite\questa_fse\win64\vsim.exe' -c -do scripts/run_sb_directed.do
```

Observed result: `PASS: sideband backpressure, success, retry, exhaustion, mismatch, and abort`.
The test also runs assertions that the request remains stable under transmit backpressure,
a retry reissues transmit-valid, and completion follows the expected response.

## Interpretation

These runs support the named controller scenarios. Feature-event counters provide scenario evidence,
but are not a merged UCDB functional-coverage closure report. The runs do not provide electrical
compliance, random-stimulus closure, or proof of all UCIe 2.0 requirements.
