---
paths:
  - "replications/**/*.R"
  - "replications/**/*.py"
  - "scripts/**/*.R"
  - "scripts/**/*.py"
---

# Replication-First Protocol

**Core principle:** Replicate original results to the dot BEFORE extending.

---

## Phase 0: Paper Intake

Before any coding:

- [ ] Read the full paper PDF; identify **every table and figure** that presents empirical results
- [ ] Record gold standard values in `quality_reports/[paper_name]_replication_targets.md`:

```markdown
## Replication Targets: [Paper Author (Year)]

| Target | Table/Figure | Value | SE/CI | N | Notes |
|--------|-------------|-------|-------|---|-------|
| Main HR | Table 2, Col 1 | 1.43 | (1.21–1.68) | 502,369 | Primary specification |
```

- [ ] Note the **Methods section** in full: sample inclusion/exclusion criteria, covariates, model type, SE clustering, software used
- [ ] Identify the **original code language** (Stata / R / Python / SAS) and what, if any, replication package exists

---

## Phase 1: Inventory & Data Audit

- [ ] Read the paper's replication README (if provided)
- [ ] Inventory replication package: language, data files, scripts, outputs
- [ ] Load provided dataset; compare to paper's described sample:
  - N (total, exposed, events)
  - Key variable distributions (means, % missing)
  - Inclusion/exclusion criteria — apply them in the paper's stated order
- [ ] Document any **discrepancies between available data and paper description** before coding

---

## Phase 2: Translate & Execute

- [ ] Follow `r-code-conventions.md` and `python-code-conventions.md` for all coding standards
- [ ] Translate line-by-line initially — **do NOT improve during replication**
- [ ] Match original specification exactly: covariates, sample restrictions, clustering, SE method
- [ ] Save all intermediate datasets as `.rds` (R) or `.parquet` / `.pkl` (Python)

### Stata → R Translation Pitfalls

| Stata | R Equivalent | Trap |
|-------|-------------|------|
| `stset time, failure(event==1) id(id)` | `Surv(time, event==1)` | Verify time-at-risk calculation is identical; `stset` supports late entry |
| `stcox x covars, cluster(id)` | `coxph(Surv(t,e) ~ x + covars, cluster=id)` | `cluster=` uses Lin-Wei-Yang SE; verify matches Stata robust |
| `reg y x, cluster(id)` | `feols(y ~ x, cluster = ~id)` | Stata clusters df-adjust differently from some R packages |
| `areg y x, absorb(id)` | `feols(y ~ x \| id)` | Check demeaning method matches |
| `probit` | `glm(family=binomial(link="probit"))` | Reference category must match |
| `logit` | `glm(family=binomial(link="logit"))` | Check if `xi:` prefix changes reference level |
| `bootstrap, reps(999)` | Depends on method | Match seed, reps, and bootstrap type exactly |
| `stcrreg` (competing risks) | `crr()` in `cmprsk` or `coxph(id=..., istate=...)` | Fine-Gray vs cause-specific hazard — must match paper |

### Stata → Python Translation Pitfalls

| Stata | Python Equivalent | Trap |
|-------|-----------------|------|
| `stset time, failure(event==1)` | `lifelines.CoxPHFitter(event_col=...)` | Verify time variable and event coding are identical |
| `stcox x covars, cluster(id)` | `CoxPHFitter().fit(df, duration_col, event_col, cluster_col=...)` | lifelines clustering may differ from Stata; compare SEs |
| `reg y x, cluster(id)` | `statsmodels.OLS().fit(cov_type='cluster', cov_kwds={'groups': ...})` | Check cluster column matches |
| `reghdfe y x, absorb(id year)` | `linearmodels.PanelOLS` or `pyhdfe` | FE absorption algorithm must be verified |
| `logit y x` | `statsmodels.Logit().fit()` | Optimization algorithm (Newton-Raphson vs BFGS) may give slightly different convergence |
| `stcrreg` (competing risks) | `lifelines.AalenJohansenFitter` or `scikit-survival` | Fine-Gray subdistribution HR — verify method |

---

## Phase 3: Verify Match

### Tolerance Thresholds

| Type | Tolerance | Rationale |
|------|-----------|-----------|
| Integers (N, events, counts) | Exact match | No reason for any difference |
| Point estimates (OR, HR, β) | ±0.01 | Rounding in paper display |
| Standard errors | ±0.05 | Bootstrap/clustering variation |
| P-values | Same significance bracket (< 0.05, < 0.01, < 0.001) | Exact p may differ slightly |
| Percentages | ±0.1pp | Display rounding |

### If Mismatch

**Do NOT proceed to extensions.** Isolate which step introduces the difference:
1. Sample size mismatch → check inclusion/exclusion criteria order, missing data handling
2. Point estimate mismatch → check covariate list, reference categories, model defaults
3. SE mismatch → check clustering level, SE computation method
4. P-value bracket mismatch → check multiple testing correction, one- vs two-sided test

Document all investigations even if unresolved.

### MIMIC-IV-Specific Considerations

- **Key identifiers:** `subject_id` (patient), `hadm_id` (hospital admission), `stay_id` (ICU stay); verify the correct join keys for each table
- **ICD codes:** Both ICD-9-CM and ICD-10-CM present; always filter on `icd_version` per the paper's specification
- **Outcome definition:** Verify exact outcome: `hospital_expire_flag` for in-hospital death; 28-day mortality requires date arithmetic from `admittime`; ICU mortality uses `icustays.dod` or `patients.dod`
- **Time variables:** Dates are shifted per patient — use relative durations (e.g., `dischtime - admittime`), not absolute calendar dates; ensure time-at-risk matches paper definition
- **Lab/chart values:** Multiple measurements per stay are common; apply the paper's stated aggregation rule (first value, last value, min, max, mean) within the specified time window
- **Exclusions:** Apply paper's stated exclusion criteria in order (e.g., age < 18, index admission only, missing key variables); document each step's effect on N
- **Competing risks:** Death in ICU vs. discharge alive is a common competing event; verify whether paper uses cause-specific or subdistribution (Fine-Gray) hazard

### Replication Report

Save to `replications/[paper_name]/validation_report.md` AND final polished version to `reports/[paper_name]_replication_report.md`:

```markdown
# Replication Report: [Paper Author (Year)]
**Date:** [YYYY-MM-DD]
**Original language:** [Stata/R/Python/SAS]
**R translation:** [replications/[paper]/R/replicate.R]
**Python translation:** [replications/[paper]/python/replicate.py]

## Summary
- **Targets checked / Passed / Failed:** N / M / K
- **Overall:** [REPLICATED / PARTIAL / FAILED]

## Results Comparison

| Target | Table/Figure | Paper | Ours | Diff | Status |
|--------|-------------|-------|------|------|--------|

## Discrepancies (if any)
- **Target:** X | **Investigation:** ... | **Resolution:** ...

## Environment
- Python version, R version, key packages (with versions), data source, MIMIC-IV version
```

---

## Phase 4: Only Then Extend

After replication is verified (all targets PASS or discrepancies documented with explanation):

- [ ] Commit replication scripts: `"Replicate [Paper] Table X -- all targets match"`
- [ ] Now extend with additional analyses (sensitivity checks, subgroups, alternative exposures)
- [ ] Each extension builds on the verified baseline
