calendar_hac <- function(fit, dates, lag = 7L) {
  x <- model.matrix(fit)
  stopifnot(length(dates) == nrow(x), !anyNA(dates), !anyNA(coef(fit)))
  w <- weights(fit)
  if (is.null(w)) w <- rep(1, nrow(x))
  scores <- rowsum(x * as.numeric(w * residuals(fit)), as.character(dates), reorder = TRUE)
  days <- as.numeric(as.Date(rownames(scores)))
  kernel <- pmax(1 - abs(outer(days, days, "-")) / (lag + 1), 0)
  bread <- solve(crossprod(x, x * w))
  groups <- nrow(scores)
  stopifnot(groups > ncol(x))
  bread %*% crossprod(scores, kernel %*% scores) %*% bread * groups / (groups - ncol(x))
}

publicity_contrast <- function(fit, covariance, terms, df) {
  contrast <- setNames(rep(0, length(coef(fit))), names(coef(fit)))
  stopifnot(all(names(terms) %in% names(contrast)))
  contrast[names(terms)] <- terms
  b <- sum(contrast * coef(fit))
  se <- sqrt(drop(t(contrast) %*% covariance %*% contrast))
  data.frame(
    estimate = b, se = se, df = df, lower = b - qt(.975, df) * se,
    upper = b + qt(.975, df) * se, p = 2 * pt(-abs(b / se), df), n = nobs(fit)
  )
}

read_broadcasts <- function(base) {
  manifest <- read.csv(file.path(base, "manifest.csv"))
  all_rows <- calendars <- list()
  for (i in seq_len(nrow(manifest))) {
    path <- file.path(base, "raw", manifest$file[i])
    stopifnot(identical(digest::digest(file = path, algo = "sha256"), manifest$sha256[i]))
    rows <- jsonlite::fromJSON(path, simplifyVector = FALSE)$data
    if (grepl("calendar[?]", manifest$url[i])) {
      stopifnot(length(rows) < 1000)
      calendars <- c(calendars, rows)
    } else {
      stopifnot(length(rows) > 0)
      all_rows <- c(all_rows, rows)
    }
  }
  fields <- c(
    "segment_id", "broadcast_id", "broadcast_date", "network_name", "segment_title",
    "segment_description", "segment_duration", "segment_type_id"
  )
  flatten <- function(rows, fields) {
    do.call(rbind, lapply(rows, function(row) {
      as.data.frame(setNames(lapply(fields, function(field) {
        if (is.null(row[[field]])) NA_character_ else as.character(row[[field]])
      }), fields))
    }))
  }
  segments <- flatten(all_rows, fields)
  programs <- flatten(calendars, c("broadcast_id", "broadcast_date", "net_dist_value", "broadcast_type_id"))
  take <- programs$net_dist_value %in% c("ABC", "CBS", "NBC") & programs$broadcast_type_id == "1"
  programs <- programs[take, ]
  stopifnot(!anyDuplicated(programs$broadcast_id), !anyDuplicated(segments$segment_id))
  stopifnot(setequal(programs$broadcast_id, segments$broadcast_id))
  m <- match(segments$broadcast_id, programs$broadcast_id)
  stopifnot(all(segments$broadcast_date == programs$broadcast_date[m]))
  stopifnot(all(segments$network_name == programs$net_dist_value[m]))
  segments$segment_duration <- as.numeric(segments$segment_duration)
  stopifnot(all(is.finite(segments$segment_duration)), all(segments$segment_duration >= 0))
  list(segments = segments, programs = programs)
}
