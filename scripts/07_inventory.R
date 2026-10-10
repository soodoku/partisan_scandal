source("R/data.R")
source("R/exhibits.R")
source("R/models.R")
s <- read_inputs()$scandals
panel <- read.csv("data/derived/panel.csv")
main <- read.csv("data/derived/main.csv")
catalog <- read.csv("data/derived/catalog.csv")
s$identity_complete <- nzchar(s$state) & s$office %in% c("G", "S")
s$dated <- !is.na(s$date)
s$in_period <- s$dated & s$date >= as.Date("2005-01-01") & s$date <= as.Date("2011-12-31")
s$main_official <- s$key %in% main$id
s$main_event <- s$source_row %in% catalog$source_row[catalog$key %in% main$id]
stopifnot(sum(s$main_event) == length(unique(main$id)))
s$office_date <- ifelse(s$dated, paste(s$key, s$date, sep = "|"), NA_character_)
write.csv(s, "data/derived/inventory_rows.csv", row.names = FALSE)

types <- c(
  "Noncriminal sexual conduct", "Prostitution or solicitation", "Sexual harassment or assault",
  "Alcohol abuse or DUI", "Illicit drugs", "Corruption or misuse of office",
  "Racist speech or behavior", "Other inflammatory statements", "Gross incompetence"
)
composition <- data.frame(
  code = as.character(seq_along(types)), category = types,
  coding_rows = vapply(as.character(seq_along(types)), function(x) sum(s$scandal_type == x), 0L),
  main_events = vapply(as.character(seq_along(types)), function(x) {
    sum(s$scandal_type == x & s$main_event)
  }, 0L)
)
write.csv(composition, "tabs/inventory_types.csv", row.names = FALSE)
write_table(
  c("Recorded category", "Coding rows", "Main events"),
  as.matrix(composition[c("category", "coding_rows", "main_events")]), "tabs/inventory_types.tex"
)

dated <- catalog[catalog$coding_status == "dated", ]
coverage <- do.call(rbind, lapply(seq_len(nrow(dated)), function(j) {
  c <- dated[j, ]
  p <- panel[panel$id == c$key, ]
  take <- p$eligible & p$party_r == p$event_party &
    abs(p$relative_month) <= 12 & p$relative_month != 0 &
    (is.na(p$next_month) | p$month_id < p$next_month)
  usable <- p[which(take), ]
  pre <- sum(usable$relative_month < 0)
  post <- sum(usable$relative_month > 0)
  reason <- if (!nrow(p)) {
    "No matched approval records"
  } else if (pre >= 2 && post >= 2) {
    "Included"
  } else if (pre < 2 && post < 2) {
    "Fewer than two polls on both sides"
  } else if (pre < 2) {
    "Fewer than two pre-event polls"
  } else {
    "Fewer than two post-event polls"
  }
  data.frame(
    politician = c$politician, key = c$key, party = c$event_party,
    event_date = c$event_date, category = c$event_type, matched_rows = nrow(p),
    pre = pre, post = post, reason = reason,
    any_poll_before = any(p$relative_month < 0), any_poll_after = any(p$relative_month > 0)
  )
}))
stopifnot(setequal(coverage$key[coverage$reason == "Included"], unique(main$id)))
write.csv(coverage, "tabs/inventory_coverage.csv", row.names = FALSE)
flow <- as.data.frame(table(coverage$reason), stringsAsFactors = FALSE)
names(flow) <- c("reason", "officials")
write.csv(flow, "tabs/inventory_attrition.csv", row.names = FALSE)
write_table(
  c("Availability after the main window rules", "Officials"),
  as.matrix(flow), "tabs/inventory_attrition.tex"
)
year <- as.data.frame(table(format(s$date[s$dated], "%Y")), stringsAsFactors = FALSE)
names(year) <- c("year", "coding_rows")
write.csv(year, "tabs/inventory_years.csv", row.names = FALSE)
party <- as.data.frame(table(s$party[s$dated]), stringsAsFactors = FALSE)
names(party) <- c("party", "dated_coding_rows")
party$main_officials <- vapply(party$party, function(x) {
  sum(coverage$party == x & coverage$reason == "Included")
}, 0L)
write.csv(party, "tabs/inventory_parties.csv", row.names = FALSE)

samples <- list(
  "All main events" = main,
  "Corruption or misuse of office" = main[main$event_type == "6", ],
  "All other recorded categories" = main[main$event_type != "6", ]
)
category_models <- do.call(rbind, lapply(names(samples), function(label) {
  do.call(rbind, lapply(c("inparty", "outparty", "gap", "all.approve"), function(outcome) {
    d <- samples[[label]]
    d <- d[!is.na(d[[outcome]]), ]
    cbind(sample = label, fit_model(d, outcome))
  }))
}))
write.csv(category_models, "tabs/inventory_models.csv", row.names = FALSE)
overall <- category_models[category_models$sample == "All main events" & category_models$outcome == "all.approve", ]

games <- read.csv("data/external/olympic_dates.csv")
games$start <- as.Date(games$start)
games$end <- as.Date(games$end)
events <- s[s$dated & !duplicated(s$office_date), ]
overlap_days <- function(date, days) {
  sum(vapply(seq_len(nrow(games)), function(j) {
    max(0, as.numeric(min(date + days - 1, games$end[j]) - max(date, games$start[j])) + 1)
  }, 0))
}
for (days in c(1, 7, 14)) {
  events[[paste0("olympic_days_", days)]] <- vapply(events$date, overlap_days, 0, days = days)
}
write.csv(events, "tabs/olympic_event_overlap.csv", row.names = FALSE)
olympics <- do.call(rbind, lapply(c(1, 7, 14), function(days) {
  x <- events[[paste0("olympic_days_", days)]] > 0
  data.frame(
    days_from_onset = days, catalog_events = sum(x),
    main_events = sum(x & events$main_event)
  )
}))
write.csv(olympics, "tabs/olympic_support.csv", row.names = FALSE)
write_table(
  c("Publicity window from onset", "Catalog events", "Main events"),
  cbind(
    paste0(olympics$days_from_onset, ifelse(olympics$days_from_onset == 1, " day", " days")),
    olympics$catalog_events, olympics$main_events
  ),
  "tabs/olympic_support.tex"
)
counts <- c(
  Rows = nrow(s), DatedRows = sum(s$dated), CleanRows = sum(s$scandal_type == "clean."),
  IncompleteRows = sum(!s$dated & s$scandal_type != "clean."),
  DistinctDates = nrow(events), DatedOffices = nrow(coverage),
  ValidDatedOffices = length(unique(s$key[s$dated & s$identity_complete])),
  MissingIdentity = sum(!s$identity_complete), OutsidePeriod = sum(s$dated & !s$in_period),
  MainEvents = sum(s$main_event), Corruption = sum(s$scandal_type == "6" & s$main_event),
  Sexual = sum(s$scandal_type %in% c("1", "2", "3") & s$main_event),
  Republican = sum(coverage$party == "R" & coverage$reason == "Included"),
  Democrat = sum(coverage$party == "D" & coverage$reason == "Included"),
  Senators = length(unique(main$id[main$office == "S"])),
  Governors = length(unique(main$id[main$office == "G"])),
  OlympicOnsets = sum(events$olympic_days_1 > 0),
  OlympicMain = sum(events$olympic_days_1 > 0 & events$main_event)
)
write.csv(data.frame(quantity = names(counts), value = counts), "tabs/inventory_counts.csv", row.names = FALSE)
writeLines(paste0("\\newcommand{\\Inventory", names(counts), "}{", counts, "}"), "tabs/inventory_macros.tex")
cat(
  paste0(
    "\\newcommand{\\Overall", c("Estimate", "Lower", "Upper"), "}{",
    c(fmt(overall$estimate), fmt(overall$lower, 2), fmt(overall$upper, 2)), "}\n"
  ),
  file = "tabs/inventory_macros.tex", append = TRUE, sep = ""
)
print(flow)
print(composition)
print(olympics)
