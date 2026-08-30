# Version History

Version pages explain the engineering delta. Git tags preserve the exact source snapshot; source trees are not copied into this directory.

| Version | Addition | Status | Page |
|---|---|---|---|
| v0.1 | Basic hierarchical LTSM controller | Stable within stated scope | [Read](v0.1_basic_ltssm.md) |
| v0.2 | Bounded SBINIT sideband sequencing | Stable within stated scope | [Read](v0.2_sideband.md) |
| v0.2-random | Seeded constrained-domain UVM campaign | Stable verification-only update | [Read](v0.2_random_uvm.md) |
| v0.3 | Concrete training engines | Planned | [Roadmap](../../ROADMAP.md) |
| v0.4 | Expanded recovery/error behavior | Planned | [Roadmap](../../ROADMAP.md) |

To inspect a stable source snapshot:

```bash
git checkout v0.1-basic-ltssm
git checkout v0.2-sideband
git checkout v0.2-random-uvm
```
