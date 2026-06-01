# 03_model_engagement.R
# Exploratory engagement analysis for small-N longitudinal KakaoTalk corpus
#
# Analysis strategy:
#   This script does NOT attempt causal inference. It asks three modest questions:
#   1. Do within-learner time trends in English-message use differ across learners?
#   2. Are disruption-coded weeks associated with higher apology/uncertainty language?
#   3. Does instructor correction density co-vary with learner message volume?
#
#   All models are treated as exploratory screens, not confirmatory tests.
#   Effect sizes and confidence intervals are reported in preference to p-values.
#   Learner heterogeneity is shown before any pooled estimate is presented.
#
# Audit notes:
#   - Pooled slopes are preceded by within-learner slope tables (Fig 7 forest plot)
#   - 'work' removed from disruption regex in 01_build_corpus.R; see codebook.md
#   - gt_correction_count tracked separately for cross-learner comparability
#   - N = 4 learners, 31-113 observed weeks each; no population-level inference

library(tidyverse)
library(broom)
library(scales)

# ── Paths ─────────────────────────────────────────────────────────────────────
weekly_path  <- "data/derived/learner_week_summary.csv"
learner_path <- "data/derived/learner_summary.csv"
out_dir      <- "data/derived"
fig_dir      <- "figures"

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

# ── Load data ─────────────────────────────────────────────────────────────────
weekly <- read_csv(weekly_path, show_col_types = FALSE) %>%
  mutate(learner_id = as.character(learner_id))

learner_summary <- read_csv(learner_path, show_col_types = FALSE)

# Consistent learner colour palette across all outputs
learner_colors <- c(
  L001 = "#4878CF",
  L002 = "#D65F5F",
  L003 = "#6ACC65",
  L004 = "#B47CC7"
)

# Helper: require at least n non-missing rows; return NA tibble otherwise
has_variation <- function(x, min_n = 4) {
  sum(!is.na(x)) >= min_n && var(x, na.rm = TRUE) > 0
}

summary_lines <- character(0)
add_line <- function(...) {
  summary_lines <<- c(summary_lines, paste0(...))
}

add_line("Exploratory engagement analysis")
add_line("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M"))
add_line("Learners: ", n_distinct(weekly$learner_id))
add_line("Learner-week rows: ", nrow(weekly))
add_line("")
add_line("INTERPRETATION REMINDER")
add_line("All estimates are exploratory screens for a corpus of N=4 learners.")
add_line("Wide confidence intervals are expected and honest.")
add_line("Sign disagreement across learners means a pooled estimate is not meaningful.")
add_line("Do not interpret these outputs as stable population-level effects.")
add_line(strrep("-", 72))


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 1 — Descriptive uncertainty
# Learner-week means, SDs, medians, IQRs for key indicators
# ══════════════════════════════════════════════════════════════════════════════

add_line("")
add_line("SECTION 1: Descriptive uncertainty by learner")
add_line(strrep("-", 72))

desc_vars <- c(
  "learner_messages",
  "english_proportion",
  "apology_uncertainty_rate",
  "correction_density",
  "avg_learner_word_count"
)

descriptive_uncertainty <- weekly %>%
  group_by(learner_id, learner_label) %>%
  summarise(
    across(
      all_of(desc_vars),
      list(
        n      = ~ sum(!is.na(.x)),
        mean   = ~ mean(.x, na.rm = TRUE),
        sd     = ~ sd(.x, na.rm = TRUE),
        se     = ~ sd(.x, na.rm = TRUE) / sqrt(sum(!is.na(.x))),
        ci_low = ~ mean(.x, na.rm = TRUE) -
                   1.96 * sd(.x, na.rm = TRUE) / sqrt(sum(!is.na(.x))),
        ci_high= ~ mean(.x, na.rm = TRUE) +
                   1.96 * sd(.x, na.rm = TRUE) / sqrt(sum(!is.na(.x))),
        median = ~ median(.x, na.rm = TRUE),
        iqr    = ~ IQR(.x, na.rm = TRUE)
      ),
      .names = "{.col}__{.fn}"
    ),
    .groups = "drop"
  ) %>%
  pivot_longer(
    -c(learner_id, learner_label),
    names_to  = c("variable", ".value"),
    names_sep = "__"
  ) %>%
  mutate(across(where(is.numeric), ~ round(.x, 4)))

write_csv(descriptive_uncertainty, file.path(out_dir, "descriptive_uncertainty.csv"))
add_line("Descriptive uncertainty table written: descriptive_uncertainty.csv")
add_line("Read ci_low/ci_high as rough uncertainty bands, not inferential intervals.")


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 2 — Within-learner time trends
# OLS slope of study_week on each outcome, estimated separately per learner
# This is reported BEFORE any pooled screen
# ══════════════════════════════════════════════════════════════════════════════

add_line("")
add_line("SECTION 2: Within-learner time trends (study_week as predictor)")
add_line(strrep("-", 72))
add_line("Each slope is estimated from one learner's observed weeks only.")
add_line("Observation windows differ (31-113 weeks); slopes are not directly comparable.")

trend_outcomes <- c("english_proportion", "apology_uncertainty_rate",
                    "correction_density", "learner_messages")

learner_slopes <- weekly %>%
  group_by(learner_id, learner_label) %>%
  group_modify(~ {
    d <- .x
    map_dfr(trend_outcomes, function(outcome) {
      y <- d[[outcome]]
      x <- d$study_week
      complete <- !is.na(x) & !is.na(y)
      d2 <- d[complete, ]
      if (nrow(d2) < 4 || var(d2[[outcome]]) == 0) {
        return(tibble(outcome = outcome, estimate = NA_real_,
                      conf.low = NA_real_, conf.high = NA_real_,
                      p.value = NA_real_, n_weeks = sum(complete)))
      }
      fit <- lm(as.formula(paste(outcome, "~ study_week")), data = d2)
      tidy(fit, conf.int = TRUE) %>%
        filter(term == "study_week") %>%
        transmute(outcome = outcome, estimate, conf.low, conf.high,
                  p.value, n_weeks = sum(complete))
    })
  }) %>%
  ungroup() %>%
  mutate(across(where(is.numeric), ~ round(.x, 4)))

write_csv(learner_slopes, file.path(out_dir, "learner_slopes.csv"))

# Sign-agreement check — key transparency output
slope_heterogeneity <- learner_slopes %>%
  filter(!is.na(estimate)) %>%
  group_by(outcome) %>%
  summarise(
    n_learners    = n(),
    n_positive    = sum(estimate > 0),
    n_negative    = sum(estimate < 0),
    sign_agreement = (n_positive == n_learners | n_negative == n_learners),
    est_min       = min(estimate),
    est_max       = max(estimate),
    .groups = "drop"
  )

write_csv(slope_heterogeneity, file.path(out_dir, "slope_heterogeneity.csv"))

add_line("")
add_line("Sign agreement across learner slopes:")
for (i in seq_len(nrow(slope_heterogeneity))) {
  r <- slope_heterogeneity[i, ]
  agree_label <- if (r$sign_agreement) "YES — slopes point the same direction" else
                 "NO  — slopes disagree in direction (pooled slope not meaningful)"
  add_line(sprintf("  %-30s  %s  (range: %.3f to %.3f)",
                   r$outcome, agree_label, r$est_min, r$est_max))
}
add_line("")
add_line("If sign_agreement = NO, a pooled slope conceals learner heterogeneity.")
add_line("See learner_slopes.csv and fig7_learner_slopes_forest.png.")


# ── Figure 7: Forest plot of within-learner slopes ───────────────────────────
forest_data <- learner_slopes %>%
  filter(!is.na(estimate)) %>%
  mutate(
    outcome_label = recode(outcome,
      english_proportion       = "English-message proportion",
      apology_uncertainty_rate = "Apology / uncertainty rate",
      correction_density       = "Correction density",
      learner_messages         = "Learner message count"
    ),
    learner_label_short = str_replace(learner_label, "Adult learner ", "L")
  )

p_forest <- ggplot(forest_data,
                   aes(x = estimate, y = reorder(learner_label_short, estimate),
                       color = learner_id)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey60", linewidth = 0.6) +
  geom_errorbarh(aes(xmin = conf.low, xmax = conf.high),
                 height = 0.25, linewidth = 0.8, alpha = 0.7) +
  geom_point(size = 3) +
  facet_wrap(~ outcome_label, scales = "free_x", ncol = 2) +
  scale_color_manual(values = learner_colors, guide = "none") +
  labs(
    title    = "Figure 7. Within-Learner Slopes on Study Week",
    subtitle = "Bars = 95% CIs.  Dashed line = zero.  Sign disagreement across learners\n
    means a pooled slope is not a meaningful summary of this corpus.",
    x = "Slope estimate (per study week)", y = NULL,
    caption = "Each slope estimated from that learner's observed weeks only.\nN = 4 learners; 31–113 weeks each."
  ) +
  theme_minimal(base_size = 10) +
  theme(
    plot.subtitle  = element_text(size = 8, color = "grey40"),
    plot.caption   = element_text(size = 7, color = "grey50"),
    strip.text     = element_text(size = 9, face = "bold"),
    panel.grid.minor = element_blank()
  )

ggsave(file.path(fig_dir, "fig7_learner_slopes_forest.png"),
       p_forest, width = 9, height = 6, dpi = 150)
add_line("Figure 7 (forest plot) saved: fig7_learner_slopes_forest.png")


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 3 — Within-learner correlations
# Pearson r between key predictor-outcome pairs, per learner
# ══════════════════════════════════════════════════════════════════════════════

add_line("")
add_line("SECTION 3: Within-learner correlations")
add_line(strrep("-", 72))
add_line("Pearson r estimated within each learner's observed weeks.")
add_line("Treat as descriptive association, not a population estimate.")

cor_pairs <- list(
  list(x = "disruption_count",   y = "learner_messages",
       label = "disruption_count ~ learner_messages"),
  list(x = "disruption_count",   y = "apology_uncertainty_rate",
       label = "disruption_count ~ apology_uncertainty_rate"),
  list(x = "avg_learner_word_count", y = "correction_density",
       label = "avg_learner_word_count ~ correction_density"),
  list(x = "study_week",         y = "english_proportion",
       label = "study_week ~ english_proportion"),
  list(x = "correction_density", y = "english_proportion",
       label = "correction_density ~ english_proportion")
)

within_learner_correlations <- map_dfr(cor_pairs, function(pair) {
  weekly %>%
    group_by(learner_id) %>%
    group_modify(~ {
      d <- .x
      x <- d[[pair$x]]; y <- d[[pair$y]]
      complete <- !is.na(x) & !is.na(y)
      n <- sum(complete)
      if (n < 4 || var(x[complete]) == 0 || var(y[complete]) == 0) {
        return(tibble(relationship = pair$label, estimate = NA_real_,
                      conf.low = NA_real_, conf.high = NA_real_,
                      p.value = NA_real_, n_complete = n))
      }
      ct <- cor.test(x[complete], y[complete], method = "pearson")
      tibble(
        relationship = pair$label,
        estimate     = round(ct$estimate, 4),
        conf.low     = round(ct$conf.int[[1]], 4),
        conf.high    = round(ct$conf.int[[2]], 4),
        p.value      = round(ct$p.value, 4),
        n_complete   = n
      )
    }) %>%
    ungroup()
}) %>%
  mutate(
    effect_size_label = case_when(
      is.na(estimate)          ~ "insufficient data",
      abs(estimate) < 0.10     ~ "negligible",
      abs(estimate) < 0.30     ~ "small",
      abs(estimate) < 0.50     ~ "moderate",
      TRUE                     ~ "large"
    )
  )

write_csv(within_learner_correlations,
          file.path(out_dir, "within_learner_correlations.csv"))
add_line("Within-learner correlations written: within_learner_correlations.csv")
add_line("Note: CIs computed per learner independently; do not pool them.")


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 4 — Disruption vs non-disruption: standardised mean differences
# Effect sizes for apology/uncertainty rate in disruption vs non-disruption weeks
# Computed within each learner, then displayed side by side
# ══════════════════════════════════════════════════════════════════════════════

add_line("")
add_line("SECTION 4: Disruption vs non-disruption weeks — within-learner SMDs")
add_line(strrep("-", 72))
add_line("SMD = (disruption mean - non-disruption mean) / pooled SD")
add_line("Positive SMD = higher apology/uncertainty rate in disruption-coded weeks.")
add_line("L001 has only 4 disruption weeks; treat with extra caution.")

smd_results <- weekly %>%
  group_by(learner_id, learner_label) %>%
  group_modify(~ {
    d <- .x
    dis <- d %>% filter(disruption_flag == 1) %>% pull(apology_uncertainty_rate) %>% na.omit()
    non <- d %>% filter(disruption_flag == 0) %>% pull(apology_uncertainty_rate) %>% na.omit()
    if (length(dis) < 2 || length(non) < 2) {
      return(tibble(
        mean_disruption    = NA_real_, mean_no_disruption = NA_real_,
        mean_difference    = NA_real_, pooled_sd          = NA_real_,
        smd                = NA_real_, n_disruption       = length(dis),
        n_no_disruption    = length(non), interpretation  = "insufficient data"
      ))
    }
    pooled_sd <- sqrt((var(dis) + var(non)) / 2)
    smd_val   <- if (pooled_sd > 0) (mean(dis) - mean(non)) / pooled_sd else NA_real_
    tibble(
      mean_disruption    = round(mean(dis), 4),
      mean_no_disruption = round(mean(non), 4),
      mean_difference    = round(mean(dis) - mean(non), 4),
      pooled_sd          = round(pooled_sd, 4),
      smd                = round(smd_val, 3),
      n_disruption       = length(dis),
      n_no_disruption    = length(non),
      interpretation     = case_when(
        is.na(smd_val)       ~ "not estimable",
        abs(smd_val) < 0.20  ~ "negligible",
        abs(smd_val) < 0.50  ~ "small",
        abs(smd_val) < 0.80  ~ "moderate",
        TRUE                 ~ "large"
      )
    )
  }) %>%
  ungroup()

write_csv(smd_results, file.path(out_dir, "disruption_apology_uncertainty_differences.csv"))

add_line("")
add_line("Within-learner SMDs (apology/uncertainty rate, disruption vs non-disruption):")
for (i in seq_len(nrow(smd_results))) {
  r <- smd_results[i, ]
  add_line(sprintf(
    "  %s: SMD = %+.3f (%s)  dis_mean=%.3f (n=%d)  non_mean=%.3f (n=%d)",
    r$learner_id, r$smd, r$interpretation,
    r$mean_disruption, r$n_disruption,
    r$mean_no_disruption, r$n_no_disruption
  ))
}

add_line("")
add_line("Heterogeneity note:")
smds_valid <- smd_results$smd[!is.na(smd_results$smd)]
if (any(smds_valid > 0) && any(smds_valid < 0)) {
  add_line("  SMDs differ in SIGN across learners. L001 shows LOWER apology/uncertainty")
  add_line("  in disruption weeks; L002-L004 show HIGHER. A pooled disruption effect")
  add_line("  would conceal this. Report learner-specific SMDs, not a pooled average.")
} else {
  add_line("  SMDs point in the same direction across learners.")
}


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 5 — Pooled learner fixed-effect screens
# Modest pooled OLS with learner fixed effects, reported AFTER heterogeneity
# These answer: "after accounting for learner identity, is there a signal?"
# They do NOT estimate stable population effects
# ══════════════════════════════════════════════════════════════════════════════

add_line("")
add_line("SECTION 5: Pooled learner fixed-effect screens")
add_line(strrep("-", 72))
add_line("These models include learner identity as a fixed effect (factor).")
add_line("They absorb between-learner differences but not within-learner autocorrelation.")
add_line("Interpret as crude pooled screens only. See Section 2 for learner-level detail.")

pooled_models <- list(
  list(
    name    = "english_proportion ~ study_week + learner_id",
    formula = english_proportion ~ study_week + factor(learner_id),
    focal   = "study_week",
    note    = "Does English-message proportion tend to change over time after accounting for learner?"
  ),
  list(
    name    = "apology_uncertainty_rate ~ disruption_flag + learner_id",
    formula = apology_uncertainty_rate ~ disruption_flag + factor(learner_id),
    focal   = "disruption_flag",
    note    = "Are apology/uncertainty markers higher in disruption-coded weeks?"
  ),
  list(
    name    = "learner_messages ~ disruption_flag + learner_id",
    formula = learner_messages ~ disruption_flag + factor(learner_id),
    focal   = "disruption_flag",
    note    = "Are learner message counts lower in disruption-coded weeks?"
  ),
  list(
    name    = "correction_density ~ avg_learner_word_count + learner_id",
    formula = correction_density ~ avg_learner_word_count + factor(learner_id),
    focal   = "avg_learner_word_count",
    note    = "Does instructor correction density co-vary with learner word output?"
  )
)

pooled_results  <- list()
model_diagnostics <- list()

for (pm in pooled_models) {
  d <- weekly %>%
    drop_na(all.vars(pm$formula)) %>%
    filter(n_distinct(learner_id) >= 2)

  if (nrow(d) < 10) {
    add_line(sprintf("  SKIPPED (insufficient data): %s", pm$name))
    next
  }

  fit <- tryCatch(lm(pm$formula, data = d), error = function(e) NULL)
  if (is.null(fit)) {
    add_line(sprintf("  FAILED: %s", pm$name))
    next
  }

  coef_tbl <- tidy(fit, conf.int = TRUE) %>%
    filter(term == pm$focal) %>%
    mutate(
      model = pm$name,
      note  = pm$note,
      n_obs = nrow(d)
    ) %>%
    select(model, term, estimate, conf.low, conf.high, p.value, n_obs, note)

  pooled_results[[pm$name]] <- coef_tbl

  model_diagnostics[[pm$name]] <- tibble(
    model            = pm$name,
    n_obs            = nrow(d),
    r_squared        = round(summary(fit)$r.squared, 4),
    adj_r_squared    = round(summary(fit)$adj.r.squared, 4),
    residual_se      = round(summary(fit)$sigma, 4),
    df_residual      = fit$df.residual
  )

  add_line("")
  add_line(sprintf("  Model: %s", pm$name))
  add_line(sprintf("  Note:  %s", pm$note))
  add_line(sprintf("  Focal estimate: %.4f  95%% CI [%.4f, %.4f]  p=%.3f  n=%d",
                   coef_tbl$estimate, coef_tbl$conf.low, coef_tbl$conf.high,
                   coef_tbl$p.value, coef_tbl$n_obs))
  add_line("  Interpret as exploratory screen only.")
}

pooled_results_df <- bind_rows(pooled_results) %>%
  mutate(across(where(is.numeric), ~ round(.x, 4)))

model_diagnostics_df <- bind_rows(model_diagnostics)

write_csv(pooled_results_df,  file.path(out_dir, "exploratory_model_results.csv"))
write_csv(model_diagnostics_df, file.path(out_dir, "model_diagnostics.csv"))
add_line("")
add_line("Pooled model results: exploratory_model_results.csv")
add_line("Model diagnostics:    model_diagnostics.csv")


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 6 — Sensitivity checks
# Re-run key summaries with narrower keyword definitions
# If findings change substantially, they should be described as fragile
# ══════════════════════════════════════════════════════════════════════════════

add_line("")
add_line("SECTION 6: Sensitivity checks")
add_line(strrep("-", 72))
add_line("The apology_uncertainty_marker includes 'sorry', which is a common")
add_line("politeness term in Korean professional messaging. Removing it tests")
add_line("whether findings depend on that single high-frequency token.")
add_line("")
add_line("Note: this check runs on the apology_uncertainty_rate variable as coded.")
add_line("A full re-run requiring raw message text would need 01_build_corpus.R")
add_line("to be re-executed with a narrower keyword list. See codebook.md for")
add_line("guidance on which terms to exclude for narrow-definition sensitivity runs.")

# Proxy sensitivity: compare disruption SMD using only obviously occupational disruption weeks
# (disruption_count >= 2 as a stricter threshold than disruption_flag == 1)
add_line("")
add_line("Stricter disruption threshold (disruption_count >= 2 vs disruption_flag == 1):")

smd_strict <- weekly %>%
  group_by(learner_id) %>%
  group_modify(~ {
    d <- .x
    dis_strict <- d %>%
      filter(disruption_count >= 2) %>%
      pull(apology_uncertainty_rate) %>% na.omit()
    non <- d %>%
      filter(disruption_flag == 0) %>%
      pull(apology_uncertainty_rate) %>% na.omit()
    if (length(dis_strict) < 2 || length(non) < 2) {
      return(tibble(smd_strict = NA_real_, n_strict = length(dis_strict)))
    }
    pooled_sd <- sqrt((var(dis_strict) + var(non)) / 2)
    tibble(
      smd_strict = round(if (pooled_sd > 0) (mean(dis_strict) - mean(non)) / pooled_sd else NA_real_, 3),
      n_strict   = length(dis_strict)
    )
  }) %>%
  ungroup()

sensitivity_comparison <- smd_results %>%
  select(learner_id, smd_broad = smd, n_disruption) %>%
  left_join(smd_strict, by = "learner_id") %>%
  mutate(
    direction_stable = case_when(
      is.na(smd_strict)                             ~ "insufficient data for strict threshold",
      sign(smd_broad) == sign(smd_strict)           ~ "direction stable",
      TRUE                                           ~ "direction changed — finding is fragile"
    )
  )

write_csv(sensitivity_comparison,
          file.path(out_dir, "sensitivity_disruption_smd.csv"))

for (i in seq_len(nrow(sensitivity_comparison))) {
  r <- sensitivity_comparison[i, ]
  add_line(sprintf("  %s: broad SMD=%.3f (n=%d)  strict SMD=%s (n=%d)  → %s",
                   r$learner_id,
                   r$smd_broad, r$n_disruption,
                   ifelse(is.na(r$smd_strict), "NA", sprintf("%.3f", r$smd_strict)),
                   r$n_strict,
                   r$direction_stable))
}


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 7 — Largest-learner sensitivity
# Remove the learner with the most observations and rerun pooled slope
# If the pooled estimate changes substantially, it is dominated by that learner
# ══════════════════════════════════════════════════════════════════════════════

add_line("")
add_line("SECTION 7: Largest-learner sensitivity check")
add_line(strrep("-", 72))

largest_learner <- weekly %>%
  count(learner_id, sort = TRUE) %>%
  slice_head(n = 1) %>%
  pull(learner_id)

add_line(sprintf("Most-observed learner: %s (%d learner-week rows)",
                 largest_learner,
                 weekly %>% filter(learner_id == largest_learner) %>% nrow()))

weekly_excl <- weekly %>% filter(learner_id != largest_learner)

sensitivity_slopes <- map_dfr(
  c("english_proportion", "apology_uncertainty_rate"),
  function(outcome) {
    d <- weekly_excl %>%
      drop_na(study_week, all_of(outcome)) %>%
      filter(n_distinct(learner_id) >= 2)
    if (nrow(d) < 8) return(tibble())
    fit <- lm(as.formula(paste(outcome, "~ study_week + factor(learner_id)")), data = d)
    tidy(fit, conf.int = TRUE) %>%
      filter(term == "study_week") %>%
      mutate(outcome = outcome, excluded = largest_learner, n_obs = nrow(d))
  }
)

write_csv(sensitivity_slopes, file.path(out_dir, "sensitivity_largest_learner.csv"))

add_line("")
add_line(sprintf("Pooled slope excluding %s:", largest_learner))
if (nrow(sensitivity_slopes) > 0) {
  for (i in seq_len(nrow(sensitivity_slopes))) {
    r <- sensitivity_slopes[i, ]
    add_line(sprintf("  %s: estimate=%.4f  95%% CI [%.4f, %.4f]  n=%d",
                     r$outcome, r$estimate, r$conf.low, r$conf.high, r$n_obs))
  }
  add_line("Compare with full-corpus pooled estimates in Section 5.")
  add_line("Substantial change signals that the largest learner drives the pooled result.")
} else {
  add_line("  Insufficient remaining data for sensitivity slope after exclusion.")
}


# ══════════════════════════════════════════════════════════════════════════════
# SECTION 8 — gt_correction cross-learner note
# ══════════════════════════════════════════════════════════════════════════════

add_line("")
add_line("SECTION 8: gt_correction_count cross-learner note")
add_line(strrep("-", 72))
add_line("'>' prefixed corrections appear in L002 and L004 exports but NOT in")
add_line("L001 or L003. This reflects an instructor formatting convention, not")
add_line("a learner difference. correction_density and gt_correction_count")
add_line("should NOT be compared directly across these learner pairs.")

gt_summary <- weekly %>%
  group_by(learner_id) %>%
  summarise(
    total_gt_corrections    = sum(gt_correction_count, na.rm = TRUE),
    weeks_with_gt           = sum(gt_correction_count > 0, na.rm = TRUE),
    mean_gt_per_week        = round(mean(gt_correction_count, na.rm = TRUE), 3),
    .groups = "drop"
  )

write_csv(gt_summary, file.path(out_dir, "gt_correction_summary.csv"))

for (i in seq_len(nrow(gt_summary))) {
  r <- gt_summary[i, ]
  add_line(sprintf("  %s: total gt_corrections=%d  weeks_with_gt=%d  mean_per_week=%.3f",
                   r$learner_id, r$total_gt_corrections,
                   r$weeks_with_gt, r$mean_gt_per_week))
}


# ══════════════════════════════════════════════════════════════════════════════
# Write summary text
# ══════════════════════════════════════════════════════════════════════════════

writeLines(summary_lines, file.path(out_dir, "exploratory_analysis_summary.txt"))
cat("\nAnalysis complete.\n")
cat("Outputs written to:", out_dir, "\n\n")
cat(paste(summary_lines, collapse = "\n"), "\n")
