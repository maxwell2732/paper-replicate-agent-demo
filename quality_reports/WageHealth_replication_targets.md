# Replication Targets: 工资制度变化与员工效用

## Paper Info
- **Title:** 工资制度变化与员工效用 (Wage System Changes and Employee Utility)
- **Data:** CHNS 1997, 2000, 2004, 2006, 2009, 2011
- **Estimator:** OLS-LPM, Logit, Tobit; city + year FE; SE clustered at city level

---

## Table 1: Baseline Results (N = 38,427 / 31,670)

| Variable | Col (1) | Col (2) | Col (3) | Col (4) |
|----------|---------|---------|---------|---------|
| log(Minwage) | 0.037** (t=2.41) | 0.045*** (t=3.04) | 0.002 (t=0.12) | 0.010 (t=0.51) |
| log(Minwage)×Post2004 | — | — | 0.058*** (t=2.80) | **0.061*** (t=2.79)** |
| Gender | — | −0.006* | — | −0.006* |
| log(Age) | — | 0.067*** | — | 0.068*** |
| Education | — | −0.006*** | — | −0.006*** |
| Avg sick rate | 9.3% | 9.2% | 9.3% | 9.2% |
| R² | 0.025 | 0.033 | 0.025 | 0.033 |

Controls (cols 2,4): Gender, log(Age), Education, GDP growth rate, log(GDP)  
FE: City + Year in all columns

---

## Table 2: Subperiod (N varies)

| Period | Col (1) no indivFE | Col (2) indivFE |
|--------|-------------------|-----------------|
| Pre-2004 | −0.102* (N=10,490) | −0.045 (N=8,752) |
| Post-2004 | 0.059** (N=27,937) | 0.066*** (N=22,918) |
| 2009–2011 | 0.171*** (N=13,583) | 0.173*** (N=10,555) |

---

## Table 3: Urban vs Rural (N varies)

| Sample | log(MW) | log(MW)×Post2004 |
|--------|---------|-----------------|
| Rural (1) | 0.036 | — |
| Rural (2) | 0.037 | — |
| Rural DID (1) | — | 0.009 (ns) |
| Rural DID (2) | — | 0.031 (ns) |
| Urban DID (3) | — | 0.062** |
| Urban DID (4) | — | 0.063** |

---

## Table 4: Logit/Tobit Robustness

| Model | log(MW)×Post2004 |
|-------|-----------------|
| Logit (1) | 0.643** |
| Logit (2) | 0.716** |
| Tobit (3) | 1.000* |
| Tobit (4) | 1.317** |

---

## Table 5A: Work Hours Mechanism (DV = log_workhours)

| Spec | log(MW)×Post2004 | N |
|------|-----------------|---|
| (1) no ctrl | 0.516*** | 21,761 |
| (2) ctrl | 0.662*** | 17,845 |
| (3) no ctrl | 0.022* | 38,365 |
| (4) ctrl | 0.039*** | 31,600 |

**STATUS: UNAVAILABLE** — b8 only in wave 1989 in harmonised CHNS file

---

## Table 6: Heterogeneity

| Interaction | Col (1) | Col (2) |
|-------------|---------|---------|
| log(MW)×Post2004×nonSOE | 0.066 (ns) | **0.146*** (t=2.58)** |
| log(MW)×Post2004×lowedu | **0.047** (t=2.13) | **0.050** (t=2.12) |

---

## Missing External Variables

| Variable | Required For | Source |
|----------|-------------|--------|
| City-level monthly minimum wage × year | Tables 1–6 (treatment) | Municipal gov't announcements, CLDS, or Ni & Wang (2018) dataset |
| City GDP (log) | Tables 1–4 controls | China City Statistical Yearbook |
| City GDP growth rate | Tables 1–4 controls | China City Statistical Yearbook |
| b8 (work hours, waves 1997–2009) | Table 5A | Raw CHNS employment module (not in harmonised file) |
| CHNS wave 2011 | All tables (adds ~7k obs) | CHNS 2011 public release |
| Sick severity measure | Table 4 Tobit | Raw CHNS health module (ordinal coding of M23) |
