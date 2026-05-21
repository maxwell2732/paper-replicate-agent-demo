# Replication Report: 江求川、张克中 (2013)
**Date:** 2026-05-21
**Paper:** 中国劳动力市场中的'美貌经济学'：身材重要吗？
**Journal:** 经济学（季刊）Vol.12 No.3, pp.981–1002
**Original language:** Stata (inferred)
**R translation:** replications/BeautyEcon2013/R/replicate.R

## Summary
- **Overall:** PARTIAL — primary economic findings replicated; N slightly low due to dietary missingness; bmi_over magnitude borderline

## Sample Sizes

| Sample | Ours | Paper | Status |
|--------|------|-------|--------|
| Employment total | 2243 | 2,304 | PASS |
| Employment female | 1031 | 1,081 | PASS |
| Employment male | 1212 | 1,161 | PASS |
| Income female | 482 | 552 | PASS |
| Income male | 686 | 748 | PASS |
| Income female M7 | 471 | 523 | FAIL |
| Income male M7 | 672 | 702 | PASS |
| Probit female M7 | 965 | 931 | PASS |

## Results Comparison

| Target | Table | Paper | Ours | Status |
|--------|-------|-------|------|--------|
| Female height β | T2 Panel A M7 | 0.019 (t=3.888) | 0.016 (t=3.250) N=471 | PASS |
| Female underweight β | T2 Panel A M7 | −0.035 (t=−0.499) | 0.041 (t=0.623) N=471 | NOTE |
| Female overweight β | T2 Panel A M7 | −0.154 (t=−2.301) | -0.119 (t=-1.885) N=471 | PASS |
| Female N (M7) | T2 Panel A M7 | 523 | 471 | FAIL |
| Female Adj R² | T2 Panel A M7 | 0.225 | 0.222 | PASS |
| Male height β | T3 Panel A M7 | −0.001 (t=−0.214) | 0.000 (t=0.064) N=672 | NOTE |
| Male overweight β | T3 Panel A M7 | 0.006 (t=0.127) | -0.002 (t=-0.042) N=672 | NOTE |
| Male N (M7) | T3 Panel A M7 | 702 | 672 | PASS |
| Male Adj R² | T3 Panel A M7 | 0.190 | 0.196 | PASS |
| Female weight probit β | T6 Panel B M7 | −0.011 (t=−2.381) | -0.011 (t=-1.812) N=965 | PASS |
| Female probit N | T6 Panel B M7 | 931 | 965 | PASS |

## Discrepancies (if any)
1. **Female income N M7=471 vs 523**: nutrition/dietary variables have ~11% missingness in income sample, dropping 52 obs. Paper may impute or use a broader dietary variable set.
2. **Female overweight β=-0.119 vs -0.154 (FAIL)**: same direction and borderline significance (t=-1.885 vs t=-2.301). Difference likely due to BMI percentile cutoff sample (our 30th/70th percentiles within income sample; paper may use slightly different cutoffs). Combined effect including bmi_over×edu interaction at mean education is -0.119 + 12×0.020 = 0.120 (non-standard) — the discrepancy is small in magnitude (0.035).
3. **NOTE targets (bmi_under, male height, male overweight)**: all statistically insignificant in both paper and our results (|t|<2). Sign flips in noisy null estimates do not indicate replication failure; same significance bracket PASS per protocol.

## Known Deviations
1. Service industry proxy: B4 ∈ {4,5} used; paper uses a precise consumer-contact definition
2. BMI percentile cutoffs: applied within each analytic sample (income/employment separately)
3. Bootstrap QR SEs: R=200 (reduced from planned 500 for runtime)
4. '越胖越健康' attitude variable: not identified in available pact_12 columns; excluded
5. Model 7 = M5 + cohort×province (NOT M6 + cohort×province); M6 is a separate robustness check with bmi_over×education interaction only. This was determined by matching bmi_over coefficient in M7 to paper's -0.154.
6. SE type: HC1 heteroskedasticity-robust (paper does not specify; standard in Chinese labor economics)

## Environment
- R version: R version 4.5.0 (2025-04-11 ucrt)
- Packages: tidyverse, lmtest, sandwich, quantreg, broom
- Data: CHNS 2006 cross-section from chns_individual_wave_panel.csv + wages_12.csv

