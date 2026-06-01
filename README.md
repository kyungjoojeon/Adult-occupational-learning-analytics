[README.md](https://github.com/user-attachments/files/28452142/README.md)
# Adult-occupational-learning-analytics
Research portfolio investigating AI-mediated feedback systems and longitudinal behavioral trace data from adult occupational English learning.
# Occupational English Learning Trace Analysis

**Kyungjoo Jeon** | PhD applicant, Learning Sciences / Learning Analytics

---

## Overview

This repository documents an exploratory longitudinal analysis of KakaoTalk
instructional message records from four adult professional English learners.
The corpus spans 269 to 824 days per learner and contains 6,045 parsed
messages across 327 observed learner-weeks.

The central question is straightforward: what patterns of participation,
English-language use, scheduling friction, and instructor feedback are visible
in the everyday messaging record of adult occupational English learners, and
what do those patterns suggest for future research design?

This is a practitioner-originated dataset analyzed with research discipline.
The learners are real professionals the instructor worked with across multiple
years. The analysis makes no causal claims and no population-level inferences.
Its purpose is to show how trace data from naturalistic instructional settings
can be handled carefully enough to generate credible research questions.
***Note on Scalability:** This repository serves as a methodological pilot framework. The parsing, data-cleaning, and feature-engineering pipelines established here are designed to scale directly to my broader longitudinal repository tracking 25 concurrent professional learners across 118 weeks.*

---

## Corpus

| Learner | Occupational domain       | Observed weeks | Learner msgs | Instructor msgs | Span      |
|---------|---------------------------|---------------|--------------|-----------------|-----------|
| L001    | Automotive / manufacturing | 31            | 74           | 146             | 269 days  |
| L002    | Technology / engineering   | 104           | 354          | 460             | 815 days  |
| L003    | Consumer goods / corporate | 79            | 1,179        | 1,618           | 579 days  |
| L004    | Technology / software      | 113           | 595          | 1,619           | 824 days  |

Source data are private KakaoTalk exports. Raw files are not committed to this
repository. The parsing workflow is manifest-driven and fully reproducible from
any set of exports matching the expected format (see `data/raw/corpus_manifest_template.csv`).

---

## Research Questions

| ID  | Question                                                                                             | Analytic approach                                      |
|-----|------------------------------------------------------------------------------------------------------|--------------------------------------------------------|
| RQ1 | How does weekly message participation vary within and across learners over the observed period?       | Learner-week summaries; within-learner trend screens   |
| RQ2 | Are schedule-disruption markers associated with changes in apology/uncertainty language within learners? | Within-learner SMDs; disruption vs. non-disruption comparison |
| RQ3 | How does English-message use change over time for each learner?                                      | Within-learner OLS slopes; forest plot for heterogeneity |
| RQ4 | Does instructor correction density co-vary with learner message volume?                              | Scatterplots; learner fixed-effect screen              |

---

## Theoretical Orientation

The project draws on a participation-based view of learning (Sfard, 1998),
operationalized through behavioral trace analytics (Clow, 2012). From this
perspective, learning is partly visible in the regularity, volume, and
character of a learner's participation in instructional routines — not as a
direct measure of internal cognitive states, but as a residue of activity left
in a digital communication record.

This framing matters for what the indicators can and cannot mean. Weekly
message volume, English-language use, scheduling-disruption markers, and
instructor feedback density are treated as observable traces of the learning
situation. They are not measures of motivation, proficiency, anxiety, or
development. Adult occupational learning adds the ecological context:
professionals studying a language while managing workplace demands face a
different participation structure than classroom learners, and the trace record
may reflect workplace rhythms as much as learning trajectories.

---

## Indicators and Interpretation Boundaries

| Indicator                   | Operational definition                                                    | What it should not be taken to mean                   |
|-----------------------------|---------------------------------------------------------------------------|-------------------------------------------------------|
| Weekly participation        | Learner message count per observed week                                   | Motivation, effort, or learning quality               |
| English-message use         | Messages containing 3+ consecutive alphabetic characters                  | Spoken fluency or language proficiency                |
| Schedule-disruption marker  | Messages containing scheduling-friction language (Korean-primary signal)  | A validated measure of occupational workload          |
| Apology/uncertainty marker  | Messages containing apology, hedging, or uncertainty language             | Anxiety, hesitation, or a psychological state         |
| Instructor feedback marker  | Instructor messages containing correction or suggestion notation          | Complete feedback quality or learner ability          |
| `>` correction marker       | Instructor corrections formatted with `>` prefix (L002, L004 only)       | Equivalent to keyword-coded corrections across learners |
| Change over time            | Descriptive patterns across observed study weeks                          | Causal growth, treatment effect, or development       |

Note on cross-learner comparability: `>` prefixed corrections appear in L002
and L004 exports but not in L001 or L003, reflecting an instructor formatting
convention rather than a learner difference. Correction density comparisons
across these learner pairs should account for this. See `docs/codebook.md`.

---

## Data Architecture

The workflow separates five layers, keeping raw private data isolated from
derived public-facing outputs.

| Layer              | Unit                             | File                                      |
|--------------------|----------------------------------|-------------------------------------------|
| Manifest           | One row per chat export          | `data/raw/corpus_manifest_local.csv`      |
| Participant metadata | One row per anonymized learner | `data/participant_metadata.csv`           |
| Message-level      | One row per parsed message       | `data/processed/message_level_corpus.csv` |
| Learner-week       | One row per learner per week     | `data/derived/learner_week_summary.csv`   |
| Learner summary    | One row per learner              | `data/derived/learner_summary.csv`        |

Parsing is logged to `data/derived/parsing_log.csv`, which records raw line
counts, date header counts, continuation merges, unmatched lines, and
observation windows for each export. This log is the primary transparency
artifact for the parsing layer.

---

## Repository Structure

```
.
├── README.md
├── scripts/
│   ├── 01_build_corpus.R          # Manifest-driven parser; produces all data layers
│   ├── 02_make_figures.R          # Figure generation (Figs 1–6)
│   └── 03_model_engagement.R      # Within-learner correlations, SMDs, pooled screens
├── data/
│   ├── participant_metadata.csv
│   ├── raw/
│   │   ├── corpus_manifest_template.csv
│   │   ├── corpus_manifest_local.csv    # Private paths; not committed
│   │   └── chat_exports/               # Private .txt files; not committed
│   ├── example/
│   │   └── corpus_manifest_synthetic.csv
│   ├── processed/
│   │   └── message_level_corpus.csv
│   └── derived/
│       ├── learner_week_summary.csv
│       ├── learner_summary.csv
│       ├── parsing_log.csv
│       ├── descriptive_uncertainty.csv
│       ├── within_learner_correlations.csv
│       ├── learner_slopes.csv
│       ├── slope_heterogeneity.csv
│       ├── disruption_apology_uncertainty_differences.csv
│       ├── sensitivity_disruption_smd.csv
│       ├── sensitivity_largest_learner.csv
│       ├── exploratory_model_results.csv
│       ├── model_diagnostics.csv
│       └── exploratory_analysis_summary.txt
├── figures/
│   ├── fig1_weekly_engagement_by_learner.png
│   ├── fig2_learner_trace_indicators.png
│   ├── fig3_feedback_gap_by_learner.png
│   ├── fig4_disruption_apology_uncertainty_by_learner.png
│   ├── fig5_observation_coverage.png
│   └── fig6_within_learner_slopes.png
└── docs/
    ├── codebook.md
    ├── data_dictionary.md
    ├── methodological_reflection_memo.md
    ├── methodological_tradeoffs.md
    ├── apology_uncertainty_validation_plan.md
    ├── statistical_interpretation.md
    └── figure_captions.md
```

---

## Reproducibility

Install required R packages:

```r
install.packages(c("tidyverse", "lubridate", "broom", "scales"))
```

Run in order:

```bash
# Build corpus from private local exports
Rscript scripts/01_build_corpus.R data/raw/corpus_manifest_local.csv data/participant_metadata.csv

# Or run with synthetic example (no private data needed)
Rscript scripts/01_build_corpus.R data/example/corpus_manifest_synthetic.csv data/participant_metadata.csv

# Generate figures
Rscript scripts/02_make_figures.R

# Run analysis
Rscript scripts/03_model_engagement.R
```

Raw chat exports are private and not committed to this repository. A reviewer
can inspect the full parsing, aggregation, and analysis workflow using the
synthetic example. Results from the real corpus are available in
`data/derived/` and `figures/`.

---

## Key Analytic Decisions

**Why learner-week aggregation.** Individual messages are too context-dependent
for most research claims; learner-level summaries erase week-to-week variation.
The learner-week layer preserves temporal structure while making cautious
cross-week comparison possible.

**Why within-learner slopes precede pooled models.** With four learners whose
observation windows differ substantially (31–113 weeks), a pooled slope
conceals heterogeneous learner trajectories. `03_model_engagement.R` reports
within-learner slopes and a sign-agreement check before any pooled estimate.
The forest plot (Fig 7) makes learner heterogeneity visible at a glance.

**Why `work` was removed from the disruption keyword list.** The term fires
frequently on English lesson content ("make me work hard," "I don't guide them
at work") unrelated to scheduling. Korean-specific terms carry the primary
disruption signal. See `docs/codebook.md` for the full keyword rationale.

**Why `>` corrections are tracked separately.** Instructor corrections
formatted with a `>` prefix appear in L002 and L004 exports but not in L001 or
L003. Absorbing them silently into `correction_density` would make
cross-learner comparison of feedback activity non-comparable. Both variables
are retained; the distinction is documented in the data dictionary.

**Why the parsing log matters.** Post-blank content lines — non-empty lines
following a blank line — were identified as a silent failure risk in an earlier
version of the parser. The current version resets continuation context at blank
lines and counts post-blank content in `lines_unmatched` rather than absorbing
it into the wrong message row. The parsing log records this count per learner
so the scope of the change is auditable.

---

## Limitations

The data do not support causal inference, proficiency estimation, learner
diagnosis, or generalization beyond this corpus. Observation windows differ
across learners and were not designed to be comparable. The coded indicators
are rule-based text markers, not validated measurement instruments. Missing
weeks may reflect disengagement, scheduling breaks, work travel, or export
boundaries — the data cannot distinguish these.

These limitations are appropriate for the project's purpose. This is an
exploratory analysis of practitioner-collected records, not an intervention
study or a validated survey instrument. Its value lies in showing how
naturalistic instructional data can be organized carefully enough to generate
questions worth asking in a more rigorous future design.

---

## References

Clow, D. (2012). The learning analytics cycle: Closing the loop effectively.
*Proceedings of the 2nd International Conference on Learning Analytics and
Knowledge*, 134–138.

Sfard, A. (1998). On two metaphors for learning and the dangers of choosing
just one. *Educational Researcher*, 27(2), 4–13.
