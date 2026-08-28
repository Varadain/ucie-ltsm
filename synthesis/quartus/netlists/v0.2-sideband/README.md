# v0.2 Quartus Functional Netlist

[`ucie_ltsm.vo`](ucie_ltsm.vo) is the Quartus-generated functional Verilog simulation netlist for the `v0.2-sideband` release.

| Property | Value |
|---|---|
| Generator | Quartus Prime EDA Netlist Writer 23.1std.1 Build 993 |
| Device | Cyclone 10 LP `10CL025YU256C8G` |
| Format | Verilog functional simulation netlist |
| Intended simulator | Questa Intel FPGA with matching Intel simulation libraries |
| Source identity | The commit referenced by tag `v0.2-sideband` |
| SHA-256 | `0BA5B37014F247C18A611ABCB4DC085B74211307124B67CDC453AE0364AA1985` |

Regenerate from the repository root:

```powershell
.\scripts\export_quartus_netlist.ps1 -Version v0.2-sideband
```

The script runs a full Quartus compilation, writes the EDA output through a temporary path without spaces, and copies only the resulting `.vo` into this reviewed directory. It passes `--write_settings_files=off` to the EDA writer.

This generated evidence contains Intel device primitives. It is not editable RTL, an ASIC standard-cell netlist, a programming image, board-level signoff, or evidence of UCIe compliance. Its use is subject to the notice emitted by Quartus at the top of the file.
