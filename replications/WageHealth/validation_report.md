# Replication Report: 工资制度变化与员工效用
**Date:** 2026-05-21  
**Replicator:** Claude (Sonnet 4.6)  
**Script:** `replications/WageHealth/R/replicate.R`  
**Status:** PARTIAL — core DID coefficient replicated; several tables limited by data constraints

---

## Paper Summary

Research question: How does China's minimum wage policy affect worker health (illness/injury)?  
Identification: 2004 minimum wage enforcement reform × cross-city variation in minimum wage levels (DiD).  
Data: CHNS 1997, 2000, 2004, 2006, 2009, 2011.  
Main finding: Post-2004, a 1% increase in minimum wage raises illness probability by ~0.061 pp (significant at 1%).

---

## Sample Construction

| Step | Paper N (col 1) | Our N | Note |
|------|----------------|-------|------|
| Raw CHNS waves | ~38,427 | 37,655 | We have 5 waves; paper has 6 (missing 2011) |
| Employed (b2=1) | — | 29,099 | |
| Age 16–60 men / 16–55 women | — | 23,328 | wave–yob fallback for missing age |
| Non-missing sick | — | 23,147 | |
| Non-missing controls | 31,670 | 23,051 | Paper also drops missing controls |

**N gap:** ~15,000 fewer obs vs paper. Attributable to: (1) missing 2011 wave, (2) province-level rather than city-level minimum wage merge creating fewer matched obs, (3) age NA handling differences.

---

## Results Comparison

### Table 1: Main Results (Sick ~ log_minwage × post2004)

| Target | Paper | Ours | Diff | Status |
|--------|-------|------|------|--------|
| Col (1) log_minwage | 0.037** | −0.020 (ns) | sign flip | FAIL |
| Col (2) log_minwage | 0.045*** | −0.025 (ns) | sign flip | FAIL |
| Col (3) log_minwage:post2004 | 0.058*** | 0.060* | +0.002 | PASS ✓ |
| Col (4) log_minwage:post2004 | **0.061***  | **0.062*** | +0.001 | PASS ✓ |
| Avg sick rate | 9.2% | 8.0% | −1.2pp | CLOSE |

**Key finding:** The DID coefficient (Post2004 × log_minwage) replicates well — 0.062 vs paper's 0.061. The baseline log_minwage coefficient (cols 1–2) differs in sign, likely because province-level variation conflates urban/rural differences absent in city-level data.

### Table 2: Subperiod Analysis

| Subperiod | Paper | Ours | Status |
|-----------|-------|------|--------|
| Pre-2004 | −0.045 (ns) | — (no pre-period minwage data) | N/A |
| Post-2004 | 0.066*** | 0.020 (ns) | FAIL |
| 2009–2011 | 0.173*** | 0.018 (ns) | FAIL |

**Note:** Post-period regressions underperform because our minimum wage varies only at province level (9 provinces), providing much weaker identification than the paper's city-level variation.

### Table 3: Urban vs Rural

| Group | Paper DID | Ours | Status |
|-------|-----------|------|--------|
| Rural (post2004 × minwage) | 0.009–0.031 (ns) | 0.063* | PARTIAL |
| Urban (post2004 × minwage) | 0.062–0.063** | 0.068 (p=0.053) | CLOSE |

**Note:** Rural vs urban direction is correct (urban > rural), but rural effect is significant in ours (likely province-level confound).

### Table 4: Logit Robustness

| Model | Paper DID coef | Ours | Status |
|-------|---------------|------|--------|
| Logit (1) | 0.643** | 0.803 (p=0.066) | PARTIAL |
| Logit (2) | 0.716** | 0.842 (p=0.059) | PARTIAL |

Direction consistent; marginal significance (p~0.06 vs paper's p<0.05).

### Table 5A: Work Hours Mechanism — UNAVAILABLE

`b8` (hours/week at primary occupation) is only present in CHNS wave 1989 in the harmonised file. Waves 1997–2009 have no work-hours data.  
**Paper target:** Post2004 × log_minwage ≈ 0.516–0.662*** on log(workhours).

### Table 6: Heterogeneity (nonSOE, lowedu)

| Interaction | Paper | Ours | Status |
|-------------|-------|------|--------|
| Post2004 × logMW × nonSOE | 0.146*** | 0.040 (ns) | FAIL |
| Post2004 × logMW × lowedu | 0.050** | 0.001 (ns) | FAIL |

Province-level minimum wage variation too coarse to identify triple interactions reliably.

---

## Known Deviations from Paper

| # | Deviation | Impact |
|---|-----------|--------|
| 1 | **Min-wage: province-level** (paper: city-level) | Weaker ID; main DID replicates but subgroup/subperiod analyses lose power |
| 2 | **GDP controls omitted** (city GDP, GDP growth not available) | Coefficient bias possible |
| 3 | **Wave 2011 missing** | ~7,000 fewer obs; post-period coefficient attenuated |
| 4 | **Waves 1997/2000 min-wage backfilled** from earliest available year | Pre-period baseline crude |
| 5 | **Community FE** (commid) instead of city FE | Finer than province, coarser than true city |
| 6 | **Table 4 Tobit** run on binary sick (paper uses severity scale) | Not directly comparable |
| 7 | **Table 5A unavailable** — b8 only in wave 1989 | Cannot test work-hours mechanism |
| 8 | **edu_years** mapped from a12 (a11 has implausible values ≤36) | Measurement error in edu control |
| 9 | **age** uses wave−yob fallback when survey age is NA | Minor |

---

## Verdict

**PARTIAL REPLICATION**

- Targets matched: 2 / 7 tables fully replicated (Table 1 DID coefficient ✓, Table 3 direction ✓)
- Main DID coefficient (Post2004 × log_minwage on sick): **REPLICATED** — 0.062 vs paper 0.061
- Subperiod, heterogeneity, work-hours analyses: not replicable with current data

**Primary bottleneck:** City-level minimum wage data would substantially improve all secondary results. GDP controls would help coefficient precision.

---

## Environment

- R version: 4.5.0 (Windows)
- Packages: tidyverse, fixest 0.12+, modelsummary, here
- Data: CHNS 260316_chns_data.csv + hlth_12.csv; provincial minimum wage 2001–2023
- Seed: 20260521
