source("R/research.R")
panel <- read.csv("data/derived/panel.csv")
roster <- research_roster(panel)
write.csv(roster, "data/research/official_roster.csv", row.names = FALSE)
records <- read_research_jsonl(list.files("data/research", "_events[.]jsonl$", full.names = TRUE))
built <- compile_research(records, roster)
write.csv(built$events, "data/derived/research_events.csv", row.names = FALSE)
write.csv(built$sources, "data/derived/research_sources.csv", row.names = FALSE)
support <- research_support(built$events, panel)
write.csv(support, "tabs/research_event_support.csv", row.names = FALSE)
searches <- read_research_jsonl(list.files("data/research", "_searches[.]jsonl$", full.names = TRUE))
fields <- c("key", "query", "result", "uncertainty")
searches <- do.call(rbind, lapply(searches, function(x) {
  as.data.frame(setNames(lapply(fields, function(n) research_scalar(x[[n]])), fields))
}))
stopifnot(all(searches$key %in% roster$key))
write.csv(searches, "data/derived/research_search_log.csv", row.names = FALSE)
roster$search_status <- ifelse(roster$key %in% searches$key, "targeted_search_recorded", "not_yet_searched")
write.csv(roster, "data/research/official_roster.csv", row.names = FALSE)
s <- support[support$window == 12 & !support$censor_other_researched_episodes, ]
d <- merge(built$events, s, by = c("event_id", "key"), sort = FALSE)
d$politician <- roster$politician[match(d$key, roster$key)]
d <- d[order(d$politician, d$date_lower), ]
lines <- c(
  "# Source-backed scandal expansion",
  "",
  sprintf(
    "This targeted pass records %d milestones in %d episodes for %d officials; searches cover %d roster keys.",
    nrow(d), length(unique(d$episode_id)), length(unique(d$key)), length(unique(searches$key))
  ),
  "The roster includes unresolved identities and officials without comparable partisan outcomes.",
  "Unsearched officials are not certified scandal-free.",
  "Dates identify the specified milestone, not necessarily first exposure.",
  "",
  "The [manuscript](../ms/main.pdf) defines scandals following Hayes (2025) and explains inclusion rules.",
  "[Full event data](../data/derived/research_events.csv), [sources](../data/derived/research_sources.csv),",
  "[search log](../data/derived/research_search_log.csv), and",
  "[all support windows](../tabs/research_event_support.csv) retain uncertainties.",
  "",
  "Counts below omit the event month and use a 12-month window with comparable paired outcomes.",
  "They do not censor other episodes.",
  "They measure polling availability, not independent scandals or validated causal identification.",
  "The support file also censors at other researched episodes; the ledger is not a complete event chronology.",
  "",
  "| Official | Dated milestone | Event | Scope | Pre / post polls | Sources |",
  "| --- | --- | --- | --- | --- | --- |"
)
for (i in seq_len(nrow(d))) {
  src <- built$sources[built$sources$event_id == d$event_id[i], ]
  links <- paste(sprintf("[%s](%s)", src$publisher, src$url), collapse = "; ")
  date <- if (d$date_precision[i] == "day") d$reported_date[i] else paste(d$date_lower[i], "to", d$date_upper[i])
  lines <- c(lines, sprintf(
    "| %s | %s | %s | %s | %d / %d | %s |",
    d$politician[i], date, d$label[i], d$inclusion_scope[i], d$pre[i], d$post[i], links
  ))
}
lines <- c(
  lines, "", "Source-specific retrieval status and date qualifications are in the event and source files.",
  "Staff allegations, disputed conflicts, and later clearances must not be rewritten as findings of personal guilt."
)
writeLines(lines, "docs/scandal-inventory-expansion.md")
