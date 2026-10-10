d <- read.csv("data/derived/main.csv")
long <- rbind(
  transform(d, copartisan = 0, approval = outparty),
  transform(d, copartisan = 1, approval = inparty)
)
interaction <- lm(approval ~ copartisan * (post + relative_month + factor(id)), data = long)
contrast <- clubSandwich::coef_test(interaction,
  vcov = "CR2", cluster = long$statecode, coefs = "copartisan:post"
)
write.csv(data.frame(
  estimate = contrast$beta, se = contrast$SE, df = contrast$df_Satt,
  p_two_sided = contrast$p_Satt,
  p_directional = pt(-contrast$beta / contrast$SE, df = contrast$df_Satt),
  lower_one_sided = contrast$beta - qt(.95, contrast$df_Satt) * contrast$SE,
  lower = contrast$beta - qt(.975, contrast$df_Satt) * contrast$SE,
  upper = contrast$beta + qt(.975, contrast$df_Satt) * contrast$SE,
  rows = nrow(long), paired_polls = nrow(d)
), "tabs/interaction.csv", row.names = FALSE)

d <- d[order(d$id, d$relative_month), ]
profiles <- list()
summaries <- list()
for (outcome in c("inparty", "outparty", "gap")) {
  d$y <- d[[outcome]]
  full <- nlme::gls(y ~ post + relative_month + factor(id),
    data = d,
    correlation = nlme::corCAR1(form = ~ relative_month | id), method = "ML"
  )
  peak <- as.numeric(logLik(full))
  grid <- sort(unique(c(seq(-18, 12, by = .25), coef(full)["post"])))
  rows <- lapply(grid, function(beta) {
    d$adjusted <- d$y - beta * d$post
    fit <- nlme::gls(adjusted ~ relative_month + factor(id),
      data = d,
      correlation = nlme::corCAR1(form = ~ relative_month | id), method = "ML"
    )
    value <- as.numeric(logLik(fit))
    stopifnot(value <= peak + 1e-6)
    data.frame(
      outcome = outcome, beta = beta, log_likelihood = value,
      relative_likelihood = exp(value - peak), lr = 2 * (peak - value)
    )
  })
  profile <- do.call(rbind, rows)
  zero <- profile[profile$beta == 0, ]
  profiles[[outcome]] <- profile
  summaries[[outcome]] <- data.frame(
    outcome = outcome, estimate = unname(coef(full)["post"]),
    rho = unname(coef(full$modelStruct$corStruct, unconstrained = FALSE)),
    sigma = full$sigma, log_likelihood = peak,
    lr_zero = zero$lr, lr_p = pchisq(zero$lr, df = 1, lower.tail = FALSE),
    peak_to_zero_likelihood = 1 / zero$relative_likelihood,
    n = nrow(d), officials = length(unique(d$id)), method = "Gaussian ML; within-official continuous AR1"
  )
}
write.csv(do.call(rbind, profiles), "tabs/likelihood_profiles.csv", row.names = FALSE)
write.csv(do.call(rbind, summaries), "tabs/likelihood_summary.csv", row.names = FALSE)
print(do.call(rbind, summaries))
