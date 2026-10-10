args <- commandArgs(trailingOnly = TRUE)
source_path <- if (length(args)) args[1] else "../partisan_campaigns/data/raw/nes08panel.Rdata"
out_prefix <- if (length(args) > 1L) args[2] else "data/external/anes2008/palin"
dir.create(dirname(out_prefix), recursive = TRUE, showWarnings = FALSE)
source_path <- normalizePath(source_path, mustWork = TRUE)
sha256 <- function(path) {
  output <- system2("shasum", c("-a", "256", shQuote(path)), stdout = TRUE)
  sub(" .*", "", output)
}
source_hash <- sha256(source_path)
stopifnot(identical(source_hash, "ef2655a1641191390b792e209b0a976abd7633df28447e6e9645ebbc24bd41df"))
raw_env <- new.env()
load(source_path, envir = raw_env)
raw <- raw_env$nes08p
stopifnot(nrow(raw) == 4240L, !anyNA(raw$caseid), !anyDuplicated(raw$caseid))

code <- function(x) {
  if (is.factor(x) || is.character(x)) {
    label <- as.character(x)
    stopifnot(all(is.na(label) | grepl("^-?[0-9]+[.]", label)))
    return(as.numeric(sub("^(-?[0-9]+)[.].*$", "\\1", label)))
  }
  as.numeric(x)
}
rating <- function(direction, like, dislike) {
  stopifnot(all(is.na(direction) | direction %in% c(-9:-1, 1:3)))
  stopifnot(all(is.na(like) | like %in% c(-9:-1, 1:3)))
  stopifnot(all(is.na(dislike) | dislike %in% c(-9:-1, 1:3)))
  y <- rep(NA_real_, length(direction))
  y[direction %in% 3] <- 50
  take <- direction %in% 1 & like %in% 1:3
  y[take] <- 100 * (7 - like[take]) / 6
  take <- direction %in% 2 & dislike %in% 1:3
  y[take] <- 100 * (dislike[take] - 1) / 6
  y
}
parse_date <- function(x) {
  x <- trimws(as.character(x))
  observed <- grepl("^[0-9]{8}$", x)
  result <- as.Date(rep(NA_character_, length(x)))
  result[observed] <- as.Date(x[observed], "%Y%m%d")
  stopifnot(all(!is.na(result[observed])))
  result
}

out <- data.frame(
  caseid = raw$caseid, cohort = code(raw$reccohor), stratum = code(raw$stratum),
  w9date = parse_date(raw$w9date), w10date = parse_date(raw$w10date),
  pid9_code = code(raw$der08w9), weight_longitudinal_9_10 = raw$wgtl10,
  weight_baseline_9 = raw$wgtcs_w9
)
for (variable in c("w9e65", "w9e66", "w9e67", "w10e71", "w10e72", "w10e73")) {
  out[[variable]] <- code(raw[[variable]])
}
out$palin9 <- rating(out$w9e65, out$w9e66, out$w9e67)
out$palin10 <- rating(out$w10e71, out$w10e72, out$w10e73)
out$party9 <- ifelse(out$pid9_code %in% 0:2, "Democrat",
  ifelse(out$pid9_code %in% 4:6, "Republican",
    ifelse(out$pid9_code %in% 3, "Independent", NA_character_)
  )
)
out$strong9 <- out$pid9_code %in% c(0, 6)
out$partisan9 <- out$pid9_code %in% c(0:2, 4:6)
out$strict_partisan9 <- out$pid9_code %in% c(0:1, 5:6)
out$observed_rating9 <- !is.na(out$palin9)
out$observed_rating10 <- !is.na(out$palin10)
out$observed_date9 <- !is.na(out$w9date)
out$observed_date10 <- !is.na(out$w10date)
out$paired_ratings <- out$observed_rating9 & out$observed_rating10
out$paired_ratings_dates <- out$paired_ratings & out$observed_date9 & out$observed_date10
milestone <- as.Date("2008-10-10")
out$baseline_before_milestone <- out$observed_date9 & out$w9date < milestone
out$followup_phase <- ifelse(!out$observed_date10, "Missing date",
  ifelse(out$w10date < milestone, "Before October 10",
    ifelse(out$w10date == milestone, "October 10", "After October 10")
  )
)
out$followup_before_election <- out$observed_date10 & out$w10date < as.Date("2008-11-04")
out$positive_longitudinal_weight <- is.finite(out$weight_longitudinal_9_10) & out$weight_longitudinal_9_10 > 0
out$positive_baseline_weight <- is.finite(out$weight_baseline_9) & out$weight_baseline_9 > 0
out$usable_stratum <- out$stratum %in% 1:2
out$eligible_unweighted_pair <- out$paired_ratings_dates & out$baseline_before_milestone &
  out$followup_phase != "October 10" & out$followup_before_election & out$partisan9
out$eligible_weighted_pair <- out$eligible_unweighted_pair & out$positive_longitudinal_weight & out$usable_stratum

# Independent branch-label reconstruction, avoiding factor-level numeric codes.
reconstructed9 <- rep(NA_real_, nrow(raw))
for (branch in c("Like", "Dislike", "Neither like nor dislike")) {
  branch_code <- match(branch, c("Like", "Dislike", "Neither like nor dislike"))
  take <- as.character(raw$w9e65) == paste0(branch_code, ". ", branch)
  if (branch == "Neither like nor dislike") reconstructed9[take] <- 50
  if (branch == "Like") {
    for (intensity in 1:3) {
      selected <- take & code(raw$w9e66) == intensity
      reconstructed9[selected] <- c(100, 100 * 5 / 6, 100 * 4 / 6)[intensity]
    }
  }
  if (branch == "Dislike") {
    for (intensity in 1:3) {
      selected <- take & code(raw$w9e67) == intensity
      reconstructed9[selected] <- c(0, 100 / 6, 100 / 3)[intensity]
    }
  }
}
stopifnot(isTRUE(all.equal(out$palin9, reconstructed9)))
stopifnot(nrow(out) == 4240L, sum(out$paired_ratings_dates) == 2501L)
stopifnot(sum(out$paired_ratings_dates & out$followup_phase == "Before October 10") == 1858L)
stopifnot(sum(out$paired_ratings_dates & out$followup_phase == "After October 10") == 591L)
stopifnot(sum(out$paired_ratings_dates & out$followup_phase == "October 10") == 52L)
stopifnot(all(!is.na(out$eligible_weighted_pair)), all(out$eligible_weighted_pair <= out$eligible_unweighted_pair))
write.csv(out, paste0(out_prefix, ".csv"), row.names = FALSE, na = "")

counts <- list()
for (sample in c("All rows", "Paired ratings and dates", "Eligible unweighted", "Eligible weighted")) {
  keep <- switch(sample,
    "All rows" = rep(TRUE, nrow(out)),
    "Paired ratings and dates" = out$paired_ratings_dates,
    "Eligible unweighted" = out$eligible_unweighted_pair,
    "Eligible weighted" = out$eligible_weighted_pair
  )
  for (party in c("All", "Democrat", "Republican", "Independent", "Missing PID")) {
    party_keep <- if (party == "All") {
      rep(TRUE, nrow(out))
    } else if (party == "Missing PID") {
      is.na(out$party9)
    } else {
      !is.na(out$party9) & out$party9 == party
    }
    for (phase in c("Before October 10", "October 10", "After October 10", "Missing date")) {
      n <- sum(keep & party_keep & out$followup_phase == phase)
      counts[[length(counts) + 1L]] <- data.frame(sample, party, phase, n = n)
    }
  }
}
counts <- do.call(rbind, counts)
write.csv(counts, paste0(out_prefix, "_counts.csv"), row.names = FALSE)
provenance <- list(
  source = source_path, source_sha256 = source_hash, source_object = "nes08p",
  source_version = unique(as.character(raw$version)), source_dimensions = dim(raw),
  export = paste0(out_prefix, ".csv"), export_sha256 = sha256(paste0(out_prefix, ".csv")),
  script = "scripts/import_anes_panel.R", export_rows = nrow(out),
  official_documentation = list(
    study = "https://electionstudies.org/data-center/2008-2009-panel-study/",
    variables = paste0(
      "https://electionstudies.org/wp-",
      "content/uploads/2009/03/anes_specialstudy_2008_2009panel_variable_list.txt"
    ),
    questionnaire = paste0(
      "https://electionstudies.org/wp-",
      "content/uploads/2009/03/anes_specialstudy_2008_2009panel_qnaire.pdf"
    ),
    derived_code = paste0(
      "https://electionstudies.org/wp-",
      "content/uploads/2009/03/anes_specialstudy_2008_2009panel_DerivedVarCode.txt"
    ),
    methodology = paste0(
      "https://electionstudies.org/wp-",
      "content/uploads/2009/03/anes_specialstudy_2008_2009panel_MethodologyRpt.pdf"
    )
  ),
  mapping = list(
    id = "caseid", date9 = "w9date: YYYYMMDD, actual interview date",
    date10 = "w10date: YYYYMMDD, actual interview date",
    palin9 = c(direction = "w9e65", like = "w9e66", dislike = "w9e67"),
    palin10 = c(direction = "w10e71", like = "w10e72", dislike = "w10e73"),
    party = paste(
      "der08w9, pre-October milestone: 0-2 Democrat including leaners; 3 independent; 4-6 Republican",
      "including leaners"
    ),
    weight_longitudinal = "wgtl10: September-October cumulative late-panel weight, both cohorts",
    weight_baseline = "wgtcs_w9: archived wave9 cross-sectional weight; final-release variable list calls this wgtcs09",
    strata = "stratum: 1 higher-density Black/Hispanic; 2 other", cohort = "reccohor: archived spelling, values1/2"
  ),
  rating_formula = paste(
    "direction1:100*(7-like)/6; direction2:100*(dislike-1)/6; direction3:50; require only",
    "applicable intensity branch"
  ),
  negative_codes = list(
    `-9` = "Refused", `-8` = "Don't know", `-7` = "No answer", `-6` = "Not asked, unit nonresponse",
    `-5` = "Not asked, terminated", `-4` = "Error; see documentation", `-3` = "Restricted access",
    `-2` = "Missing; see documentation", `-1` = "Inapplicable"
  ),
  missing_rules = paste(
    "Negative item/PID codes are nonresponse; retained in raw-code fields, never numeric ratings.",
    "Structural missing unused intensity branches do not invalidate a rating. Date strings",
    "without 8 digits are missing. Zero/nonfinite weights are retained but flagged ineligible for",
    "weighted analysis."
  ),
  milestone = paste(
    "2008-10-10, candidate report-release milestone; same-day follow-up excluded because within-day",
    "order unknown; this is not original scandal onset"
  ),
  selection = paste(
    "All 4240 source rows retained. Paired-count reproduction uses two ratings and two dates.",
    "Suggested unweighted eligibility additionally requires September PID partisan, baseline before",
    "milestone, follow-up before 2008-11-04 and not milestone day. Weighted eligibility additionally",
    "requires positive wgtl10 and valid stratum. These are feasibility flags, not preregistered",
    "inclusion decisions."
  ),
  caution = paste(
    "Within-person data do not randomize interview timing or eliminate concurrent campaign events.",
    "September baseline occurs after the scandal's earlier public history. No effect estimates are",
    "calculated."
  ),
  counts = counts
)
jsonlite::write_json(provenance, paste0(out_prefix, "_provenance.json"), pretty = TRUE, auto_unbox = TRUE, na = "null")
print(subset(counts, sample %in% c("Paired ratings and dates", "Eligible weighted") & n > 0))
