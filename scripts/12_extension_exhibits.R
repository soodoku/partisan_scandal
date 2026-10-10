source("R/exhibits.R")
events <- read.csv("data/derived/research_events.csv")
searches <- read.csv("data/derived/research_search_log.csv")
external <- read.csv("tabs/external_inventory_counts.csv")
anes <- read.csv("data/external/anes2008/palin.csv")
metadata <- jsonlite::read_json("data/external/anes2008/palin_provenance.json")
stopifnot(identical(
  digest::digest(file = "data/external/anes2008/palin.csv", algo = "sha256"), metadata$export_sha256
))
macros <- c(
  ResearchMilestones = nrow(events), ResearchEpisodes = length(unique(events$episode_id)),
  ResearchOfficials = length(unique(events$key)), ResearchSearched = length(unique(searches$key)),
  ResearchCoreMilestones = sum(events$inclusion_scope == "core"),
  AnesPaired = sum(anes$paired_ratings_dates), AnesWeighted = sum(anes$eligible_weighted_pair),
  AnesSameDay = sum(anes$paired_ratings_dates & anes$followup_phase == "October 10")
)
external_names <- c(
  preuss_events = "PreussEvents", preuss_matched_events = "PreussMatched",
  nyhan_episodes = "NyhanEpisodes", nyhan_matched_episodes = "NyhanMatched",
  nyhan_annual_onsets = "NyhanOnsets", nyhan_articles = "NyhanArticles",
  rakich_rows = "RakichRows", rakich_matched_rows = "RakichMatched"
)
for (name in names(external_names)) {
  macros[external_names[name]] <- external$n[external$quantity == name]
}
writeLines(
  sprintf("\\newcommand{\\%s}{%s}", names(macros), format(macros, trim = TRUE)),
  "tabs/extension_macros.tex"
)
replication <- read.csv("tabs/nyhan_ols_replication.csv")
approval <- replication$table == 1 & replication$term == "lagpospct"
congestion <- replication$table == 2 & replication$term == "disaster"
take <- replication$cluster == "statenum" & (approval | congestion)
replication <- replication[take, ]
rows <- cbind(
  paste("Table", replication$table),
  ifelse(replication$outcome == "aponset", "Scandal onset", "Article count"),
  ifelse(replication$term == "lagpospct", "Lagged approval", "Neighboring-state disasters"),
  fmt(replication$coefficient, 3), fmt(replication$se, 3), replication$n
)
write_table(c("Original table", "Outcome", "Regressor", "Estimate", "SE", "$N$"),
  rows, "tabs/nyhan_replication.tex",
  alignment = "lllrrr"
)
counts <- read.csv("data/external/anes2008/palin_counts.csv")
take <- counts$sample == "Eligible weighted" & counts$party %in% c("Democrat", "Republican") &
  counts$phase %in% c("Before October 10", "After October 10")
counts <- counts[take, ]
write_table(c("September party", "October interview", "Respondents"),
  as.matrix(counts[c("party", "phase", "n")]), "tabs/anes_support.tex",
  alignment = "llr"
)
