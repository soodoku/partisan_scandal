testthat::test_that("the public companion data reconstruct the archived experiment", {
  with_project({
    env <- new.env()
    sys.source("scripts/08_experiment.R", envir = env)
    d <- env$experiment
    testthat::expect_equal(nrow(d), 746L)
    testthat::expect_equal(sum(d$strong), 226L)
    testthat::expect_equal(sum(d$attention), 724L)
    testthat::expect_equal(sum(d$dem_complete & d$rep_complete), 745L)
    testthat::expect_equal(d$polarization, 50 + d$raw_gap / 2)
    testthat::expect_true(all(d$polarization >= 0 & d$polarization <= 100))
    model <- subset(env$models, sample == "All assigned" & inference == "Original OLS")
    archived <- c(.65, -.05, -.03, .00, -.02, .05, .10, .07, .04, .11)
    testthat::expect_equal(round(model$estimate / 100, 2), archived)
    testthat::expect_equal(model$estimate[10], 11.203128, tolerance = 1e-6)
    testthat::expect_equal(model$se[10], 3.381722, tolerance = 1e-6)
    selected <- subset(
      env$results,
      sample == "All assigned" & strength == "Strong" &
        contrast == "Nonresponse versus response" & !standardized & outcome == "polarization" &
        inference == "Welch cell contrast"
    )
    a <- d$polarization[d$strong & d$arm == "Out stable"]
    b <- d$polarization[d$strong & d$arm == "Out decline"]
    independent <- t.test(a, b)
    testthat::expect_equal(selected$estimate, mean(a) - mean(b))
    testthat::expect_equal(selected$lower, unname(independent$conf.int[1]))
    testthat::expect_equal(selected$p, independent$p.value)
    robust <- env$experiment_contrast(
      d[d$strong, ], "polarization", c("Out stable" = 1, "Out decline" = -1),
      hc3 = TRUE
    )
    testthat::expect_equal(robust$se^2, var(a) / (length(a) - 1) + var(b) / (length(b) - 1))
    strict <- d[d$attention, ]
    strong <- strict[strict$strong, ]
    party_mean <- party_var <- numeric(2)
    parties <- c("Democrat", "Republican")
    for (i in seq_along(parties)) {
      stable <- strong$polarization[strong$party == parties[i] & strong$arm == "Out stable"]
      decline <- strong$polarization[strong$party == parties[i] & strong$arm == "Out decline"]
      party_mean[i] <- mean(stable) - mean(decline)
      party_var[i] <- var(stable) / length(stable) + var(decline) / length(decline)
    }
    shares <- vapply(parties, function(p) mean(strong$party == p), numeric(1))
    standardized <- subset(
      env$results,
      sample == "Strict attention" & strength == "Strong" & standardized &
        outcome == "polarization" & contrast == "Nonresponse versus response" & inference == "Welch cell contrast"
    )
    testthat::expect_equal(standardized$estimate, sum(shares * party_mean))
    testthat::expect_equal(standardized$se^2, sum(shares^2 * party_var))
    for (i in seq_along(parties)) {
      stable <- strict$polarization[!strict$strong & strict$party == parties[i] & strict$arm == "Out stable"]
      decline <- strict$polarization[!strict$strong & strict$party == parties[i] & strict$arm == "Out decline"]
      party_mean[i] <- party_mean[i] - (mean(stable) - mean(decline))
      party_var[i] <- party_var[i] + var(stable) / length(stable) + var(decline) / length(decline)
    }
    shares <- vapply(parties, function(p) mean(strict$party == p), numeric(1))
    moderation <- subset(
      env$results,
      sample == "Strict attention" & strength == "Strong minus weak" & standardized &
        outcome == "polarization" & contrast == "Nonresponse versus response" & inference == "Welch cell contrast"
    )
    testthat::expect_equal(moderation$estimate, sum(shares * party_mean))
    testthat::expect_equal(moderation$se^2, sum(shares^2 * party_var))
    hc3 <- subset(env$models, sample == "All assigned" & inference == "HC3")
    baseline <- d$polarization[!d$strong & d$arm == "Control"]
    testthat::expect_equal(hc3$se[1], sqrt(var(baseline) / (length(baseline) - 1)))
    rows <- subset(
      env$results,
      sample == "All assigned" & !standardized & outcome == "polarization" &
        inference == "Welch cell contrast" &
        contrast == "Nonresponse versus response"
    )
    testthat::expect_equal(
      rows$estimate[rows$strength == "Strong minus weak"],
      rows$estimate[rows$strength == "Strong"] - rows$estimate[rows$strength == "Weak"]
    )
    testthat::expect_equal(
      rows$se[rows$strength == "Strong minus weak"]^2,
      sum(rows$se[rows$strength %in% c("Strong", "Weak")]^2)
    )
  })
})
