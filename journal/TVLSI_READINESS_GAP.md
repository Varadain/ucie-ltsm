# TVLSI Readiness Gap

## Current judgment

The repository supports a careful paper draft and reproducibility package, but
not yet a strong TVLSI submission. The controller is a bounded UCIe 2.0-derived
digital subset, and the strongest implementation result is an unconstrained-I/O
FPGA wrapper fit. TVLSI reviewers are likely to ask for stronger novelty,
quantitative comparison, implementation depth, and coverage closure.

## Must resolve before submission

1. **Author and ethics metadata.** Add complete author names, affiliations,
   emails, ORCIDs, contribution statements, funding/conflict disclosures,
   biographies, and author-approved AI-use disclosure.
2. **Coverage closure.** Run with a license/tool flow that produces native
   functional and code coverage. Publish the coverage model, exclusions,
   per-bin closure, and uncovered behavior. Explicit counters are useful but
   are not a substitute for coverage closure.
3. **Implementation comparison.** Add a fair, controlled baseline or ablation:
   controller-only versus integrated engines, bypassed versus production path,
   and wide diagnostic ports versus CSR wrapper. Use identical tool/device/
   constraints and report deltas without mixing map and fit values.
4. **Physical credibility.** Prefer a board-level demonstration with assigned
   pins and external I/O constraints, or an ASIC flow with reproducible library,
   constraints, area, power methodology, and multi-corner timing. Do not add
   fabricated or estimated PPA.
5. **Broader protocol depth.** Replace more `phase_done_i` abstractions with
   implemented and independently verified MBINIT/MBTRAIN behavior, or narrow
   the venue/title further.
6. **Independent replication.** Re-run the documented scripts from a clean
   clone and archive hashes, tool logs, and environment details. A second
   machine/operator replication would materially strengthen the artifact.
7. **Literature completion.** Perform IEEE Xplore/Scopus/Web of Science searches
   with recorded queries and dates; resolve the two metadata-check entries and
   verify that no directly comparable open UCIe LTSM RTL paper is missed.

## Strongly recommended

- Add mutation or fault-injection experiments demonstrating that assertions,
  predictor checks, and scenario counters detect seeded defects.
- Add formal proofs for compact safety properties or clearly label bounded
  formal results.
- Add CDC/RDC, lint, and synthesis warning triage.
- Measure simulation cost per seed and report reproducibility variance.
- Add a two-end behavioral link partner and multi-rate/retrain experiments.
- Obtain advisor/coauthor review of the novelty statement and venue fit.

## Submission stop conditions

Do not submit while any of these are true:

- a claim uses “compliant,” “complete,” “silicon-ready,” or “signoff”;
- author/ORCID/biography/AI-disclosure fields are placeholders;
- a numerical result lacks a traceability ID;
- a figure lacks editable source and provenance;
- private specification material is embedded or staged;
- the paper presents the wide core as fitted or presents internal-clock STA as
  board timing closure; or
- references marked “metadata check required” remain unresolved.
