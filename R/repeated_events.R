repeated_event_sample <- function(inputs, panel, window = 12) {
  events <- inputs$scandals[!is.na(inputs$scandals$date), ]
  events <- events[order(events$date, events$source_row), ]
  events <- events[!duplicated(events[c("key", "month_id")]), ]
  out <- list()
  for (i in seq_len(nrow(events))) {
    event <- events[i, ]
    times <- sort(unique(events$month_id[events$key == event$key]))
    previous <- max(c(-Inf, times[times < event$month_id]))
    following <- min(c(Inf, times[times > event$month_id]))
    take <- panel$key == event$key & panel$eligible &
      panel$party_r == event$party & abs(panel$month_id - event$month_id) <= window &
      panel$month_id != event$month_id & panel$month_id > previous &
      panel$month_id < following
    d <- panel[which(take), ]
    if (sum(d$month_id < event$month_id) < 2 || sum(d$month_id > event$month_id) < 2) next
    d$politician_id <- d$key
    d$relative_month <- d$month_id - event$month_id
    d$post <- as.integer(d$relative_month > 0)
    d$id <- paste(event$key, event$source_row, sep = ":")
    d$event_source <- event$source_row
    d$event_date <- event$date
    d$event_month <- event$month_id
    d$event_type <- event$scandal_type
    out[[length(out) + 1]] <- d
  }
  do.call(rbind, out)
}
