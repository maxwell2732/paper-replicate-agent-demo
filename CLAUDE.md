# Project Reference — MIMIC-IV Empirical Replication Agent

> **Note:** This repository now uses **GitHub Copilot** as the primary AI assistant.
> The main instructions file for Copilot is `.github/copilot-instructions.md`.
> This file is kept as a project reference document.

**Project:** MIMIC-IV Empirical Replication Agent
**Institution:** China Agricultural University
**Branch:** main

---

## Core Principles

- **Plan first** -- enter plan mode before non-trivial tasks; save plans to `quality_reports/plans/`
- **Verify after** -- run scripts and confirm outputs match targets at the end of every task
- **Replicate before extending** -- match published results exactly before any modifications
- **Quality gates** -- nothing ships below 80/100
- **[LEARN] tags** -- when corrected, save `[LEARN:category] wrong → right` to MEMORY.md

---

## Folder Structure

```
paper-replicate-agent-demo/
├── CLAUDE.md                    # This file
├── .claude/                     # Rules, skills, agents, hooks
├── papers/                      # Source PDFs and original replication packages
│   └── [PaperName]/
│       ├── original_paper.pdf
│       ├── supplementary.pdf
│       ├── *.do / *.R           # Original Stata/R code (if provided)
│       └── README.md
├── data/                        # Datasets (gitignored — sensitive MIMIC-IV data)
├── replications/                # Our replication scripts and outputs
│   └── [PaperName]/
│       ├── R/replicate.R
│       ├── R/figures/
│       ├── R/results/
│       ├── python/replicate.py  # (if Python replication needed)
│       └── validation_report.md
├── reports/                     # Polished final replication reports
├── scripts/                     # Utility scripts (quality_score.py, helpers)
│   └── R/                       # Shared R utility functions
├── quality_reports/             # Plans, session logs, replication targets
│   ├── plans/
│   ├── specs/
│   ├── session_logs/
│   ├── merges/
│   └── [Paper]_replication_targets.md
├── explorations/                # Exploratory analysis sandbox
│   └── ARCHIVE/
├── master_supporting_docs/      # Methodology reference papers and slides
│   ├── supporting_papers/
│   └── supporting_slides/
└── templates/                   # Session log, quality report templates
```

---

## Commands

```bash
# Collect data from MIMIC-IV PostgreSQL into data/
Rscript scripts/R/collect_data.R

# Run R replication script
Rscript replications/[PaperName]/R/replicate.R

# Run Python replication script
python replications/[PaperName]/python/replicate.py

# Quality score
python scripts/quality_score.py replications/[PaperName]/R/replicate.R
```

---

## Quality Thresholds

| Score | Gate | Meaning |
|-------|------|---------|
| 80 | Commit | Good enough to save |
| 90 | PR | Ready for deployment |
| 95 | Excellence | Aspirational |

---

## Workflow Quick Reference

| Task | What It Does |
|------|-------------|
| Replicate a paper | Full 6-phase replication pipeline |
| Data analysis | End-to-end R analysis |
| R code review | R code quality review |
| Manuscript review | Manuscript review |
| Literature review | Literature search + synthesis |
| Research ideation | Research questions + strategies |
| Proofread | Grammar/typo review of reports |

---

## Active Replications

| Paper | Status | Targets | Pass | Fail | Notes |
|-------|--------|---------|------|------|-------|
| *(add your study here)* | — | — | — | — | MIMIC-IV |

---

## MIMIC-IV Data Notes

- **Data location:** `data/` (gitignored — sensitive)
- **Access:** PhysioNet Data Use Agreement + CITI training required; see [physionet.org/content/mimiciv](https://physionet.org/content/mimiciv/)
- **Key identifiers:** `subject_id` (patient), `hadm_id` (hospital admission), `stay_id` (ICU stay)
- **Core modules:** `hosp/` (admissions, diagnoses, labs, prescriptions) and `icu/` (icustays, chartevents)
- **ICD codes:** Both ICD-9-CM and ICD-10-CM used; verify with `diagnoses_icd` `icd_version` column
- **Time variables:** Use `admittime`/`dischtime` for hospital stay; `intime`/`outtime` for ICU stay
- **De-identification:** Dates are shifted per patient; use relative times, not absolute calendar dates
