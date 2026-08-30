# v0.2 Randomized UVM Netlist Identity

The `v0.2-random-uvm` update changes verification code and documentation only. Its synthesizable RTL and Quartus constraints are byte-for-byte identical to `v0.2-sideband`, so the reviewed functional netlist is intentionally not duplicated.

- Authoritative netlist: [`../v0.2-sideband/ucie_ltsm.vo`](../v0.2-sideband/ucie_ltsm.vo)
- SHA-256: `0BA5B37014F247C18A611ABCB4DC085B74211307124B67CDC453AE0364AA1985`
- Generator: Quartus Prime EDA Netlist Writer 23.1std.1 Build 993
- Device: Cyclone 10 LP `10CL025YU256C8G`
- RTL delta from `v0.2-sideband`: none

The netlist remains functional simulation evidence, not editable RTL, an ASIC standard-cell netlist, a programming image, board-level signoff, or evidence of UCIe compliance.
