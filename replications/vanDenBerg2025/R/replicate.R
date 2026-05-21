# =============================================================================
# Replication: van den Berg, von Hinke & Wang (2025)
# "Prenatal Sugar Exposure and Long-Run Outcomes" (PNAS, pgaf301)
#
# Replicates Table 1, Panel A (OLS) for 3 outcomes available in UKB data:
#   1. Years of schooling (edu_years)
#   2. Height in cm (height)
#   3. Type 2 diabetes binary (t2dm)
#
# Data:   data/260222_ukb_data.csv
# Output: replications/vanDenBerg2025/R/results/table1_replication.csv
# Author: Replication Agent
# Date:   2026-02-22
# =============================================================================

# ---- Phase 0: Packages & Paths -----------------------------------------------

suppressPackageStartupMessages({
  if (!requireNamespace("here",      quietly = TRUE)) install.packages("here")
  if (!requireNamespace("tidyverse", quietly = TRUE)) install.packages("tidyverse")
  if (!requireNamespace("sandwich",  quietly = TRUE)) install.packages("sandwich")
  if (!requireNamespace("lmtest",    quietly = TRUE)) install.packages("lmtest")
  library(here)
  library(tidyverse)
  library(sandwich)
  library(lmtest)
})

set.seed(42)

DATA_PATH <- "C:/Users/zhuch/Dropbox/2021 Spring and Fall/2022.04.06 UK Biobank/ukbdata/SNP_data/260222_ukb_data.csv"
OUT_DIR   <- here("replications", "vanDenBerg2025", "R", "results")
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

cat("==========================================================\n")
cat("  van den Berg et al. (2025) — Replication\n")
cat("==========================================================\n\n")

# ---- Phase 1: Load Data ------------------------------------------------------

cat("Phase 1: Loading data...\n")
df_raw <- read_csv(DATA_PATH, show_col_types = FALSE, na = c("", "NA"))
cat(sprintf("  Raw N = %d rows, %d columns\n\n", nrow(df_raw), ncol(df_raw)))

# Quick check: key columns present?
required_cols <- c("n_34_0_0", "n_52_0_0", "n_31_0_0", "n_21000", "n_1647",
                   "n_1767", "n_1777", "n_3659", "edu_years", "height",
                   "ts_130708_0_0")
missing_cols <- setdiff(required_cols, colnames(df_raw))
if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
}
cat("  All required columns present.\n\n")

# ---- Phase 2: Variable Construction ------------------------------------------

cat("Phase 2: Constructing variables...\n")

df <- df_raw %>%
  mutate(
    # Linear calendar time: months elapsed since January 1960
    # Jan 1960 = 0, April 1949 = -129, May 1952 = -92
    dob_yearmo = (n_34_0_0 - 1960L) * 12L + (n_52_0_0 - 1L),

    # Treatment indicator: born April 1949 – May 1950 (in utero during derationing)
    #   Derationing: April 24 – August 13, 1949
    #   Gestational exposure → birth window: Apr 1949 – May 1950
    #   Apr 1949 yearmo = (1949-1960)*12 + (4-1) = -132 + 3 = -129
    #   May 1950 yearmo = (1950-1960)*12 + (5-1) = -120 + 4 = -116
    E = as.integer(dob_yearmo >= -129L & dob_yearmo <= -116L),

    # Linear time trend, centered at start of exposure window (April 1949)
    time_c = dob_yearmo - (-129L),

    # Male dummy (n_31_0_0: 1=Male, 0=Female)
    male = n_31_0_0,

    # Month of birth as factor (month 1 = January = reference category)
    month_f = factor(n_52_0_0, levels = 1:12),

    # T2DM binary: 1 if first-occurrence date recorded, 0 otherwise
    # ts_130708_0_0 is the UKB "first occurrence" field for Type 2 diabetes (ICD E11)
    t2dm = as.integer(!is.na(ts_130708_0_0))
  )

cat(sprintf("  dob_yearmo range: %d to %d\n",
            min(df$dob_yearmo, na.rm = TRUE), max(df$dob_yearmo, na.rm = TRUE)))
cat(sprintf("  E=1 (treated) before filtering: N = %d\n", sum(df$E == 1, na.rm = TRUE)))
cat(sprintf("  t2dm=1 before filtering: N = %d (%.1f%%)\n",
            sum(df$t2dm == 1, na.rm = TRUE),
            100 * mean(df$t2dm == 1, na.rm = TRUE)))
cat("\n")

# ---- Phase 3: Sample Selection -----------------------------------------------

cat("Phase 3: Applying sample restrictions...\n")

# Calendar time bounds for sample window:
#   April 1947: (1947-1960)*12 + (4-1) = -156 + 3 = -153
#   May  1952:  (1952-1960)*12 + (5-1) = -96  + 4 = -92
YM_MIN <- -153L   # April 1947
YM_MAX <-  -92L   # May 1952

n_start <- nrow(df)

df_analysis <- df %>%
  filter(
    n_21000 == 1001,                       # White British (self-reported)
    n_1647 %in% c(1, 2),                   # Born in England (1) or Wales (2)
    dob_yearmo >= YM_MIN,                  # Born April 1947 or later
    dob_yearmo <= YM_MAX,                  # Born May 1952 or earlier
    !(n_1767 %in% 1),                      # Not adopted (1=yes; keep 0, -1, NA)
    !(n_1777 %in% 1),                      # Not multiple birth
    is.na(n_3659),                         # No recorded immigration year (UK-born)
    !is.na(male)                           # Non-missing sex
  )

cat(sprintf("  Start: N = %d\n",            n_start))
cat(sprintf("  After all filters: N = %d\n", nrow(df_analysis)))
cat(sprintf("  Exposure group (E=1): N = %d\n", sum(df_analysis$E == 1)))
cat(sprintf("  Control group  (E=0): N = %d\n", sum(df_analysis$E == 0)))
cat(sprintf("  Birth year range: %d – %d\n",
            min(df_analysis$n_34_0_0, na.rm = TRUE),
            max(df_analysis$n_34_0_0, na.rm = TRUE)))
cat(sprintf("  Male: %.1f%%\n",
            100 * mean(df_analysis$male, na.rm = TRUE)))
cat("\n")

# Distribution of birth years in analysis sample
cat("  Birth-year distribution in analysis sample:\n")
df_analysis %>%
  count(n_34_0_0) %>%
  print(n = Inf)
cat("\n")

# ---- Phase 4: Regression Function --------------------------------------------

run_vdb_reg <- function(outcome_var, df) {
  # Keep complete cases for this outcome
  df_sub <- df %>%
    filter(!is.na(.data[[outcome_var]]))

  n_obs <- nrow(df_sub)

  if (n_obs < 500) {
    warning(sprintf("Very few observations (%d) for outcome %s", n_obs, outcome_var))
  }

  # OLS: y ~ E + male + month_f + time_c + time_c:E
  fmla <- as.formula(
    paste0(outcome_var, " ~ E + male + month_f + time_c + I(time_c * E)")
  )

  fit <- lm(fmla, data = df_sub)

  # HC1-robust SEs clustered at year-month of birth (per paper)
  vcov_cl <- vcovCL(fit, cluster = ~dob_yearmo, type = "HC1")
  ct       <- coeftest(fit, vcov = vcov_cl)

  list(
    fit   = fit,
    ct    = ct,
    n     = n_obs,
    ymean = mean(df_sub[[outcome_var]], na.rm = TRUE),
    ysd   = sd(df_sub[[outcome_var]],   na.rm = TRUE)
  )
}

# ---- Phase 5: Run Regressions ------------------------------------------------

cat("Phase 5: Running regressions...\n\n")

outcomes <- c("edu_years", "height", "t2dm")
results_list <- setNames(
  lapply(outcomes, function(o) {
    cat(sprintf("--- Outcome: %s ---\n", o))
    res <- run_vdb_reg(o, df_analysis)
    print(res$ct)
    cat(sprintf("N = %d | Mean = %.4f | SD = %.4f\n\n",
                res$n, res$ymean, res$ysd))
    res
  }),
  outcomes
)

# ---- Phase 6: Build Results Table --------------------------------------------

cat("Phase 6: Building results table...\n\n")

# Published targets — Table 1, Panel A (column 1: without geographic controls)
targets <- tibble(
  outcome   = c("edu_years", "height", "t2dm"),
  paper_est = c( 0.157,       0.013,  -0.003),
  paper_se  = c( 0.047,       0.066,   0.002),
  paper_sig = c("***",        "",      "")
)

results_tbl <- map_dfr(outcomes, function(o) {
  res <- results_list[[o]]
  ct  <- res$ct
  idx <- which(rownames(ct) == "E")

  tibble(
    outcome  = o,
    our_est  = ct[idx, "Estimate"],
    our_se   = ct[idx, "Std. Error"],
    our_pval = ct[idx, "Pr(>|t|)"],
    our_sig  = case_when(
      ct[idx, "Pr(>|t|)"] < 0.001 ~ "***",
      ct[idx, "Pr(>|t|)"] < 0.01  ~ "**",
      ct[idx, "Pr(>|t|)"] < 0.05  ~ "*",
      ct[idx, "Pr(>|t|)"] < 0.10  ~ ".",
      TRUE                         ~ ""
    ),
    n        = res$n,
    ymean    = res$ymean
  )
}) %>%
  left_join(targets, by = "outcome") %>%
  mutate(
    abs_dev  = abs(our_est - paper_est),
    pct_dev  = if_else(
      paper_est != 0,
      abs((our_est - paper_est) / paper_est) * 100,
      NA_real_
    ),
    # PASS: within ±0.05 of paper's point estimate
    match = case_when(
      is.na(our_est)       ~ "MISSING",
      abs_dev <= 0.05      ~ "PASS",
      TRUE                 ~ "REVIEW"
    )
  )

# ---- Phase 7: Print Comparison -----------------------------------------------

cat("==========================================================\n")
cat("  REPLICATION RESULTS (vs. van den Berg et al. Table 1A)\n")
cat("==========================================================\n\n")

fmt_row <- function(outcome_label, our, our_se, our_sig, paper, paper_se, paper_sig,
                    abs_dev, pct_dev, match_flag) {
  cat(sprintf(
    "  %-12s | Our: %7.4f (%5.4f)%3s | Paper: %7.4f (%5.4f)%3s | |Δ|=%5.4f | %s%%  [%s]\n",
    outcome_label, our, our_se, our_sig, paper, paper_se, paper_sig,
    abs_dev, ifelse(is.na(pct_dev), "  NA", sprintf("%5.1f", pct_dev)), match_flag
  ))
}

walk(seq_len(nrow(results_tbl)), function(i) {
  r <- results_tbl[i, ]
  fmt_row(r$outcome, r$our_est, r$our_se, r$our_sig,
          r$paper_est, r$paper_se, r$paper_sig,
          r$abs_dev, r$pct_dev, r$match)
})

cat("\nSample sizes:\n")
walk(outcomes, function(o) {
  cat(sprintf("  %-12s N = %d\n", o, results_list[[o]]$n))
})

cat(sprintf("\nPaper reference N (edu): ~84,165\n"))

# ---- Phase 8: Save Results ---------------------------------------------------

cat("\nPhase 8: Saving results...\n")

write_csv(results_tbl, file.path(OUT_DIR, "table1_replication.csv"))
cat(sprintf("  Saved: %s\n", file.path(OUT_DIR, "table1_replication.csv")))

# Also save a readable text summary
summary_lines <- c(
  "van den Berg et al. (2025) Replication Summary",
  paste0("Generated: ", Sys.time()),
  "",
  "Outcome     | Our est  | Our SE  | Paper est | Paper SE | |Δ| | Status",
  paste(rep("-", 70), collapse = "")
)
for (i in seq_len(nrow(results_tbl))) {
  r <- results_tbl[i, ]
  summary_lines <- c(summary_lines,
    sprintf("%-12s| %8.4f | %7.4f | %9.4f | %8.4f | %5.4f | %s",
            r$outcome, r$our_est, r$our_se,
            r$paper_est, r$paper_se, r$abs_dev, r$match)
  )
}
writeLines(summary_lines, file.path(OUT_DIR, "summary.txt"))
cat(sprintf("  Saved: %s\n\n", file.path(OUT_DIR, "summary.txt")))

pass_n <- sum(results_tbl$match == "PASS",    na.rm = TRUE)
rev_n  <- sum(results_tbl$match == "REVIEW",  na.rm = TRUE)

cat("==========================================================\n")
cat(sprintf("  PASS: %d/3 outcomes within ±0.05 of paper target\n", pass_n))
cat(sprintf("  REVIEW: %d/3 outcomes outside threshold\n", rev_n))
cat("==========================================================\n")

# ---- Phase 9: Placebo Falsification Tests ------------------------------------

cat("\nPhase 9: Placebo falsification tests...\n\n")

# Load patchwork (needed for Phase 10 too)
suppressPackageStartupMessages({
  if (!requireNamespace("patchwork", quietly = TRUE)) install.packages("patchwork")
  library(patchwork)
})

FIG_DIR <- here("replications", "vanDenBerg2025", "R", "figures")
dir.create(FIG_DIR, recursive = TRUE, showWarnings = FALSE)

# Placebo windows (same 14-month width as real treatment: -129 to -116)
# Pre-placebo:  Apr 1947 – May 1948 → yearmo -153 to -140
# Post-placebo: Apr 1951 – May 1952 → yearmo -105 to -92

df_analysis <- df_analysis %>%
  mutate(
    fake_E_pre  = as.integer(dob_yearmo >= -153L & dob_yearmo <= -140L),
    fake_E_post = as.integer(dob_yearmo >= -105L & dob_yearmo <= -92L),
    time_pre    = dob_yearmo - (-153L),   # centered at start of pre-placebo window
    time_post   = dob_yearmo - (-105L)    # centered at start of post-placebo window
  )

run_placebo_reg <- function(outcome_var, fake_E_var, time_var, df) {
  df_sub <- df %>% filter(!is.na(.data[[outcome_var]]))

  fmla <- as.formula(
    paste0(outcome_var, " ~ ", fake_E_var,
           " + male + month_f + ", time_var,
           " + I(", time_var, " * ", fake_E_var, ")")
  )

  fit <- lm(fmla, data = df_sub)
  vcov_cl <- vcovCL(fit, cluster = ~dob_yearmo, type = "HC1")
  ct      <- coeftest(fit, vcov = vcov_cl)
  idx     <- which(rownames(ct) == fake_E_var)

  list(
    est  = ct[idx, "Estimate"],
    se   = ct[idx, "Std. Error"],
    pval = ct[idx, "Pr(>|t|)"],
    n    = nrow(df_sub)
  )
}

# Run placebo regressions for all outcomes × both windows
placebo_rows <- list()
for (o in outcomes) {
  pre  <- run_placebo_reg(o, "fake_E_pre",  "time_pre",  df_analysis)
  post <- run_placebo_reg(o, "fake_E_post", "time_post", df_analysis)

  placebo_rows[[length(placebo_rows) + 1]] <- tibble(
    outcome  = o, window = "pre_placebo",
    est = pre$est, se = pre$se, pval = pre$pval, n = pre$n
  )
  placebo_rows[[length(placebo_rows) + 1]] <- tibble(
    outcome  = o, window = "post_placebo",
    est = post$est, se = post$se, pval = post$pval, n = post$n
  )
}
placebo_tbl <- bind_rows(placebo_rows)

# Print combined table: real vs placebos
cat("  Placebo falsification results (α₁ estimate, SE, p-value):\n\n")
cat(sprintf("  %-12s  %-14s  %9s  %7s  %7s\n",
            "Outcome", "Window", "Estimate", "SE", "p-val"))
cat(sprintf("  %s\n", paste(rep("-", 60), collapse = "")))

for (o in outcomes) {
  # Real estimate
  r_real <- results_tbl %>% filter(outcome == o)
  cat(sprintf("  %-12s  %-14s  %9.4f  %7.4f  %7.4f\n",
              o, "REAL", r_real$our_est, r_real$our_se, r_real$our_pval))
  # Placebos
  for (wnd in c("pre_placebo", "post_placebo")) {
    r_p <- placebo_tbl %>% filter(outcome == o, window == wnd)
    sig <- if (r_p$pval < 0.05) "*" else ""
    cat(sprintf("  %-12s  %-14s  %9.4f  %7.4f  %7.4f %s\n",
                "", wnd, r_p$est, r_p$se, r_p$pval, sig))
  }
  cat("\n")
}

write_csv(placebo_tbl, file.path(OUT_DIR, "placebo_results.csv"))
cat(sprintf("  Saved: %s\n\n", file.path(OUT_DIR, "placebo_results.csv")))

# ---- Phase 10: Figure 1 — Event-Study Cohort Plot ----------------------------

cat("Phase 10: Building event-study figure...\n")

outcome_labels <- c(edu_years = "Years of schooling",
                    height    = "Height (cm)",
                    t2dm      = "Type 2 diabetes (binary)")

# Shaded window boundaries (in dob_yearmo units)
real_lo  <- -129L; real_hi  <- -116L
pre_lo   <- -153L; pre_hi   <- -140L
post_lo  <- -105L; post_hi  <-  -92L

make_event_panel <- function(outcome_var, df) {
  df_sub <- df %>% filter(!is.na(.data[[outcome_var]]))

  # Base model without treatment indicator
  fmla_base <- as.formula(
    paste0(outcome_var, " ~ male + month_f + time_c")
  )
  fit_base <- lm(fmla_base, data = df_sub)

  # Partial residuals re-centered to outcome mean
  y_mean  <- mean(df_sub[[outcome_var]], na.rm = TRUE)
  partial <- residuals(fit_base) + y_mean

  df_sub$partial <- partial

  # Aggregate: mean and SE by birth yearmo
  agg <- df_sub %>%
    group_by(dob_yearmo) %>%
    summarise(
      ymean = mean(partial, na.rm = TRUE),
      yse   = sd(partial, na.rm = TRUE) / sqrt(n()),
      .groups = "drop"
    )

  # Approximate year label: dob_yearmo = (year-1960)*12 + (month-1)
  # year ≈ 1960 + dob_yearmo / 12
  agg <- agg %>%
    mutate(year_approx = 1960 + dob_yearmo / 12)

  ggplot(agg, aes(x = dob_yearmo, y = ymean)) +
    # Placebo shading (gray)
    annotate("rect", xmin = pre_lo,  xmax = pre_hi,  ymin = -Inf, ymax = Inf,
             fill = "gray70", alpha = 0.3) +
    annotate("rect", xmin = post_lo, xmax = post_hi, ymin = -Inf, ymax = Inf,
             fill = "gray70", alpha = 0.3) +
    # Real treatment shading (red)
    annotate("rect", xmin = real_lo, xmax = real_hi, ymin = -Inf, ymax = Inf,
             fill = "#d73027", alpha = 0.2) +
    # Smooth trend (loess) — fit separately pre and post real window
    geom_smooth(
      data = agg %>% filter(dob_yearmo < real_lo),
      aes(x = dob_yearmo, y = ymean),
      method = "loess", span = 0.5, se = FALSE,
      color = "steelblue", linewidth = 0.8
    ) +
    geom_smooth(
      data = agg %>% filter(dob_yearmo > real_hi),
      aes(x = dob_yearmo, y = ymean),
      method = "loess", span = 0.5, se = FALSE,
      color = "steelblue", linewidth = 0.8
    ) +
    # Data points with error bars
    geom_errorbar(aes(ymin = ymean - 1.96 * yse, ymax = ymean + 1.96 * yse),
                  width = 0, color = "gray50", alpha = 0.6) +
    geom_point(size = 1.2, color = "black") +
    # Labels
    labs(
      title = outcome_labels[outcome_var],
      x     = "Birth year-month",
      y     = "Partial residual (outcome scale)"
    ) +
    scale_x_continuous(
      breaks = seq(-153, -92, by = 12),
      labels = function(x) sprintf("%.1f", 1960 + x / 12)
    ) +
    theme_bw(base_size = 10) +
    theme(
      plot.title   = element_text(face = "bold", size = 10),
      panel.grid.minor = element_blank()
    )
}

panels <- lapply(outcomes, function(o) make_event_panel(o, df_analysis))

fig1 <- (panels[[1]] / panels[[2]] / panels[[3]]) +
  plot_annotation(
    title    = "Figure 1: Birth-cohort event study — prenatal sugar derationing (van den Berg et al., 2025)",
    subtitle = "Red band = real treatment window (Apr 1949–May 1950). Gray bands = placebo windows.\nPoints show mean partial residuals ± 1.96 SE by birth year-month. Lines = loess trend.",
    theme    = theme(
      plot.title    = element_text(face = "bold", size = 11),
      plot.subtitle = element_text(size = 9, color = "gray40")
    )
  )

fig1_path <- file.path(FIG_DIR, "fig1_event_study.png")
ggsave(fig1_path, fig1, width = 12, height = 10, dpi = 150)
cat(sprintf("  Saved: %s\n\n", fig1_path))

# ---- Phase 11: Figure 2 — Coefficient Forest Plot ----------------------------

cat("Phase 11: Building forest plot...\n")

# Build data frame: real + placebo estimates for all outcomes
forest_rows <- list()
outcome_order <- rev(outcomes)  # bottom-to-top for readability

for (o in outcome_order) {
  r_real <- results_tbl %>% filter(outcome == o)
  forest_rows[[length(forest_rows) + 1]] <- tibble(
    outcome   = o,
    window    = "Real treatment",
    est       = r_real$our_est,
    se        = r_real$our_se,
    color_grp = "real"
  )

  for (wnd in c("Pre-placebo", "Post-placebo")) {
    wnd_key <- if (wnd == "Pre-placebo") "pre_placebo" else "post_placebo"
    r_p <- placebo_tbl %>% filter(outcome == o, window == wnd_key)
    forest_rows[[length(forest_rows) + 1]] <- tibble(
      outcome   = o,
      window    = wnd,
      est       = r_p$est,
      se        = r_p$se,
      color_grp = "placebo"
    )
  }
}
forest_df <- bind_rows(forest_rows) %>%
  mutate(
    ci_lo  = est - 1.96 * se,
    ci_hi  = est + 1.96 * se,
    # row label for y-axis
    row_label = paste0(outcome_labels[outcome], "\n(", window, ")"),
    row_label = factor(row_label, levels = rev(unique(row_label)))
  )

fig2 <- ggplot(forest_df, aes(x = est, y = row_label, color = color_grp)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray40") +
  geom_pointrange(
    aes(xmin = ci_lo, xmax = ci_hi),
    size = 0.5, linewidth = 0.8
  ) +
  scale_color_manual(
    values  = c("real" = "#2166ac", "placebo" = "gray55"),
    labels  = c("real" = "Real treatment", "placebo" = "Placebo"),
    name    = NULL
  ) +
  labs(
    title    = "Figure 2: Treatment vs. placebo coefficient estimates",
    subtitle = "van den Berg et al. (2025) replication — α₁ with 95% CI\nBlue = real treatment window; Gray = placebo windows",
    x        = "OLS coefficient (α₁)",
    y        = NULL
  ) +
  theme_bw(base_size = 10) +
  theme(
    plot.title       = element_text(face = "bold", size = 11),
    plot.subtitle    = element_text(size = 9, color = "gray40"),
    legend.position  = "bottom",
    panel.grid.minor = element_blank()
  )

fig2_path <- file.path(FIG_DIR, "fig2_forest_plot.png")
ggsave(fig2_path, fig2, width = 8, height = 7, dpi = 150)
cat(sprintf("  Saved: %s\n\n", fig2_path))

# ---- Final Summary -----------------------------------------------------------

cat("==========================================================\n")
cat(sprintf("  PASS: %d/3 outcomes within ±0.05 of paper target\n", pass_n))
cat(sprintf("  REVIEW: %d/3 outcomes outside threshold\n", rev_n))
cat("  Placebo CSV:   results/placebo_results.csv\n")
cat("  Figure 1:      figures/fig1_event_study.png\n")
cat("  Figure 2:      figures/fig2_forest_plot.png\n")
cat("==========================================================\n")
cat("\nDone.\n")
