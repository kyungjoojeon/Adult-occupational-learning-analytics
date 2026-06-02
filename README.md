# Adult Occupational English Learning Analytics

A reproducible learning analytics study examining longitudinal instructional communication among adult professional English learners.

---

## Overview

Adult professionals often learn a second language under conditions that differ substantially from traditional classroom environments. Workplace obligations, scheduling disruptions, and competing professional demands may influence how learners participate in instructional interactions over time.

This repository presents an exploratory longitudinal trace analysis of instructional KakaoTalk communication records from four adult professional English learners observed across 269–824 days of instruction.

**Corpus Summary**

| Metric              | Value        |
| ------------------- | ------------ |
| Learners            | 4            |
| Messages            | 6,045        |
| Learner Messages    | 2,202        |
| Instructor Messages | 3,843        |
| Observation Period  | 269–824 days |
| Learner-Weeks       | 327          |

The project emphasizes reproducibility, measurement transparency, and methodological reflection rather than causal claims or population-level inference.

---

## Research Questions

**RQ1.** How does weekly participation vary within and across adult professional learners over time?

**RQ2.** Are disruption-coded weeks associated with changes in apology/uncertainty language markers?

**RQ3.** How sensitive are these associations to alternative indicator definitions?

**RQ4.** How does English-language participation change longitudinally for each learner?

**RQ5.** What characteristics of workplace-constrained language learning should future adaptive feedback systems recognize?

---

## Key Findings

### Finding 1: Disruption-related communication patterns varied across learners

Three of four learners exhibited elevated apology/uncertainty marker rates during disruption-coded weeks, although effect sizes differed substantially across individuals.

### Finding 2: The strongest observed relationship remained stable across alternative definitions

Sensitivity analyses showed that learner L002 maintained a highly consistent disruption–communication association across four alternative keyword specifications (SMD range: +0.75 to +0.81), suggesting that the finding was not driven by a single lexical choice.

### Finding 3: Participation trajectories were heterogeneous

Learners demonstrated substantially different English-language participation trajectories. One learner exhibited a positive longitudinal trend whose confidence interval excluded zero, while other learners showed flat or declining patterns.

---

## Key Figures

### Figure 4. Disruption Weeks and Communicative Stance

![Figure 4](./figures/fig4_disruption_apology_uncertainty_by_learner.png)

Comparison of apology/uncertainty marker rates during disruption-coded and non-disruption weeks.

---

### Figure 7. Forest Plot of Within-Learner Slopes

![](figures/fig7_learner_slopes_forest.png)

Learner-specific OLS slope estimates for English-language participation with 95% confidence intervals.

---

### Figure 8. Sensitivity Analysis Across Alternative Indicator Definitions

![Figure 8](./figures/fig8_sensitivity_smd.png)

Standardized mean differences estimated under multiple operational definitions. Stable estimates indicate robustness to measurement specification, whereas larger shifts suggest greater sensitivity to keyword selection.

---

## Why This Repository Exists

This project was developed as an independent pilot study by a practitioner-researcher preparing for doctoral work in:

* Learning Analytics
* Educational Technology
* Learning Sciences
* AI-Mediated Feedback Systems

The repository serves three purposes:

1. Demonstrate a reproducible workflow for transforming instructional communication logs into analyzable behavioral trace data.
2. Explore methodological challenges in practitioner-generated learning analytics datasets.
3. Present an early-stage research artifact suitable for future doctoral and conference work.

---

## Methodological Principles

### Small-N Transparency

Because the corpus contains four learners, analyses focus primarily on within-learner comparisons rather than population-level inference.

### Indicator Transparency

Behavioral indicators are operational definitions rather than validated psychological measures.

For example:

| Indicator                  | Should Not Be Interpreted As   |
| -------------------------- | ------------------------------ |
| Schedule disruption marker | Objective workload measurement |
| Apology/uncertainty marker | Anxiety or emotional state     |
| Correction density         | Teaching quality               |

### Sensitivity Analysis

Alternative keyword definitions were systematically evaluated to assess robustness and expose measurement dependence.

---

## Repository Structure

```text
scripts/
├── 01_build_corpus.R
├── 02_make_figures.R
├── 03_model_engagement.R
└── sensitivity_checks.R

data/
├── processed/
├── derived/
└── example/

figures/

docs/
├── working_paper_adult_occupational_learning_analytics.pdf
├── codebook.md
├── indicator_validation_memo.md
├── methodological_reflection_memo.md
├── future_analytic_directions.md
└── theoretical_framing.md
```

---

## Reproducibility

Install required packages:

```r
install.packages(
  c("tidyverse","lubridate","broom","scales")
)
```

Run the pipeline:

```bash
Rscript scripts/01_build_corpus.R
Rscript scripts/02_make_figures.R
Rscript scripts/03_model_engagement.R
Rscript scripts/sensitivity_checks.R
```

Synthetic example data are included for replication purposes. Raw learner communication records are private and are not distributed.

---

## Documentation

| Document                       | Purpose                                       |
| ------------------------------ | --------------------------------------------- |
| Working Paper                  | Full pilot study manuscript                   |
| Codebook                       | Indicator definitions and keyword lists       |
| Indicator Validation Memo      | Construct validity discussion                 |
| Methodological Reflection Memo | Research and parser development notes         |
| Future Analytic Directions     | Statistical roadmap and corpus expansion plan |
| Theoretical Framing            | Variable-to-theory mapping                    |

---

## Limitations

This corpus contains four learners observed over unequal time spans. Indicators are rule-based and do not constitute validated psychological measures. Findings should be interpreted as exploratory behavioral trace analyses rather than evidence of causal effects or population-level relationships.

---

## Citation

Jeon, K. (2026). *Adult Occupational English Learning Analytics: A Longitudinal Trace Analysis of Instructional Communication Data.* Working paper.
