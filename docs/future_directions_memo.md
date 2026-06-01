**Future Analytic Directions Memo**

Kyungjoo Jeon  ·  Adult Occupational English Learning Trace Analysis  ·  2025-05

**WHY MIXED-EFFECTS MODELS ARE NOT APPROPRIATE FOR THE CURRENT CORPUS**

The current corpus has **N \= 4 learners** with 31–113 observed weeks each. Mixed-effects models partition variance between groups (learners) and within groups (weeks). With only four groups, the random-effects variance estimates are unreliable — there is not enough between-group data for the model to distinguish true learner heterogeneity from noise. Simulation studies suggest a minimum of **15–20 groups** for trustworthy random intercepts, and 30+ for random slopes (Maas & Hox, 2005). Fitting lmer(apology\_rate \~ disruption\_flag \+ (1|learner\_id)) on this corpus would produce an estimate, but the confidence interval on the random-effects variance would be so wide as to be uninterpretable. Reporting it without this caveat would be statistically misleading.

A second constraint is temporal autocorrelation. Weekly observations within a learner are not independent — a learner’s message volume in week *t* is correlated with week *t−1*. Standard mixed models assume residual independence. The current analysis uses within-learner OLS slopes and SMDs, which sidestep this assumption by treating each learner’s series separately. A rigorous longitudinal model would require an AR(1) or compound-symmetry covariance structure in the residuals, which is estimable but requires more observations per learner than L001 (31 weeks) currently provides.

**WHAT EACH ANALYTIC UPGRADE REQUIRES — AND WHAT IT ENABLES**

| Model | Minimum corpus | Requires | Enables |
| :---- | :---- | :---- | :---- |
| Random-intercept (lme4) | N ≥ 15 learners | Comparable obs windows | Learner-level variability partitioned from week-level; pooled disruption estimate with valid SE |
| Random-slope | N ≥ 30 learners | Balanced design | Tests whether disruption effect differs by learner; estimates cross-learner heterogeneity formally |
| Growth curve model | N ≥ 20, equal windows | Standardized start point | Models individual learning trajectories with formal inference on time trends |
| Latent growth curve (SEM) | N ≥ 100 learners | Validated survey scales | Links trace indicators to latent constructs (anxiety, workload); tests measurement model |
| AR(1) time-series per learner | N ≥ 50 weeks per learner | No additional data collection | Accounts for autocorrelation in weekly series; applicable to L002 and L004 now |

Green row: applicable to the **current corpus** for L002 and L004 (104 and 113 weeks). Amber: requires corpus expansion. Red: requires redesign.

**WHAT DEMONSTRATES STATISTICAL MATURITY WITH THE CURRENT CORPUS**

The following additions are statistically appropriate now and signal doctoral-level awareness without overstating the data:

**▸  Bootstrap confidence intervals on SMDs** — resample disruption/non-disruption weeks 1,000 times within each learner; report empirical 95% CIs alongside parametric estimates. Accounts for small group sizes without invoking asymptotic assumptions.

**▸  AR(1) autocorrelation check** — run Durbin-Watson test on OLS residuals from within-learner time trends. If autocorrelation is detected, report corrected standard errors (Newey-West). Demonstrates awareness that weekly observations are not independent.

**▸  Demonstrate lme4 with explicit limitation statement** — fit the random-intercept model, report the estimate, then state: “With N=4 groups the random-effects variance is not reliably estimated; this model is shown for methodological illustration only and should not be interpreted as a stable population-level effect.” Faculty reviewers will read this as statistical fluency, not weakness.

**▸  Effect size precision: report Hedges’ g alongside Cohen’s d-style SMDs** — Hedges’ g applies a small-sample correction to SMD. With disruption group sizes of 4–44, this matters. The correction is one line of R.

**CORPUS EXPANSION REQUIRED FOR MIXED-EFFECTS INFERENCE**

| Phase | Learners | Weeks needed | Unlocks | Status |
| :---- | :---: | :---: | :---- | :---: |
| Current | 4 | 31–113 ea. | Within-learner SMD, OLS slopes, sensitivity checks | **Done** |
| Near-term | 10–15 | ≥ 40 ea. | Random-intercept model; formal test of pooled disruption effect | **Next** |
| PhD study | 30+ | Comparable | Random-slope model; growth curve; between-learner moderators | Future |

Reference: Maas & Hox (2005). Sufficient sample sizes for multilevel modeling. Methodology, 1(3), 86–92.