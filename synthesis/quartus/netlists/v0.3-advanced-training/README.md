# v0.3 Quartus Functional Netlist

[`ucie_ltsm.vo`](ucie_ltsm.vo) is the reviewed Quartus-generated functional Verilog simulation netlist for the `v0.3-advanced-training` release.

| Property | Value |
|---|---|
| Generator | Quartus Prime EDA Netlist Writer 23.1std.1 Build 993 |
| Device | Cyclone 10 LP `10CL025YU256C8G` |
| Format | Verilog functional simulation netlist |
| Intended simulator | Questa Intel FPGA with matching Intel simulation libraries |
| Source identity | The release commit referenced by annotated tag `v0.3-advanced-training` |
| SHA-256 | `09D414CA3B4CF192F8D83119F18AC6994FB0C4A6F707C0021E405D1B7AFEC04C` |
| Size | 931,416 bytes |

Regenerate from the repository root:

```powershell
.\scripts\export_quartus_netlist.ps1 -Version v0.3-advanced-training
```

The script runs a full Quartus compilation, writes the EDA output through a temporary path without spaces, and copies only the resulting `.vo` into this reviewed directory. It passes `--write_settings_files=off` to the EDA writer.

Review confirmed the expected training ports, Intel device primitives, standard Intel-generated license notice, and no repository-machine or private-reference path. The SHA-256 above identifies the exact reviewed bytes.

This generated evidence is not editable RTL, an ASIC standard-cell netlist, a programming image, board-level signoff, BER evidence, or proof of UCIe compliance. Its use is subject to the notice emitted by Quartus at the top of the file.
