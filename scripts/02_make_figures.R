# 02_make_figures.R
# Generates all seven figures for the occupational English learning trace corpus.
#
# Figures produced:
#   fig1_weekly_engagement_by_learner.png   — longitudinal participation per learner
#   fig2_learner_trace_indicators.png       — learner-level summary with raw points
#   fig3_feedback_gap_by_learner.png        — word count vs correction density
#   fig4_disruption_apology_uncertainty_by_learner.png — within-learner SMD comparison
#   fig5_observation_coverage.png           — coverage heatmap
#   fig6_residual_check.png                 — residual plot for pooled engagement screen
#   fig7_learner_slopes_forest.png          — within-learner slope forest plot
#
# Design principles:
#   - Individual learner-week data points are shown in every summary figure.
#   - Pooled estimates are never shown without learner-level context.
#   - Heterogeneity is visible before any summary statistic.
#   - Captions embedded in subtitles describe what the figure is and is not.
#
# Dependencies: tidyverse, broom, scales
# Run after: 01_build_corpus.R
# Note: fig7 computes within-learner slopes internally and writes learner_slopes.csv.

library(tidyverse)
library(broom)
library(scales)

# ── Paths ──────────────────────────────────────────────────────────────────────
weekly_path  <- "data/derived/learner_week_summary.csv"
slopes_path  <- "data/derived/learner_slopes.csv"
fig_dir      <- "figures"

dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

weekly <- read_csv(weekly_path, show_col_types = FALSE) %>%
  mutate(learner_id = as.character(learner_id))

if (nrow(weekly) == 0) stop("learner_week_summary.csv is empty. Run 01_build_corpus.R first.")

# ── Shared palette and helpers ─────────────────────────────────────────────────
LEARNER_COLORS <- c(
  L001 = "#4878CF",
  L002 = "#D65F5F",
  L003 = "#6ACC65",
  L004 = "#B47CC7"
)

weekly <- weekly %>%
  mutate(learner_short = str_replace(learner_label, "Adult learner ", "L"))

caption_text <- function(...) {
  paste0(strwrap(paste0(...), width = 110), collapse = "\n")
}

save_fig <- function(plot, filename, width = 10, height = 6) {
  path <- file.path(fig_dir, filename)
  ggsave(path, plot, width = width, height = height, dpi = 150, bg = "white")
  cat("Saved:", path, "\n")
}

base_theme <- function() {
  theme_minimal(base_size = 10) +
    theme(
      plot.title       = element_text(face = "bold", size = 11),
      plot.subtitle    = element_text(size = 8, color = "grey40", lineheight = 1.3),
      plot.caption     = element_text(size = 7, color = "grey55", hjust = 0),
      panel.grid.minor = element_blank(),
      strip.text       = element_text(face = "bold", size = 9)
    )
}


# ── Figure 1: Weekly engagement per learner ────────────────────────────────────
cat("Generating Figure 1...\n")

disruption_weeks <- weekly %>%
  filter(disruption_flag == 1) %>%
  mutate(ypos = learner_messages + 0.3)

max_lm <- max(weekly$learner_messages, na.rm = TRUE)

fig1 <- ggplot(weekly, aes(x = study_week)) +
  geom_col(aes(y = learner_messages, fill = learner_id),
           alpha = 0.55, width = 0.85) +
  geom_line(aes(y = english_proportion * max_lm, group = learner_id),
            color = "#222222", linewidth = 0.6, alpha = 0.75, na.rm = TRUE) +
  geom_point(data = disruption_weeks, aes(y = ypos),
             shape = 4, size = 1.8, color = "#CC2222", stroke = 0.9) +
  scale_y_continuous(
    name     = "Learner messages per week",
    sec.axis = sec_axis(~ . / max_lm,
                        name   = "English-message proportion",
                        labels = label_percent(accuracy = 1))
  ) +
  scale_x_continuous(name = "Study week (learner-relative)") +
  scale_fill_manual(values = LEARNER_COLORS, guide = "none") +
  facet_wrap(~ learner_short, ncol = 1, scales = "free_y") +
  labs(
    title    = "Figure 1. Weekly Engagement Across Learners",
    subtitle = paste0(
      "Bars = learner message count (left axis).  Line = English-message proportion (right axis).\n",
      "Red \u00d7 = disruption-coded week.  Observation windows differ; do not compare ",
      "absolute week numbers across panels."
    ),
    caption  = caption_text(
      "Observed weeks: L001=31, L002=104, L003=79, L004=113.  ",
      "English proportion is NA for zero-message weeks (line interrupted)."
    )
  ) +
  base_theme() +
  theme(axis.title.y.right = element_text(angle = 90, hjust = 0.5, size = 8))

save_fig(fig1, "fig1_weekly_engagement_by_learner.png", width = 10, height = 10)


# ── Figure 2: Learner trace indicators with raw points ────────────────────────
cat("Generating Figure 2...\n")

trace_vars <- tribble(
  ~variable,                  ~label,
  "english_proportion",       "English-message\nproportion",
  "apology_uncertainty_rate", "Apology / uncertainty\nmarker rate",
  "correction_density",       "Instructor correction\ndensity"
)

trace_long <- weekly %>%
  select(learner_id, learner_short, all_of(trace_vars$variable)) %>%
  pivot_longer(-c(learner_id, learner_short),
               names_to = "variable", values_to = "value") %>%
  left_join(trace_vars, by = "variable") %>%
  filter(!is.na(value))

learner_means <- trace_long %>%
  group_by(learner_id, learner_short, variable, label) %>%
  summarise(mean_value = mean(value, na.rm = TRUE), .groups = "drop")

set.seed(42)
fig2 <- ggplot(trace_long,
               aes(x = learner_short, y = value, color = learner_id)) +
  geom_jitter(alpha = 0.30, size = 1.4, width = 0.18, shape = 16) +
  geom_point(data = learner_means, aes(y = mean_value),
             size = 4, shape = 21, fill = "white", color = "black", stroke = 1.0) +
  geom_point(data = learner_means, aes(y = mean_value, fill = learner_id),
             size = 3.5, shape = 21, stroke = 0, alpha = 0.9) +
  scale_color_manual(values = LEARNER_COLORS, guide = "none") +
  scale_fill_manual(values  = LEARNER_COLORS, guide = "none") +
  facet_wrap(~ label, scales = "free_y", ncol = 3) +
  labs(
    title    = "Figure 2. Learner-Level Trace Indicators",
    subtitle = paste0(
      "Small points = individual learner-week observations (jittered).  ",
      "Large outlined circles = within-learner mean.\n",
      "Indicators are descriptive traces, not validated measures of proficiency, ",
      "motivation, or psychological state."
    ),
    x = NULL, y = "Value",
    caption  = caption_text(
      "N = 4 learners; do not interpret visual separation as evidence of ",
      "stable learner differences.  Wide within-learner spread is expected and honest."
    )
  ) +
  base_theme()

save_fig(fig2, "fig2_learner_trace_indicators.png", width = 10, height = 5)


# ── Figure 3: Word count vs correction density ────────────────────────────────
cat("Generating Figure 3...\n")

fig3_data <- weekly %>%
  filter(!is.na(avg_learner_word_count), !is.na(correction_density))

fig3 <- ggplot(fig3_data,
               aes(x = avg_learner_word_count, y = correction_density,
                   color = learner_id)) +
  geom_point(alpha = 0.45, size = 2.0, shape = 16) +
  geom_smooth(aes(group = learner_id), method = "lm", se = FALSE,
              linewidth = 0.7, alpha = 0.7, show.legend = FALSE) +
  scale_color_manual(values = LEARNER_COLORS,
                     labels = c("L001","L002","L003","L004"), name = "Learner") +
  labs(
    title    = "Figure 3. Written Production and Instructor Feedback Density",
    subtitle = paste0(
      "Each point = one learner-week.  Lines = within-learner OLS trend only; ",
      "no pooled fit shown.\n",
      "Co-occurrence of higher word count and higher correction density ",
      "does not imply causation."
    ),
    x       = "Avg learner word count per week",
    y       = "Instructor correction density\n(corrections / instructor messages)",
    caption = caption_text(
      "Keyword-coded corrections only.  ",
      "> -prefix corrections (L002, L004) tracked separately; see codebook.md."
    )
  ) +
  base_theme() +
  theme(legend.position = "right")

save_fig(fig3, "fig3_feedback_gap_by_learner.png", width = 9, height = 5.5)


# ── Figure 4: Disruption vs non-disruption apology/uncertainty ────────────────
cat("Generating Figure 4...\n")

fig4_data <- weekly %>%
  filter(!is.na(apology_uncertainty_rate)) %>%
  mutate(
    disruption_label = if_else(disruption_flag == 1,
                               "Disruption\nweek", "No disruption\nweek"),
    disruption_label = factor(disruption_label,
                              levels = c("No disruption\nweek", "Disruption\nweek"))
  )

# Facet label showing n per group
facet_ns <- fig4_data %>%
  count(learner_short, learner_id, disruption_label) %>%
  pivot_wider(names_from = disruption_label, values_from = n, names_repair = "minimal") %>%
  mutate(facet_label = paste0(
    learner_short, "\ndis=", `Disruption\nweek`,
    "  non=", `No disruption\nweek`
  ))

fig4_data <- fig4_data %>%
  left_join(facet_ns %>% select(learner_short, facet_label), by = "learner_short")

fig4_means <- fig4_data %>%
  group_by(learner_id, facet_label, disruption_label) %>%
  summarise(mean_rate = mean(apology_uncertainty_rate, na.rm = TRUE), .groups = "drop")

set.seed(77)
fig4 <- ggplot(fig4_data,
               aes(x = disruption_label, y = apology_uncertainty_rate,
                   color = learner_id)) +
  geom_jitter(alpha = 0.40, size = 1.8, width = 0.12, shape = 16) +
  geom_point(data = fig4_means, aes(y = mean_rate),
             size = 5, shape = 21, fill = "white", color = "black", stroke = 1.1) +
  geom_point(data = fig4_means, aes(y = mean_rate, fill = learner_id),
             size = 4.5, shape = 21, stroke = 0, alpha = 0.9) +
  geom_line(data = fig4_means, aes(y = mean_rate, group = facet_label),
            color = "grey50", linewidth = 0.7, linetype = "dashed") +
  scale_color_manual(values = LEARNER_COLORS, guide = "none") +
  scale_fill_manual(values  = LEARNER_COLORS, guide = "none") +
  facet_wrap(~ facet_label, ncol = 4) +
  labs(
    title    = "Figure 4. Apology / Uncertainty Markers: Disruption vs Non-Disruption Weeks",
    subtitle = paste0(
      "Small points = learner-week observations.  Large circles = group mean.\n",
      "Dashed line connects means.  Within-learner comparison only; ",
      "no causal inference warranted."
    ),
    x = NULL, y = "Apology / uncertainty marker rate",
    caption = caption_text(
      "L001 has only 4 disruption weeks; treat that estimate with extra caution.  ",
      "Within-learner SMDs: L001=\u22120.55, L002=+0.76, L003=+0.46, L004=+0.55.  ",
      "Apology/uncertainty marker is a communicative stance proxy, not an anxiety measure."
    )
  ) +
  base_theme()

save_fig(fig4, "fig4_disruption_apology_uncertainty_by_learner.png", width = 12, height = 5)


# ── Figure 5: Coverage heatmap ────────────────────────────────────────────────
cat("Generating Figure 5...\n")

max_week     <- max(weekly$study_week, na.rm = TRUE)
all_learners <- sort(unique(weekly$learner_id))

obs_counts <- weekly %>%
  count(learner_id, name = "obs_weeks")

coverage_grid <- expand_grid(
  learner_id = all_learners,
  study_week = seq_len(max_week)
) %>%
  left_join(weekly %>% select(learner_id, study_week) %>% mutate(observed = 1L),
            by = c("learner_id","study_week")) %>%
  mutate(observed = replace_na(observed, 0L)) %>%
  left_join(obs_counts, by = "learner_id") %>%
  mutate(learner_facet = paste0("Adult learner ", str_sub(learner_id, 2),
                                "  (", obs_weeks, " wks observed)"))

fig5 <- ggplot(coverage_grid,
               aes(x = study_week,
                   y = fct_rev(factor(learner_facet)),
                   fill = factor(observed))) +
  geom_tile(color = NA, height = 0.85) +
  scale_fill_manual(
    values = c("0" = "#EEEEEE", "1" = "#4878CF"),
    labels = c("Unobserved", "Observed"),
    name   = NULL
  ) +
  scale_x_continuous(name   = "Study week (learner-relative)",
                     breaks = c(1, seq(20, max_week, by = 20))) +
  labs(
    title    = "Figure 5. Observation Coverage by Learner-Week",
    subtitle = paste0(
      "Blue = week with at least one observed message.  Grey = no messages recorded.\n",
      "Uneven windows limit cross-learner longitudinal comparison.  ",
      "Inspect before interpreting trend analyses."
    ),
    y       = NULL,
    caption = caption_text(
      "Gaps may reflect missed lessons, travel, export boundaries, or ",
      "weeks without any messaging.  The parser cannot distinguish these causes."
    )
  ) +
  base_theme() +
  theme(
    legend.position = "bottom",
    legend.key.size = unit(0.4, "cm"),
    axis.text.y     = element_text(size = 9)
  )

save_fig(fig5, "fig5_observation_coverage.png", width = 12, height = 3.5)


# ── Figure 6: Residual check for pooled engagement screen ─────────────────────
cat("Generating Figure 6...\n")

fig6_data <- weekly %>%
  filter(!is.na(disruption_flag), !is.na(learner_messages))

fit_pooled <- lm(learner_messages ~ disruption_flag + factor(learner_id),
                 data = fig6_data)

fig6_aug <- augment(fit_pooled, data = fig6_data)

fig6 <- ggplot(fig6_aug, aes(x = .fitted, y = .resid, color = learner_id)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60", linewidth = 0.7) +
  geom_point(alpha = 0.45, size = 1.8, shape = 16) +
  geom_smooth(method = "loess", se = FALSE, linewidth = 0.7,
              color = "#333333", alpha = 0.6) +
  scale_color_manual(values = LEARNER_COLORS,
                     labels = c("L001","L002","L003","L004"), name = "Learner") +
  labs(
    title    = "Figure 6. Residual Check \u2014 Pooled Engagement Screen",
    subtitle = paste0(
      "Model: learner_messages ~ disruption_flag + factor(learner_id).  ",
      "Dashed line = zero residual.\n",
      "Systematic curvature or fan shape would signal model misspecification."
    ),
    x       = "Fitted values",
    y       = "Residuals",
    caption = caption_text(
      "Small N limits diagnostic power.  ",
      "See Figure 7 for learner-specific within-learner patterns."
    )
  ) +
  base_theme() +
  theme(legend.position = "right")

save_fig(fig6, "fig6_residual_check.png", width = 8, height = 5)


# ── Figure 7: Within-learner slopes forest plot ───────────────────────────────
cat("Generating Figure 7...\n")

trend_outcomes <- tribble(
  ~outcome,                   ~outcome_label,
  "english_proportion",       "English-message proportion",
  "apology_uncertainty_rate", "Apology / uncertainty rate",
  "correction_density",       "Instructor correction density",
  "learner_messages",         "Learner message count"
)

learner_slopes <- weekly %>%
  group_by(learner_id, learner_short) %>%
  group_modify(~ {
    d <- .x
    map_dfr(trend_outcomes$outcome, function(out) {
      dd <- d %>% select(study_week, val = all_of(out)) %>% drop_na()
      out_label <- trend_outcomes$outcome_label[trend_outcomes$outcome == out]
      if (nrow(dd) < 4 || var(dd$val) == 0) {
        return(tibble(outcome = out, outcome_label = out_label,
                      estimate = NA_real_, conf_low = NA_real_,
                      conf_high = NA_real_, p_value = NA_real_, n_weeks = nrow(dd)))
      }
      fit <- lm(val ~ study_week, data = dd)
      tb  <- tidy(fit, conf.int = TRUE) %>% filter(term == "study_week")
      tibble(outcome = out, outcome_label = out_label,
             estimate = tb$estimate, conf_low = tb$conf.low,
             conf_high = tb$conf.high, p_value = tb$p.value, n_weeks = nrow(dd))
    })
  }) %>%
  ungroup()

# Write slopes CSV
write_csv(
  learner_slopes %>%
    rename(learner_label = learner_short) %>%
    mutate(across(where(is.numeric), ~ round(.x, 6))),
  slopes_path
)
cat("  Written:", slopes_path, "\n")

# Sign-agreement annotation
sign_agree <- learner_slopes %>%
  filter(!is.na(estimate)) %>%
  group_by(outcome, outcome_label) %>%
  summarise(agree = all(estimate > 0) | all(estimate < 0), .groups = "drop") %>%
  mutate(agree_label = if_else(agree,
                               "Signs agree",
                               "Signs disagree \u2014 pooled slope misleading"))

fig7_data <- learner_slopes %>%
  filter(!is.na(estimate)) %>%
  left_join(sign_agree, by = c("outcome","outcome_label")) %>%
  mutate(learner_short = fct_reorder(learner_short, estimate))

fig7 <- ggplot(fig7_data,
               aes(x = estimate, y = learner_short, color = learner_id)) +
  geom_vline(xintercept = 0, linetype = "dashed",
             color = "grey55", linewidth = 0.7) +
  geom_errorbar(aes(xmin = conf_low, xmax = conf_high), 
              width = 0.25, linewidth = 1.0, alpha = 0.65) +
  geom_point(size = 3.5, shape = 16) +
  geom_text(data = sign_agree,
            aes(x = Inf, y = -Inf, label = agree_label),
            inherit.aes = FALSE,
            hjust = 1.05, vjust = -0.4,
            size = 2.8, color = "grey40", fontface = "italic") +
  scale_color_manual(values = LEARNER_COLORS, guide = "none") +
  facet_wrap(~ outcome_label, scales = "free_x", ncol = 2) +
  labs(
    title    = "Figure 7. Within-Learner Slopes on Study Week",
    subtitle = paste0(
      "Each point = OLS slope estimated from that learner's observed weeks only.  ",
      "Bars = 95% CIs.\n",
      "Dashed line = zero slope.  Sign disagreement across learners means a pooled slope ",
      "is not a meaningful summary."
    ),
    x       = "Slope estimate (change per study week)",
    y       = NULL,
    caption = caption_text(
      "Observation windows: L001=31 wks, L002=104 wks, L003=79 wks, L004=113 wks.  ",
      "Slopes not directly comparable across learners with different window lengths.  ",
      "L003 English-proportion slope is the only estimate with CI entirely above zero."
    )
  ) +
  base_theme() +
  theme(panel.spacing = unit(1.2, "lines"))

save_fig(fig7, "fig7_learner_slopes_forest.png", width = 10, height = 6)

cat("\nAll 7 figures saved to:", fig_dir, "\n")
