# FPGA CSR Wrapper Verification

## Purpose

`ucie_ltsm_fpga_wrapper` keeps the verified v0.4 controller unchanged while replacing wide physical diagnostic/status outputs with a compact byte-wide CSR interface. The wrapper reduces the selected FPGA package use from the unfittable 149-pin controller top to 119 pins without using virtual pins.

## CSR map

| Address | Access | Contents |
|---:|---|---|
| `0x00` | RO | LTSM state |
| `0x01` | RO | MBINIT substate |
| `0x02` | RO | MBTRAIN substate |
| `0x03` | RO | Sideband enable, mainband tristate, link, timeout and error handshake flags |
| `0x04` | RO | Retained error cause |
| `0x05` | RO | Error event count bits 7:0 |
| `0x06` | RO | Error event count bits 15:8 |
| `0x07` | RO | Training error count bits 7:0 |
| `0x08` | RO | Training error count bits 15:8 |
| `0x09` | RO | Wrapper version (`0x04`) |
| `0x10` | WO | Bit 0 requests error-log clear |

`csr_ready_o` acknowledges a valid request in the same cycle. Undefined reads return zero. The core itself remains the reusable ASIC-facing module; this wrapper is the FPGA implementation boundary.

## Verification

The self-checking wrapper test reaches ACTIVE, reads state/status/version, injects a one-cycle fatal event, checks immediate handshake through internal observation, reads the retained cause/count through CSR, proves clear is ignored in TRAINERROR, releases recovery, proves clear succeeds in RESET, and checks an undefined address. It passed with zero Questa compilation or simulation errors.

The preserved gate also passed in fresh invocations:

- nine deterministic UVM tests;
- five sideband seeds / 200 transactions;
- five DATATRAINCENTER1 seeds / 160 trials;
- five recovery seeds / 180 trials; and
- controller, sideband, LFSR and error-manager directed suites.

## Quartus result

Quartus Prime Lite 23.1std.1 full compilation passed for Cyclone 10 LP `10CL025YU256C8G`:

- 804 logic elements (3%);
- 499 registers;
- 119 physical pins (79%);
- zero virtual pins;
- worst setup slack `+0.624 ns` at the slow 85 C corner;
- worst hold slack `+0.178 ns` across analyzed corners; and
- zero setup/hold TNS for `clk_i` at 80 MHz.

The design is not fully constrained because board pin assignments and external I/O delays are not defined. These numbers qualify the internal FPGA core clock only, not board timing, ASIC timing or UCIe link rate.

Warnings include constant unused sideband message bits, unused CSR write-data bits 7:1, missing exact pin locations/I/O delays, the Lite-edition LogicLock limitation and the existing parameter-width truncation warning in `ucie_error_manager`. None prevented fitting or analyzed internal-clock timing.

## Commands

```powershell
vsim -c -do scripts/run_fpga_wrapper_directed.do
quartus_sh --flow compile ucie_ltsm_fpga
.\scripts\run_uvm_regression.ps1
.\scripts\run_random_regression.ps1
.\scripts\run_datatrain_random_regression.ps1
.\scripts\run_recovery_random_regression.ps1
```
