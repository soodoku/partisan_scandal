approval_source_surname <- function(x) {
  x <- tolower(trimws(gsub("*", "", x, fixed = TRUE)))
  aliases <- c(
    session = "sessions", spector = "specter", billnelson = "nelson",
    bennelson = "nelson", "nelson  ben" = "nelson",
    "kennedy  ed" = "kennedy", "kerry  john" = "kerry", "byrd  rober" = "byrd"
  )
  replace <- x %in% names(aliases)
  x[replace] <- unname(aliases[x[replace]])
  normalize_surname(x)
}

approval_source_key <- function(state, office, name, year, month) {
  paste(state, office, approval_source_surname(name), year, month, sep = "|")
}

approval_source_percent <- function(x) {
  x <- trimws(as.character(x))
  missing <- is.na(x) | x %in% c("", "**", "NA")
  if (any(!missing & !grepl("^[0-9]+([.][0-9]+)?%?$", x))) {
    stop("Invalid source percentage")
  }
  value <- rep(NA_real_, length(x))
  value[!missing] <- as.numeric(sub("%$", "", x[!missing]))
  stopifnot(all(is.na(value) | (value >= 0 & value <= 100)))
  value
}

read_approval_sources <- function(path = "data/external") {
  raw <- read.csv(file.path(path, "surveyusa_polls.csv"))
  raw$source_row <- seq_len(nrow(raw))
  raw <- raw[grepl("Senator|Governor|President", raw$question), ]
  office <- ifelse(grepl("Senator", raw$question), "S",
    ifelse(grepl("Governor", raw$question), "G", "P")
  )
  name <- sub(".*of the job (.*?) is doing.*", "\\1", raw$question)
  start <- as.Date(raw$from_date, "%m/%d/%Y")
  end <- as.Date(raw$to_date, "%m/%d/%Y")
  stopifnot(!anyNA(start), all(is.na(end) | end >= start))
  source <- data.frame(
    source_file = "data/external/surveyusa_polls.csv",
    source_row = raw$source_row, source_name = name,
    source_state = sub("^State of ", "", raw$state), source_office = office,
    source_year = as.integer(format(start, "%Y")),
    source_month = as.integer(format(start, "%m")),
    source_start_date = start, source_end_date = end,
    source_date_precision = "day", source_poll_id = as.character(raw$pollid),
    source_poll_key = paste0("surveyusa:", raw$pollid), source_url = raw$url,
    source_sample_n = as.numeric(raw$n), source_party = NA_character_,
    comparable_party_definition = !nzchar(raw$composition_party_affiliation_strong_republican) &
      !nzchar(raw$composition_party_affiliation_strong_democrat),
    source_response_scale = "approve/disapprove/not sure",
    source_denominator_status = "total N and rounded party shares; exact party counts unavailable"
  )
  for (group in c("all", "republican", "democrat", "independent")) {
    suffix <- if (group == "all") "all" else paste0("party_affiliation_", group)
    for (measure in c("approve", "disapprove", "composition")) {
      source[[paste("source", group, measure, sep = "_")]] <-
        approval_source_percent(raw[[paste(measure, suffix, sep = "_")]])
    }
  }
  duplicate_key <- paste(source$source_poll_key, office, name, sep = "|")
  source$source_duplicate <- duplicated(duplicate_key) | duplicated(duplicate_key, fromLast = TRUE)
  duplicates <- which(duplicated(duplicate_key))
  for (i in duplicates) {
    j <- match(duplicate_key[i], duplicate_key)
    compare <- setdiff(names(source), "source_row")
    stopifnot(identical(unname(as.list(source[i, compare])), unname(as.list(source[j, compare]))))
  }
  source <- source[!duplicated(duplicate_key), ]
  president <- read.csv(file.path(path, "jacobson_presidents.csv"))
  composition_key <- paste(president$state, president$Month)
  stopifnot(!anyDuplicated(composition_key))
  for (kind in c("senators", "governors", "presidents")) {
    filename <- paste0("jacobson_", kind, ".csv")
    jacobson <- read.csv(file.path(path, filename))
    state <- if (kind == "presidents") jacobson$state else jacobson$State
    year <- 2005L + (jacobson$Month + 3L) %/% 12L
    month <- (jacobson$Month + 3L) %% 12L + 1L
    next_month <- month %% 12L + 1L
    next_year <- year + (month == 12L)
    prior <- source[rep(NA_integer_, nrow(jacobson)), ]
    prior$source_file <- paste0("data/external/", filename)
    prior$source_row <- seq_len(nrow(jacobson))
    prior$source_office <- switch(kind,
      senators = "S",
      governors = "G",
      presidents = "P"
    )
    prior$source_name <- if (kind == "senators") jacobson$Senator else NA_character_
    prior$source_state <- state.name[state]
    prior$source_year <- year
    prior$source_month <- month
    prior$source_start_date <- as.Date(sprintf("%04d-%02d-01", year, month))
    prior$source_end_date <- as.Date(sprintf("%04d-%02d-01", next_year, next_month)) - 1L
    prior$source_date_precision <- "month"
    prior$source_poll_key <- paste0("jacobson:", (jacobson$Month - 1L) * 50L + state)
    prior$source_duplicate <- FALSE
    prior$comparable_party_definition <- TRUE
    prior$source_response_scale <- "collapsed approve/disapprove; original options unverified"
    prior$source_denominator_status <- "rounded party shares; total N and exact party counts unavailable"
    if (kind == "senators") prior$source_party <- ifelse(jacobson$Party == 1, "R", "D")
    index <- match(paste(state, jacobson$Month), composition_key)
    stopifnot(!anyNA(index))
    groups <- c(all = "All", republican = "Rep", democrat = "Dem", independent = "Ind")
    for (group in names(groups)) {
      for (measure in c("approve", "disapprove")) {
        if (kind == "presidents") {
          if (measure == "disapprove") next
          column <- paste("Approval", groups[group], sep = ".")
        } else if (kind == "senators") {
          column <- paste(groups[group], if (group == "all") measure else tools::toTitleCase(measure), sep = ".")
        } else {
          column <- paste(if (group == "all") "all" else groups[group], measure, sep = ".")
          if (group == "independent") column <- if (measure == "approve") "Ind.Approve" else "Ind.disaprove"
        }
        stopifnot(column %in% names(jacobson))
        prior[[paste("source", group, measure, sep = "_")]] <- approval_source_percent(jacobson[[column]])
      }
      if (group != "all") {
        prior[[paste0("source_", group, "_composition")]] <- president[[paste0("PID.", groups[group])]][index]
      }
    }
    source <- rbind(source, prior)
  }
  rownames(source) <- NULL
  source
}

enrich_approval <- function(approval, path = "data/external") {
  source <- read_approval_sources(path)
  historical_names <- names(approval)
  monthly <- source$source_date_precision == "month" & source$source_office != "S"
  source_key <- approval_source_key(
    source$source_state, source$source_office,
    ifelse(monthly, "", source$source_name), source$source_year, source$source_month
  )
  stopifnot(!anyDuplicated(source_key))
  historical_monthly <- approval$year <= 2006 & approval$office != "S"
  key <- approval_source_key(
    approval$statename, approval$office,
    ifelse(historical_monthly, "", approval$name), approval$year, approval$month.n
  )
  index <- match(key, source_key)
  if (anyNA(index)) stop("Historical approval record lacks source match")
  matched <- source[index, ]
  known_party <- !is.na(matched$source_party) & !is.na(approval$party_r)
  stopifnot(all(approval$party_r[known_party] == matched$source_party[known_party]))
  groups <- c(all = "all", rep = "republican", dem = "democrat", ind = "independent")
  for (prefix in names(groups)) {
    group <- groups[prefix]
    for (measure in c("approve", "disapprove")) {
      before <- approval[[paste(prefix, measure, sep = ".")]]
      after <- matched[[paste("source", group, measure, sep = "_")]]
      missing_presidential <- approval$office == "P" & approval$year <= 2006 &
        (measure == "disapprove" | (group == "all" & is.na(before)))
      comparable <- !missing_presidential
      equal <- (is.na(before) & is.na(after)) | (!is.na(before) & !is.na(after) & before == after)
      if (any(comparable & !equal)) stop("Historical approval outcome differs from source")
    }
  }
  result <- cbind(approval, matched)
  result$record_provenance <- "historical"
  restore <- source$source_year == 2006 & source$source_month == 12 &
    source$source_office %in% c("S", "G")
  missing <- source[restore, ]
  identity_key <- with(approval, paste(statename, office, approval_source_surname(name), sep = "|"))
  for (i in seq_len(nrow(missing))) {
    row <- missing[i, ]
    candidate <- which(approval$year == 2006 & identity_key == paste(
      row$source_state, row$source_office, approval_source_surname(row$source_name),
      sep = "|"
    ))
    if (!length(candidate)) stop("Restored poll has no historical identity")
    identities <- unique(approval[candidate, c("key", "party_r", "statecode")])
    stopifnot(nrow(identities) == 1L, !is.na(identities$party_r))
    new <- approval[candidate[1], , drop = FALSE]
    new[, ] <- NA
    for (field in c("statecode", "statename", "lastname", "name", "party", "party_r", "type", "office", "key")) {
      new[[field]] <- approval[[field]][candidate[1]]
    }
    new$row_id <- max(approval$row_id) + i
    new$X <- -row$source_row
    new$pollid <- -as.integer(row$source_poll_id)
    new$year <- 2006L
    new$month <- "December"
    new$month.n <- 12L
    new$month_id <- 2006L * 12L + 12L
    groups <- c(all = "all", rep = "republican", dem = "democrat", ind = "independent")
    for (group in names(groups)) {
      for (measure in c("approve", "disapprove")) {
        new[[paste(group, measure, sep = ".")]] <- row[[paste("source", groups[group], measure, sep = "_")]]
      }
    }
    new$inparty <- ifelse(new$party_r == "R", new$rep.approve, new$dem.approve)
    new$outparty <- ifelse(new$party_r == "R", new$dem.approve, new$rep.approve)
    new$in.approve <- new$inparty
    new$out.approve <- new$outparty
    new$gap <- new$inparty - new$outparty
    for (field in names(approval)) {
      if (is.integer(approval[[field]])) new[[field]] <- as.integer(new[[field]])
    }
    new <- cbind(new, row)
    new$record_provenance <- "restored December 2006"
    result <- rbind(result, new)
  }
  rownames(result) <- NULL
  stopifnot(!anyDuplicated(result$row_id), identical(result[seq_len(nrow(approval)), historical_names], approval))
  result
}
