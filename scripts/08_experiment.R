principled <- new.env()
sys.source("data/external/principled/data.R", envir = principled)
experiment <- principled$read_mturk("data/external/principled/mturk.csv")
for (side in c("dem", "rep")) {
  items <- sapply(c(1:5, 7:8), function(i) {
    value <- principled$coalesce_checked(
      experiment[[paste0(side, "_traits_", i)]],
      experiment[[paste0(side, "_traits_", i, ".1")]]
    )
    principled$trait_score(value, i %in% c(2, 3, 7))
  })
  experiment[[paste0(side, "_seven")]] <- principled$available_mean(items)
  experiment[[paste0(side, "_complete")]] <- rowSums(is.na(items)) == 0
}
experiment$in_seven <- ifelse(experiment$party == "Democrat", experiment$dem_seven, experiment$rep_seven)
experiment$out_seven <- ifelse(experiment$party == "Democrat", experiment$rep_seven, experiment$dem_seven)
experiment$raw_gap <- experiment$in_seven - experiment$out_seven
experiment$polarization <- 50 + experiment$raw_gap / 2
experiment <- experiment[experiment$assigned & experiment$party %in% c("Democrat", "Republican"), ]

experiment_contrast <- function(d, outcome, arms, strength = "All",
                                standardized = FALSE, moderation = FALSE, hc3 = FALSE) {
  shares <- prop.table(table(d$party))
  if (strength != "All") {
    d <- d[d$strong == (strength == "Strong"), ]
    shares <- prop.table(table(d$party))
  }
  if (!standardized) {
    d$party <- "Pooled"
    shares <- c(Pooled = 1)
  }
  groups <- if (moderation) c(FALSE, TRUE) else NA
  cells <- list()
  for (g in groups) {
    for (party in names(shares)) {
      for (arm in names(arms)) {
        take <- d$party == party & d$arm == arm
        if (!is.na(g)) take <- take & d$strong == g
        y <- d[[outcome]][take]
        y <- y[!is.na(y)]
        a <- unname(shares[party] * arms[arm])
        if (!is.na(g)) a <- a * ifelse(g, 1, -1)
        cells[[length(cells) + 1L]] <- data.frame(n = length(y), mean = mean(y), variance = var(y), a = a)
      }
    }
  }
  cells <- do.call(rbind, cells)
  stopifnot(all(cells$n > 1))
  v <- cells$a^2 * cells$variance / cells$n
  estimate <- sum(cells$a * cells$mean)
  se <- sqrt(sum(v))
  df <- sum(v)^2 / sum(v^2 / (cells$n - 1))
  if (hc3) {
    se <- sqrt(sum(cells$a^2 * cells$variance / (cells$n - 1)))
    df <- sum(cells$n) - nrow(cells)
  }
  data.frame(
    outcome, estimate, se, df,
    lower = estimate - qt(.975, df) * se,
    upper = estimate + qt(.975, df) * se, p = 2 * pt(-abs(estimate / se), df), n = sum(cells$n)
  )
}

experiment_hc3 <- function(fit) {
  x <- model.matrix(fit)
  bread <- solve(crossprod(x))
  meat <- crossprod(x * as.numeric(residuals(fit) / (1 - hatvalues(fit))))
  bread %*% meat %*% bread
}

results <- models <- list()
for (sample in c("All assigned", "Strict attention")) {
  d <- if (sample == "All assigned") experiment else experiment[experiment$attention, ]
  d$arm_factor <- factor(d$arm, levels = c("Control", "In decline", "In stable", "Out decline", "Out stable"))
  fit <- lm(polarization ~ arm_factor * strong, data = d)
  for (inference in c("Original OLS", "HC3")) {
    covariance <- if (inference == "Original OLS") vcov(fit) else experiment_hc3(fit)
    se <- sqrt(diag(covariance))
    estimate <- coef(fit)
    models[[length(models) + 1L]] <- data.frame(
      sample, inference,
      term = names(estimate), estimate, se,
      lower = estimate - qt(.975, df.residual(fit)) * se,
      upper = estimate + qt(.975, df.residual(fit)) * se,
      p = 2 * pt(-abs(estimate / se), df.residual(fit)), n = nrow(d)
    )
  }
  for (standardized in c(FALSE, TRUE)) {
    for (strength in c("All", "Strong", "Weak", "Strong minus weak")) {
      for (contrast in c("Nonresponse versus control", "Nonresponse versus response")) {
        arms <- if (contrast == "Nonresponse versus control") {
          c("Out stable" = 1, "Control" = -1)
        } else {
          c("Out stable" = 1, "Out decline" = -1)
        }
        for (outcome in c("polarization", "raw_gap", "in_seven", "out_seven", "out_ft")) {
          moderation <- strength == "Strong minus weak"
          for (hc3 in c(FALSE, TRUE)) {
            estimate <- experiment_contrast(
              d, outcome, arms, if (moderation) "All" else strength, standardized, moderation, hc3
            )
            results[[length(results) + 1L]] <- cbind(
              sample, strength, contrast, standardized,
              inference = if (hc3) "HC3 cell contrast" else "Welch cell contrast", estimate
            )
          }
        }
      }
    }
  }
}
results <- do.call(rbind, results)
models <- do.call(rbind, models)
write.csv(results, "tabs/experiment_bridge.csv", row.names = FALSE)
write.csv(models, "tabs/experiment_archived_model.csv", row.names = FALSE)

selected <- subset(
  results,
  sample == "Strict attention" & standardized & outcome == "polarization" &
    inference == "Welch cell contrast" &
    strength %in% c("Strong", "Strong minus weak")
)
labels <- c(
  "StrongControl", "StrongResponse", "ModerationControl", "ModerationResponse"
)
macros <- character()
for (i in seq_len(nrow(selected))) {
  for (field in c("estimate", "lower", "upper", "p")) {
    value <- selected[[field]][i]
    formatted <- if (field == "p") {
      if (value < .001) "<.001" else sub("^0", "", sprintf("%.3f", value))
    } else {
      sprintf("%.1f", value)
    }
    field_label <- paste0(toupper(substr(field, 1, 1)), substring(field, 2))
    macros <- c(macros, sprintf("\\newcommand{\\Exp%s%s}{%s}", labels[i], field_label, formatted))
  }
}
counts <- c(
  AssignedN = nrow(experiment), StrongN = sum(experiment$strong),
  AttentionN = sum(experiment$attention), AttentionStrongN = sum(experiment$attention & experiment$strong)
)
macros <- c(macros, sprintf("\\newcommand{\\Exp%s}{%d}", names(counts), counts))
archive_interaction <- subset(
  models,
  sample == "All assigned" & inference == "HC3" & term == "arm_factorOut stable:strongTRUE"
)
extra <- list(ArchivedInteraction = archive_interaction)
for (side in c("in_seven", "out_seven")) {
  label <- if (side == "in_seven") "DirectOwnTraits" else "DirectOpponentTraits"
  extra[[label]] <- subset(
    results,
    sample == "Strict attention" & standardized & strength == "Strong" &
      contrast == "Nonresponse versus response" & inference == "Welch cell contrast" & outcome == side
  )
}
for (label in names(extra)) {
  row <- extra[[label]]
  for (field in c("estimate", "lower", "upper", "p")) {
    value <- if (field == "p") sub("^0", "", sprintf("%.3f", row[[field]])) else sprintf("%.1f", row[[field]])
    field_label <- paste0(toupper(substr(field, 1, 1)), substring(field, 2))
    macros <- c(macros, sprintf("\\newcommand{\\Exp%s%s}{%s}", label, field_label, value))
  }
}
writeLines(macros, "tabs/experiment_macros.tex")
lines <- c(
  "\\begin{tabular}{llrr}", "\\toprule",
  "Group & Comparison & Estimate [95\\% CI] & $p$ \\\\", "\\midrule"
)
for (i in seq_len(nrow(selected))) {
  row <- selected[i, ]
  lines <- c(lines, sprintf(
    "%s & %s & %.1f [%.1f, %.1f] & %s \\\\",
    row$strength, sub("Nonresponse versus ", "Unchanged vs. ", row$contrast),
    row$estimate, row$lower, row$upper,
    if (row$p < .001) "$<.001$" else sub("^0", "", sprintf("%.3f", row$p))
  ))
}
writeLines(c(lines, "\\bottomrule", "\\end{tabular}"), "tabs/experiment_bridge.tex")
