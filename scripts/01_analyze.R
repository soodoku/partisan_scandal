source("R/data.R")
source("R/models.R")
source("R/approval_sources.R")
source("R/controls.R")
source("R/repeated_events.R")
for (path in c("data/derived", "tabs", "figs", "docs", "ms")) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
}
original <- read_inputs()
inputs <- original
inputs$approval <- enrich_approval(inputs$approval)
built <- build_panel(inputs)
panel <- built$panel
main <- analysis_sample(panel)
legacy <- legacy_sample(original)
write.csv(panel, "data/derived/panel.csv", row.names = FALSE)
write.csv(built$catalog, "data/derived/catalog.csv", row.names = FALSE)
write.csv(main, "data/derived/main.csv", row.names = FALSE)
write.csv(legacy_models(legacy), "tabs/legacy.csv", row.names = FALSE)

specs <- list(
  "Primary: 12 months" = list(window = 12),
  "Fieldwork-date classification" = list(window = 12, event_month = "fieldwork"),
  "Original coverage only" = list(window = 12),
  "6 months" = list(window = 6),
  "18 months" = list(window = 18),
  "No censoring at later scandals" = list(window = 12, censor = FALSE),
  "Event month assigned post" = list(window = 12, event_month = "post"),
  "Event month assigned pre" = list(window = 12, event_month = "pre"),
  "Separate pre/post slopes" = list(window = 12),
  "Politician-specific slopes" = list(window = 12),
  "Calendar-month fixed effects" = list(window = 12),
  "Politician clustering" = list(window = 12),
  "No time trend" = list(window = 12),
  "Equal politician weight" = list(window = 12),
  "One observation per side" = list(window = 12, min_side = 1)
)
results <- do.call(rbind, lapply(names(specs), function(label) {
  d <- do.call(analysis_sample, c(list(panel = panel), specs[[label]]))
  if (label == "Original coverage only") {
    d <- analysis_sample(panel[panel$record_provenance == "historical", ])
  }
  trend <- switch(label,
    "Separate pre/post slopes" = "separate",
    "Politician-specific slopes" = "individual",
    "Calendar-month fixed effects" = "calendar",
    "No time trend" = "none",
    "common"
  )
  if (label == "Equal politician weight") {
    d$analysis_weight <- 1 / as.numeric(table(d$id)[d$id])
  }
  cluster <- if (label == "Politician clustering") "id" else "statecode"
  out <- do.call(rbind, lapply(c("inparty", "outparty", "gap"), function(y) {
    fit_model(d, y, trend = trend, cluster = cluster)
  }))
  cbind(specification = label, out)
}))
write.csv(results, "tabs/models.csv", row.names = FALSE)

influence <- do.call(rbind, lapply(unique(main$id), function(id) {
  d <- main[main$id != id, ]
  out <- fit_model(d, "gap")
  cbind(omitted = main$politician[match(id, main$id)], out)
}))
write.csv(influence, "tabs/leave_one_out.csv", row.names = FALSE)

support <- do.call(rbind, lapply(split(main, main$id), function(d) {
  pre <- d[d$post == 0, ]
  post <- d[d$post == 1, ]
  data.frame(
    politician = d$politician[1], state = d$statecode[1], office = d$office[1],
    party = d$event_party[1], date = d$event_date[1], type = d$event_type[1],
    pre = nrow(pre), post = nrow(post),
    in_pre = mean(pre$inparty), in_post = mean(post$inparty),
    out_pre = mean(pre$outparty), out_post = mean(post$outparty),
    gap_change = mean(post$gap) - mean(pre$gap)
  )
}))
write.csv(support, "tabs/support.csv", row.names = FALSE)

# A within-preperiod break probes instability without claiming randomized timing.
placebo <- main[main$relative_month < 0, ]
placebo$post <- as.integer(placebo$relative_month >= -6)
p_support <- tapply(placebo$post, placebo$id, function(x) {
  sum(x == 0) >= 2 && sum(x == 1) >= 2
})
placebo <- placebo[placebo$id %in% names(p_support)[p_support], ]
placebo_results <- do.call(rbind, lapply(c("inparty", "outparty", "gap"), function(y) {
  fit_model(placebo, y)
}))
write.csv(placebo_results, "tabs/placebo.csv", row.names = FALSE)

# Group comparisons are exploratory and their small-cluster uncertainty is retained.
subgroups <- list(
  Republicans = main[main$event_party == "R", ],
  Democrats = main[main$event_party == "D", ],
  Governors = main[main$office == "G", ],
  Senators = main[main$office == "S", ],
  Corruption = main[main$event_type == "6", ],
  Other = main[main$event_type != "6", ]
)
subgroup_results <- do.call(rbind, lapply(names(subgroups), function(label) {
  out <- fit_model(subgroups[[label]], "gap")
  cbind(group = label, out)
}))
write.csv(subgroup_results, "tabs/subgroups.csv", row.names = FALSE)

# Missingness is recorded before complete-case selection, within the event window.
nearby <- panel$coding_status == "dated" &
  abs(panel$relative_month) <= 12 & panel$relative_month != 0
near <- panel[which(nearby), ]
missingness <- aggregate(!near$complete,
  by = list(office = near$office, post = near$post), FUN = mean
)
names(missingness)[3] <- "missing_fraction"
write.csv(missingness, "tabs/missingness.csv", row.names = FALSE)

raw_keys <- paste(
  inputs$approval$statecode, inputs$approval$type,
  inputs$approval$lastname, inputs$approval$year, inputs$approval$month
)
counts <- c(
  raw_rows = nrow(original$approval), expanded_rows = nrow(panel),
  restored_rows = nrow(panel) - nrow(original$approval),
  raw_poll_ids = length(unique(original$approval$pollid)),
  duplicated_politician_month = sum(duplicated(raw_keys)),
  presidential_rows = sum(panel$office == "P"),
  nonpresidential_rows = sum(panel$office != "P"),
  matched_dated_rows = sum(panel$coding_status == "dated"),
  main_rows = nrow(main), main_polls = length(unique(main$source_poll_key)),
  main_politicians = length(unique(main$id)), main_states = length(unique(main$statecode)),
  raw_catalog_rows = nrow(inputs$scandals),
  distinct_offices = nrow(built$catalog),
  dated_offices = sum(built$catalog$coding_status == "dated"),
  clean_offices = sum(built$catalog$coding_status == "clean"),
  unmatched_nonpresidential = sum(panel$office != "P" & panel$coding_status == "unmatched"),
  incomplete_rows = sum(panel$coding_status == "incomplete"),
  main_pre_in = mean(main$inparty[main$post == 0]),
  main_pre_out = mean(main$outparty[main$post == 0]),
  main_post_in = mean(main$inparty[main$post == 1]),
  main_post_out = mean(main$outparty[main$post == 1])
)
write.csv(data.frame(quantity = names(counts), value = counts),
  "tabs/counts.csv",
  row.names = FALSE
)
writeLines(capture.output(sessionInfo()), "docs/session-info.txt")
print(results[results$outcome == "gap", ])

paired <- paired_control_sample(main, panel)
paired_treated <- paired
for (y in c("inparty", "outparty", "gap")) paired_treated[[y]] <- paired[[paste0(y, "_treated")]]
repeated <- repeated_event_sample(inputs, panel)
additional <- list(
  "Matched controls, treated only" = paired_treated,
  "Matched controls, net change" = paired,
  "Repeated recorded events" = repeated
)
extra <- do.call(rbind, lapply(names(additional), function(label) {
  d <- additional[[label]]
  result <- do.call(rbind, lapply(c("inparty", "outparty", "gap"), function(y) fit_model(d, y)))
  result$units <- length(unique(d$id))
  result$politicians <- length(unique(if (label == "Repeated recorded events") d$politician_id else d$id_treated))
  cbind(specification = label, result)
}))
write.csv(extra, "tabs/extensions.csv", row.names = FALSE)
write.csv(paired, "data/derived/paired_controls.csv", row.names = FALSE)
write.csv(repeated, "data/derived/repeated_events.csv", row.names = FALSE)
write.csv(unique(paired[c("politician_treated", "politician_control", "statecode")]),
  "tabs/control_pairs.csv",
  row.names = FALSE
)
print(extra[extra$outcome == "gap", ])
