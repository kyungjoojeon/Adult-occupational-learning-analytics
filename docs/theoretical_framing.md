# Theoretical Framing

**Kyungjoo Jeon**  
Adult Occupational English Learning Trace Analysis  
2025-05

---

## Overview

This project sits at the intersection of four theoretical traditions: Learning Analytics, self-regulated learning, participation-based views of learning, and adult occupational learning. Each tradition motivates a distinct subset of the indicators and shapes what the corpus can and cannot be asked to show. This document maps each variable to its theoretical home, states what the theory predicts, and notes what the current data can address and what it cannot.

---

## 1\. Learning Analytics and the Feedback Loop

Clow (2012) describes the learning analytics cycle as a continuous loop of data generation, aggregation, analysis, and feedback to learners. The motivating question is whether data traces left by learning activity can close the feedback loop — making patterns visible to instructors or learners that would otherwise go unnoticed.

This corpus is an instance of that cycle at the practitioner level. The KakaoTalk record is a digital trace of instructional interaction. The aggregation layer (learner-week summaries) makes participation patterns visible at a temporal resolution that would be difficult to track mentally across years of instruction. The analysis layer (within-learner trends, disruption comparisons) asks whether trace patterns co-vary in theoretically meaningful ways.

**Variables grounded here:**  
`learner_messages`, `english_proportion`, `correction_density`, `study_week` as an aggregation unit.

**What the theory predicts:** Trace data will reveal participation patterns that are not visible in any single session but emerge across weeks and months. Learners with irregular participation patterns may show different learning trajectories than those with regular engagement.

**What this corpus can address:** Whether participation regularity varies systematically across learners and co-varies with disruption-coded weeks.

**What it cannot address:** Whether feedback derived from these traces actually changes learner behavior — the closing of the loop — because no feedback intervention was designed or measured.

---

## 2\. Self-Regulated Learning

Zimmerman (2000) defines self-regulated learning as the degree to which learners are metacognitively, motivationally, and behaviorally active participants in their own learning. The SRL cycle has three phases: forethought (goal-setting, planning), performance (monitoring, strategy use), and self-reflection (self-evaluation, adaptation).

In adult occupational language learning, self-regulation is not a stable individual trait but a dynamic response to competing demands. Pintrich (2000) distinguishes four domains of regulation: cognition, motivation, behavior, and context. The context domain is particularly relevant here — adult professionals must regulate not only their study strategies but their participation itself, negotiating when and whether to engage given workplace demands.

**Variables grounded here:**  
`schedule_disruption`, `apology_uncertainty_rate`, `disruption_flag`, weekly participation patterns.

**What the theory predicts:** Learners managing high contextual demands (scheduling disruption) will show irregular participation, potentially accompanied by more hedging and apologetic language that reflects negotiation of competing obligations. This is the behavioral and motivational dimension of SRL under occupational constraint.

**What this corpus can address:** Whether disruption-coded weeks co-occur with changes in participation volume and apology/uncertainty language within learners. The disruption-apology association (SMD range \+0.46 to \+0.78 for L002-L004) is consistent with SRL theory's prediction of contextual interference with learning engagement.

**What it cannot address:** Whether learners are consciously self-regulating — the metacognitive and motivational components of SRL require self-report instruments (e.g., the Motivated Strategies for Learning Questionnaire, Pintrich et al., 1991\) or think-aloud protocols. Message frequency and language markers are behavioral traces, not evidence of intentional self-regulation.

**Critical distinction:** This corpus can show *what* learners do during disruption-coded weeks. It cannot show *why* they do it. The SRL framing motivates the question; it does not validate the answer.

---

## 3\. Participation-Based Views of Learning

Sfard (1998) distinguishes two metaphors for learning: the acquisition metaphor, which treats learning as accumulating knowledge; and the participation metaphor, which treats learning as becoming a more competent participant in social practices. The participation view is particularly appropriate for language learning, where competence is inherently relational and situational.

Wenger (1998) extended participation theory through the concept of communities of practice, where learning is made visible through changing forms of participation — frequency, nature, and character of engagement in shared activities. In a 1-to-1 instructional messaging context, the relevant community is dyadic: the learner and instructor co-construct a practice of English-language interaction through repeated exchanges over time.

**Variables grounded here:**  
`english_proportion`, `english_messages`, `learner_messages`, within-learner time trends on English-message proportion.

**What the theory predicts:** Increasing English-language participation in messaging over time is a visible indicator of growing engagement with the target language as an instructional medium, not merely as lesson content. L003's positive English-proportion trend (+0.0026 per week, the only slope with CI entirely above zero) is consistent with this prediction for that learner.

**What this corpus can address:** Whether English-language participation in messaging changes over the observation window within each learner, and whether learners differ in their trajectories — which they clearly do (sign disagreement across learners in the forest plot).

**What it cannot address:** Whether changes in messaging English use reflect changes in broader spoken or written English competence outside the instructional exchange. Participation in one narrow communicative context (instructor-learner messaging) is not equivalent to participation in English as a professional language more generally.

---

## 4\. Formative Feedback and Corrective Interaction

Black and Wiliam (1998) established that formative assessment — feedback provided during learning with the intent to improve it — produces some of the largest effect sizes in educational research. Nicol and Macfarlane-Dick (2006) extended this to seven principles of good feedback practice, emphasizing feedback that facilitates self-assessment, delivers high-quality information, and fosters dialogue.

In SLA, Lyster and Ranta (1997) demonstrated that corrective feedback type (recast vs. explicit correction) differentially affects learner uptake. The `>` prefix correction convention used by the instructor in L002 and L004 exports is closest to a recast: the instructor produces the target form immediately following the learner's error, without explicit metalinguistic commentary. Heift (2010) showed that even in CALL contexts, the presence of corrective prompts affects learner engagement with error.

**Variables grounded here:**  
`correction_density`, `contains_gt_correction`, `gt_correction_count`.

**What the theory predicts:** Weeks with higher instructor correction density should co-vary with richer learner production (more language to correct), consistent with the participation-correction relationship in SLA. This directional prediction is visible in the Figure 3 scatterplot for some learners.

**What this corpus can address:** Whether keyword-coded correction density co-varies with learner message volume within learners. The `>` prefix correction convention can be distinguished from keyword-based corrections, preserving cross-learner comparability.

**What it cannot address:** Whether corrections in messaging lead to learner uptake, the central question in Lyster and Ranta (1997). Uptake requires evidence that the learner used the corrected form in subsequent production — which would require analyzing message content over time at a linguistic level this corpus does not support. Correction density here is a measure of feedback opportunity, not feedback effectiveness.

---

## Variable-to-Theory Mapping

| Variable | Primary theory | What it traces | What it cannot establish |
| :---- | :---- | :---- | :---- |
| `learner_messages` | Learning Analytics (Clow, 2012\) | Participation frequency | Engagement quality or effort |
| `english_proportion` | Participation theory (Sfard, 1998; Wenger, 1998\) | English-medium interaction use | Proficiency or fluency |
| `schedule_disruption` | SRL — context regulation (Pintrich, 2000\) | Scheduling-friction language | Actual workload or disruption events |
| `apology_uncertainty_rate` | SRL — motivation; FL anxiety (Horwitz et al., 1986\) | Hedging and apologetic stance | Anxiety or motivational state |
| `correction_density` | Formative feedback (Black & Wiliam, 1998; Lyster & Ranta, 1997\) | Explicit correction notation rate | Feedback quality or learner uptake |
| `gt_correction_count` | Corrective feedback — recast type (Lyster & Ranta, 1997\) | Reformulation-style corrections | Cross-learner feedback comparison |
| Time trends | Learning Analytics feedback loop (Clow, 2012\) | Within-learner trajectory patterns | Causal development or growth |

---

## What This Framing Does and Does Not Claim

The four theoretical traditions above motivate the indicators and explain why the patterns being tracked are worth investigating. They do not validate the indicators. A learning analytics researcher reading this corpus would recognize the trace-analytics framing as appropriate for the data type. An SRL researcher would recognize the participation and contextual regulation framing as plausible but would want validated instruments before drawing conclusions about self-regulation. An SLA researcher would recognize the corrective feedback framing but note that uptake evidence is absent.

This is the correct epistemic position for an exploratory practitioner- originated corpus. The theoretical framing makes the project legible to researchers across these traditions, places the indicators in established scholarly conversations, and clarifies what kinds of follow-up study — with validated instruments, human coding, and longitudinal experimental designs — the corpus is designed to motivate.

---

## References

Black, P., and Wiliam, D. (1998). Assessment and classroom learning. *Assessment in Education: Principles, Policy and Practice*, 5(1), 7–74.

Clow, D. (2012). The learning analytics cycle: Closing the loop effectively. *Proceedings of the 2nd International Conference on Learning Analytics and Knowledge*, 134–138.

Heift, T. (2010). Prompts or not? Learners' interactions with feedback in CALL. *Language Learning and Technology*, 14(1), 79–97.

Horwitz, E. K., Horwitz, M. B., and Cope, J. (1986). Foreign language classroom anxiety. *The Modern Language Journal*, 70(2), 125–132.

Lyster, R., and Ranta, L. (1997). Corrective feedback and learner uptake. *Studies in Second Language Acquisition*, 19(1), 37–66.

Nicol, D. J., and Macfarlane-Dick, D. (2006). Formative assessment and self-regulated learning: A model and seven principles of good feedback practice. *Studies in Higher Education*, 31(2), 199–218.

Pintrich, P. R. (2000). The role of goal orientation in self-regulated learning. In M. Boekaerts, P. R. Pintrich, and M. Zeidner (Eds.), *Handbook of self-regulation* (pp. 451–502). Academic Press.

Pintrich, P. R., Smith, D. A. F., Garcia, T., and McKeachie, W. J. (1991). *A manual for the use of the Motivated Strategies for Learning Questionnaire (MSLQ)*. University of Michigan.

Sfard, A. (1998). On two metaphors for learning and the dangers of choosing just one. *Educational Researcher*, 27(2), 4–13.

Wenger, E. (1998). *Communities of practice: Learning, meaning, and identity*. Cambridge University Press.

Zimmerman, B. J. (2000). Attaining self-regulation: A social cognitive perspective. In M. Boekaerts, P. R. Pintrich, and M. Zeidner (Eds.), *Handbook of self-regulation* (pp. 13–39). Academic Press.  
