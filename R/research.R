read_research_jsonl <- function(paths) {
  unlist(lapply(paths, function(path) {
    lapply(readLines(path, warn = FALSE), jsonlite::fromJSON, simplifyVector = FALSE)
  }), recursive = FALSE)
}

research_scalar <- function(x) {
  if (is.null(x)) {
    return(NA_character_)
  }
  stopifnot(length(x) == 1L)
  as.character(x)
}

research_roster <- function(panel) {
  panel <- panel[panel$office %in% c("G", "S"), ]
  do.call(rbind, lapply(split(panel, panel$key), function(d) {
    known <- unique(d$politician[!is.na(d$politician)])
    if (!length(known)) known <- unique(d$name[!is.na(d$name)])
    unresolved <- grepl("[|]NA$", d$key[1])
    months <- sort(unique(sprintf("%04d-%02d", d$year, d$month.n)))
    data.frame(
      key = d$key[1], politician = if (unresolved) "Unresolved transition record" else known[1],
      state = d$statecode[1], office = d$office[1], party = d$party_r[1],
      polls = nrow(d), eligible_polls = sum(d$eligible),
      first_month = min(months), last_month = max(months), observed_months = paste(months, collapse = ";"),
      prior_status = d$coding_status[1], identity_resolved = !unresolved,
      eligibility_note = if (unresolved) {
        "Official identity unresolved"
      } else if (d$key[1] == "VT|S|jeffords") {
        "Independent; co-partisan mapping undefined"
      } else if (d$key[1] == "VA|G|warner|R") {
        "Mark Warner governor party miscoded in source; no paired outcomes; not silently relinked"
      } else if (!any(d$eligible)) {
        "No comparable complete paired partisan outcomes"
      } else {
        "Comparable paired outcomes available"
      }
    )
  }))
}

compile_research <- function(records, roster) {
  fields <- c(
    "event_id", "episode_id", "key", "label", "category", "allegation_status", "reported_date",
    "date_precision", "incident_date", "milestone", "description", "date_basis",
    "original_relationship", "research_status", "notes", "inclusion_scope", "subject_scope",
    "date_lower", "date_upper"
  )
  events <- do.call(rbind, lapply(records, function(x) {
    as.data.frame(setNames(lapply(fields, function(n) research_scalar(x[[n]])), fields))
  }))
  stopifnot(!anyDuplicated(events$event_id), all(events$key %in% roster$key))
  stopifnot(all(events$inclusion_scope %in% c("core", "broad_only", "context", "uncertain")))
  stopifnot(all(events$date_precision %in% c("day", "month", "interval")))
  for (i in seq_len(nrow(events))) {
    date <- as.Date(events$reported_date[i])
    stopifnot(!is.na(date))
    if (events$date_precision[i] == "month") {
      events$date_lower[i] <- format(date, "%Y-%m-01")
      events$date_upper[i] <- as.character(as.Date(format(date + 32, "%Y-%m-01")) - 1)
    } else if (events$date_precision[i] == "day") {
      events$date_lower[i] <- events$date_upper[i] <- as.character(date)
    }
  }
  stopifnot(!anyNA(as.Date(events$date_lower)), !anyNA(as.Date(events$date_upper)))
  stopifnot(all(as.Date(events$date_lower) <= as.Date(events$date_upper)))
  sources <- do.call(rbind, lapply(records, function(x) {
    stopifnot(length(x$sources) > 0)
    do.call(rbind, lapply(seq_along(x$sources), function(j) {
      s <- x$sources[[j]]
      f <- c(
        "url", "title", "publisher", "publication_date", "source_type", "supports",
        "retrieval_status", "access_date"
      )
      data.frame(
        event_id = x$event_id, source_id = paste0(x$event_id, ":", j),
        as.data.frame(setNames(lapply(f, function(n) research_scalar(s[[n]])), f))
      )
    }))
  }))
  stopifnot(all(grepl("^https?://", sources$url)), !anyDuplicated(sources$source_id))
  stopifnot(setequal(events$event_id, sources$event_id))
  stopifnot(all(tapply(events$key, events$episode_id, function(x) length(unique(x))) == 1))
  list(events = events, sources = sources)
}

research_support <- function(events, panel, windows = c(3, 6, 12)) {
  month <- function(x) as.integer(format(as.Date(x), "%Y")) * 12L + as.integer(format(as.Date(x), "%m"))
  lower <- month(events$date_lower)
  upper <- month(events$date_upper)
  result <- list()
  for (i in seq_len(nrow(events))) {
    d <- panel[which(panel$key == events$key[i] & panel$eligible), ]
    other <- events$key == events$key[i] & events$episode_id != events$episode_id[i] &
      events$inclusion_scope != "context"
    prior <- max(c(-Inf, upper[other & upper < lower[i]]))
    next_event <- min(c(Inf, lower[other & lower > upper[i]]))
    concurrent <- any(other & lower <= upper[i] & upper >= lower[i])
    for (window in windows) {
      for (censor in c(FALSE, TRUE)) {
        take <- d$month_id >= lower[i] - window & d$month_id <= upper[i] + window
        if (censor) take <- take & d$month_id > prior & d$month_id < next_event
        pre <- sum(take & d$month_id < lower[i])
        post <- sum(take & d$month_id > upper[i])
        result[[length(result) + 1L]] <- data.frame(
          event_id = events$event_id[i], key = events$key[i], window = window,
          censor_other_researched_episodes = censor, concurrent_episode = concurrent,
          pre = pre, post = post, has_two_each_side = pre >= 2 & post >= 2
        )
      }
    }
  }
  do.call(rbind, result)
}
