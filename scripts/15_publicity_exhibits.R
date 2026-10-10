source("R/exhibits.R")
coverage <- read.csv("tabs/publicity_coverage_models.csv")
opinion <- read.csv("tabs/publicity_opinion_models.csv")
programs <- read.csv("data/derived/broadcast_programs.csv")
programs <- programs[substr(programs$date, 1, 4) == "2004", ]
programs$date <- as.Date(programs$date)
programs$period <- ifelse(programs$date < as.Date("2004-08-13"), "Before",
  ifelse(programs$date <= as.Date("2004-08-29"), "Olympics", "After")
)
periods <- do.call(rbind, lapply(split(programs, interaction(programs$network, programs$period)), function(z) {
  data.frame(
    network = z$network[1], period = z$period[1], n = nrow(z),
    swift_present = 100 * mean(z$swiftboat_allegation_present),
    swift_minutes = mean(z$swiftboat_allegation_minutes), olympic_minutes = mean(z$olympics_competing_news_minutes)
  )
}))
write.csv(periods, "tabs/publicity_broadcast_periods.csv", row.names = FALSE)
extract <- function(data, outcome, specification = "Linear trend", group = NULL, definition = NULL) {
  take <- data$outcome == outcome & data$specification == specification & data$lag == 7
  if (!is.null(group)) take <- take & data$group == group
  if (!is.null(definition)) take <- take & data$definition == definition
  row <- data[take, ]
  stopifnot(nrow(row) == 1)
  row
}
labels <- c(
  "Olympics segments (minutes)", "Swift Boat coverage (pp)",
  "Swift Boat segments (minutes)", "Kerry rating: Democrats", "Kerry rating: Republicans",
  "Kerry rating: Democrats minus Republicans"
)
outcomes <- c(
  "olympics_competing_news_minutes", "swiftboat_allegation_present", "swiftboat_allegation_minutes",
  rep("rating", 3)
)
groups <- c(rep(NA_character_, 3), "Democrat", "Republican", "Democrat minus Republican")
rows <- list()
for (i in seq_along(labels)) {
  data <- if (i <= 3) coverage else opinion
  group <- if (i <= 3) NULL else groups[i]
  definition <- if (i <= 3) NULL else "Strict party"
  a <- extract(data, outcomes[i], group = group, definition = definition)
  b <- extract(data, outcomes[i], "No trend", group, definition)
  rows[[i]] <- c(
    labels[i], sprintf("%s [%s, %s]", fmt(a$estimate), fmt(a$lower), fmt(a$upper)),
    sprintf("%s [%s, %s]", fmt(b$estimate), fmt(b$lower), fmt(b$upper)), a$n
  )
}
write_table(c("Outcome", "Linear trend", "No trend", "Days"), do.call(rbind, rows), "tabs/publicity_main.tex")

awareness <- read.csv("tabs/publicity_awareness.csv")
awareness <- awareness[order(awareness$network, -awareness$n), ]
write_table(
  c("Network", "Interview dates", "$N$", "Seen", "Heard only", "Aware (\\%)"),
  cbind(awareness$network, awareness$period, awareness$n, awareness$seen, awareness$heard_only, fmt(awareness$aware)),
  "tabs/publicity_awareness.tex", "llrrrr"
)
take <- opinion$definition == "All viewers" & opinion$lag == 7 &
  opinion$outcome %in% c("age", "female_pct", "edu", "college_pct", "democrat_pct", "nbc_share")
selection <- opinion[take, ]
selection$label <- c(
  age = "Mean age (years)", female_pct = "Women (percentage points)",
  edu = "Mean education category (1--9)", college_pct = "College degree (percentage points)",
  democrat_pct = "Identify as Democrats (percentage points)",
  nbc_share = "NBC share among ABC/CBS/NBC viewers"
)[selection$outcome]
write_table(
  c("Audience characteristic", "Specification", "Change", "95\\% interval"),
  cbind(
    selection$label, selection$specification, fmt(selection$estimate, 2),
    sprintf("[%s, %s]", fmt(selection$lower, 2), fmt(selection$upper, 2))
  ),
  "tabs/publicity_composition.tex", "llrr"
)

macros <- c(PublicityPrograms = nrow(programs), PublicitySegments = sum(programs$swiftboat_allegation_count))
for (network in c("ABC", "CBS", "NBC")) {
  z <- periods[periods$network == network & periods$period == "Olympics", ]
  macros[paste0("OlympicMinutes", network)] <- fmt(z$olympic_minutes)
  z <- awareness[awareness$network == network & awareness$period == "August 14--16", ]
  macros[paste0("Aware", network)] <- fmt(z$aware)
}
for (item in c("Presence", "Duration")) {
  a <- extract(coverage, if (item == "Presence") "swiftboat_allegation_present" else "swiftboat_allegation_minutes")
  for (field in c("estimate", "lower", "upper")) {
    macros[paste0("Publicity", item, tools::toTitleCase(field))] <- fmt(a[[field]], 2)
  }
}
data <- read.csv("data/derived/naes2004_publicity.csv")
macros["PublicityInterviews"] <- format(nrow(data), big.mark = ",", trim = TRUE)
macros["PublicityNetworkViewers"] <- format(sum(!is.na(data$network)), big.mark = ",", trim = TRUE)
take <- !is.na(data$network) & !is.na(data$rating) & data$pid3 %in% c("Democrat", "Republican")
macros["PublicityPartisanRatings"] <- format(sum(take), big.mark = ",", trim = TRUE)
writeLines(sprintf("\\newcommand{\\%s}{%s}", names(macros), macros), "tabs/publicity_macros.tex")

weekly <- programs
weekly$week <- as.integer(weekly$date - min(weekly$date)) %/% 7
weekly <- aggregate(
  cbind(swiftboat_allegation_minutes, olympics_competing_news_minutes) ~ network + week,
  weekly, mean
)
weekly$date <- as.Date("2004-07-22") + weekly$week * 7 + 3
plot_data <- rbind(
  data.frame(weekly[c("network", "date")], topic = "Olympics", minutes = weekly$olympics_competing_news_minutes),
  data.frame(weekly[c("network", "date")],
    topic = "Swift Boat allegations", minutes = weekly$swiftboat_allegation_minutes
  )
)
write.csv(plot_data, "data/derived/publicity_plot.csv", row.names = FALSE)
plot <- ggplot2::ggplot(plot_data, ggplot2::aes(date, minutes, color = network, linetype = network)) +
  ggplot2::annotate("rect",
    xmin = as.Date("2004-08-13"), xmax = as.Date("2004-08-29"),
    ymin = -Inf, ymax = Inf, alpha = .3, fill = "grey80"
  ) +
  ggplot2::geom_line(linewidth = .7) +
  ggplot2::geom_point(size = 2) +
  ggplot2::facet_wrap(~topic, ncol = 1, scales = "free_y") +
  ggplot2::scale_color_manual(values = c(ABC = "#0072B2", CBS = "#009E73", NBC = "#D55E00")) +
  ggplot2::scale_x_date(date_breaks = "2 weeks", date_labels = "%b %d") +
  ggplot2::scale_y_continuous(limits = c(0, NA), expand = ggplot2::expansion(mult = c(0, .08))) +
  ggplot2::labs(x = NULL, y = "Minutes per program", color = NULL, linetype = NULL) +
  paper_theme() +
  ggplot2::theme(legend.position = "bottom", axis.title.y = ggplot2::element_text(angle = 90))
ggplot2::ggsave("figs/publicity_coverage.pdf", plot, width = 6.5, height = 4.4)
