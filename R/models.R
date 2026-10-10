fit_model <- function(data, outcome, trend = "common", cluster = "statecode") {
  rhs <- switch(trend,
    common = "post + relative_month + factor(id)",
    separate = "post * relative_month + factor(id)",
    individual = "post + factor(id) * relative_month",
    calendar = "post + factor(id) + factor(month_id)",
    none = "post + factor(id)"
  )
  if (!"analysis_weight" %in% names(data)) data$analysis_weight <- 1
  fit <- lm(as.formula(paste(outcome, "~", rhs)), data = data, weights = analysis_weight)
  stopifnot(!anyNA(coef(fit)))
  test <- clubSandwich::coef_test(fit,
    vcov = "CR2", cluster = data[[cluster]],
    coefs = "post", test = "Satterthwaite", inverse_var = FALSE
  )
  b <- unname(coef(fit)["post"])
  se <- test$SE
  df <- test$df_Satt
  data.frame(
    outcome = outcome, estimate = b, se = se, df = df,
    lower = b - qt(.975, df) * se, upper = b + qt(.975, df) * se,
    p = test$p_Satt, n = nrow(data), politicians = length(unique(data$id)),
    states = length(unique(data$statecode)), trend = trend, cluster = cluster
  )
}

legacy_models <- function(data) {
  do.call(rbind, lapply(c("inparty", "outparty", "gap"), function(outcome) {
    fit <- lm(as.formula(paste(outcome, "~ post + relative_day + factor(name)")),
      data = data
    )
    t <- summary(fit)$coefficients["post", ]
    data.frame(
      outcome = outcome, estimate = t[1], se = t[2],
      n = nobs(fit), p = t[4], row.names = NULL
    )
  }))
}
