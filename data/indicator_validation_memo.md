# Indicator Validation Memo

**Kyungjoo Jeon**  
Adult Occupational English Learning Trace Analysis  
2025-05

---

## Purpose

This memo explains why the three primary coded indicators in this corpus exist, what theoretical constructs they are intended to approximate, how well they approximate those constructs given the available data, and what conclusions they can and cannot support. It consolidates validation reasoning distributed across `docs/codebook.md`, `docs/methodological_reflection_memo.md`, and `scripts/sensitivity_checks.R` into a single document for faculty reviewers.

The short answer to "why should I trust these indicators?" is: trust them as exploratory proxies derived from naturalistic instructional data, not as validated measurement instruments. Their value lies in identifying patterns worth investigating more rigorously, not in establishing causal claims.

---

## Theoretical Grounding

Each indicator is grounded in a distinct theoretical rationale.

**Schedule-disruption markers** are motivated by research on adult occupational learning under workplace constraints (Billett, 2001; Knowles, 1980). Adults managing competing professional and learning demands face what Knowles termed the need for self-direction under real-world constraints. Irregular participation and scheduling friction are among the most consistent surface manifestations of those constraints in distance and hybrid instructional settings. From a behavioral trace analytics perspective (Clow, 2012), messaging records may contain residues of that friction in scheduling language. The indicator does not measure workload directly — it captures scheduling-friction language, a plausible trace of workload.

**Apology and uncertainty markers** are motivated by two converging bodies of research. Horwitz, Horwitz, and Cope (1986) established foreign language anxiety as a distinct construct associated with communication apprehension and fear of negative evaluation. Skehan (1998) and Kormos and Denes (2004) connected anxiety to fluency and production features in L2 speech. In written instructional messaging, hedging and apologetic language may be visible surface residues of the communicative anxiety that affects spoken production. However, cross-cultural communication research (Brown and Levinson, 1987\) documents that apology and hedging are routine politeness strategies in Korean professional discourse, independent of affective state. This ambiguity cannot be resolved by the indicator alone.

**Instructor correction markers** are motivated by the corrective feedback literature in SLA (Lyster and Ranta, 1997; Heift, 2010). Correction density in instructional interaction is associated with feedback quality and the opportunity structure for noticing and uptake. In a messaging corpus, explicit correction notation represents the subset of instructor feedback visible in the text record — a known partial proxy, but a useful first-pass signal.

---

## Indicator 1: Schedule-Disruption Marker

### Why this indicator exists

The central research interest in this corpus is how occupational demands co-occur with learning participation patterns. If scheduling friction is reflected in message language, it can be observed in the text record without requiring external workload measures that were never collected.

### Operational definition

A learner message is coded `TRUE` if it contains any term from the disruption keyword list. English terms: meeting, busy, late, overtime, business trip, deadline, delay, reschedul, can't make, cannot make, work trip, work conflict, stuck at work. Korean terms: 회의, 야근, 출장, 일정, 변경, 불가, 늘.

The standalone English term `work` was removed after audit because it triggered on lesson content at high rates.

### Corpus evidence

Fires on 148 of 2,202 learner messages (6.7%). Disruption week rates range from 13% (L001, 4/31 weeks) to 48% (L003, 38/79 weeks).

### Known false positives

From corpus inspection:

- "Homework at late night. Good night" — `late` triggers on a productive message.  
- "His friend is busy" — `busy` matches a third-party reference.  
- "I don't think we need to reschedule. Just keep going as scheduled" — `reschedul` fires on a message explicitly denying disruption.  
- "I've been thinking about this lately" — `late` matches as a substring.

### Known false negatives

Learners occasionally express scheduling friction without any listed keyword, through implicit rescheduling requests or general statements of overwhelm in sentence structures containing no trigger term.

### Sensitivity evidence — most important finding

Removing `late` reduces L003 disruption weeks from 38 to 20 and L004 from 44 to 14\. Korean-only keywords produce only 2 disruption weeks for L003 and zero for L004. L001 and L002 are stable across definitions.

This is substantively important: L003 and L004 expressed scheduling friction in English (`late`, `busy`, `meeting`) rather than in Korean scheduling vocabulary (야근, 출장, 회의). The disruption indicator for these learners measures English-language scheduling communication, not occupational disruption as a Korean-language concept. Whether this reflects messaging style, proficiency level, or genuine communication preferences cannot be determined from the data.

### Valid interpretation range

Appropriate: "Disruption-coded weeks contain scheduling-friction language." Appropriate: "L002's disruption-coded weeks show elevated apology/uncertainty language across keyword definitions."  
Too strong: "L003 and L004 experienced higher occupational disruption."

---

## Indicator 2: Apology and Uncertainty Marker

### Why this indicator exists

Foreign language anxiety co-varies with participation and production quality in L2 research. If apology/uncertainty language in messaging co-varies with participation patterns or disruption-coded weeks, that is worth investigating with more rigorous methods. The indicator exists to make this pattern visible descriptively.

### Operational definition

A learner message is coded `TRUE` if it contains any term from the apology/ uncertainty keyword list. English terms: sorry, apolog, maybe, not sure, i think, i guess, afraid, worried, confus, can't, cannot, unable. Korean terms: 죄송, 미안, 걱정, 헷갈, 모르, 어렵, 못.

### Corpus evidence

Fires on 205 of 2,202 learner messages (9.3%). Mean weekly rates range from 0.055 (L003) to 0.159 (L004).

### Known false positives

From corpus inspection:

- "Sorry to hear, hope you stay warm and healthy" — sympathy, not apology or anxiety.  
- "Can't wait for it" — enthusiasm, triggering `can't`.  
- "Tell me your Tokyo story next week. Can't wait" — same pattern.  
- 못 is broad in Korean; it expresses inability but also appears idiomatically in expressions unrelated to uncertainty.

`sorry` alone accounts for 46% of all apology/uncertainty hits. Removing it reduces L004's mean weekly rate from 0.159 to 0.063 — a 60% reduction.

### Known false negatives

Korean politeness structures that express deference through grammatical endings rather than lexical items (-는데, \-지만, \-아/어서) are not captured. Learners writing in grammatically hedged Korean without any listed keyword will not be coded.

### The cross-cultural confound

In Korean professional communication, apologetic and deferential language is a routine politeness norm. A learner writing 죄송합니다 before every rescheduling request is following a social script, not expressing distress. The indicator cannot distinguish these communicative functions from the raw text.

### Sensitivity evidence

For L002, where the disruption-apology association is strongest (SMD: \+0.776), the result is stable whether or not `sorry` is included (no-sorry SMD: \+0.747). This is the best available evidence that L002's pattern is not primarily a politeness-frequency artifact. For L004, the association weakens substantially without `sorry` (SMD drops from \+0.554 to \+0.426), suggesting a meaningful politeness contribution to L004's marker rate.

### Validation path

A genuine validation would require: (1) manual coding of 100-150 stratified messages by two independent raters using a codebook distinguishing politeness-routine apology, uncertainty about language, scheduling inability, and emotional worry; (2) inter-rater reliability check (Cohen's kappa target

\= 0.70); (3) correlation of human-coded categories with the keyword indicator. This has not been done. See `docs/apology_uncertainty_validation_plan.md`.

### Valid interpretation range

Appropriate: "Apology/uncertainty language is more common in disruption-coded weeks for L002, L003, and L004."  
Appropriate: "L004's elevated rate is substantially driven by `sorry`, which may reflect politeness conventions."  
Too strong: "Higher rates indicate learner anxiety."

---

## Indicator 3: Instructor Correction Marker

### Why this indicator exists

Corrective feedback density in instructional interaction provides a rough signal of explicit feedback opportunity. In a messaging corpus, this is visible only for corrections that are textually notated — a known limitation, but a useful first-pass signal for comparing feedback patterns descriptively.

### Two operationalizations

**`contains_correction`** flags messages with correction notation (`->`, `=>`) or correction vocabulary. Fires on 153 of 3,843 instructor messages (4.0%). Comparable across all four learners.

**`contains_gt_correction`** flags messages that absorbed `>`\-prefixed continuation lines. Fires on 35 instructor messages — exclusively in L002 (12) and L004 (23). Zero in L001 and L003.

The `>` prefix is an instructor formatting habit, not a learner difference. Cross-learner comparison of correction density must account for this or it produces a finding about instructor formatting, not instructional feedback.

### Known false positives

`->` could match URLs or code snippets (rare in this corpus). `better` was restricted to `better:` (colon required) to reduce casual encouragement false positives.

### Known false negatives

Verbal corrections in Zoom or phone sessions are entirely absent from the text record. Corrections delivered as implicit recasts without explicit notation are not captured. The proportion of actual instructional feedback visible in messaging is unknown and cannot be estimated without session records.

### Valid interpretation range

Appropriate: "Keyword-coded correction density is a partial proxy for explicit written feedback notation."  
Too strong: "L002 received more corrective feedback than L001."

---

## Overall Validation Status

| Indicator | Theoretical grounding | Sensitivity stability | Primary threat | Status |
| :---- | :---- | :---- | :---- | :---- |
| Disruption | Adult learning, trace analytics | L001/L002 stable; L003/L004 late-dependent | `late` false positives; English-only for L003/L004 | Exploratory; L002 most interpretable |
| Apology/uncertainty | FL anxiety, politeness theory | L002 stable; L004 sorry-fragile | Korean politeness confound | Exploratory; requires manual validation |
| Correction (keyword) | Corrective feedback SLA | Comparable across learners | Misses verbal corrections | Exploratory; partial proxy |
| Correction (gt) | Corrective feedback SLA | Not comparable across learners | Formatting confound | Descriptive only |

None reaches the standard of a validated measurement instrument. All four are defensible as first-pass exploratory proxies for theoretically motivated phenomena. The strongest single finding — L002's disruption-apology association (SMD: \+0.776, stable across keyword definitions) — rests on the most keyword-robust indicator pair and is the result most worth carrying forward to a more rigorously designed study.

---

## What Validation Would Actually Require

**For disruption:** Participant interviews or experience sampling to verify that disruption-coded weeks correspond to learner-reported high-workload periods; or a validated workload scale collected alongside messaging.

**For apology/uncertainty:** Human coding of a stratified message sample with inter-rater reliability, distinguishing politeness routine from affective signal; or a validated foreign language anxiety scale (e.g., FLCAS, Horwitz et al., 1986\) collected at intervals to check against weekly marker rates.

**For correction:** Session records documenting which sessions were text-based and which were spoken, enabling estimation of the proportion of corrections captured by the messaging record.

The current project generates the questions these methods would answer. That is the appropriate claim for a practitioner-originated exploratory corpus.

---

## References

Billett, S. (2001). *Learning in the workplace: Strategies for effective practice*. Allen and Unwin.

Brown, P., and Levinson, S. C. (1987). *Politeness: Some universals in language usage*. Cambridge University Press.

Clow, D. (2012). The learning analytics cycle: Closing the loop effectively. *Proceedings of the 2nd International Conference on Learning Analytics and Knowledge*, 134-138.

Heift, T. (2010). Prompts or not? Learners' interactions with feedback in CALL. *Language Learning and Technology*, 14(1), 79-97.

Horwitz, E. K., Horwitz, M. B., and Cope, J. (1986). Foreign language classroom anxiety. *The Modern Language Journal*, 70(2), 125-132.

Knowles, M. S. (1980). *The modern practice of adult education* (2nd ed.). Cambridge.

Kormos, J., and Denes, M. (2004). Exploring measures and perceptions of fluency in the speech of second language learners. *System*, 32(2), 145-164.

Lyster, R., and Ranta, L. (1997). Corrective feedback and learner uptake. *Studies in Second Language Acquisition*, 19(1), 37-66.

Skehan, P. (1998). *A cognitive approach to language learning*. Oxford University Press.  
