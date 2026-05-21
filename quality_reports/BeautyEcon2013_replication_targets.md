# Replication Targets: 江求川、张克中 (2013)

**Paper:** 中国劳动力市场中的"美貌经济学"：身材重要吗？
**Journal:** 经济学（季刊）Vol.12 No.3, pp.981–1002
**Data:** CHNS 2006 cross-section
**Script:** `replications/BeautyEcon2013/R/replicate.R`
**Date added:** 2026-05-21

---

## Sample Sizes

| Sample | Paper N | Tolerance | Notes |
|--------|---------|-----------|-------|
| Employment total | 2,304 | ±200 | Urban, non-agri, age M≤55/F≤50 |
| Employment female | 1,081 | ±100 | |
| Employment male | 1,161 | ±100 | |
| Income female | 552 | ±100 | Employed + non-missing C8 |
| Income male | 748 | ±100 | |

---

## Table 2: Female Income (OLS, Panel A — BMI dummies, Model 7)

| Variable | Paper β | Paper t | Significance | Notes |
|----------|---------|---------|--------------|-------|
| Height | 0.019 | 3.888 | *** | Per cm; primary beauty measure |
| Underweight | −0.035 | −0.499 | n.s. | BMI < 30th percentile |
| Overweight | −0.154 | −2.301 | ** | BMI > 70th percentile |
| N | 523 | — | — | M7 drops obs with missing dietary vars |
| Adj R² | 0.225 | — | — | |

## Table 2: Female Income (OLS, Panel B — height + weight, Model 7)

| Variable | Paper β | Paper t | Significance | Notes |
|----------|---------|---------|--------------|-------|
| Height | 0.022 | 4.569 | *** | |
| Weight | −0.004 | −1.906 | * | |
| N | 523 | — | — | |

---

## Table 3: Male Income (OLS, Panel A — BMI dummies, Model 7)

| Variable | Paper β | Paper t | Significance | Notes |
|----------|---------|---------|--------------|-------|
| Height | −0.001 | −0.214 | n.s. | No height premium for men |
| Underweight | −0.113 | −1.474 | n.s. | |
| Overweight | 0.006 | 0.127 | n.s. | |
| N | 702 | — | — | |
| Adj R² | 0.190 | — | — | |

---

## Table 6: Employment Probit

### Female, Panel B (height + weight), Model 7
| Variable | Paper β | Paper t | Significance |
|----------|---------|---------|--------------|
| Height | 0.016 | 1.398 | n.s. |
| Weight | −0.011 | −2.381 | ** |
| N | 931 | — | — |

### Female, Panel A (BMI dummies), Model 7
| Variable | Paper AME | Paper t |
|----------|-----------|---------|
| Overweight | −0.101 | −2.51 |

---

## Key Economic Findings to Verify

1. **Female height premium**: significant (~0.019***/cm) → replicate sign AND significance
2. **Male height premium**: null (t < 1) → replicate non-significance
3. **Female overweight penalty in employment** (AME ≈ -0.101)
4. **Female weight employment**: -0.011** (each kg reduces employment probability)
5. **No beauty effect on male income**: all BMI terms null for males

---

## Known Deviations (Acceptable)

1. Service industry proxy (Table 5): B4 ∈ {4,5} — paper uses precise consumer-contact definition
2. BMI percentile cutoffs: within income/employment samples separately (may differ from paper)
3. QR bootstrap R=200 (plan: 500)
4. "越胖越健康" dietary attitude variable not identified in pact_12
5. HC1 robust SE (paper doesn't specify SE type)
6. Model 7 = M5 + cohort×province (NOT M6 + cohort×province based on bmi_over comparison)
