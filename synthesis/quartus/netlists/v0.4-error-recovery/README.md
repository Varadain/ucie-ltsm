# v0.4 Quartus Functional Netlists

This directory contains the reviewed functional Verilog netlists for the v0.4 retained-TRAINERROR and compact FPGA/CSR-wrapper checkpoint. They are generated evidence, not editable RTL or a programming image.

| File | Top-level purpose | Bytes | SHA-256 |
|---|---|---:|---|
| [`ucie_ltsm_fpga_wrapper.vo`](ucie_ltsm_fpga_wrapper.vo) | Release FPGA boundary; compact byte CSR and verified `ucie_ltsm` instance | 1,118,539 | `102231FB12CEA16D83070312EFF10FC04A95E0C85D297AE48ABB5D1515D13B52` |
| [`ucie_ltsm.vo`](ucie_ltsm.vo) | Reusable wide-diagnostic core view; synthesis/functional-simulation evidence only | 944,809 | `34756D33181875CB10D05FEBB60E079814EEB98301CB9FA01BE0F5F08BDEF969` |

## Provenance

- Tool: Quartus Prime Lite 23.1std.1, EDA Netlist Writer 23.1std.1.
- Device: Cyclone 10 LP `10CL025YU256C8G`.
- Source checkpoint: wrapper verification commit `23205f08f16230bdc4925b38cbf2eb9535afc69f` plus the release documentation/evidence commit that contains this manifest.
- Generated: 2026-08-31.
- Wrapper command:

  ```powershell
  .\scripts\export_quartus_netlist.ps1 `
    -Version v0.4-error-recovery `
    -Project ucie_ltsm_fpga `
    -OutputName ucie_ltsm_fpga_wrapper.vo
  ```

The wrapper exporter runs a full compile before writing the netlist. The core-only view was regenerated from the unmodified `ucie_ltsm` project after successful Analysis & Synthesis, then exported with the functional EDA Netlist Writer. The core top has 149 physical pins and does not fit the selected package, so no core-top fitter or timing claim is attached to `ucie_ltsm.vo`. The 119-pin wrapper is the fitted v0.4 implementation boundary.

## Review and limitations

- Both files expose the expected top module and were scanned for workspace, attachment, and private-reference paths; none are present.
- The files contain Intel FPGA primitives and notices and require matching Intel simulation libraries for functional simulation.
- They are not RTL, post-route timing netlists, ASIC standard-cell netlists, bitstreams, or board-level signoff evidence.
- The wrapper build has positive internal 80 MHz setup/hold slack, but board pin locations and external I/O delays are absent.
- Nothing in these files establishes analog PHY behavior, BER, interoperability, or UCIe compliance.

See the [FPGA/CSR wrapper result](../../../../docs/06_results/fpga_csr_wrapper.md) and [v0.4 milestone page](../../../../docs/versions/v0.4_error_recovery.md) for the qualified measurements and verification scope.
