source("R/data.R")
original <- legacy_sample(read_inputs())
legacy_clustered <- do.call(rbind, lapply(c("inparty", "outparty", "gap"), function(outcome) {
  fit <- lm(as.formula(paste(outcome, "~ post + relative_day + factor(name)")), data = original)
  test <- clubSandwich::coef_test(fit, vcov = "CR2", cluster = original$statecode, coefs = "post")
  data.frame(
    outcome = outcome, estimate = test$beta, se = test$SE, df = test$df_Satt,
    lower = test$beta - qt(.975, test$df_Satt) * test$SE,
    upper = test$beta + qt(.975, test$df_Satt) * test$SE,
    n = nobs(fit)
  )
}))
write.csv(legacy_clustered, "tabs/legacy_clustered.csv", row.names = FALSE)
models <- read.csv("tabs/models.csv")
dates <- read.csv("tabs/date_sensitivity.csv")
chosen <- rbind(
  models[models$specification %in% c("Primary: 12 months", "No time trend"), ],
  dates[dates$specification == "Supported exposure months", ]
)
rows <- do.call(rbind, lapply(seq_len(nrow(chosen)), function(i) {
  x <- chosen[i, ]
  thresholds <- if (x$outcome == "gap") c(-5, 0, 5, 10) else c(-2, -5, -10)
  data.frame(
    specification = x$specification, outcome = x$outcome,
    threshold = thresholds, estimate = x$estimate, lower = x$lower, upper = x$upper,
    below_interval = thresholds < x$lower, above_interval = thresholds > x$upper,
    within_interval = thresholds >= x$lower & thresholds <= x$upper
  )
}))
write.csv(rows, "tabs/effect_size_bounds.csv", row.names = FALSE)
