source("R/publicity.R")
source("R/exhibits.R")
raw <- read_broadcasts("data/external/publicity/vanderbilt")
codes <- read.csv("data/research/broadcast_topic_codes.csv")
stopifnot(!anyDuplicated(codes$segment_id), setequal(codes$segment_id, raw$segments$segment_id))
segments <- merge(raw$segments, codes, by = "segment_id", suffixes = c("", "_coded"))
stopifnot(all(segments$broadcast_id == segments$broadcast_id_coded))
stopifnot(all(segments$segment_duration == segments$duration_seconds))
topics <- c(
  "swiftboat_allegation", "swiftboat_literal", "kerry_military_controversy_broad",
  "olympics_competing_news", "troopergate"
)
segments$substantive_news <- as.logical(segments$substantive_news)
segments$abstract_available <- as.logical(segments$abstract_available)
for (topic in topics) {
  segments[[topic]] <- as.logical(segments[[topic]])
  stopifnot(all(!segments[[topic]] | segments$substantive_news))
}
programs <- do.call(rbind, lapply(split(segments, segments$broadcast_id), function(d) {
  out <- data.frame(broadcast_id = d$broadcast_id[1], date = d$date[1], network = d$network[1])
  out$news_minutes <- sum(d$segment_duration[d$substantive_news]) / 60
  out$missing_news_abstracts <- sum(d$substantive_news & !d$abstract_available)
  for (topic in topics) {
    out[[paste0(topic, "_present")]] <- as.integer(any(d[[topic]]))
    out[[paste0(topic, "_minutes")]] <- sum(d$segment_duration[d[[topic]]]) / 60
    out[[paste0(topic, "_count")]] <- sum(d[[topic]])
  }
  out
}))
stopifnot(!anyDuplicated(programs[c("date", "network")]))
write.csv(programs, "data/derived/broadcast_programs.csv", row.names = FALSE)
write.csv(segments, "data/derived/broadcast_segments.csv", row.names = FALSE)
measures <- c(
  "swiftboat_allegation_present", "swiftboat_allegation_minutes",
  "olympics_competing_news_minutes", "kerry_military_controversy_broad_present"
)
daily <- reshape(programs[c("date", "network", measures)], idvar = "date", timevar = "network", direction = "wide")
daily <- daily[order(daily$date), ]
daily$complete <- complete.cases(daily)
daily <- daily[substr(daily$date, 1, 4) == "2004", ]
daily$olympics <- as.integer(daily$date >= "2004-08-13" & daily$date <= "2004-08-29")
daily$after <- as.integer(daily$date > "2004-08-29")
daily$day <- as.numeric(as.Date(daily$date) - as.Date("2004-08-13"))
daily$weekday <- as.integer(format(as.Date(daily$date), "%u")) <= 5
for (measure in measures) {
  daily[[measure]] <- daily[[paste0(measure, ".NBC")]] -
    (daily[[paste0(measure, ".ABC")]] + daily[[paste0(measure, ".CBS")]]) / 2
  if (grepl("present$", measure)) daily[[measure]] <- 100 * daily[[measure]]
}
write.csv(daily, "data/derived/broadcast_network_gaps.csv", row.names = FALSE)
models <- list()
for (measure in measures) {
  for (specification in c("Linear trend", "No trend", "Weekdays", "Before closing")) {
    take <- daily$complete
    if (specification == "Weekdays") take <- take & daily$weekday
    if (specification == "Before closing") take <- take & daily$after == 0
    d <- daily[take, ]
    rhs <- c("olympics", if (specification != "Before closing") "after", if (specification != "No trend") "day")
    fit <- lm(reformulate(rhs, measure), data = d)
    for (lag in c(3L, 7L, 10L)) {
      v <- calendar_hac(fit, d$date, lag)
      out <- publicity_contrast(fit, v, c(olympics = 1), nrow(d) - length(coef(fit)))
      out$outcome <- measure
      out$specification <- specification
      out$lag <- lag
      models[[length(models) + 1L]] <- out
    }
  }
}
models <- do.call(rbind, models)
write.csv(models, "tabs/publicity_coverage_models.csv", row.names = FALSE)
print(models[models$specification == "Linear trend" & models$lag == 7, ])

opinions <- list()
for (year in c(2004, 2008)) {
  d <- read.csv(sprintf("data/external/publicity/naes/naes%d.csv", year))
  meta <- jsonlite::read_json(sprintf("data/external/publicity/naes/naes%d_provenance.json", year))
  stopifnot(identical(digest::digest(file = meta$output_path, algo = "sha256"), meta$output_sha256))
  variable <- if (year == 2004) "cab01" else "aap01"
  take <- d[[variable]] %in% 0:10 & d$pid3 %in% c("Democrat", "Republican")
  d <- d[take, ]
  d$rating <- 10 * d[[variable]]
  d$date <- d$interview_date
  first <- if (year == 2004) "2004-07-22" else "2008-09-19"
  last <- if (year == 2004) "2004-09-12" else "2008-10-31"
  d <- d[d$date >= first & d$date <= last, ]
  groups <- split(d, interaction(d$date, d$pid3, drop = TRUE))
  opinions[[as.character(year)]] <- do.call(rbind, lapply(groups, function(z) {
    data.frame(
      year = year, date = z$date[1], party = z$pid3[1], n = nrow(z),
      rating = mean(z$rating)
    )
  }))
}
opinions <- do.call(rbind, opinions)
write.csv(opinions, "data/derived/naes_publicity_daily.csv", row.names = FALSE)
