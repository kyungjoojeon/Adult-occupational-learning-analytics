[README.md](https://github.com/user-attachments/files/28488189/README.md)
# Occupational English Learning Trace Analysis

**Kyungjoo Jeon** | PhD applicant, Learning Sciences / Learning Analytics | leaders94@gmail.com

---

## Why This Repository Exists

This repository has three purposes:

1. Demonstrate a reproducible workflow for transforming private instructional messaging records into analyzable behavioral trace data.
2. Explore methodological challenges specific to practitioner-generated learning analytics datasets — anonymization, indicator validity, keyword sensitivity, and small-N longitudinal design.
3. Provide an early-stage research artifact for doctoral work in Learning Analytics and Educational Technology.

The learners are real adult professionals. The messages are real instructional exchanges. The analysis makes no causal claims and no population-level inferences.

---

## Corpus

| Learner | Occupational domain        | Observed weeks | Learner msgs | Instructor msgs | Span     |
|---------|----------------------------|---------------|--------------|-----------------|----------|
| L001    | Automotive / manufacturing  | 31            | 74           | 146             | 269 days |
| L002    | Technology / engineering    | 104           | 354          | 460             | 815 days |
| L003    | Consumer goods / corporate  | 79            | 1,179        | 1,618           | 579 days |
| L004    | Technology / software       | 113           | 595          | 1,619           | 824 days |
| **Total** |                          | **327**       | **2,202**    | **3,843**       |          |

Source data are private KakaoTalk exports. Raw files are not committed to this repository. The parsing pipeline is fully reproducible from the synthetic example in `data/example/`.

---

## Research Questions

| ID  | Question                                                                                                    | Analytic approach                                            |
|-----|-------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------|
| RQ1 | How does weekly message participation vary within and across learners over the observed period?              | Learner-week summaries; within-learner trend screens         |
| RQ2 | Are disruption-coded weeks associated with higher apology/uncertainty marker rates within learners?          | Within-learner SMDs; disruption vs. non-disruption comparison |
| RQ3 | How stable are these associations across alternative keyword definitions?                                    | Sensitivity analysis: broad, no-late, no-sorry, Korean-only  |
| RQ4 | How does English-message use change over time for each learner?                                             | Within-learner OLS slopes; forest plot for heterogeneity     |
| RQ5 | What design implications emerge for AI-mediated feedback systems?                                           | Discussed in working paper Section 6                         |

---

## Key Findings

**Disruption and communicative stance.** Disruption-coded weeks are associated with higher apology/uncertainty language for three of four learners. L002 shows the strongest and most robust association: SMD +0.75 to +0.81 across four keyword sensitivity definitions. L001 shows the opposite direction but has only four disruption-coded weeks.

**English-message participation trends.** Slopes disagree in direction across learners. L003 is the only learner with a positive English-proportion slope whose confidence interval lies entirely above zero (+0.0026/week, 95% CI: [+0.0010, +0.0042]). A pooled slope is not interpretable given this heterogeneity.

**Cross-learner disruption signal.** L004 shows zero disruption weeks under Korean-only keyword definitions across 113 observed weeks — indicating scheduling friction was communicated exclusively in English for that learner.

---

## Key Figures

**Figure 4 — Apology/uncertainty marker rates in disruption vs. non-disruption weeks**

![Figure 4: Apology/Uncertainty Markers by Disruption Week Status](./figures/fig4_disruption_apology_uncertainty_by_learner.png)

*Each panel shows one learner. Points are individual learner-weeks (jittered). Large circles are group means. Dashed line connects means.*

---

**Figure 7 — Within-learner OLS slopes on study week (forest plot)**

![Figure 7: Within-Learner Slopes Forest Plot](./figures/fig7_learner_slopes_forest.png)

*Each point is an OLS slope estimated from one learner's observed weeks. Bars are 95% CIs. Dashed line = zero. Sign disagreement across learners means a pooled slope is not a meaningful summary.*

---

## Analytic Approach

Because the corpus contains four learners, analyses focus on within-learner comparisons rather than population-level inference. The project therefore emphasizes descriptive trends, standardized mean differences, keyword sensitivity checks, and methodological transparency.

Pooled fixed-effect models are included as exploratory screens only, and are always preceded by individual learner results. With N = 4 groups, random-effects variance estimates would be unreliable; the Future Analytic Directions memo documents the corpus expansion required to unlock multilevel modeling.

---

## Indicators

Three behavioral indicators are extracted from the message text using rule-based keyword detection.

| Indicator | Operational definition | What it should not be taken to mean |
|-----------|----------------------|--------------------------------------|
| Schedule-disruption marker | Messages containing scheduling-friction language | A validated measure of occupational workload |
| Apology/uncertainty marker | Messages containing apology, hedging, or uncertainty language | Anxiety, hesitation, or a psychological state |
| Instructor correction density | Proportion of instructor messages with correction notation | Total feedback quality or learner ability |
| `>` correction marker | `>`-prefixed corrections (L002, L004 only) | Equivalent to keyword-coded corrections across learners |

The `>` prefix reflects an instructor formatting convention, not a learner difference. Correction indicators are tracked separately across these two formats to preserve cross-learner comparability. See `docs/codebook.md` for full keyword lists, false positive documentation, and sensitivity analysis rationale.

---

## Data Architecture

| Layer              | Unit                           | File                                      |
|--------------------|--------------------------------|-------------------------------------------|
| Manifest           | One row per chat export        | `data/raw/corpus_manifest_local.csv`      |
| Participant metadata | One row per anonymized learner | `data/participant_metadata.csv`          |
| Message-level      | One row per parsed message     | `data/processed/message_level_corpus.csv` |
| Learner-week       | One row per learner per week   | `data/derived/learner_week_summary.csv`   |
| Learner summary    | One row per learner            | `data/derived/learner_summary.csv`        |

Parsing is logged to `data/derived/parsing_log.csv`, recording raw line counts, continuation merges, unmatched lines, and date spans per export. This log is the primary transparency artifact for the data ingestion layer and is safe to commit publicly.

---

## Repository Structure

```
.
├── README.md
├── scripts/
│   ├── 01_build_corpus.R          # Manifest-driven parser; produces all data layers
│   ├── 02_make_figures.R          # Generates Figs 1–7; writes learner_slopes.csv
│   ├── 03_model_engagement.R      # Within-learner SMDs, slopes, pooled screens
│   └── sensitivity_checks.R       # Six keyword sensitivity tests; writes Fig 8
├── data/
│   ├── participant_metadata.csv
│   ├── raw/
│   │   ├── corpus_manifest_template.csv
│   │   └── corpus_manifest_local.csv    # Private paths; not committed
│   ├── example/
│   │   ├── corpus_synthetic_export.txt  # Fabricated export; safe to publish
│   │   └── corpus_manifest_synthetic.csv
│   ├── processed/
│   │   └── message_level_corpus.csv
│   └── derived/
│       ├── learner_week_summary.csv
│       ├── learner_summary.csv
│       ├── learner_slopes.csv
│       ├── parsing_log.csv
│       ├── disruption_apology_uncertainty_differences.csv
│       ├── sensitivity_smd_comparison.csv
│       ├── sensitivity_disruption_narrow.csv
│       └── exploratory_model_results.csv
├── figures/
│   ├── fig1_weekly_engagement_by_learner.png
│   ├── fig2_learner_trace_indicators.png
│   ├── fig3_feedback_gap_by_learner.png
│   ├── fig4_disruption_apology_uncertainty_by_learner.png
│   ├── fig5_observation_coverage.png
│   ├── fig6_within_learner_slopes.png
│   ├── fig7_learner_slopes_forest.png
│   └── fig8_sensitivity_smd.png
└── docs/
    ├── working_paper.pdf                    # Full pilot study manuscript (9 pages)
    ├── codebook.md                          # Keyword lists, false positives, sensitivity rationale
    ├── data_dictionary.md                   # Variable definitions and change log
    ├── indicator_validation_memo.md         # Theoretical grounding and validity limits
    ├── theoretical_framing.md              # Variable-to-theory mapping table
    ├── methodological_reflection_memo.md    # Audit findings, parser revisions, positionality
    ├── future_analytic_directions.md        # Statistical upgrade roadmap and corpus expansion thresholds
    └── apology_uncertainty_validation_plan.md
```

---

## Reproducibility

Install required R packages:

```r
install.packages(c("tidyverse", "lubridate", "broom", "scales"))
```

Run in order using the synthetic example (no private data required):

```bash
Rscript scripts/01_build_corpus.R data/example/corpus_manifest_synthetic.csv data/participant_metadata.csv
Rscript scripts/02_make_figures.R
Rscript scripts/03_model_engagement.R
Rscript scripts/sensitivity_checks.R
```

To run against private local exports, replace the first argument with `data/raw/corpus_manifest_local.csv`. Results from the real corpus are available in `data/derived/` and `figures/`.

---

## Documentation

| Document | Contents |
|----------|----------|
| [`docs/working_paper.pdf`](./docs/working_paper.pdf) | Full pilot study manuscript (Introduction, Literature, Corpus, Indicators, Results, Limitations, AI Feedback Implications) |
| [`docs/codebook.md`](./docs/codebook.md) | Exact keyword lists, corpus hit rates, false positive examples, cross-learner comparability notes |
| [`docs/indicator_validation_memo.md`](./docs/indicator_validation_memo.md) | Theoretical grounding for each indicator; known threats to validity; what validation would require |
| [`docs/theoretical_framing.md`](./docs/theoretical_framing.md) | Variable-to-theory mapping across SRL, behavioral trace analytics, participation theory, and formative feedback |
| [`docs/methodological_reflection_memo.md`](./docs/methodological_reflection_memo.md) | Parser audit findings, blank-line continuation fix, `>` correction asymmetry, practitioner-to-researcher reflection |
| [`docs/future_analytic_directions.md`](./docs/future_analytic_directions.md) | Why mixed models require N >= 15; corpus expansion roadmap; what can be done now |
| [`docs/data_dictionary.md`](./docs/data_dictionary.md) | Every variable in every output file, with types, derivations, and change log |

---

## Limitations

The corpus contains four learners with unequal observation windows, no independent learning outcome measures, and rule-based indicators without inter-rater reliability checks. The apology/uncertainty marker faces a cross-cultural interpretive challenge: apologetic and deferential language is a routine politeness convention in Korean professional messaging, and keyword matching cannot distinguish this from affective stance. The disruption indicator for L003 and L004 is heavily dependent on the English term *late*; removing it substantially reduces disruption week counts for both learners.

These constraints are documented transparently in the working paper (Section 5), the codebook, and the sensitivity analysis report. They define the appropriate scope of the findings, not a reason to dismiss them.

---

## References

Clow, D. (2012). The learning analytics cycle: Closing the loop effectively. *Proceedings of the 2nd International Conference on Learning Analytics and Knowledge*, 134-138.

Maas, C. J. M., & Hox, J. J. (2005). Sufficient sample sizes for multilevel modeling. *Methodology*, 1(3), 86-92.

Pintrich, P. R. (2000). The role of goal orientation in self-regulated learning. In M. Boekaerts, P. R. Pintrich, & M. Zeidner (Eds.), *Handbook of self-regulation* (pp. 451-502). Academic Press.

Sfard, A. (1998). On two metaphors for learning and the dangers of choosing just one. *Educational Researcher*, 27(2), 4-13.
