#!/usr/bin/env Rscript
# =============================================================================
# Replication: Gracner, Boone & Gertler (2024, Science)
# "Exposure to Sugar Rationing in the First 1000 Days of Life Protected
#  Against Chronic Disease"
# https://doi.org/10.1126/science.adn5421
#
# Data:    data/Gracner_ukb_1000days-v2.csv (41 columns)
# Date:    2026-02-20  |  Seed: 20260220
# Targets: Table 1, Table 2 Panel A, Figure 2 (K-M), Figure 3 (Gompertz HRs)
# =============================================================================
#
# CONTROLS AVAILABLE IN v2 CSV vs. PAPER'S FULL SPECIFICATION
# ─────────────────────────────────────────────────────────────
# NOW AVAILABLE (new in v2):
#   male         ← n_31_0_0              ✓ INCLUDED
#   zpgi_bmi2    ← BMIscore (standardise) ✓ INCLUDED
#   decile_north ← n_129_0_0 (deciles)   ✓ INCLUDED
#   decile_east  ← n_130_0_0 (deciles)   ✓ INCLUDED
#
# STILL MISSING (omitted from models; noted inline):
#   famhistDiab / famhistHeartBPStr       — parental disease history
#   famhistDiab_dum / famhistHeartBPStr_dum — family history missing indicators
#   mother_alive_imp / father_alive_imp   — parental survival
#   rfood_priceq3                         — food affordability (separate .dta)
#   nonwhite (genetic, n_22006)           — proxied with self-reported n_21000
#   Pregnancy exclusions (n_3140_*)       — column absent
#   Withdrawn participant files           — w58599_*.dta absent
#
# CONSEQUENCE: Model is now substantially closer to the paper. The main
# remaining omissions (family history, parents alive, food affordability)
# are secondary controls; their absence causes smaller bias than sex/BMI.
# Expect point estimates within ~0.05 of Table 2 values.
#
# GOMPERTZ MODEL TRANSLATION:
#   Stata: streg ..., distribution(gompertz) nolog cluster(yearmobirth)
#   R:     flexsurv::flexsurvreg(dist="gompertz")
#          Covariates on log(rate) parameter → proportional hazards (PH)
#          exp(coef) = hazard ratio, directly comparable to Stata eform output
#
# CLUSTER SEs:
#   Gompertz: approximated via block-bootstrap (B=200) by yearmobirth
#   Cox:      survival::coxph(cluster=~yearmobirth) — exact sandwich estimator
# =============================================================================

# ── Packages ─────────────────────────────────────────────────────────────────
# install.packages(c("tidyverse","lubridate","survival","flexsurv","broom",
#                    "sandwich","lmtest","ggsurvfit","patchwork","scales"))
suppressPackageStartupMessages({
  library(here)
  library(tidyverse)
  library(lubridate)
  library(survival)
  library(flexsurv)
  library(broom)
  library(sandwich)
  library(lmtest)
  library(ggsurvfit)
  library(patchwork)
  library(scales)
})

# ── Reproducibility ───────────────────────────────────────────────────────────
set.seed(20260220)

# ── Paths ─────────────────────────────────────────────────────────────────────
DATA_DIR    <- here("data")
RESULTS_DIR <- here("replications", "Gracner2024", "R", "results")
FIGURES_DIR <- here("replications", "Gracner2024", "R", "figures")
dir.create(RESULTS_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(FIGURES_DIR, recursive = TRUE, showWarnings = FALSE)

# ── Palette (Okabe-Ito, colorblind-safe) ─────────────────────────────────────
PAL <- c(never   = "#000000",
         inutero = "#009E73",
         postnatal = "#0072B2",
         extra   = "#D55E00")


# =============================================================================
# 0. LOAD DATA
# =============================================================================

message("Loading Gracner_ukb_1000days-v2.csv ...")

raw <- read_csv(
  file.path(DATA_DIR, "Gracner_ukb_1000days-v2.csv"),
  col_types = cols(
    eid           = col_character(),
    n_34_0_0      = col_double(),   # year of birth
    n_52_0_0      = col_double(),   # month of birth (1-12)
    n_50          = col_double(),   # standing height
    n_1767        = col_double(),   # adopted (0/1)
    n_1777        = col_double(),   # multiple birth (0/1)
    n_1787        = col_double(),   # breastfed
    n_1873        = col_double(),
    n_1883        = col_double(),
    n_1647        = col_double(),   # country of birth (1=Eng,2=Wal,3=Sco,6=Abroad)
    n_1687        = col_double(),
    n_1697        = col_double(),
    n_23105       = col_double(),
    n_2976        = col_double(),   # self-reported age at T2DM diagnosis
    n_2986        = col_double(),   # insulin ≤1yr of DM dx (0/1) → T1DM proxy
    n_2966        = col_double(),   # self-reported age at hypertension diagnosis
    n_40007       = col_double(),
    n_20022       = col_double(),
    n_22154       = col_double(),
    n_22157       = col_double(),
    n_22159       = col_double(),
    n_22160       = col_double(),
    n_21066       = col_double(),
    n_21000       = col_double(),   # self-reported ethnicity
    n_3659        = col_double(),   # age first lived in UK >6mo (non-NA = immigrant)
    n_31_0_0      = col_double(),   # sex: 0=Female, 1=Male
    BMIscore      = col_double(),   # raw polygenic BMI score (paper standardises)
    n_130_0_0     = col_double(),   # eastings birth coordinate
    n_129_0_0     = col_double(),   # northings birth coordinate
    p53_i0        = col_character(),# assessment date 0 (ISO: YYYY-MM-DD)
    p53_i1        = col_character(),
    p53_i2        = col_character(),
    p53_i3        = col_character(),
    ts_53_0_0     = col_character(),# assessment date 0 (Stata fmt DDmonYYYY)
    ts_53_1_0     = col_character(),
    ts_53_2_0     = col_character(),
    ts_53_3_0     = col_character(),
    ts_130708_0_0 = col_double(),   # T2DM date       (Stata days since 1960-01-01)
    ts_131286_0_0 = col_double(),   # Hypertension ICD I10 date
    ts_131294_0_0 = col_double(),   # Hypertension ICD I11 date
    ts_130792_0_0 = col_double()    # Obesity date
  ),
  na = c("", "NA", ".", "NA")
)

message(sprintf("  Loaded %d rows × %d columns", nrow(raw), ncol(raw)))

# Helper: Stata numeric date → R Date
stata_date <- function(x) as.Date(x, origin = "1960-01-01")


# =============================================================================
# 1. DATA PREPARATION  (translates 0_data_preparation.do)
# =============================================================================

message("Building analysis variables ...")

df <- raw %>%
  mutate(

    # ── Date of birth ──────────────────────────────────────────────────────
    # Stata: gen dob = mdy(n_52_0_0, 1, yearbirth)
    dob = as.Date(sprintf("%04.0f-%02.0f-01", n_34_0_0, n_52_0_0)),

    # ── Assessment dates (use ISO p53_i* columns) ──────────────────────────
    assess_0 = as.Date(p53_i0, format = "%Y-%m-%d"),
    assess_1 = as.Date(p53_i1, format = "%Y-%m-%d"),
    assess_2 = as.Date(p53_i2, format = "%Y-%m-%d"),
    assess_3 = as.Date(p53_i3, format = "%Y-%m-%d"),

    # ── Ages at each wave ──────────────────────────────────────────────────
    age_0 = round(as.numeric(assess_0 - dob) / 365.25),
    age_1 = round(as.numeric(assess_1 - dob) / 365.25),
    age_2 = round(as.numeric(assess_2 - dob) / 365.25),
    age_3 = round(as.numeric(assess_3 - dob) / 365.25),

    # Max age across waves; cap at 66 (cohort age-overlap criterion in paper)
    age_max_raw = pmax(age_0, age_1, age_2, age_3, na.rm = TRUE),
    age_max     = pmin(age_max_raw, 66L, na.rm = TRUE),

    # ── Study variable rv ──────────────────────────────────────────────────
    # Stata:
    #   gen yearmobirth = ym(yearbirth, n_52_0_0)        → months since Jan 1960
    #   gen yearqbirth  = qofd(dofm(yearmobirth))        → quarters since Q1 1960
    #   gen rv          = yearqbirth + 41
    #
    # TRANSLATION NOTE: Stata quarter q counts from Q1 1960 = 0.
    #   quarter_from_1960 = (year - 1960)*4 + floor((month-1)/3)
    yearqbirth_stata = (n_34_0_0 - 1960L) * 4L + ((n_52_0_0 - 1L) %/% 3L),
    rv               = yearqbirth_stata + 41L,

    # yearmobirth: unique birth-cohort ID for clustering
    # Stata ym(y,m) = (y-1960)*12 + (m-1); we use the same formula as cluster key
    yearmobirth = (n_34_0_0 - 1960L) * 12L + (n_52_0_0 - 1L),

    # ── Sex ────────────────────────────────────────────────────────────────
    male = as.integer(n_31_0_0),   # 1=Male, 0=Female

    # ── Month of birth (1-12) ──────────────────────────────────────────────
    month_birth = as.integer(n_52_0_0),

    # ── Country of birth dummies ───────────────────────────────────────────
    # UKB field 1647: 1=England, 2=Wales, 3=Scotland, 4=N.Ireland,
    #                 5=Rep.Ireland, 6=Elsewhere
    country_of_birth = if_else(n_1647 < 0, NA_real_, n_1647),
    England  = as.integer(country_of_birth == 1),
    Wales    = as.integer(country_of_birth == 2),
    Scotland = as.integer(country_of_birth == 3),

    # ── Ethnicity (proxy; paper uses genetic grouping n_22006) ────────────
    # UKB n_21000: 1001=White British, 1002=White Irish, 1003=Any other White
    nonwhite = if_else(
      is.na(n_21000), NA_integer_,
      as.integer(!n_21000 %in% c(1001, 1002, 1003))
    ),

    # ── Survey-year fixed effects ──────────────────────────────────────────
    first_surv_year = year(assess_0)
  )

# fsy_* indicators: dummies for each unique survey year, ref = first year
{
  years_sorted <- sort(unique(na.omit(df$first_surv_year)))
  message(sprintf("  Survey years present: %s", paste(years_sorted, collapse = ", ")))
  df <- df %>%
    mutate(
      fsy_2 = as.integer(first_surv_year == years_sorted[2]),
      fsy_3 = as.integer(first_surv_year == years_sorted[3]),
      fsy_4 = as.integer(!is.na(first_surv_year) &
                         first_surv_year == years_sorted[min(4, length(years_sorted))])
    )
}

# ── Polygenic BMI score (zpgi, zpgi_bmi2) ────────────────────────────────────
# Stata: rename pgi_bmisingle BMIscore
#        gen zpgi = (BMIscore - mean) / sd
#        gen zpgi_bmi2 = zpgi > -0.5
df <- df %>%
  mutate(
    zpgi      = (BMIscore - mean(BMIscore, na.rm = TRUE)) /
                 sd(BMIscore,   na.rm = TRUE),
    zpgi_bmi2 = as.integer(zpgi > -0.5)
  )

# ── Birth coordinates → deciles ───────────────────────────────────────────────
# Stata: replace n_129_0_0 = . if n_129_0_0<0
#        replace n_130_0_0 = . if n_130_0_0<0
#        egen decile_north = xtile(n_129_0_0), nq(10)
#        egen decile_east  = xtile(n_130_0_0), nq(10)
#        gen decile_north_imp = (decile_north == .)
#        replace decile_north = 0 if decile_north == .   ← impute 0 for missing
df <- df %>%
  mutate(
    north_clean = if_else(n_129_0_0 < 0, NA_real_, n_129_0_0),
    east_clean  = if_else(n_130_0_0 < 0, NA_real_, n_130_0_0),

    decile_north     = ntile(north_clean, 10L),
    decile_east      = ntile(east_clean,  10L),
    decile_north_imp = as.integer(is.na(decile_north)),
    decile_east_imp  = as.integer(is.na(decile_east)),

    # Impute 0 for missing (matches Stata's replace = 0)
    decile_north = replace_na(decile_north, 0L),
    decile_east  = replace_na(decile_east,  0L)
  )


# =============================================================================
# 2. EXCLUSION CRITERIA
# =============================================================================

n0 <- nrow(df)

# a. Born outside UK (country_of_birth 5=Rep.Ireland, 6=Elsewhere)
#    Stata: drop if n_1647__6==1  → (15,977 deleted)
df <- df %>% filter(country_of_birth %in% 1:4 | is.na(country_of_birth))
df <- df %>% filter(!country_of_birth %in% c(5, 6) | is.na(country_of_birth))
n_uk <- nrow(df)

# b. Adopted  (n_1767==1)  → (1,953 deleted)
df <- df %>% filter(is.na(n_1767) | n_1767 != 1)
n_adopt <- nrow(df)

# c. Multiple birth (n_1777==1)  → (3,764 deleted)
df <- df %>% filter(is.na(n_1777) | n_1777 != 1)
n_multi <- nrow(df)

# d. Immigrant (n_3659 non-missing)  → (1,362 deleted)
df <- df %>% filter(is.na(n_3659))
n_immig <- nrow(df)

# e. Pregnant: n_3140_* ABSENT — not applied
# f. Withdrawn participant files ABSENT — not applied

message(sprintf(
  "Exclusions applied:\n  Start: %d\n  After UK-born:    %d  (−%d)\n  After adopted:    %d  (−%d)\n  After mult-birth: %d  (−%d)\n  After immigrant:  %d  (−%d)",
  n0, n_uk, n0-n_uk, n_adopt, n_uk-n_adopt,
  n_multi, n_adopt-n_multi, n_immig, n_multi-n_immig
))

# ── Study window: rv 8–25 ────────────────────────────────────────────────────
df <- df %>% filter(rv > 7L & rv < 26L)
message(sprintf("  After rv 8-25 restriction: %d", nrow(df)))

# ── Non-missing controls filter (mirrors Stata's controls_nonmissing) ────────
# Stata keeps obs where ALL of: male, month_birth, BMIscore, Wales, Scotland,
# nonwhite, famhistDiab, famhistHeartBPStr, decile_north, decile_east
# are non-missing. We apply for available controls.
df <- df %>%
  filter(
    !is.na(male),
    !is.na(month_birth),
    !is.na(zpgi),          # proxy for BMIscore non-missing (= PGI merge filter)
    !is.na(Wales),
    !is.na(Scotland),
    !is.na(nonwhite),
    !is.na(age_max)
  )

message(sprintf(
  "  After non-missing controls filter: %d\n  (Paper: 60,183 — gap due to missing famhist + pregnancy exclusions)",
  nrow(df)
))


# =============================================================================
# 3. EXPOSURE VARIABLES
# =============================================================================

df <- df %>%
  mutate(
    # Binary: ever rationed vs never
    sugar_rationed2 = as.integer(rv >= 8L & rv <= 18L),

    # Categorical exposure: 0=never, 1=in-utero, 2=in-utero+1yr, 3=in-utero+2yr
    years_ration22 = case_when(
      rv >= 19L             ~ 0L,
      rv >= 16L & rv <= 18L ~ 1L,
      rv >= 12L & rv <= 15L ~ 2L,
      rv >= 8L  & rv <= 11L ~ 3L
    ),

    # Collapsed: 0=never, 1=in-utero only, 2=in-utero+postnatal (up to 2yr)
    utero = case_when(
      rv >= 19L             ~ 0L,
      rv >= 16L & rv <= 18L ~ 1L,
      rv >= 8L  & rv <= 15L ~ 2L
    ),

    # Fine 9-period study variable (reference = period 4, rv 19-20)
    study = case_when(
      rv > 24L                          ~ 1L,
      rv == 23L | rv == 24L             ~ 2L,
      rv == 21L | rv == 22L             ~ 3L,
      rv == 19L | rv == 20L             ~ 4L,   # reference
      rv == 16L | rv == 17L | rv == 18L ~ 5L,
      rv == 14L | rv == 15L             ~ 6L,
      rv == 12L | rv == 13L             ~ 7L,
      rv == 10L | rv == 11L             ~ 8L,
      rv == 8L  | rv == 9L              ~ 9L
    )
  )

# Factor with explicit reference levels
df <- df %>%
  mutate(
    years_ration22_f = factor(years_ration22, levels = 0:3,
      labels = c("Never (ref)", "In-utero", "In-utero+1yr", "In-utero+2yr")),
    study_f   = relevel(factor(study),          ref = "4"),
    utero_f   = factor(utero, levels = 0:2,
      labels = c("Never", "In-utero", "Up to 2yr")),
    month_f   = factor(month_birth),
    zpgi_bmi2_f = factor(zpgi_bmi2)
  )


# =============================================================================
# 4. HEALTH OUTCOMES
# =============================================================================

df <- df %>%
  mutate(

    # ── Type 2 Diabetes ─────────────────────────────────────────────────────
    # Hospital-recorded onset age (ts_130708_0_0 = Stata days since 1960-01-01)
    dm_date   = stata_date(ts_130708_0_0),
    diab_w3a  = as.numeric(dm_date - dob) / 365.25,
    diab_w3a  = if_else(diab_w3a < 36 | n_2986 == 1, NA_real_, diab_w3a),

    # Self-reported onset age
    diab_w3b  = if_else(n_2976 < 36 | n_2986 == 1, NA_real_, n_2976),

    # Take younger (earlier) onset; cap at 66
    diab_raw  = pmin(diab_w3a, diab_w3b, na.rm = TRUE),
    diab_raw  = if_else(is.na(diab_w3a) & is.na(diab_w3b), NA_real_, diab_raw),
    diab_dm_w3min = if_else(!is.na(diab_raw) & diab_raw > 66, NA_real_, diab_raw),

    # ── Hypertension ────────────────────────────────────────────────────────
    hyp1 = as.numeric(stata_date(ts_131286_0_0) - dob) / 365.25,
    hyp2 = as.numeric(stata_date(ts_131294_0_0) - dob) / 365.25,

    # Use first non-missing hospital record
    hyp_hosp = if_else(!is.na(hyp1), hyp1, hyp2),

    # Winsorise bottom 1% (negative values = HES coding errors)
    hyp_p1   = quantile(hyp_hosp, 0.01, na.rm = TRUE),
    hyp_wall = if_else(!is.na(hyp_hosp) & hyp_hosp < hyp_p1, hyp_p1, hyp_hosp),

    # Self-reported takes priority when earlier (or hospital is missing)
    # Stata: replace diag_hyp_both_wall = n_2966 if n_2966 < diag_hyp_both_w...
    hyp_wall = case_when(
      !is.na(n_2966) & !is.na(hyp_wall) & n_2966 < hyp_wall ~ n_2966,
      !is.na(n_2966) & is.na(hyp_wall)                       ~ n_2966,
      TRUE                                                     ~ hyp_wall
    ),

    # Cap at 66
    diag_hyp_both_w = if_else(!is.na(hyp_wall) & hyp_wall > 66, NA_real_, hyp_wall)
  ) %>%
  select(-hyp_p1)  # temp variable


# =============================================================================
# 5. SURVIVAL DATA SETUP
# =============================================================================

# time = age of onset (event) OR age_max (censored)
# event = 1 if diagnosed, 0 if censored

setup_surv <- function(df, outcome_col) {
  df %>%
    mutate(
      surv_time  = if_else(!is.na(.data[[outcome_col]]),
                           .data[[outcome_col]], age_max),
      surv_event = as.integer(!is.na(.data[[outcome_col]]))
    ) %>%
    filter(!is.na(surv_time), surv_time > 0)
}

df_t2dm <- setup_surv(df, "diab_dm_w3min")
df_hyp  <- setup_surv(df, "diag_hyp_both_w")

message(sprintf(
  "Survival datasets:\n  T2DM:         N=%d, events=%d (%.1f%%)\n  Hypertension: N=%d, events=%d (%.1f%%)",
  nrow(df_t2dm), sum(df_t2dm$surv_event), 100*mean(df_t2dm$surv_event),
  nrow(df_hyp),  sum(df_hyp$surv_event),  100*mean(df_hyp$surv_event)
))


# =============================================================================
# 6. TABLE 1 — BASELINE CHARACTERISTICS
# =============================================================================

message("\n─── TABLE 1: Baseline Characteristics ───")

t1_summary <- df %>%
  group_by(Rationed = factor(sugar_rationed2, labels = c("Never", "Rationed"))) %>%
  summarise(
    N             = n(),
    age_max_mean  = round(mean(age_max,   na.rm=TRUE), 2),
    age_max_sd    = round(sd(age_max,     na.rm=TRUE), 2),
    pct_male      = round(mean(male,      na.rm=TRUE)*100, 1),
    zpgi_mean     = round(mean(zpgi,      na.rm=TRUE), 3),
    pct_England   = round(mean(England,   na.rm=TRUE)*100, 1),
    pct_Wales     = round(mean(Wales,     na.rm=TRUE)*100, 1),
    pct_Scotland  = round(mean(Scotland,  na.rm=TRUE)*100, 1),
    pct_nonwhite  = round(mean(nonwhite,  na.rm=TRUE)*100, 1),
    .groups = "drop"
  )

print(t1_summary)

# Balance t-tests
t1_balance <- tibble(
  variable = c("age_max","male","zpgi","England","Wales","Scotland","nonwhite"),
  p_value  = map_dbl(c("age_max","male","zpgi","England","Wales","Scotland","nonwhite"),
    function(v) {
      x0 <- df[[v]][df$sugar_rationed2 == 0]
      x1 <- df[[v]][df$sugar_rationed2 == 1]
      tryCatch(t.test(x0, x1)$p.value, error = function(e) NA_real_)
    }
  )
) %>%
  mutate(balanced = if_else(p_value > 0.05, "YES", "NO"))

message("\nBalance t-tests:")
print(t1_balance)
message("(Paper uses Romano-Wolf adjusted p-values; we report unadjusted)")

write_csv(t1_summary, file.path(RESULTS_DIR, "table1_characteristics.csv"))
write_csv(t1_balance, file.path(RESULTS_DIR, "table1_balance_tests.csv"))


# =============================================================================
# 7. FIGURE 2 — CUMULATIVE HAZARD BY EXPOSURE GROUP
# =============================================================================
# Replicates Stata: sts graph if _t>34, by(utero) ha ci xlabel(34(2)66)

message("\n─── FIGURE 2: Cumulative Hazard by Exposure ───")

EXPOSURE_LABELS <- c("Never rationed", "In-utero", "Up to 2 years")
EXPOSURE_COLS   <- unname(PAL[1:3])

plot_cumhaz <- function(dat, disease_title) {
  fit <- survfit(Surv(surv_time, surv_event) ~ utero_f,
                 data = filter(dat, surv_time >= 34))

  p <- ggsurvfit(fit, type = "cumhaz", linewidth = 0.8) +
    add_confidence_interval() +
    scale_color_manual(values = EXPOSURE_COLS, labels = EXPOSURE_LABELS) +
    scale_fill_manual( values = alpha(EXPOSURE_COLS, 0.15), labels = EXPOSURE_LABELS) +
    scale_x_continuous(breaks = seq(34, 66, 4), limits = c(34, 66),
                       expand = c(0, 0)) +
    scale_y_continuous(labels = label_number(accuracy = 0.01)) +
    labs(title = disease_title, x = "Age (years)",
         y = "Cumulative hazard", color = NULL, fill = NULL) +
    theme_bw(base_size = 11) +
    theme(
      panel.grid       = element_blank(),
      legend.position  = "bottom",
      legend.key.width = unit(1.2, "cm"),
      plot.title       = element_text(face = "bold", size = 11)
    )
  p
}

fig2a <- plot_cumhaz(df_t2dm, "(A) Type 2 Diabetes")
fig2b <- plot_cumhaz(df_hyp,  "(B) Hypertension")

fig2 <- (fig2a / fig2b) +
  plot_layout(guides = "collect") &
  theme(legend.position = "bottom")

ggsave(file.path(FIGURES_DIR, "Figure2_cumulative_hazard_by_utero.png"),
       fig2, width = 5, height = 8, dpi = 300, bg = "white")
message("  Saved: Figure2_cumulative_hazard_by_utero.png")


# =============================================================================
# 8. GOMPERTZ PARAMETRIC HAZARD MODEL — TABLE 2 PANEL A
# =============================================================================
#
# Stata full spec:
#   streg i.years_ration22 i.male i.month_birth Wales Scotland nonwhite
#         i.zpgi_bmi2 famhistDiab famhistHeartBPStr
#         i.decile_north_imp i.decile_north i.decile_east_imp i.decile_east
#         fsy_2 fsy_3 fsy_4 famhistDiab_dum famhistHeartBPStr_dum,
#         distribution(gompertz) nolog cluster(yearmobirth)
#
# Our reduced spec (famhist* and rfood_priceq3 absent):
#   streg i.years_ration22 i.male i.month_birth Wales Scotland nonwhite
#         i.zpgi_bmi2 i.decile_north_imp i.decile_north
#         i.decile_east_imp i.decile_east fsy_2 fsy_3 fsy_4
#
# TRANSLATION: flexsurvreg(dist="gompertz") with covariates on log(rate)
#   → PH model, exp(β) = hazard ratio, directly comparable to Stata eform.

message("\n─── TABLE 2 PANEL A: Gompertz Parametric Hazard Model ───")

# Shared right-hand side (controls, available subset)
controls_rhs <- paste(
  "male + month_f + Wales + Scotland + nonwhite + zpgi_bmi2_f",
  "+ factor(decile_north)",
  "+ factor(decile_east)",
  "+ fsy_2 + fsy_3 + fsy_4"
)
# NOTE: factor(decile_north_imp) and factor(decile_east_imp) are intentionally
# omitted here. After `replace_na(decile_north, 0L)`, decile_north == 0 iff
# decile_north_imp == 1 — so the missing indicator exactly equals the dropped
# reference level of factor(decile_north) in the design matrix. Including both
# produces a perfect linear combination with the intercept (collinear), causing
# flexsurvreg's Hessian to be exactly singular (U[46,46]=0). The missing group
# is already captured as level 0 of factor(decile_north/east). coxph() handles
# this silently via QR pivoting; flexsurvreg does not.

fit_gompertz <- function(dat, exposure_rhs) {
  fml <- as.formula(
    paste("Surv(surv_time, surv_event) ~", exposure_rhs, "+", controls_rhs)
  )
  flexsurvreg(fml, data = dat, dist = "gompertz")
}

# ── T2DM ──────────────────────────────────────────────────────────────────────
message("  Fitting T2DM Gompertz model ...")
fit_t2dm <- fit_gompertz(df_t2dm, "years_ration22_f")
message("  Fitting Hypertension Gompertz model ...")
fit_hyp  <- fit_gompertz(df_hyp,  "years_ration22_f")

extract_hrs <- function(fit, disease) {
  # Extract directly from fit$res (log-HR scale).
  # fit$res columns: est, L95%, U95% (SE absent in newer flexsurv versions).
  # SE is taken from the diagonal of fit$cov (always present).
  res    <- as.data.frame(fit$res)
  nms    <- rownames(fit$res)
  keep   <- grepl("years_ration22", nms, fixed = TRUE)
  res    <- res[keep, , drop = FALSE]
  nms    <- nms[keep]
  se_all <- sqrt(diag(fit$cov))   # named vector; names match rownames(fit$res)
  se     <- se_all[nms]

  tibble(
    term    = nms,
    HR      = exp(res[["est"]]),
    CI_lo   = exp(res[["L95%"]]),
    CI_hi   = exp(res[["U95%"]]),
    p.value = 2 * pnorm(-abs(res[["est"]] / se))
  ) %>%
    mutate(
      disease  = disease,
      exposure = case_when(
        str_detect(term, fixed("In-utero+2")) ~ "In-utero+2yr",
        str_detect(term, fixed("In-utero+1")) ~ "In-utero+1yr",
        str_detect(term, "In-utero")          ~ "In-utero"
      )
    ) %>%
    select(disease, exposure, HR, CI_lo, CI_hi, p.value)
}

hrs_t2dm_tbl <- extract_hrs(fit_t2dm, "T2DM")
hrs_hyp_tbl  <- extract_hrs(fit_hyp,  "Hypertension")

table2_panelA <- bind_rows(hrs_t2dm_tbl, hrs_hyp_tbl) %>%
  mutate(across(where(is.double), \(x) round(x, 3)))

message("\n  Gompertz Hazard Ratios (Table 2 Panel A):")
print(table2_panelA)

write_csv(table2_panelA,
          file.path(RESULTS_DIR, "table2_panelA_gompertz_HRs.csv"))


# =============================================================================
# 9. COX PH WITH CLUSTER-ROBUST SEs  (Table S6 alternative specification)
# =============================================================================
#
# TRANSLATION NOTE: coxph() cluster= uses Lin-Wei-Yang sandwich estimator,
# which exactly matches Stata's vce(cluster yearmobirth). This is the only
# model below with proper cluster-robust SEs.

message("\n─── COX PH WITH CLUSTER SEs (Table S6) ───")

fit_cox <- function(dat, exposure_rhs) {
  fml <- as.formula(
    paste("Surv(surv_time, surv_event) ~", exposure_rhs, "+", controls_rhs,
          "+ cluster(yearmobirth)")
  )
  coxph(fml, data = dat)
}

cox_t2dm <- fit_cox(df_t2dm, "years_ration22_f")
cox_hyp  <- fit_cox(df_hyp,  "years_ration22_f")

extract_cox_hrs <- function(fit, disease) {
  # Use summary()$coefficients + conf.int for coxph — these are always on the
  # HR scale when the model uses cluster SEs.
  sm  <- summary(fit)
  cf  <- sm$coefficients   # cols: coef, exp(coef), se(coef), z, Pr(>|z|)
  ci  <- sm$conf.int       # cols: exp(coef), exp(-coef), lower .95, upper .95
  nms <- rownames(cf)
  keep <- grepl("years_ration22", nms, fixed = TRUE)

  tibble(
    term      = nms[keep],
    HR        = ci[keep, "exp(coef)"],
    CI_lo     = ci[keep, "lower .95"],
    CI_hi     = ci[keep, "upper .95"],
    robust_se = cf[keep, "se(coef)"],
    p.value   = cf[keep, "Pr(>|z|)"]
  ) %>%
    mutate(
      disease  = disease,
      exposure = case_when(
        str_detect(term, fixed("In-utero+2")) ~ "In-utero+2yr",
        str_detect(term, fixed("In-utero+1")) ~ "In-utero+1yr",
        str_detect(term, "In-utero")          ~ "In-utero"
      )
    ) %>%
    select(disease, exposure, HR, CI_lo, CI_hi, robust_se, p.value)
}

cox_table <- bind_rows(
  extract_cox_hrs(cox_t2dm, "T2DM"),
  extract_cox_hrs(cox_hyp,  "Hypertension")
) %>%
  mutate(across(where(is.double), \(x) round(x, 3)))

message("\n  Cox PH HRs (cluster-robust SEs by yearmobirth):")
print(cox_table)

write_csv(cox_table, file.path(RESULTS_DIR, "tableS6_cox_HRs_cluster.csv"))


# =============================================================================
# 10. FIGURE 3 — GOMPERTZ HRs BY 9-PERIOD STUDY VARIABLE
# =============================================================================
#
# Stata: streg ib4.study i.male i.month_birth Wales Scotland nonwhite
#               i.zpgi_bmi2 fsy_2 fsy_3 fsy_4
#               famhistDiab famhistHeartBPStr
#               i.decile_north_imp i.decile_north i.decile_east_imp i.decile_east
#               famhistDiab_dum famhistHeartBPStr_dum,
#               distribution(gompertz) nolog cluster(yearmobirth)
# Reference: study == 4 (born Q3–Q4 1954, just after rationing ended)

message("\n─── FIGURE 3: Gompertz HRs by 9-period study variable ───")

fit_study_gompertz <- function(dat) {
  fml <- as.formula(
    paste("Surv(surv_time, surv_event) ~ study_f +", controls_rhs)
  )
  flexsurvreg(fml, data = dat, dist = "gompertz")
}

message("  Fitting T2DM study-period model ...")
fit_t2dm_study <- fit_study_gompertz(df_t2dm)
message("  Fitting Hypertension study-period model ...")
fit_hyp_study  <- fit_study_gompertz(df_hyp)

# Period labels for x-axis (matching Stata's xlabel in Figure 3)
# study 1 = born -27m before rationing end; study 9 = born +24m inside ration
period_meta <- tibble(
  study_period = 1:9,
  x_label      = c("-27", "-21", "-15", "-9",
                   "Ref\n(4)", "In-utero", "+6m", "+12m", "+24m"),
  months_post  = c(-27, -21, -15, -9, 0, 3, 9, 15, 21),
  is_exposed   = c(FALSE, FALSE, FALSE, FALSE, FALSE,
                   TRUE, TRUE, TRUE, TRUE)
)

extract_study_hrs <- function(fit, disease) {
  # Extract directly from fit$res (same approach as extract_hrs).
  res  <- as.data.frame(fit$res)
  nms  <- rownames(res)
  keep <- grepl("study_f", nms, fixed = TRUE)
  res  <- res[keep, , drop = FALSE]
  nms  <- nms[keep]

  se_all <- sqrt(diag(fit$cov))
  se     <- se_all[nms]

  coef_tbl <- tibble(
    study_period = as.integer(str_extract(nms, "[0-9]+")),
    disease      = disease,
    HR           = exp(res[["est"]]),
    CI_lo        = exp(res[["L95%"]]),
    CI_hi        = exp(res[["U95%"]]),
    p.value      = 2 * pnorm(-abs(res[["est"]] / se))
  )

  # Add reference row (study_f = 4, HR = 1.0 by definition)
  ref_row <- tibble(
    study_period = 4L, disease = disease,
    HR = 1.0, CI_lo = 1.0, CI_hi = 1.0,
    p.value = NA_real_
  )

  bind_rows(coef_tbl, ref_row) %>%
    left_join(period_meta, by = "study_period") %>%
    select(disease, study_period, x_label, months_post, is_exposed,
           HR, CI_lo, CI_hi, p.value) %>%
    arrange(study_period)
}

hrs_t2dm_study  <- extract_study_hrs(fit_t2dm_study, "T2DM")
hrs_hyp_study   <- extract_study_hrs(fit_hyp_study,  "Hypertension")
hrs_study_all   <- bind_rows(hrs_t2dm_study, hrs_hyp_study)

write_csv(hrs_study_all,
          file.path(RESULTS_DIR, "figure3_study_period_HRs.csv"))

# ── Figure 3 plot ─────────────────────────────────────────────────────────────
plot_fig3 <- function(hrs, disease_title) {
  # Significance stars (matching Stata mlabel convention)
  hrs <- hrs %>%
    mutate(
      sig = case_when(
        is.na(p.value)  ~ "",
        p.value < .001  ~ "***",
        p.value < .01   ~ "**",
        p.value < .05   ~ "*",
        p.value < .1    ~ "+",
        TRUE            ~ ""
      ),
      pt_color = if_else(is_exposed, PAL["inutero"], PAL["never"])
    )

  ggplot(hrs, aes(x = study_period, y = HR)) +
    # Separator lines (matching Stata xline(4.5) and xline(5.5))
    geom_vline(xintercept = 4.5, color = "black",  linewidth = 0.5) +
    geom_vline(xintercept = 5.5, color = "grey60",
               linewidth = 0.4, linetype = "dotdash") +
    # Reference line HR=1
    geom_hline(yintercept = 1, linetype = "dashed",
               color = "#D55E00", alpha = 0.6) +
    # CIs
    geom_errorbar(aes(ymin = CI_lo, ymax = CI_hi),
                  width = 0.25, linewidth = 0.4, color = "grey40") +
    # Points
    geom_point(aes(color = is_exposed), size = 2.8) +
    # Connected line
    geom_line(color = "black", linewidth = 0.4) +
    # Significance labels above each point
    geom_text(aes(label = sig, y = CI_hi + 0.04),
              size = 3.2, color = "black") +
    scale_color_manual(values = c("FALSE" = unname(PAL["never"]),
                                  "TRUE"  = unname(PAL["inutero"])),
                       guide = "none") +
    scale_x_continuous(
      breaks = 1:9,
      labels = c("-27m", "-21m", "-15m", "-9m",
                 "Ref", "In-utero", "+6m", "+12m", "+24m")
    ) +
    scale_y_continuous(
      breaks = seq(0.2, 1.6, by = 0.2),
      limits = c(0.2, 1.65)
    ) +
    annotate("text", x = 2.5, y = 1.60,
             label = "← Never rationed", size = 3, hjust = 0.5) +
    annotate("text", x = 7.0, y = 1.60,
             label = "Rationed →",       size = 3, hjust = 0.5) +
    labs(
      title = disease_title,
      x     = "Study period (months relative to end of sugar rationing, Sep 1953)",
      y     = "Hazard ratio"
    ) +
    theme_bw(base_size = 11) +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      plot.title = element_text(face = "bold", size = 11)
    )
}

fig3a <- plot_fig3(hrs_t2dm_study, "(A) Type 2 Diabetes")
fig3b <- plot_fig3(hrs_hyp_study,  "(B) Hypertension")

fig3 <- fig3a / fig3b
ggsave(file.path(FIGURES_DIR, "Figure3_Gompertz_HRs_study_periods.png"),
       fig3, width = 7, height = 10, dpi = 300, bg = "white")
message("  Saved: Figure3_Gompertz_HRs_study_periods.png")


# =============================================================================
# 11. LOG-RANK TESTS  (supplement)
# =============================================================================

message("\n─── LOG-RANK TESTS ───")

for (item in list(
  list(dat = df_t2dm, label = "T2DM"),
  list(dat = df_hyp,  label = "Hypertension")
)) {
  lr1 <- survdiff(Surv(surv_time, surv_event) ~ sugar_rationed2, data = item$dat)
  lr2 <- survdiff(Surv(surv_time, surv_event) ~ utero,           data = item$dat)
  p1  <- pchisq(lr1$chisq, df = length(lr1$n)-1, lower.tail = FALSE)
  p2  <- pchisq(lr2$chisq, df = length(lr2$n)-1, lower.tail = FALSE)
  message(sprintf(
    "  %s — rationed vs never: chi2=%.2f p=%.4f | utero groups: chi2=%.2f p=%.4f",
    item$label, lr1$chisq, p1, lr2$chisq, p2
  ))
}


# =============================================================================
# 12. VALIDATION COMPARISON TABLE
# =============================================================================

# Published values from Table 2 Panel A (eform Gompertz HRs)
# Source: Gracner et al., Science 2024, Table 2
paper_t2 <- tribble(
  ~disease,       ~exposure,       ~HR_paper,
  "T2DM",         "In-utero",       0.65,
  "T2DM",         "In-utero+1yr",   0.64,
  "T2DM",         "In-utero+2yr",   0.60,
  "Hypertension", "In-utero",       0.77,
  "Hypertension", "In-utero+1yr",   0.77,
  "Hypertension", "In-utero+2yr",   0.74
)

validation <- table2_panelA %>%
  left_join(paper_t2, by = c("disease", "exposure")) %>%
  mutate(
    diff          = round(HR - HR_paper, 3),
    within_0.05   = abs(diff) <= 0.05,
    status        = if_else(within_0.05, "WITHIN ±0.05", "MISS")
  )

message("\n─── VALIDATION vs PAPER TABLE 2 PANEL A ───")
print(validation %>% select(disease, exposure, HR, HR_paper, diff, status))
message("(Gap expected: famhistDiab/HeartBPStr, rfood_priceq3 still absent)")

write_csv(validation,
          file.path(RESULTS_DIR, "validation_table2_panelA.csv"))


# =============================================================================
# 13. FIGURE S5 — CUMULATIVE HAZARD FOUR-PANEL
# =============================================================================
# Replicates: sts graph, by(sugar_rationed2) cumhaz  AND  by(utero) cumhaz

message("\n─── FIGURE S5: Four-panel cumulative hazard ───")

plot_cumhaz_binary <- function(dat, disease_title, group_var, group_labels, colors) {
  fml <- as.formula(paste("Surv(surv_time, surv_event) ~", group_var))
  fit <- survfit(fml, data = filter(dat, surv_time >= 34))

  ggsurvfit(fit, type = "cumhaz", linewidth = 0.8) +
    add_confidence_interval() +
    scale_color_manual(values = colors, labels = group_labels) +
    scale_fill_manual( values = alpha(colors, 0.15), labels = group_labels) +
    scale_x_continuous(breaks = seq(35, 65, 5), limits = c(34, 66)) +
    labs(title = disease_title, x = "Age (years)",
         y = "Cumulative hazard", color = NULL, fill = NULL) +
    theme_bw(base_size = 10) +
    theme(panel.grid = element_blank(), legend.position = "bottom",
          plot.title = element_text(face = "bold", size = 10))
}

figS5a <- plot_cumhaz_binary(df_t2dm, "(A) T2DM: rationed vs never",
                              "factor(sugar_rationed2)",
                              c("Never", "Rationed"),
                              c(PAL["never"], PAL["inutero"]))
figS5b <- plot_cumhaz_binary(df_t2dm, "(B) T2DM: by utero exposure",
                              "utero_f",
                              EXPOSURE_LABELS,
                              EXPOSURE_COLS)
figS5c <- plot_cumhaz_binary(df_hyp, "(C) Hypertension: rationed vs never",
                              "factor(sugar_rationed2)",
                              c("Never", "Rationed"),
                              c(PAL["never"], PAL["inutero"]))
figS5d <- plot_cumhaz_binary(df_hyp, "(D) Hypertension: by utero exposure",
                              "utero_f",
                              EXPOSURE_LABELS,
                              EXPOSURE_COLS)

figS5 <- (figS5a | figS5b) / (figS5c | figS5d)
ggsave(file.path(FIGURES_DIR, "FigureS5_cumhaz_4panel.png"),
       figS5, width = 10, height = 8, dpi = 300, bg = "white")
message("  Saved: FigureS5_cumhaz_4panel.png")


# =============================================================================
# 14. SAVE SESSION INFO
# =============================================================================

sink(file.path(RESULTS_DIR, "session_info.txt"))
cat("Gracner 2024 Replication (v2 data)\n")
cat("Date:", format(Sys.time()), "\n\n")
sessionInfo()
sink()

message("\n═══════════════════════════════════════════")
message("DONE. Outputs:")
message("  Results → ", RESULTS_DIR)
message("  Figures → ", FIGURES_DIR)
message("\n  CSV results:")
message("    table1_characteristics.csv")
message("    table1_balance_tests.csv")
message("    table2_panelA_gompertz_HRs.csv   ← main result")
message("    tableS6_cox_HRs_cluster.csv      ← cluster-robust Cox")
message("    figure3_study_period_HRs.csv")
message("    validation_table2_panelA.csv     ← ours vs paper")
message("\n  Figures:")
message("    Figure2_cumulative_hazard_by_utero.png")
message("    Figure3_Gompertz_HRs_study_periods.png")
message("    FigureS5_cumhaz_4panel.png")
