# Codebook

**Project:** Occupational English Learning Trace Analysis  
**Author:** Kyungjoo Jeon  
**Last updated:** 2025-05  
**Script reference:** `scripts/01_build_corpus.R`

This codebook defines every coded variable in `data/processed/message_level_corpus.csv`
and `data/derived/learner_week_summary.csv`. For each variable it records the
exact operational definition, the keyword list or detection rule used in the
parser, known false positive and false negative risks, cross-learner
comparability notes, and interpretation boundaries.

These variables are rule-based text markers extracted from naturally occurring
instructional messages. They are not validated measurement instruments. Each
one captures a pattern worth tracking descriptively; none of them directly
measures the psychological or instructional construct it resembles.

---

## 1. speaker_role

**Unit:** message  
**Values:** `Learner`, `Instructor`  
**Type:** categorical

**Rule:** A message is coded `Instructor` if the sender name matches the
`instructor_sender_pattern` field in the corpus manifest (case-insensitive
regex). All other senders are coded `Learner`.

**Manifest pattern for this corpus:** `Apple` (the instructor's KakaoTalk
display name across all four exports).

**Cross-learner note:** All four exports use the same instructor pattern.
Learner sender names carry a `E ` prefix (e.g., `E GaEun Choi`) — this is a
KakaoTalk contact-tag artifact, not an unknown sender. The parser correctly
classifies these as `Learner` because they do not match `Apple`.

**False positive risk:** In a group chat with multiple participants, non-
instructor, non-learner senders would be classified as `Learner`. All four
exports in this corpus are 1-to-1 instructional chats; this risk does not apply
here. The parsing log's `unmatched_senders` column (expected value: 1 per
export) documents this.

**Interpretation boundary:** `speaker_role` does not distinguish between
learner messages that are homework, scheduling, casual chat, or practice output.
All are coded identically.

---

## 2. is_english

**Unit:** message  
**Values:** `TRUE`, `FALSE`  
**Type:** binary flag

**Rule:**
```
str_detect(message, "[A-Za-z]{3,}")
```
A message is coded `TRUE` if it contains at least one sequence of three or
more consecutive alphabetic characters.

**Corpus rate (learner messages):** 80.9% (1,782 of 2,202)

**Rationale for 3-character threshold:** The 1–2 character threshold would
capture Korean romanization artifacts (e.g., `ㅠ` typed as `ㅠ`, short
particles romanized in informal typing) and would not meaningfully distinguish
English-language production. The 3-character threshold is a pragmatic boundary,
not a linguistic definition of "English."

**Known false positives:** Korean words occasionally romanized in casual
messaging (`bb`, `lol`, `ok`) may trigger this flag if they happen to reach 3
characters. Learner messages in this corpus are predominantly bilingual; the
flag is used as a rough English-use signal, not as a proficiency measure.

**Known false negatives:** Very short English responses (`OK`, `Hi`, `No`,
`Go`) are not captured. These are real communicative acts but are low-frequency
and do not meaningfully affect `english_proportion` at the learner-week level.

**Interpretation boundary:** `is_english` does not measure English fluency,
accuracy, complexity, or spoken production. A message containing one English
phrase in an otherwise Korean message is coded identically to a fully English
message.

---

## 3. schedule_disruption

**Unit:** message (learner only; instructor messages are not coded for this)  
**Values:** `TRUE`, `FALSE`  
**Type:** binary flag

**Rule:**
```
meeting | busy | late | overtime | business trip | deadline | delay |
reschedul | can't make | cannot make | work trip | work conflict |
stuck at work |
회의 | 야근 | 출장 | 일정 | 변경 | 불가 | 늦
```
Case-insensitive. Any match codes the message `TRUE`.

**Corpus rate (learner messages):** 6.7% (148 of 2,202)

**Per-learner disruption week rates:**

| Learner | Disruption weeks | Total weeks | Rate |
|---------|-----------------|-------------|------|
| L001    | 4               | 31          | 13%  |
| L002    | 17              | 104         | 16%  |
| L003    | 38              | 79          | 48%  |
| L004    | 44              | 113         | 39%  |

**Audit note — `work` removed:** An earlier version of this variable included
the standalone term `work` in the English keyword list. This was removed after
inspection revealed it fired frequently on lesson content unrelated to
scheduling — for example: "make me work hard," "it doesn't seem to relate to my
work," "he works even during lunch." The Korean terms carry the primary
scheduling signal and are more specific to the intended construct.

**Known false positives from corpus inspection:**

- *"Thanks for all the research (restaurant & steel industry). You have such a
  warm heart."* — `research` not matched, but this message type illustrates
  that English lesson content often co-occurs with scheduling messages. The
  flag may fire on the same message for different reasons.
- *"Homework at late night. Good night."* — `late` matches but this is a
  homework submission note, not a scheduling disruption.
- *"please give us a moment till my husband reaches out to me... his friend is
  busy."* — `busy` matches but refers to a third party, not the learner's
  own schedule.
- *"I don't think we need to reschedule. Just keep going as scheduled on the
  14th."* — `reschedul` matches but the message is explicitly saying no
  disruption occurred.

**Known false negatives:** Learners occasionally signal scheduling friction in
Korean without using any of the listed terms. A learner writing a Korean
sentence about being unable to attend without using 불가, 못, or 늦 would not
be captured.

**Interpretation boundary:** `schedule_disruption` is a text-based proxy for
scheduling friction. It is not a validated measure of occupational workload,
work pressure, or schedule disruption as a psychological experience. A week
coded as `disruption_flag = 1` means at least one learner message that week
contained a scheduling-friction keyword.

**Cross-learner comparability:** The keyword list is identical across all four
learners. However, learners differ substantially in how often they discuss
scheduling in messages — L003 and L004 show disruption rates of 39–48%
compared to 13–16% for L001 and L002. This difference may reflect real
differences in occupational scheduling, differences in how much learners
communicate about scheduling with the instructor, or differences in message
volume and style. These cannot be separated with the available data.

---

## 4. apology_uncertainty_marker

**Unit:** message (learner only)  
**Values:** `TRUE`, `FALSE`  
**Type:** binary flag

**Rule:**
```
sorry | apolog | maybe | not sure | i think | i guess | afraid |
worried | confus | can't | cannot | unable |
죄송 | 미안 | 걱정 | 헷갈 | 모르 | 어렵 | 못
```
Case-insensitive. Any match codes the message `TRUE`.

**Corpus rate (learner messages):** 9.3% (205 of 2,202)

**Per-learner mean weekly rates:**

| Learner | Mean weekly rate |
|---------|-----------------|
| L001    | 0.080           |
| L002    | 0.104           |
| L003    | 0.055           |
| L004    | 0.159           |

**What this variable is:** A broad communicative stance marker. It captures
language associated with apology, hedging, uncertainty about wording, inability
to attend, or worry. In Korean professional communication, these functions are
often performed by overlapping surface forms.

**What this variable is not:** It is not a measure of anxiety, hesitation,
motivation, or any validated psychological state. The original variable name
`anxiety_marker` was rejected precisely because the available data cannot
support that interpretation.

**Known false positives from corpus inspection:**

- *"Sorry to hear, hope u stay warm and healthy."* — `sorry` matches but
  expresses sympathy, not apology or anxiety.
- *"Tell me your Tokyo story next week. Can't wait."* — `can't` matches but
  expresses anticipation.
- *"I think so if you are okay we may able to match the time."* — `i think`
  matches and is a hedging form, which is the intended signal, but it also
  functions here as a casual agreement marker.
- *"oh can't wait for it. Please don't forget it to show me on Monday class."*
  — `can't` matches in an enthusiastic non-anxious message.
- *"Sorry this is what we talked at chicken pub.. but how can i use this?"* —
  `sorry` and `cannot` both match; the first is a casual conversational
  connector.

**Known false negatives:** Korean politeness and hesitation are sometimes
expressed through grammatical structure (e.g., sentence-final `-는데`, `-지만`)
rather than through lexical items. These are not captured.

**Cross-cultural interpretation note:** In Korean professional contexts,
apology and deference are routine features of polite messaging. A learner may
write apologetically even when they are not anxious. This is not a flaw in the
data — it is an important interpretive constraint. High `apology_uncertainty_rate`
may reflect communicative norms as much as psychological state.

**Recommended validation:** If this variable is used in any analysis beyond
exploratory description, a manual coding check of 50–100 sampled messages is
warranted. See `docs/apology_uncertainty_validation_plan.md` for a lightweight
procedure.

**Interpretation boundary:** Report as "apology/uncertainty language" or
"communicative stance markers." Do not report as "anxiety," "hesitation," or
any psychological construct.

---

## 5. contains_correction

**Unit:** message (instructor messages only; learner messages may match but the
variable is used only for instructor rows in `correction_density`)  
**Values:** `TRUE`, `FALSE`  
**Type:** binary flag

**Rule:**
```
(-> | =>) | correction | corrected | suggestion | better: | revise |
수정 | 교정
```
Case-insensitive.

**Corpus rate (instructor messages):** 4.0% (153 of 3,843)

**What this captures:** Instructor messages containing explicit correction
notation symbols (`->`, `=>`), correction vocabulary, or Korean correction
terms. This is the keyword-based correction signal.

**Interaction with `contains_gt_correction`:** The `>` prefix correction
convention used by the instructor in L002 and L004 exports is tracked
separately. Some messages may be coded `TRUE` for both variables; they are not
mutually exclusive.

**Known false positives:**

- Messages containing `->` in URLs or code snippets (rare in this corpus;
  most URLs are captured by `contains_url`).
- The term `better` in casual encouragement ("you did better this week") would
  match `better:` only if followed by a colon, which limits this false positive.

**Known false negatives:** Corrections delivered as questions ("Don't you mean
X?"), corrections embedded in recast sentences without explicit notation, and
corrections delivered in spoken sessions not recorded in messages are not
captured.

**Interpretation boundary:** `correction_density` (correction count / instructor
message count) is a proxy for the density of explicit feedback notation in
instructor messages, not for total feedback quality. Sessions delivered by voice
call, video, or in-person are entirely absent from this record.

---

## 6. contains_gt_correction

**Unit:** message  
**Values:** `TRUE`, `FALSE`  
**Type:** binary flag

**Rule:**
```
Continuation line beginning with: ^>\s*[A-Za-z가-힣]
```
Set to `TRUE` on the message row that absorbed one or more `>`-prefixed
continuation lines during parsing.

**Corpus rate (instructor messages):** 0.9% (35 of 3,843)

**What this captures:** The instructor's correction convention of prefixing
reformulations with `>` followed by the corrected form. Example from corpus:

```
[Apple] [오후 8:00] I'm very hard time
> I'm having a very hard time
```

The correction line is absorbed into the preceding message row and
`contains_gt_correction` is set `TRUE` on that row.

**CRITICAL cross-learner comparability note:**

| Learner | Total `>` corrections | Exports using this convention |
|---------|-----------------------|-------------------------------|
| L001    | 0                     | No                            |
| L002    | 12                    | Yes                           |
| L003    | 0                     | No                            |
| L004    | 23                    | Yes                           |

This difference reflects an instructor formatting habit, not a learner
difference in feedback received. `correction_density` (which uses only
`contains_correction`) and `gt_correction_count` should **not** be summed or
compared across L001/L003 versus L002/L004 without explicitly accounting for
this. Cross-learner comparisons of feedback density should use both variables
separately or restrict comparison to within-learner trajectories.

---

## 7. is_media_placeholder

**Unit:** message  
**Values:** `TRUE`, `FALSE`  
**Type:** binary flag

**Rule:** Message text (after stripping whitespace) exactly matches one of:

```
사진 | 동영상 | 파일 | 이모티콘 | 삭제된 메시지
```

**Corpus rate (learner messages):** 2.0% (45 of 2,202)

**What this captures:** KakaoTalk exports replace media attachments (photos,
videos, files, emoji stickers) and deleted messages with these Korean
placeholder strings. They represent real communicative acts but contain no
linguistic content.

**Analytic treatment:** Rows where `is_media_placeholder = TRUE` are retained
in the corpus for participation counting (a photo send is a real message) but
are excluded from `avg_learner_word_count` calculations. `word_count` is set to
0 for these rows.

---

## 8. is_grammar_exercise

**Unit:** message  
**Values:** `TRUE`, `FALSE`  
**Type:** binary flag

**Rule:**
```
str_detect(message, "-{5,}")
```
A message is coded `TRUE` if it contains five or more consecutive hyphens.

**Corpus rate:** 0.0% by `is_grammar_exercise = TRUE` (zero matches with the
strict five-hyphen rule). One message matched a related separator pattern during
inspection: a vocabulary list row (`가라앉은 Sunk 빵빵한 Bloated...`) that
contained hyphens in a different format. This variable captures very little in
the current corpus and should not be used as a primary analytic variable.

**Note for future versions:** If lesson structure detection is a priority, this
variable would benefit from a broader rule capturing vocabulary list formats,
numbered drill sequences, or explicit lesson-break separators.

---

## 9. word_count

**Unit:** message  
**Values:** non-negative integer  
**Type:** count

**Rule:** Whitespace-delimited token count of the message string, after
`str_squish()`. Set to 0 for `is_media_placeholder = TRUE` rows.

**Interpretation boundary:** This is a rough token count. Korean words are not
space-delimited in the same way as English; Korean portions of bilingual
messages will count each particle-attached word form as one token. The variable
is most meaningful for English-dominant messages.

---

## 10. message_seq

**Unit:** message  
**Values:** positive integer  
**Type:** sequence identifier

**Rule:** Row number within each learner's parsed export, assigned after sorting
by `datetime_clean`.

**Purpose:** Unique row identifier. The combination of `(learner_id,
date_clean, time_clean)` is NOT unique — KakaoTalk records only minute-level
timestamps, and multiple messages within the same minute share an identical
timestamp. `message_seq` is the only guaranteed unique identifier per learner.

---

## Learner-week variables derived from message-level flags

The following variables in `learner_week_summary.csv` are aggregated from the
message-level flags above. Brief definitions are given here; full variable
descriptions are in `docs/data_dictionary.md`.

| Variable | Derived from | Aggregation |
|----------|-------------|-------------|
| `learner_messages` | `speaker_role` | Count of learner rows per week |
| `instructor_messages` | `speaker_role` | Count of instructor rows per week |
| `english_messages` | `is_english` AND `speaker_role == Learner` | Count per week |
| `english_proportion` | `english_messages / learner_messages` | Ratio; NA if no learner messages |
| `disruption_count` | `schedule_disruption` AND `speaker_role == Learner` | Count per week |
| `disruption_flag` | `disruption_count > 0` | Binary; 1 if any disruption marker |
| `apology_uncertainty_count` | `apology_uncertainty_marker` AND `speaker_role == Learner` | Count per week |
| `apology_uncertainty_rate` | `apology_uncertainty_count / learner_messages` | Ratio; NA if no learner messages |
| `correction_count` | `contains_correction` AND `speaker_role == Instructor` | Count per week |
| `gt_correction_count` | `contains_gt_correction` | Count per week (all speakers) |
| `correction_density` | `correction_count / instructor_messages` | Ratio; NA if no instructor messages |
| `avg_learner_word_count` | `word_count` for learner, non-media rows | Mean per week |

---

## Removed or deprecated terms

| Term | Reason removed | Replacement |
|------|---------------|-------------|
| `anxiety_marker` | Implied psychological state not supported by data | `apology_uncertainty_marker` |
| `work` (standalone) | High false positive rate on English lesson content | Retained via `work trip`, `work conflict`, `stuck at work` |
| `self-regulated learning behaviors` | Theoretical overclaim for message counts | "Participation traces" or "weekly participation" |
| `longitudinal development` | Implies growth or learning progress | "Descriptive change across observed weeks" |

---

## Change log

| Date | Change | Reason |
|------|--------|--------|
| 2025-05 | `anxiety_marker` renamed `apology_uncertainty_marker` | Avoid implied psychological measurement |
| 2025-05 | `work` removed from disruption keyword list | High false positive rate on lesson content |
| 2025-05 | `contains_gt_correction` added as separate variable | Cross-learner correction comparability |
| 2025-05 | `is_media_placeholder` added | Exclude placeholder tokens from word_count |
| 2025-05 | `message_seq` added | Unique row identifier (timestamp not unique) |
| 2025-05 | Blank-line continuation reset added to parser | Prevent cross-turn content absorption |
| 2025-05 | L004 (Google.txt) added to corpus | Corpus was incomplete without this learner |
