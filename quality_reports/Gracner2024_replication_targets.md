# Replication Targets: Gracner, Boone & Gertler (2024, Science)
**Paper:** "Exposure to Sugar Rationing in the First 1000 Days of Life Protected Against Chronic Disease"
**DOI:** https://doi.org/10.1126/science.adn5421
**Date recorded:** 2026-02-20

---

## Sample (Table S1 / Methods)

| Target | Value | Source |
|--------|-------|--------|
| Final analytic sample N | 60,183 | 0_data_preparation.do line: `count // 60,183` |
| Born outside UK (excluded) | 15,977 | comment in do-file |
| Adopted (excluded) | 1,953 | comment |
| Multiple birth (excluded) | 3,764 | comment |
| Immigrants (excluded) | 1,362 | comment |
| Study window | rv 8–25 (Q4 1951 – Q1 1956) | do-file |
| Age follow-up cap | 66 years | do-file: `replace age_max=66 if age_max>66` |

---

## Table 1: Baseline Characteristics by Rationing Status

*(From paper Table 1; fill when paper Table 1 values are confirmed)*

| Variable | Never rationed (rv 19-25) | Rationed (rv 8-18) | p-value |
|----------|--------------------------|---------------------|---------|
| Mean max age | ~61 | ~63 | -- |
| Male (%) | ~54% | ~54% | (balance expected) |
| Nonwhite (%) | ~5% | ~5% | (balance expected) |
| England (%) | ~88% | ~88% | (balance expected) |

*Note: Paper reports Romano-Wolf corrected p-values; we report unadjusted t-test p-values.*

---

## Table 2 Panel A: Gompertz Hazard Ratios

*(Source: Science 2024, Table 2 Panel A. Exposure vs. never-rationed group.)*

### Type 2 Diabetes (diab_dm_w3min)

| Exposure | HR | 95% CI | p-value |
|----------|----|--------|---------|
| In-utero only (years_ration22=1) | 0.65 | -- | < 0.05 |
| In-utero + up to 1 year (=2) | 0.64 | -- | < 0.05 |
| In-utero + up to 2 years (=3) | 0.60 | -- | < 0.001 |

### Hypertension (diag_hyp_both_w)

| Exposure | HR | 95% CI | p-value |
|----------|----|--------|---------|
| In-utero only (years_ration22=1) | 0.77 | -- | < 0.05 |
| In-utero + up to 1 year (=2) | 0.77 | -- | < 0.001 |
| In-utero + up to 2 years (=3) | 0.74 | -- | < 0.001 |

*Model: Gompertz PH, cluster-robust SEs by yearmobirth, reference = never rationed*
*Controls: male, month_birth, Wales, Scotland, nonwhite, zpgi_bmi2, famhistDiab,*
*famhistHeartBPStr, decile_north/east (+ imputed), fsy_2-4, famhistDiab_dum, famhistHeartBPStr_dum*

---

## Table 2 Panel B: Delay in Age of Onset (stteffects ra)

*(Source: Science 2024, Table 2 Panel B)*

### Type 2 Diabetes

| Exposure | Delay (years) | SE | p-value |
|----------|---------------|----|---------|
| In-utero only | ~+4 years | -- | -- |
| In-utero + 1yr | ~+4 years | -- | -- |
| In-utero + 2yr | ~+4 years | -- | -- |

*Note: stteffects ra (regression adjustment) not replicated in current script.*
*Would require teffects or similar ATE estimation in R.*

---

## Figure 3: HRs by 9-Period Study Variable

| Study period | Label | Expected direction |
|-------------|-------|--------------------|
| 1–4 | Never/minimally exposed | HR ≈ 1.0 (flat) |
| 5 | In-utero | HR < 1 |
| 6–9 | In-utero + postnatal | HR < 1, declining |

*Reference: study period 4 (rv_sem1920 = born Q3-Q4 1954)*

---

## Known Deviations from Original

| Item | Original | Our Replication | Impact |
|------|----------|-----------------|--------|
| Key controls | male, zpgi_bmi2, famhistDiab, famhistHeartBPStr, decile_north/east | OMITTED | Point estimates will differ — PARTIAL REPLICATION |
| Cluster SEs | cluster(yearmobirth) in Gompertz | Not implemented in flexsurv; Cox has cluster SEs | SEs differ |
| Sample | 60,183 (with PGI merge + withdrawals) | Larger (missing exclusions) | N will differ |
| ethnicity | Genetic ethnic grouping (n_22006) | Self-reported (n_21000) | Minor differences |
| Pregnancy exclusion | Applied | NOT applied | Minor N difference |
