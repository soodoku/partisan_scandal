source("R/exhibits.R")
models <- read.csv("tabs/models.csv")
main <- models[models$specification == "Primary: 12 months", ]
labels <- c(
  inparty = "Co-partisan approval", outparty = "Opposing-partisan approval",
  gap = "Co-partisan minus opposing"
)
rows <- cbind(
  labels[main$outcome], fmt(main$estimate), fmt(main$se),
  paste0("[", fmt(main$lower), ", ", fmt(main$upper), "]"), fmt(main$df), fmt(main$p, 3)
)
write_table(c("Outcome", "Change", "SE", "95\\% CI", "df", "$p$"), rows, "tabs/main.tex")
gap <- models[models$outcome == "gap", ]
rows <- cbind(
  gap$specification, fmt(gap$estimate),
  paste0("[", fmt(gap$lower), ", ", fmt(gap$upper), "]"), gap$n, gap$politicians
)
write_table(c("Specification", "Gap change", "95\\% CI", "Rows", "Officials"), rows, "tabs/sensitivity.tex")
support <- read.csv("tabs/support.csv")
rows <- cbind(
  support$politician, support$state, support$office, support$party,
  support$date, support$pre, support$post, fmt(support$gap_change)
)
write_table(c("Official", "State", "Office", "Party", "Recorded date", "Pre", "Post", "$\\Delta$ gap"),
  rows, "tabs/support.tex",
  alignment = "lllllrrr"
)
subgroups <- read.csv("tabs/subgroups.csv")
rows <- cbind(
  subgroups$group, fmt(subgroups$estimate),
  paste0("[", fmt(subgroups$lower), ", ", fmt(subgroups$upper), "]"),
  subgroups$politicians, subgroups$states, fmt(subgroups$df)
)
write_table(c("Subgroup", "Gap change", "95\\% CI", "Officials", "States", "df"), rows, "tabs/subgroups.tex")
legacy <- read.csv("tabs/legacy.csv")
write_table(
  c("Outcome", "Change", "Conventional SE", "Rows"),
  cbind(labels[legacy$outcome], fmt(legacy$estimate, 3), fmt(legacy$se, 3), legacy$n),
  "tabs/legacy.tex"
)

macros <- new.env()
macros$lines <- character()
add_macro <- function(name, value) {
  macros$lines <- c(macros$lines, paste0("\\newcommand{\\", name, "}{", value, "}"))
}
counts <- read.csv("tabs/counts.csv")
for (i in seq_len(nrow(counts))) {
  words <- strsplit(counts$quantity[i], "_")[[1]]
  name <- paste0("Count", paste0(toupper(substring(words, 1, 1)), substring(words, 2), collapse = ""))
  add_macro(name, if (counts$value[i] == round(counts$value[i])) {
    format(counts$value[i], big.mark = ",", scientific = FALSE, trim = TRUE)
  } else {
    fmt(counts$value[i])
  })
}
for (i in seq_len(nrow(main))) {
  prefix <- c("In", "Out", "Gap")[i]
  add_macro(paste0(prefix, "Estimate"), fmt(main$estimate[i]))
  add_macro(paste0(prefix, "Lower"), fmt(main$lower[i]))
  add_macro(paste0(prefix, "Upper"), fmt(main$upper[i]))
  add_macro(paste0(prefix, "P"), fmt(main$p[i], 3))
  add_macro(paste0(prefix, "Df"), fmt(main$df[i]))
}
add_macro("InPenalty", fmt(-main$estimate[main$outcome == "inparty"]))
add_macro("OutPenalty", fmt(-main$estimate[main$outcome == "outparty"]))
add_macro("EqualEventChange", fmt(mean(support$gap_change)))
add_macro("EventMinChange", fmt(min(support$gap_change)))
add_macro("EventMaxChange", fmt(max(support$gap_change)))
loo <- read.csv("tabs/leave_one_out.csv")
add_macro("LooMin", fmt(min(loo$estimate)))
add_macro("LooMax", fmt(max(loo$estimate)))
no_trend <- gap[gap$specification == "No time trend", ]
add_macro("NoTrendEstimate", fmt(no_trend$estimate))
add_macro("NoTrendLower", fmt(no_trend$lower))
add_macro("NoTrendUpper", fmt(no_trend$upper))
p <- read.csv("tabs/placebo.csv")
p <- p[p$outcome == "gap", ]
add_macro("PlaceboEstimate", fmt(p$estimate))
add_macro("PlaceboLower", fmt(p$lower))
add_macro("PlaceboUpper", fmt(p$upper))
add_macro("PlaceboOfficials", p$politicians)
for (outcome in c("inparty", "outparty", "gap")) {
  row <- legacy[legacy$outcome == outcome, ]
  prefix <- c(inparty = "LegacyIn", outparty = "LegacyOut", gap = "LegacyGap")[outcome]
  add_macro(paste0(prefix, "Estimate"), fmt(row$estimate, 3))
}
add_macro("LegacyN", format(legacy$n[1], big.mark = ",", trim = TRUE))
raw <- read.csv("data/derived/main.csv")
add_macro("RestoredMain", sum(raw$record_provenance != "historical"))
bootstrap <- read.csv("tabs/bootstrap.csv")
add_macro("BootstrapP", fmt(bootstrap$p, 3))
add_macro("BootstrapDraws", format(bootstrap$draws, big.mark = ",", trim = TRUE))
dates <- read.csv("tabs/date_sensitivity.csv")
supported <- dates[dates$specification == "Supported exposure months" & dates$outcome == "gap", ]
add_macro("SupportedEstimate", fmt(supported$estimate))
add_macro("SupportedLower", fmt(supported$lower))
add_macro("SupportedUpper", fmt(supported$upper))
add_macro("SupportedOfficials", supported$politicians)


extension <- read.csv("tabs/extensions.csv")
get_gap <- function(label) extension[extension$specification == label & extension$outcome == "gap", ]
paired <- get_gap("Matched controls, net change")
treated <- get_gap("Matched controls, treated only")
repeated <- get_gap("Repeated recorded events")
corrected <- dates[dates$specification == "Bond/Kerry alternative dates" & dates$outcome == "gap", ]
interval <- function(x) paste0(fmt(x$estimate), " points [", fmt(x$lower), ", ", fmt(x$upper), "]")
for (prefix in c("Paired", "Treated", "Repeated", "Corrected")) {
  result <- get(tolower(prefix))
  for (field in c("estimate", "lower", "upper")) {
    add_macro(paste0(prefix, paste0(toupper(substring(field, 1, 1)), substring(field, 2))), fmt(result[[field]]))
  }
  for (field in intersect(c("politicians", "states", "units", "n"), names(result))) {
    add_macro(paste0(prefix, paste0(toupper(substring(field, 1, 1)), substring(field, 2))), result[[field]])
  }
}
add_macro("LargestMainPenalty", fmt(-main$lower[main$outcome == "inparty"]))
add_macro("LargestSupportedPenalty", fmt(-dates$lower[
  dates$specification == "Supported exposure months" & dates$outcome == "inparty"
]))
legacy_cr <- read.csv("tabs/legacy_clustered.csv")
add_macro("LegacyClusterInLower", fmt(legacy_cr$lower[legacy_cr$outcome == "inparty"]))
add_macro("LegacyClusterInUpper", fmt(legacy_cr$upper[legacy_cr$outcome == "inparty"]))
likelihood <- read.csv("tabs/likelihood_summary.csv")
for (i in seq_len(nrow(likelihood))) {
  prefix <- c("LikeIn", "LikeOut", "LikeGap")[i]
  add_macro(paste0(prefix, "Estimate"), fmt(likelihood$estimate[i]))
  add_macro(paste0(prefix, "Ratio"), fmt(likelihood$peak_to_zero_likelihood[i]))
  add_macro(paste0(prefix, "P"), fmt(likelihood$lr_p[i], 3))
}
interaction <- read.csv("tabs/interaction.csv")
add_macro("InteractionP", fmt(interaction$p_two_sided, 3))
add_macro("InteractionDirectionalP", fmt(interaction$p_directional, 3))
add_macro("InteractionDirectionalLower", fmt(interaction$lower_one_sided))
add_macro("BootstrapDirectionalP", fmt(bootstrap$p_directional, 3))
writeLines(macros$lines, "tabs/macros.tex")
bounds <- read.csv("tabs/effect_size_bounds.csv")
bounds <- bounds[bounds$outcome == "inparty", ]
rows <- do.call(rbind, lapply(unique(bounds$specification), function(label) {
  x <- bounds[bounds$specification == label, ]
  c(
    label, paste0("[", fmt(x$lower[1]), ", ", fmt(x$upper[1]), "]"),
    ifelse(x$below_interval, "Excluded", "Included")
  )
}))
write_table(c("Specification", "95\\% interval", "$-2$ points", "$-5$ points", "$-10$ points"),
  rows, "tabs/effect_sizes.tex",
  alignment = "llccc"
)
summary <- c(
  "# Computed results", "",
  "Generated by `scripts/02_exhibits.R`; intervals are 95% CR2/Satterthwaite intervals.", "",
  "| Outcome | Main estimate | Interval |", "|---|---:|---:|",
  vapply(seq_len(nrow(main)), function(i) {
    paste0(
      "| ", labels[main$outcome[i]], " | ",
      fmt(main$estimate[i]), " | [", fmt(main$lower[i]), ", ", fmt(main$upper[i]), "] |"
    )
  }, ""),
  "", paste0(
    "Main sample: ", nrow(raw), " observations, ", length(unique(raw$id)), " officials, ",
    length(unique(raw$statecode)), " states. Restored December observations in main: ",
    sum(raw$record_provenance != "historical"), "."
  ),
  paste0("No trend: ", interval(no_trend), ". Supported exposure months: ", interval(supported), "."),
  paste0("Paired-control net change: ", interval(paired), ". Same-sample treated-only: ", interval(treated), "."),
  paste0("Repeated events: ", interval(repeated), ". Wild-bootstrap p: ", fmt(bootstrap$p, 3), "."),
  paste0(
    "Predicted positive interaction: one-sided p = ", fmt(interaction$p_directional, 3),
    "; two-sided p = ", fmt(interaction$p_two_sided, 3),
    "; one-sided 95% lower bound = ", fmt(interaction$lower_one_sided), " points."
  ),
  paste0(
    "Gaussian CAR1 profile likelihood, positive-gap MLE versus zero: ",
    fmt(likelihood$peak_to_zero_likelihood[likelihood$outcome == "gap"]),
    ":1. This is a likelihood ratio, not posterior odds."
  ),
  "", "The data support conditional associations around cataloged events.",
  "They do not establish co-partisan immunity or a causal scandal effect.",
  "The separately reconstructed survey experiment is reported in `experiment_bridge.csv`."
)
writeLines(summary, "tabs/summary.md")

main$label <- factor(labels[main$outcome], levels = rev(labels))
p <- ggplot2::ggplot(main, ggplot2::aes(x = estimate, y = label)) +
  ggplot2::geom_vline(xintercept = 0, colour = "grey65", linewidth = .4) +
  ggplot2::geom_segment(ggplot2::aes(x = lower, xend = upper, yend = label), linewidth = .7) +
  ggplot2::geom_point(size = 2.5, colour = "#24485c") +
  ggplot2::labs(x = "Adjusted change in approval (percentage points)") +
  paper_theme()
ggplot2::ggsave("figs/approval_changes.pdf", p, width = 6.6, height = 2.6)

raw <- read.csv("data/derived/main.csv")
p <- ggplot2::ggplot(raw, ggplot2::aes(x = relative_month, y = gap, group = id)) +
  ggplot2::geom_vline(xintercept = 0, colour = "grey60", linetype = 2, linewidth = .3) +
  ggplot2::geom_line(linewidth = .35, colour = "#24485c") +
  ggplot2::geom_point(size = .7, colour = "#24485c") +
  ggplot2::facet_wrap(~politician, ncol = 3) +
  ggplot2::labs(x = "Months from the recorded scandal", y = "Approval gap (percentage points)") +
  paper_theme() +
  ggplot2::theme(
    axis.title.y = ggplot2::element_text(angle = 90, margin = ggplot2::margin(r = 12)),
    strip.text = ggplot2::element_text(size = 9)
  )
ggplot2::ggsave("figs/event_paths.pdf", p, width = 7, height = 8)

profile <- read.csv("tabs/likelihood_profiles.csv")
profile$label <- factor(labels[profile$outcome], levels = labels)
p <- ggplot2::ggplot(profile, ggplot2::aes(x = beta, y = relative_likelihood)) +
  ggplot2::geom_vline(xintercept = 0, colour = "grey60", linetype = 2, linewidth = .3) +
  ggplot2::geom_line(colour = "#24485c", linewidth = .65) +
  ggplot2::facet_wrap(~label, nrow = 1) +
  ggplot2::scale_x_continuous(breaks = seq(-15, 10, 5)) +
  ggplot2::labs(x = "Post-event change (percentage points)", y = "Relative profile likelihood") +
  paper_theme() +
  ggplot2::theme(
    axis.title.y = ggplot2::element_text(angle = 90, margin = ggplot2::margin(r = 12)),
    strip.text = ggplot2::element_text(size = 9)
  )
ggplot2::ggsave("figs/likelihood_profiles.pdf", p, width = 7, height = 2.8)
