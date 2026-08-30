# Documentation Map

The documentation follows the order in which a new reader usually needs the ideas.

1. [Getting started](00_getting_started/README.md) - UCIe, chiplets, and why link training exists.
2. [Glossary and abbreviation long forms](glossary.md) - canonical definitions for project terms.
3. [Architecture](01_ucie_architecture/README.md) - what this controller contains and what it abstracts.
4. [LTSM](02_ltssm/README.md) - state hierarchy, transitions, signals, timing, and errors.
5. [Algorithm](03_algorithm/README.md) - behavioral description and pseudocode before RTL syntax.
6. [RTL](04_rtl/README.md) - module hierarchy and SystemVerilog mapping.
7. [Verification](05_verification/README.md) - directed testing, UVM, assertions, and gaps.
8. [Results](06_results/README.md) - reproducible Questa and Quartus evidence.
9. [Versions](versions/README.md) - what each stable milestone adds.

Supporting material:

- [Project glossary](glossary.md)
- [Requirements traceability](requirements_traceability.md)
- [Repository audit and migration map](repository_audit.md)
- [Incremental design, verification, and release workflow](development_workflow.md)
- [Research/journal plan](journal_plan.md) - proposed work, not completed evidence
- [Repository-wide documentation status](../DOCUMENTATION_STATUS.md)

## Evidence vocabulary

- **Implemented** means behavior is present in the checked RTL.
- **Tested** means a named test exercises the behavior and the latest recorded run passed.
- **Specification-aligned** means the model intentionally follows a referenced structural or behavioral concept.
- **Planned** means no implementation claim is being made.
- **UCIe compliant** is not used because the project lacks a complete PHY and official compliance evidence.
