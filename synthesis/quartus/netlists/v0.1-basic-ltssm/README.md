# v0.1 Quartus Functional Netlist

[`ucie_ltsm.vo`](ucie_ltsm.vo) is the Quartus-generated functional Verilog simulation netlist for the `v0.1-basic-ltssm` release.

| Property | Value |
|---|---|
| Generator | Quartus Prime EDA Netlist Writer 23.1std.1 Build 993 |
| Device | Cyclone 10 LP `10CL025YU256C8G` |
| Format | Verilog functional simulation netlist |
| Intended simulator | Questa Intel FPGA with the matching Intel simulation libraries |
| Source identity | The commit referenced by tag `v0.1-basic-ltssm` |
| SHA-256 | `EC6887689F53E5B71CCCD5FD536CC24699EB19EF6DBCA7803C4798BBB9341D60` |

Regenerate from the repository root:

```powershell
.\scripts\export_quartus_netlist.ps1
```

The script runs a clean full Quartus compilation, writes through a temporary path without spaces to avoid a Quartus EDA Netlist Writer path limitation observed on Windows, and copies only the resulting `.vo` into this reviewed directory.

This file is generated evidence, not the editable design source. It contains Intel device primitives and is not an ASIC standard-cell netlist, a programming image, or a claim of board-level timing closure. Its use is subject to the notice emitted by Quartus at the top of the file.
