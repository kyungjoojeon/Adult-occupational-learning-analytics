# Build a multi-learner longitudinal corpus from private KakaoTalk exports.
#
# Audit fixes applied (2025-05):
#   1. Post-blank continuation absorption: blank lines now RESET continuation
#      context. Post-blank content is counted in lines_unmatched rather than
#      silently absorbed into the wrong message row.
#   2. gt_correction flag: '>' prefixed correction lines are flagged separately
#      from keyword-based contains_correction, allowing cross-learner comparison
#      that does not conflate formatting conventions.
#   3. schedule_disruption regex: standalone 'work' removed (fires on lesson
#      content). Korean-specific terms retained as primary signal.
#   4. Google.txt (L004) added to manifest and metadata.
#   5. unmatched_senders warning threshold raised to >2 (E-prefix is normal).
#   6. continuation_rate warning threshold raised to >6.0 (100-400% is normal
#      for multi-line instructor lesson messages in KakaoTalk).
#   7. media_placeholder flag added to exclude photo/video tokens from
#      word_count calculations.
#   8. message_seq added as unique row identifier.
#   9. Manifest <-> metadata completeness check added before parsing.
#  10. date_span_days, first/last message dates added to parsing_log.

library(tidyverse)
library(lubridate)
library(stringr)

args <- commandArgs(trailingOnly = TRUE)

manifest_path <- if (length(args) >= 1) args[[1]] else "data/raw/corpus_manifest_local.csv"
metadata_path <- if (length(args) >= 2) args[[2]] else "data/participant_metadata.csv"
message_path  <- "data/processed/message_level_corpus.csv"
weekly_path   <- "data/derived/learner_week_summary.csv"
learner_path  <- "data/derived/learner_summary.csv"
log_path      <- "data/derived/parsing_log.csv"

parsing_log_rows <- list()

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("data/derived",   recursive = TRUE, showWarnings = FALSE)

if (!file.exists(manifest_path)) {
  stop(
    "Missing corpus manifest: ", manifest_path, "\n",
    "Use data/raw/corpus_manifest_template.csv or pass a manifest path as the first argument.",
    call. = FALSE
  )
}

if (!file.exists(metadata_path)) {
  stop("Missing participant metadata: ", metadata_path, call. = FALSE)
}

manifest <- read_csv(manifest_path, show_col_types = FALSE) %>%
  mutate(
    learner_id                = as.character(learner_id),
    source_file_path          = as.character(source_file_path),
    instructor_sender_pattern = as.character(instructor_sender_pattern),
    export_encoding           = coalesce(as.character(export_encoding), "UTF-8")
  )

metadata <- read_csv(metadata_path, show_col_types = FALSE) %>%
  mutate(learner_id = as.character(learner_id))

required_manifest_cols <- c("learner_id", "source_file_path", "instructor_sender_pattern")
missing_manifest_cols  <- setdiff(required_manifest_cols, names(manifest))
if (length(missing_manifest_cols) > 0) {
  stop(
    "Manifest is missing required columns: ",
    paste(missing_manifest_cols, collapse = ", "),
    call. = FALSE
  )
}

# ── Manifest <-> metadata completeness check ────────────────────────────────
manifest_ids <- manifest$learner_id
metadata_ids <- metadata$learner_id

missing_from_metadata <- setdiff(manifest_ids, metadata_ids)
if (length(missing_from_metadata) > 0) {
  warning(
    "These learner_ids appear in the manifest but have no metadata row: ",
    paste(missing_from_metadata, collapse = ", "),
    "\n  They will parse but join as NA in analysis_df."
  )
}

missing_from_manifest <- setdiff(metadata_ids, manifest_ids)
if (length(missing_from_manifest) > 0) {
  message(
    "Note: these metadata learner_ids have no manifest entry (not parsed): ",
    paste(missing_from_manifest, collapse = ", ")
  )
}

# ── Parsing helpers ──────────────────────────────────────────────────────────

parse_date_line <- function(line) {
  date_match <- str_match(line, "^-+\\s*(\\d{4})\\D+(\\d{1,2})\\D+(\\d{1,2})")
  if (is.na(date_match[1, 1])) return(NA_Date_)
  make_date(
    year  = as.integer(date_match[1, 2]),
    month = as.integer(date_match[1, 3]),
    day   = as.integer(date_match[1, 4])
  )
}

parse_message_line <- function(line) {
  msg_match <- str_match(line, "^\\[(.+?)\\]\\s+\\[(.*?)\\s*(\\d{1,2}:\\d{2})\\]\\s*(.*)$")
  if (is.na(msg_match[1, 1])) return(NULL)
  tibble(
    sender_raw   = msg_match[1, 2],
    time_marker  = msg_match[1, 3],
    time_raw     = msg_match[1, 4],
    message      = msg_match[1, 5],
    contains_gt_correction = FALSE   # default; set TRUE if continuation carries >
  )
}

to_24_hour <- function(time_marker, time_raw) {
  hour_raw   <- as.integer(str_extract(time_raw, "\\d{1,2}(?=:)"))
  minute_raw <- as.integer(str_extract(time_raw, "(?<=:)\\d{2}"))
  is_pm <- str_detect(time_marker, regex("PM|afternoon|\u C624\u D6C4|\u 3145\u C37D", ignore_case = TRUE))
  is_am <- str_detect(time_marker, regex("AM|morning|\u C624\u C804|\u 3145\u C804",  ignore_case = TRUE))
  hour_24 <- case_when(
    is_pm & hour_raw < 12 ~ hour_raw + 12L,
    is_am & hour_raw == 12 ~ 0L,
    TRUE ~ hour_raw
  )
  sprintf("%02d:%02d:00", hour_24, minute_raw)
}

speaker_role_for <- function(sender_raw, instructor_sender_pattern) {
  if_else(
    str_detect(sender_raw, regex(instructor_sender_pattern, ignore_case = TRUE)),
    "Instructor",
    "Learner"
  )
}

# ── Core parser ──────────────────────────────────────────────────────────────

parse_export <- function(learner_id, source_file_path, instructor_sender_pattern, export_encoding) {

  log <- list(
    learner_id                = learner_id,
    source_file               = basename(source_file_path),
    file_found                = file.exists(source_file_path),
    raw_lines                 = NA_integer_,
    date_header_lines         = NA_integer_,
    message_lines_matched     = NA_integer_,
    continuation_merges       = NA_integer_,
    gt_correction_lines       = NA_integer_,
    lines_unmatched           = NA_integer_,
    na_date_messages          = NA_integer_,
    total_messages            = NA_integer_,
    learner_messages          = NA_integer_,
    instructor_messages       = NA_integer_,
    unmatched_senders         = NA_integer_,
    unique_unmatched_senders  = NA_character_,
    first_message_date        = NA_character_,
    last_message_date         = NA_character_,
    date_span_days            = NA_integer_,
    parse_note                = ""
  )

  if (!file.exists(source_file_path)) {
    warning("Skipping missing source file for ", learner_id, ": ", source_file_path)
    log$parse_note <- "file not found"
    parsing_log_rows[[learner_id]] <<- log
    return(tibble())
  }

  raw_text <- read_lines(source_file_path, locale = locale(encoding = export_encoding))
  log$raw_lines <- length(raw_text)

  parsed_rows        <- list()
  current_date       <- NA_Date_
  date_header_count  <- 0L
  continuation_count <- 0L
  gt_correction_count <- 0L
  unmatched_count    <- 0L

  # FIX 1: blank lines reset continuation context to prevent cross-turn absorption
  prev_line_was_content <- FALSE

  for (line in raw_text) {

    # Blank line: close any open continuation context
    if (str_squish(line) == "") {
      prev_line_was_content <- FALSE
      next
    }

    # Date header
    possible_date <- parse_date_line(line)
    if (!is.na(possible_date)) {
      current_date <- possible_date
      date_header_count <- date_header_count + 1L
      prev_line_was_content <- FALSE
      next
    }

    # Message header
    parsed_message <- parse_message_line(line)
    if (!is.null(parsed_message)) {
      parsed_rows[[length(parsed_rows) + 1]] <- parsed_message %>%
        mutate(date_clean = current_date)
      prev_line_was_content <- TRUE
      next
    }

    # Continuation: only absorb if immediately following a message or prior continuation
    # (no blank line in between)
    if (prev_line_was_content && length(parsed_rows) > 0) {
      last_index <- length(parsed_rows)

      # FIX 2: flag '>' correction lines distinctly before absorbing
      if (str_detect(str_squish(line), "^>\\s*[A-Za-z\uAC00-\uD7A3]")) {
        parsed_rows[[last_index]]$contains_gt_correction <- TRUE
        gt_correction_count <- gt_correction_count + 1L
      }

      parsed_rows[[last_index]]$message <- str_squish(
        paste(parsed_rows[[last_index]]$message, line)
      )
      continuation_count <- continuation_count + 1L
      # prev_line_was_content stays TRUE
      next
    }

    # Non-empty line that is not a date, message, or valid continuation
    unmatched_count <- unmatched_count + 1L
    prev_line_was_content <- FALSE
  }

  log$date_header_lines     <- date_header_count
  log$message_lines_matched <- length(parsed_rows)
  log$continuation_merges   <- continuation_count
  log$gt_correction_lines   <- gt_correction_count
  log$lines_unmatched       <- unmatched_count

  if (length(parsed_rows) == 0) {
    log$parse_note <- "no messages parsed; check export format or encoding"
    parsing_log_rows[[learner_id]] <<- log
    warning("No messages parsed for ", learner_id, ". Check export format and encoding.")
    return(tibble())
  }

  result <- bind_rows(parsed_rows) %>%
    mutate(
      learner_id   = learner_id,
      speaker_role = speaker_role_for(sender_raw, instructor_sender_pattern),
      speaker_id   = if_else(speaker_role == "Instructor",
                             paste0(learner_id, "_Instructor"),
                             learner_id),
      source_file  = basename(source_file_path),
      message_seq  = row_number()   # FIX 8: unique row ID (date+time is NOT unique)
    )

  # Sender diagnostics
  all_senders        <- unique(result$sender_raw)
  matched_instructor <- str_detect(all_senders, regex(instructor_sender_pattern, ignore_case = TRUE))
  unmatched_senders  <- all_senders[!matched_instructor]

  # Date span for log
  non_na_dates <- result$date_clean[!is.na(result$date_clean)]

  log$total_messages           <- nrow(result)
  log$learner_messages         <- sum(result$speaker_role == "Learner")
  log$instructor_messages      <- sum(result$speaker_role == "Instructor")
  log$na_date_messages         <- sum(is.na(result$date_clean))
  log$unmatched_senders        <- length(unmatched_senders)
  log$unique_unmatched_senders <- if (length(unmatched_senders) > 0)
                                    paste(unmatched_senders, collapse = "; ")
                                  else ""
  log$first_message_date       <- if (length(non_na_dates) > 0) as.character(min(non_na_dates)) else NA_character_
  log$last_message_date        <- if (length(non_na_dates) > 0) as.character(max(non_na_dates)) else NA_character_
  log$date_span_days           <- if (length(non_na_dates) > 0)
                                    as.integer(max(non_na_dates) - min(non_na_dates))
                                  else NA_integer_

  if (log$na_date_messages > 0) {
    log$parse_note <- paste0(log$na_date_messages,
      " messages have NA date (no preceding date header in export)")
  }

  parsing_log_rows[[learner_id]] <<- log
  result
}

# ── Run parser ───────────────────────────────────────────────────────────────

message_df <- pmap_dfr(
  manifest %>% select(learner_id, source_file_path, instructor_sender_pattern, export_encoding),
  parse_export
)

# ── Write parsing log ────────────────────────────────────────────────────────

parsing_log <- bind_rows(parsing_log_rows)
write_csv(parsing_log, log_path)
cat("\nParsing log written to:", log_path, "\n")

# ── Validation pass ──────────────────────────────────────────────────────────

missing_files <- parsing_log %>% filter(!file_found)
if (nrow(missing_files) > 0) {
  warning(nrow(missing_files), " export file(s) not found: ",
          paste(missing_files$learner_id, collapse = ", "),
          "\n  Affected learners will be absent from all outputs.")
}

na_date_problems <- parsing_log %>%
  filter(!is.na(total_messages), total_messages > 0) %>%
  mutate(na_date_pct = na_date_messages / total_messages) %>%
  filter(na_date_pct > 0.05)
if (nrow(na_date_problems) > 0) {
  warning("High NA-date rate (>5%) for: ",
          paste(na_date_problems$learner_id, collapse = ", "),
          "\n  Date headers may be missing or in an unexpected format.")
}

no_instructor <- parsing_log %>%
  filter(!is.na(instructor_messages), instructor_messages == 0, file_found)
if (nrow(no_instructor) > 0) {
  warning("No instructor messages detected for: ",
          paste(no_instructor$learner_id, collapse = ", "),
          "\n  Check instructor_sender_pattern in the manifest.")
}

# FIX 5: threshold raised to >2 — single unmatched sender is normal (E-prefix contact tag)
extra_senders <- parsing_log %>%
  filter(unmatched_senders > 2, file_found)
if (nrow(extra_senders) > 0) {
  warning("More than 2 unmatched sender names in: ",
          paste(extra_senders$learner_id, collapse = ", "),
          "\n  Possible group-chat participants or system labels.",
          "\n  Note: unmatched_senders = 1 is normal in 1-to-1 exports where",
          "\n  the learner contact uses a display-name prefix (e.g. 'E ').")
}

# FIX 6: threshold raised to >6.0 — rates of 1-4x are normal for lesson message blocks
continuation_problems <- parsing_log %>%
  filter(!is.na(message_lines_matched), message_lines_matched > 0) %>%
  mutate(continuation_rate = continuation_merges / message_lines_matched) %>%
  filter(continuation_rate > 6.0)
if (nrow(continuation_problems) > 0) {
  warning("Very high continuation rate (>600%) for: ",
          paste(continuation_problems$learner_id, collapse = ", "),
          "\n  This may indicate a changed export format or pasted document content.")
}

# Console summary
cat("\n\u2500\u2500 Parsing validation summary \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n")
parsing_log %>%
  mutate(
    continuation_rate = round(continuation_merges / pmax(message_lines_matched, 1), 2),
    obs_window        = paste0(first_message_date, " to ", last_message_date,
                               " (", date_span_days, "d)")
  ) %>%
  select(learner_id, message_lines_matched, continuation_rate, gt_correction_lines,
         lines_unmatched, na_date_messages, learner_messages, instructor_messages,
         obs_window, parse_note) %>%
  print(n = Inf, width = Inf)
cat("\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\n")

if (nrow(message_df) == 0) {
  stop("No message rows were parsed. Check file paths, encodings, and KakaoTalk export format.", call. = FALSE)
}

# ── Feature engineering ──────────────────────────────────────────────────────

# FIX 7: media placeholder flag — exclude from word_count calculations
media_placeholder_terms <- c("\uC0AC\uC9C4", "\uB3D9\uC601\uC0C1", "\uD30C\uC77C",
                              "\uC774\uBAA8\uD2F0\uCF58", "\uC0AD\uC81C\uB41C \uBA54\uC2DC\uC9C0")

analysis_df <- message_df %>%
  mutate(
    time_clean      = to_24_hour(time_marker, time_raw),
    datetime_clean  = ymd_hms(paste(date_clean, time_clean), quiet = TRUE),
    message         = str_squish(message),

    # FIX 7: flag media placeholders before word_count
    is_media_placeholder = str_squish(message) %in% media_placeholder_terms,

    # word_count excludes media placeholder rows (set to 0 for clean aggregation)
    word_count      = if_else(is_media_placeholder, 0L, as.integer(str_count(message, "\\S+"))),
    char_count      = nchar(message),

    # is_english threshold: 3+ consecutive alpha chars (excludes romanization artifacts)
    # Note: excludes 1-2 char English tokens (OK, Hi, No); see data_dictionary for rationale
    is_english      = str_detect(message, "[A-Za-z]{3,}"),

    # contains_correction: keyword-based; does NOT require '>' format
    contains_correction = str_detect(
      message,
      regex(
        "(^|\\s)(->|=>)|correction|corrected|suggestion|better:|revise|\uC218\uC815|\uAD50\uC815",
        ignore_case = TRUE
      )
    ),

    # FIX 2: contains_gt_correction already set in parser; propagate here
    contains_gt_correction = coalesce(contains_gt_correction, FALSE),

    # FIX 3: 'work' removed — fires on English lesson content, not scheduling
    # Korean terms retained as primary disruption signal
    schedule_disruption = str_detect(
      message,
      regex(
        paste0(
          "meeting|busy|late|overtime|business trip|deadline|delay|",
          "reschedul|can't make|cannot make|work trip|work conflict|stuck at work|",
          "\uD68C\uC758|\uC57C\uADFC|\uCD9C\uC7A5|\uC77C\uC815|\uBCC0\uACBD|\uBD88\uAC00|\uB2A6"
        ),
        ignore_case = TRUE
      )
    ),

    apology_uncertainty_marker = str_detect(
      message,
      regex(
        paste0(
          "sorry|apolog|maybe|not sure|i think|i guess|afraid|worried|confus|",
          "can't|cannot|unable|",
          "\uC8C4\uC1A1|\uBBF8\uC548|\uAC71\uC815|\uD5F7\uAC08|\uBAA8\uB974|\uC5B4\uB835|\uBBAB"
        ),
        ignore_case = TRUE
      )
    ),

    contains_url        = str_detect(message, "https?://"),
    is_grammar_exercise = str_detect(message, "-{5,}")

  ) %>%
  arrange(learner_id, datetime_clean) %>%
  group_by(learner_id) %>%
  mutate(
    study_week       = as.integer(difftime(date_clean, min(date_clean, na.rm = TRUE), units = "weeks")) + 1L,
    hour_24          = hour(datetime_clean),
    message_sequence = row_number()
  ) %>%
  ungroup() %>%
  left_join(metadata, by = "learner_id") %>%
  select(
    learner_id, learner_label, learner_type, occupational_domain,
    schedule_context, intake_context_notes, opic_target, weeks_enrolled, primary_focus,
    date_clean, study_week, datetime_clean, hour_24, message_sequence,
    speaker_id, speaker_role,
    word_count, char_count,
    is_english, is_media_placeholder,
    contains_correction, contains_gt_correction,
    schedule_disruption, apology_uncertainty_marker,
    contains_url, is_grammar_exercise,
    message
  )

write_csv(analysis_df, message_path)

# ── Learner-week summary ─────────────────────────────────────────────────────

weekly_summary <- analysis_df %>%
  filter(!is.na(study_week)) %>%   # exclude NA-week messages from summaries
  group_by(learner_id, learner_label, occupational_domain, study_week) %>%
  summarise(
    week_start                = min(date_clean, na.rm = TRUE),
    learner_messages          = sum(speaker_role == "Learner", na.rm = TRUE),
    instructor_messages       = sum(speaker_role == "Instructor", na.rm = TRUE),
    total_messages            = n(),

    # FIX 7: exclude media placeholders from word count
    avg_learner_word_count    = mean(
      word_count[speaker_role == "Learner" & !is_media_placeholder],
      na.rm = TRUE
    ),

    english_messages          = sum(speaker_role == "Learner" & is_english, na.rm = TRUE),
    english_proportion        = if_else(learner_messages > 0,
                                        english_messages / learner_messages, NA_real_),
    disruption_count          = sum(speaker_role == "Learner" & schedule_disruption, na.rm = TRUE),
    disruption_flag           = as.integer(disruption_count > 0),
    apology_uncertainty_count = sum(speaker_role == "Learner" & apology_uncertainty_marker, na.rm = TRUE),
    apology_uncertainty_rate  = if_else(learner_messages > 0,
                                        apology_uncertainty_count / learner_messages, NA_real_),

    # Keyword-based corrections
    correction_count          = sum(speaker_role == "Instructor" & contains_correction, na.rm = TRUE),
    # FIX 2: gt-correction count separately for cross-learner comparability
    gt_correction_count       = sum(contains_gt_correction, na.rm = TRUE),
    correction_density        = if_else(instructor_messages > 0,
                                        correction_count / instructor_messages, NA_real_),
    .groups = "drop"
  )

write_csv(weekly_summary, weekly_path)

# ── Learner summary ──────────────────────────────────────────────────────────

learner_summary <- weekly_summary %>%
  group_by(learner_id, learner_label, occupational_domain) %>%
  summarise(
    observed_weeks                = n_distinct(study_week),
    first_week                    = min(week_start, na.rm = TRUE),
    last_week                     = max(week_start, na.rm = TRUE),
    learner_messages              = sum(learner_messages, na.rm = TRUE),
    instructor_messages           = sum(instructor_messages, na.rm = TRUE),
    mean_weekly_learner_messages  = mean(learner_messages, na.rm = TRUE),
    mean_english_proportion       = mean(english_proportion, na.rm = TRUE),
    disruption_weeks              = sum(disruption_flag, na.rm = TRUE),
    mean_apology_uncertainty_rate = mean(apology_uncertainty_rate, na.rm = TRUE),
    mean_correction_density       = mean(correction_density, na.rm = TRUE),
    total_gt_corrections          = sum(gt_correction_count, na.rm = TRUE),
    .groups = "drop"
  )

write_csv(learner_summary, learner_path)

cat("Multi-learner corpus build complete.\n")
cat("Learners parsed:", n_distinct(analysis_df$learner_id), "\n")
cat("Messages parsed:", nrow(analysis_df), "\n")
cat("Learner-week rows:", nrow(weekly_summary), "\n")
cat("Parsing log:", log_path, "\n")
