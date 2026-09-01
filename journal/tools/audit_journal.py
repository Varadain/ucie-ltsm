"""Fail-fast publication package audit."""

from __future__ import annotations

import re
import subprocess
from pathlib import Path
from xml.etree import ElementTree as ET


ROOT = Path(__file__).resolve().parents[2]
JOURNAL = ROOT / "journal"
MAIN = JOURNAL / "manuscript" / "main.tex"

REQUIRED = [
    "README.md", "project_evidence_matrix.md", "specification_scope.md",
    "novelty_audit.md", "literature_review_matrix.md", "reference_audit.md",
    "result_traceability.md", "target_journal_rules.md",
    "TVLSI_READINESS_GAP.md", "manuscript/main.tex",
    "manuscript/references.bib", "manuscript/main.pdf",
    "figures/figure_sources.md", "review/technical_consistency_check.md",
    "review/claim_evidence_check.md", "review/citation_check.md",
    "review/figure_quality_check.md", "review/journal_compliance_check.md",
]


def run(*args):
    return subprocess.run(args, cwd=ROOT, check=True, text=True,
                          capture_output=True).stdout


def main():
    errors = []
    for rel in REQUIRED:
        if not (JOURNAL / rel).exists():
            errors.append(f"missing required artifact: {rel}")

    expected_counts = {"source": 9, "svg": 12, "pdf": 12, "png": 12}
    for subdir, suffix in (("source", ".drawio"), ("svg", ".svg"),
                           ("pdf", ".pdf"), ("png", ".png")):
        files = sorted((JOURNAL / "figures" / subdir).glob(f"*{suffix}"))
        if len(files) != expected_counts[subdir]:
            errors.append(
                f"expected {expected_counts[subdir]} {suffix} figures, found {len(files)}"
            )
        if suffix in (".drawio", ".svg"):
            for path in files:
                try:
                    ET.parse(path)
                except Exception as exc:
                    errors.append(f"invalid XML {path}: {exc}")

    main_text = MAIN.read_text(encoding="utf-8")
    abstract = re.search(r"\\begin\{abstract\}(.*?)\\end\{abstract\}", main_text, re.S)
    if not abstract:
        errors.append("abstract not found")
    else:
        abstract_text = re.sub(r"\\[A-Za-z]+(?:\{[^}]*\})?", " ", abstract.group(1))
        words = re.findall(r"\b[\w'-]+\b", abstract_text)
        if len(words) > 250:
            errors.append(f"abstract has {len(words)} words (>250)")
        if re.search(r"\\cite|\\footnote|\$", abstract.group(1)):
            errors.append("abstract contains citation, footnote, or inline equation")

    bib_text = (JOURNAL / "manuscript" / "references.bib").read_text(encoding="utf-8")
    bib_keys = set(re.findall(r"@[A-Za-z]+\{([^,]+),", bib_text))
    section_text = "\n".join(p.read_text(encoding="utf-8") for p in
                             (JOURNAL / "manuscript" / "sections").glob("*.tex"))
    cited = set()
    for group in re.findall(r"\\cite\{([^}]+)\}", main_text + section_text):
        cited.update(x.strip() for x in group.split(","))
    missing_bib = cited - bib_keys
    if missing_bib:
        errors.append(f"cited BibTeX keys missing: {sorted(missing_bib)}")

    all_tex = main_text + "\n" + section_text
    for fig in re.findall(r"\\includegraphics(?:\[[^]]*\])?\{([^}]+)\}", all_tex):
        if not (JOURNAL / "figures" / "pdf" / fig).exists():
            errors.append(f"missing figure PDF referenced by LaTeX: {fig}")

    md_link = re.compile(r"\[[^]]+\]\(([^)]+)\)")
    for md in JOURNAL.rglob("*.md"):
        for target in md_link.findall(md.read_text(encoding="utf-8")):
            clean = target.split("#", 1)[0]
            if not clean or re.match(r"https?://", clean):
                continue
            if not (md.parent / clean).resolve().exists():
                errors.append(f"broken relative link in {md.relative_to(ROOT)}: {target}")

    try:
        pdfinfo = run("pdfinfo", str(JOURNAL / "manuscript" / "main.pdf"))
        match = re.search(r"^Pages:\s+(\d+)", pdfinfo, re.M)
        if not match or int(match.group(1)) != 12:
            errors.append("manuscript PDF is not the audited twelve-page build")
    except Exception as exc:
        errors.append(f"pdfinfo failed: {exc}")

    log_path = JOURNAL / "manuscript" / "main.log"
    if log_path.exists() and re.search(r"Undefined|undefined|Overfull|LaTeX Error|Package .* Error", log_path.read_text(errors="ignore")):
        errors.append("LaTeX log contains undefined/overfull/error diagnostic")

    tracked_private = run("git", "ls-files", "references_private").strip()
    if tracked_private:
        errors.append("private reference content is tracked by git")

    diff_check = subprocess.run(["git", "diff", "--check"], cwd=ROOT,
                                text=True, capture_output=True)
    if diff_check.returncode:
        errors.append("git diff --check failed:\n" + diff_check.stdout + diff_check.stderr)

    if errors:
        print("JOURNAL_AUDIT_FAIL")
        print("\n".join(errors))
        raise SystemExit(1)
    print(f"JOURNAL_AUDIT_PASS cited_refs={len(cited)} figures=12 pages=12")


if __name__ == "__main__":
    main()
