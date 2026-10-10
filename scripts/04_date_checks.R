source("R/data.R")
source("R/models.R")
source("R/approval_sources.R")
inputs <- read_inputs()
inputs$approval <- enrich_approval(inputs$approval)
review <- read.csv("docs/event_date_review.csv")
stopifnot(all(inputs$scandals$name[review$source_row] == review$politician))
revised <- inputs
for (name in c("Kit Bond", "John Kerry")) {
  row <- review[review$politician == name, ]
  revised$scandals$date[row$source_row] <- as.Date(row$alternative_exact_date)
}
revised$scandals$month_id <- as.integer(format(revised$scandals$date, "%Y")) * 12L +
  as.integer(format(revised$scandals$date, "%m"))
panel <- build_panel(revised)$panel
full <- analysis_sample(panel)
supported <- full[full$politician %in% review$politician[review$retain_in_supported_month_sensitivity], ]
result <- do.call(rbind, lapply(c("Bond/Kerry alternative dates", "Supported exposure months"), function(label) {
  d <- if (label == "Supported exposure months") supported else full
  out <- do.call(rbind, lapply(c("inparty", "outparty", "gap"), function(y) fit_model(d, y)))
  cbind(specification = label, out)
}))
write.csv(result, "tabs/date_sensitivity.csv", row.names = FALSE)
write.csv(supported, "data/derived/supported_dates.csv", row.names = FALSE)
print(result)
