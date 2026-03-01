# GitHub Copilot Instructions — MIMIC-IV Empirical Replication Agent

**Project:** MIMIC-IV Empirical Replication Agent
**Institution:** China Agricultural University

You are assisting with empirical replication of published academic papers using MIMIC-IV data.
Your role is that of a research contractor: plan the approach, write R/Python scripts, validate outputs
against published targets, document discrepancies, and report results.

---

## Core Principles

- **Plan first** — for non-trivial tasks, describe the approach and wait for approval before coding
- **Verify after** — run scripts and confirm outputs match targets at the end of every task
- **Replicate before extending** — match published results exactly before any modifications
- **Quality gates** — nothing ships below 80/100 (see Quality Gates section below)
- **[LEARN] tags** — when corrected, note `[LEARN:category] wrong → right` for MEMORY.md

---

## Project Layout

```
paper-replicate-agent-demo/
├── .github/copilot-instructions.md  # This file
├── papers/                          # Source PDFs and original replication packages
│   └── [PaperName]/
│       ├── original_paper.pdf
│       ├── supplementary.pdf
│       ├── *.do / *.R               # Original Stata/R code (if provided)
│       └── README.md
├── data/                            # Datasets (gitignored — sensitive MIMIC-IV data)
├── replications/                    # Our replication scripts and outputs
│   └── [PaperName]/
│       ├── R/replicate.R
│       ├── R/figures/
│       ├── R/results/
│       ├── python/replicate.py
│       └── validation_report.md
├── reports/                         # Polished final replication reports
├── scripts/                         # Utility scripts (quality_score.py, helpers)
│   └── R/                           # Shared R utility functions
├── quality_reports/                 # Plans, session logs, replication targets
│   ├── plans/
│   ├── specs/
│   ├── session_logs/
│   └── [Paper]_replication_targets.md
├── explorations/                    # Exploratory analysis sandbox
├── master_supporting_docs/          # Methodology reference papers and slides
└── templates/                       # Session log, quality report templates
```

---

## Replication Pipeline (6 Phases)

### Phase 0: Paper Intake

Before any coding:
- Read the full paper PDF; identify **every table and figure** with empirical results
- Record gold standard values in `quality_reports/[paper_name]_replication_targets.md`
- Note the Methods section in full: sample criteria, covariates, model type, SE clustering, software
- Identify the original code language (Stata/R/Python/SAS) and any replication package

### Phase 1: Inventory & Data Audit

- Load the dataset; compare to the paper's described sample (N, events, key variables)
- Apply inclusion/exclusion criteria in the paper's stated order
- Document any discrepancies between available data and paper description before coding

### Phase 2: Translate & Execute

- Translate line-by-line first — **do NOT improve during replication**
- Match original specification exactly: covariates, sample restrictions, clustering, SE method
- Save all intermediate datasets as `.rds` (R) or `.parquet`/`.pkl` (Python)
- Follow coding conventions in the sections below

#### Stata → R Translation Pitfalls

| Stata | R Equivalent | Watch Out For |
|-------|-------------|--------------|
| `stset time, failure(event==1) id(id)` | `Surv(time, event==1)` | Verify time-at-risk; `stset` supports late entry |
| `stcox x covars, cluster(id)` | `coxph(Surv(t,e) ~ x + covars, cluster=id)` | `cluster=` uses Lin-Wei-Yang SE |
| `reg y x, cluster(id)` | `feols(y ~ x, cluster = ~id)` | Stata clusters df-adjust differently |
| `areg y x, absorb(id)` | `feols(y ~ x \| id)` | Check demeaning method matches |
| `stcrreg` (competing risks) | `crr()` in `cmprsk` | Fine-Gray vs cause-specific hazard |

#### Stata → Python Translation Pitfalls

| Stata | Python Equivalent | Watch Out For |
|-------|-----------------|--------------|
| `stset time, failure(event==1)` | `lifelines.CoxPHFitter(event_col=...)` | Verify time variable and event coding |
| `stcox x covars, cluster(id)` | `CoxPHFitter().fit(..., cluster_col=...)` | lifelines clustering may differ |
| `reg y x, cluster(id)` | `statsmodels.OLS().fit(cov_type='cluster', ...)` | Check cluster column matches |
| `reghdfe y x, absorb(id year)` | `linearmodels.PanelOLS` or `pyhdfe` | FE absorption algorithm |
| `stcrreg` (competing risks) | `lifelines.AalenJohansenFitter` | Fine-Gray subdistribution HR |

### Phase 3: Verify Match

**Tolerance Thresholds:**

| Type | Tolerance |
|------|-----------|
| Integers (N, events, counts) | Exact match |
| Point estimates (OR, HR, β) | ±0.01 |
| Standard errors | ±0.05 |
| P-values | Same significance bracket (< 0.05, < 0.01, < 0.001) |
| Percentages | ±0.1pp |

If mismatch: **do NOT proceed to extensions**. Isolate the step that introduces the difference.

### Phase 4: Document Discrepancies

- Investigate every near-miss; document explanations
- Save to `replications/[paper]/validation_report.md`

### Phase 5: Report

Save polished report to `reports/[paper_name]_replication_report.md`:

```markdown
# Replication Report: [Paper Author (Year)]
**Date:** YYYY-MM-DD

## Summary
- Targets checked / Passed / Failed: N / M / K
- Overall: [REPLICATED / PARTIAL / FAILED]

## Results Comparison
| Target | Table/Figure | Paper | Ours | Diff | Status |

## Discrepancies
## Environment
```

---

## Quality Gates

Run `python scripts/quality_score.py <file>` to score any `.R`, `.py`, or `.qmd` file.

| Score | Gate |
|-------|------|
| ≥ 95 | Excellence (aspirational) |
| ≥ 90 | PR ready |
| ≥ 80 | Commit threshold |
| < 80  | Blocked — fix critical issues first |

### Scoring Rubric

**R Scripts (.R):**
| Severity | Issue | Deduction |
|----------|-------|-----------|
| Critical | Syntax errors | -100 |
| Critical | Hardcoded absolute paths | -20 |
| Critical | Missing `set.seed()` for stochastic code | -10 |
| Major | Missing figure generation | -5 |
| Major | Results not saved as `.rds` | -5 |

**Python Scripts (.py):**
| Severity | Issue | Deduction |
|----------|-------|-----------|
| Critical | Syntax errors | -100 |
| Critical | Hardcoded absolute paths | -20 |
| Critical | Missing random seed for stochastic code | -15 |
| Critical | Results not saved | -15 |
| Major | `inplace=True` in pandas | -5 |
| Major | Figure not saved at 300 DPI | -5 |

**Replication Reports (.md):**
| Severity | Issue | Deduction |
|----------|-------|-----------|
| Critical | Comparison table missing | -20 |
| Critical | Discrepancies not investigated | -15 |
| Major | Sample size not reported | -10 |
| Major | Verdict (REPLICATED/PARTIAL/FAILED) missing | -10 |

---

## R Code Conventions

- `set.seed()` called ONCE at top (use `YYYYMMDD` format)
- All packages loaded at top via `library()` — never `require()`
- All paths relative to repository root using `here::here()`
- `dir.create(..., recursive = TRUE)` for output directories
- `snake_case` naming; verb-noun pattern for functions (`run_simulation`, `fit_cox_model`)
- Comments explain **WHY**, not WHAT
- Lines ≤ 100 characters (exception: mathematical formulas with inline explanation comment)
- Figures: 300 DPI, transparent background, colorblind-safe palette (`viridis` or Okabe-Ito)
- Save every computed object with `saveRDS(result, here("replications", ..., "results", "name.rds"))`

**R Script Structure:**
```r
# Replication: [Paper Author (Year)]
# Date: YYYY-MM-DD
# Original: Stata / Python
# R version: X.Y.Z
# Key packages: survival X.X, fixest X.X

library(here)
library(tidyverse)
library(survival)

set.seed(YYYYMMDD)

data_dir    <- here("data")
results_dir <- here("replications", "[paper_name]", "R", "results")
dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)

# --- 1. Load Data ---
# --- 2. Sample Construction ---
# --- 3. Model Fitting ---
# --- 4. Save Results ---
```

---

## Python Code Conventions

- Always use `pathlib.Path` — never string concatenation for paths
- Seed at top: `random.seed(YYYYMMDD)` + `np.random.seed(YYYYMMDD)`
- All imports at top (stdlib → third-party → local)
- Never `inplace=True` in pandas; always `.copy()` when modifying a slice
- Save results as `.parquet` or `.pkl`; figures at 300 DPI with `bbox_inches="tight"`
- Never use `plt.show()` in scripts (breaks headless execution)
- Comment every Stata→Python translation decision with a `# TRANSLATION NOTE:`

**Okabe-Ito palette:**
```python
OKABE_ITO = ["#E69F00", "#56B4E9", "#009E73", "#F0E442",
             "#0072B2", "#D55E00", "#CC79A7", "#000000"]
```

---

## MIMIC-IV-Specific Considerations

- **Data location:** `data/` — gitignored; never commit MIMIC-IV data
- **Access:** PhysioNet Data Use Agreement + CITI training required; see [physionet.org/content/mimiciv](https://physionet.org/content/mimiciv/)
- **Key identifiers:** `subject_id` (patient), `hadm_id` (hospital admission), `stay_id` (ICU stay in `icu/icustays`)
- **Core modules used:** `hosp/` (admissions, patients, diagnoses_icd, labevents, prescriptions) and `icu/` (icustays, chartevents, outputevents)
- **ICD codes:** Both ICD-9-CM (`icd_version = 9`) and ICD-10-CM (`icd_version = 10`) present; always filter by version per paper's specification
- **Time variables:** Use `admittime`/`dischtime` for hospital LOS; `intime`/`outtime` for ICU LOS; dates are shifted per patient — use relative durations, not calendar dates
- **Outcomes:** Verify outcome definition: `hospital_expire_flag` (in-hospital death in `admissions`), 28-day mortality requires date arithmetic from `admittime`
- **Lab/chart values:** Multiple measurements per stay are common; apply the paper's stated aggregation rule (first value, last value, min, max, or mean within a time window)
- **Exclusions:** Apply paper's stated exclusions in order (e.g., age < 18, re-admissions, missing key variables); document each step's effect on N

### PostgreSQL Connection (R)

MIMIC-IV is hosted in a local PostgreSQL instance. Use the `data-collector` agent (`.claude/agents/data-collector.md`) to extract tables. The standard R connection is:

```r
library(DBI)
library(RPostgres)

con <- dbConnect(
  RPostgres::Postgres(),
  dbname   = "mimiciv",
  host     = "localhost",
  port     = 5432,
  user     = "postgres",
  password = Sys.getenv("MIMIC_DB_PASSWORD", unset = "hello")
)
```

**Read-only rule:** Only `SELECT` queries are permitted. The `data-collector` agent enforces this; replication scripts must also never call `INSERT`, `UPDATE`, `DELETE`, or any DDL on this connection.

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

## Active Replications

| Paper | Status | Notes |
|-------|--------|-------|
| *(add your study here)* | — | MIMIC-IV |

---

## Workflow Reminders

- Save plans to `quality_reports/plans/YYYY-MM-DD_short-description.md`
- Save session notes incrementally — don't batch
- After completing a task: run `python scripts/quality_score.py` and report the score
- Append any corrections as `[LEARN:category] wrong → right` in `MEMORY.md`
