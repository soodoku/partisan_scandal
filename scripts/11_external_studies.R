source("R/data.R")
source("R/research.R")
base <- "data/external/scandal_studies"
roster <- read.csv("data/research/official_roster.csv")
panel <- read.csv("data/derived/panel.csv")
book <- file.path(base, "preuss2024", "Scandals and deaths of politicians.xlsx")
scandals <- as.data.frame(readxl::read_excel(book, sheet = "Scandals"))
references <- as.data.frame(readxl::read_excel(book, sheet = "Scandal references"))
cycles <- as.data.frame(readxl::read_excel(book, sheet = "Senate cycles"))
scandals$external_id <- sprintf("preuss2024:%03d", seq_len(nrow(scandals)))
for (name in c("Break date", "Major news date")) {
  scandals[[name]] <- as.Date(scandals[[name]])
  references[[name]] <- as.Date(references[[name]])
}
scandals$name_key <- trimws(scandals$Name)
references$name_key <- trimws(references$Name)
names(references)[names(references) == "Name"] <- "reference_name"
names(references)[names(references) == "Major news date"] <- "reference_major_news_date"
join_key <- c("name_key", "Break date")
stopifnot(!anyDuplicated(references[join_key]), !anyDuplicated(scandals[join_key]))
preuss <- merge(scandals, references, by = join_key, all.x = TRUE, sort = FALSE)
stopifnot(nrow(preuss) == nrow(scandals), !anyNA(preuss[["Break date title"]]))
preuss$major_date_agrees <- preuss[["Major news date"]] == preuss$reference_major_news_date
state_map <- unique(cycles[c("Politician", "State")])
stopifnot(!anyDuplicated(state_map$Politician))
preuss$state <- state.abb[match(state_map$State[match(preuss$name_key, trimws(state_map$Politician))], state.name)]
preuss$office <- ifelse(preuss[["Political position"]] == "Senate", "S", "H")
preuss$key <- paste(preuss$state, preuss$office, normalize_surname(preuss$Name), sep = "|")
preuss$key[preuss$Name == "Mark Robert Warner"] <- "VA|S|warner|D"
preuss$matched <- preuss$key %in% roster$key
preuss$source_definition <- paste(
  "First English-language news article located in NexisUni;",
  "author-coded, not independently redated here"
)
preuss$definition_review <- ifelse(grepl("remarks", preuss$Headline, ignore.case = TRUE),
  "broad_only_remarks", "candidate_requires_core_review"
)
preuss <- preuss[order(preuss$external_id), ]
write.csv(preuss, "data/derived/preuss_scandals_joined.csv", row.names = FALSE)

nyhan <- as.data.frame(haven::read_dta(file.path(base, "nyhan2017", "gov-year-replication.dta")))
nyhan$key <- paste(nyhan$stateabbrev, "G", normalize_surname(nyhan$gov_name), sep = "|")
nyhan$key[nyhan$key == "VA|G|warner"] <- "VA|G|warner|R"
nyhan$matched <- nyhan$key %in% roster$key
nyhan$source_party_note <- ifelse(nyhan$key == "VA|G|warner|R",
  "Raw approval key miscoded R; source governor identity matched only; no paired outcomes", ""
)
nyhan$poll_year_overlap <- vapply(seq_len(nrow(nyhan)), function(i) {
  any(panel$key == nyhan$key[i] & panel$year == nyhan$year[i])
}, logical(1))
write.csv(nyhan, "data/derived/nyhan_governor_year_joined.csv", row.names = FALSE)
episodes <- read.csv(file.path(base, "nyhan2017", "nyhan_scandal_events.csv"))
episodes$external_id <- sprintf("nyhan2017:%02d", seq_len(nrow(episodes)))
episodes$key <- NA_character_
episodes$identity_status <- "no_unique_source_governor"
for (i in seq_len(nrow(episodes))) {
  year <- as.integer(substr(episodes$ap_scandal_label_date[i], 1, 4))
  candidates <- nyhan[nyhan$stateabbrev == episodes$state[i] & nyhan$year == year & nyhan$aponset == 1, ]
  if (nrow(candidates) > 1) {
    named <- vapply(normalize_surname(candidates$gov_name), function(n) {
      grepl(paste0("\\b", n, "\\b"), tolower(episodes$episode_description[i]))
    }, logical(1))
    if (sum(named) == 1) candidates <- candidates[named, ]
  }
  if (nrow(candidates) == 1) {
    episodes$key[i] <- candidates$key
    episodes$identity_status[i] <- "source_governor_year"
  }
}
episodes$matched <- episodes$key %in% roster$key
write.csv(episodes, "data/derived/nyhan_episodes_joined.csv", row.names = FALSE)

rakich <- read.csv(file.path(base, "rakich", "rakich_scandals.csv"), check.names = FALSE)
rakich$external_id <- sprintf("rakich:%03d", seq_len(nrow(rakich)))
rakich$state <- state.abb[match(rakich$State, state.name)]
rakich$office <- unname(c(Governor = "G", Senator = "S")[rakich$Position])
rakich$key <- paste(rakich$state, rakich$office, normalize_surname(rakich$Politician), sep = "|")
rakich$matched <- !is.na(rakich$office) & rakich$key %in% roster$key
rakich$source_definition <- "Discovery inventory; Year is not a validated disclosure date"
write.csv(rakich, "data/derived/rakich_scandals_joined.csv", row.names = FALSE)

external <- rbind(
  data.frame(
    event_id = preuss$external_id[preuss$matched], key = preuss$key[preuss$matched],
    date_lower = preuss[["Break date"]][preuss$matched], source = "preuss2024"
  ),
  data.frame(
    event_id = episodes$external_id[episodes$matched], key = episodes$key[episodes$matched],
    date_lower = as.Date(episodes$ap_scandal_label_date[episodes$matched]), source = "nyhan2017"
  )
)
external$date_upper <- external$date_lower
external$episode_id <- external$event_id
external$inclusion_scope <- "uncertain"
support <- research_support(external, panel)
support <- support[!support$censor_other_researched_episodes, ]
support$source <- external$source[match(support$event_id, external$event_id)]
write.csv(support, "tabs/external_event_support.csv", row.names = FALSE)

terms <- c("lagpospct", "divgov", "oppag", "commission", "electionyear", "years1", "years2", "loglag", "fullyear")
models <- list()
for (table in c("1", "2")) {
  slopes <- c(terms, if (table == "2") c("disaster", "indisaster"))
  for (outcome in c("aponset", "apscandalcount")) {
    columns <- c(outcome, slopes, "statenum", "govid2", "yeardummies")
    d <- nyhan[complete.cases(nyhan[columns]), ]
    fit <- lm(reformulate(c(slopes, "factor(statenum)", "factor(yeardummies)"), outcome), data = d)
    stopifnot(!anyNA(coef(fit)))
    for (cluster in c("statenum", "govid2")) {
      v <- clubSandwich::vcovCR(fit, cluster = d[[cluster]], type = "CR1S", inverse_var = FALSE)
      b <- coef(fit)[slopes]
      se <- sqrt(diag(v))[slopes]
      clusters <- length(unique(d[[cluster]]))
      models[[length(models) + 1L]] <- data.frame(
        table = table, outcome = outcome, cluster = cluster, n = nrow(d), clusters = clusters,
        term = slopes, coefficient = unname(b), se = unname(se),
        p = 2 * pt(-abs(b / se), clusters - 1), r2 = summary(fit)$r.squared
      )
    }
  }
}
write.csv(do.call(rbind, models), "tabs/nyhan_ols_replication.csv", row.names = FALSE)
counts <- data.frame(
  quantity = c(
    "preuss_events", "preuss_senate_events", "preuss_matched_events", "nyhan_rows", "nyhan_episodes",
    "nyhan_annual_onsets", "nyhan_articles", "nyhan_matched_episodes", "nyhan_poll_year_rows",
    "rakich_rows", "rakich_matched_rows"
  ),
  n = c(
    nrow(preuss), sum(preuss$office == "S"), sum(preuss$matched), nrow(nyhan), nrow(episodes),
    sum(nyhan$aponset), sum(nyhan$apscandalcount), sum(episodes$matched), sum(nyhan$poll_year_overlap),
    nrow(rakich), sum(rakich$matched)
  )
)
write.csv(counts, "tabs/external_inventory_counts.csv", row.names = FALSE)
