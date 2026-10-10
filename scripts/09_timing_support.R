main <- read.csv("data/derived/main.csv")
panel <- read.csv("data/derived/panel.csv")
summarize_support <- function(d, unit, lower, upper) {
  data.frame(
    time_unit = unit, lower = lower, upper = upper, records = nrow(d),
    officials = length(unique(d$id)), states = length(unique(d$statecode))
  )
}
windows <- list(c(-12, -7), c(-6, -4), c(-3, -1), c(1, 1), c(1, 3), c(4, 6), c(7, 12))
monthly <- do.call(rbind, lapply(windows, function(w) {
  d <- main[main$relative_month >= w[1] & main$relative_month <= w[2], ]
  summarize_support(d, "calendar_month", w[1], w[2])
}))
take <- panel$id %in% main$id & panel$eligible & panel$source_date_precision == "day" &
  !is.na(panel$event_date) & (is.na(panel$next_month) | panel$month_id < panel$next_month)
daily <- panel[which(take), ]
daily$start <- as.numeric(as.Date(daily$source_start_date) - as.Date(daily$event_date))
daily$end <- as.numeric(as.Date(daily$source_end_date) - as.Date(daily$event_date))
day_windows <- list(c(-90, -1), c(0, 7), c(0, 30), c(31, 90), c(91, 180))
day_support <- do.call(rbind, lapply(day_windows, function(w) {
  d <- daily[which(daily$start >= w[1] & daily$end <= w[2]), ]
  summarize_support(d, "day_whole_fieldwork", w[1], w[2])
}))
write.csv(rbind(monthly, day_support), "tabs/timing_support.csv", row.names = FALSE)
precision <- as.data.frame(table(main$source_date_precision))
names(precision) <- c("source_date_precision", "records")
write.csv(precision, "tabs/timing_precision.csv", row.names = FALSE)
