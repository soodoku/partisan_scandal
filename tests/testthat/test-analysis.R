testthat::test_that("original analytical inputs retain their source bytes", {
  with_project({
    manifest <- read.csv("data/raw/manifest.csv")
    hashes <- vapply(manifest$file, function(path) digest::digest(file = path, algo = "sha256"), character(1))
    testthat::expect_identical(unname(hashes), manifest$sha256)
  })
})

testthat::test_that("original join is reproduced and corrected keys separate offices", {
  with_project({
    inputs <- read_inputs()
    old <- legacy_models(legacy_sample(inputs))
    testthat::expect_equal(old$n, rep(1476, 3))
    testthat::expect_equal(old$estimate, c(.6235113, -3.1396926, 3.7632039), tolerance = 1e-6)
    b <- build_panel(inputs)
    testthat::expect_equal(nrow(b$panel), nrow(inputs$approval))
    testthat::expect_equal(b$panel$row_id, inputs$approval$row_id)
    m <- b$panel[b$panel$statecode == "AK" & b$panel$lastname %in% "murkowski", ]
    testthat::expect_true(all(m$politician[m$office == "S"] == "Lisa Murkowski"))
    testthat::expect_true(all(m$politician[m$office == "G"] == "Frank Murkowski"))
    testthat::expect_equal(normalize_surname("Robert L. Ehrlich, Jr."), "ehrlich")
    testthat::expect_equal(normalize_surname("Jon Huntsman, Jr."), "huntsman")
  })
})

testthat::test_that("event selection is chronological and invariant to source ordering", {
  with_project({
    i <- read_inputs()
    b <- build_panel(i)
    set.seed(99)
    i$scandals <- i$scandals[sample(nrow(i$scandals)), ]
    shuffled <- build_panel(i)
    testthat::expect_equal(b$panel, shuffled$panel)
    c <- b$catalog
    testthat::expect_equal(c$event_date[c$key == "AK|G|palin"], as.Date("2008-07-28"))
    testthat::expect_equal(c$event_date[c$key == "TN|S|frist"], as.Date("2005-09-23"))
    testthat::expect_true(all(is.na(b$panel$post[b$panel$coding_status != "dated"])))
    d <- analysis_sample(b$panel)
    testthat::expect_true(all(d$relative_month != 0))
    testthat::expect_true(all(is.na(d$next_month) | d$month_id < d$next_month))
    testthat::expect_true(all(tapply(d$post, d$id, function(x) sum(x == 0) >= 2 && sum(x == 1) >= 2)))
    testthat::expect_false(anyDuplicated(d[c("id", "month_id")]) > 0)
    testthat::expect_equal(d$gap, d$inparty - d$outparty)
    testthat::expect_true(all(d$inparty >= 0 & d$inparty <= 100))
    testthat::expect_true(all(d$outparty >= 0 & d$outparty <= 100))
  })
})

testthat::test_that("OLS contrast agrees with residualization and paired outcomes", {
  with_project({
    d <- read.csv("data/derived/main.csv")
    y <- resid(lm(gap ~ relative_month + factor(id), d))
    x <- resid(lm(post ~ relative_month + factor(id), d))
    direct <- sum(x * y) / sum(x^2)
    fitted <- fit_model(d, "gap")
    testthat::expect_equal(direct, fitted$estimate, tolerance = 1e-10)
    in_fit <- fit_model(d, "inparty")
    out_fit <- fit_model(d, "outparty")
    testthat::expect_equal(in_fit$estimate - out_fit$estimate, fitted$estimate, tolerance = 1e-10)
    testthat::expect_equal(fitted$lower, fitted$estimate - qt(.975, fitted$df) * fitted$se)
    testthat::expect_equal(fitted$p, 2 * pt(-abs(fitted$estimate / fitted$se), fitted$df))
  })
})

testthat::test_that("CR2 covariance matches an independent matrix calculation", {
  with_project({
    d <- read.csv("data/derived/main.csv")
    fit <- lm(gap ~ post + relative_month + factor(id), d)
    x <- model.matrix(fit)
    bread <- solve(crossprod(x))
    meat <- matrix(0, ncol(x), ncol(x))
    for (g in unique(d$statecode)) {
      keep <- which(d$statecode == g)
      xx <- x[keep, , drop = FALSE]
      eig <- eigen(diag(length(keep)) - xx %*% bread %*% t(xx), symmetric = TRUE)
      scale <- ifelse(eig$values > 1e-8, 1 / sqrt(pmax(eig$values, 1e-8)), 0)
      adjustment <- eig$vectors %*% diag(scale) %*% t(eig$vectors)
      score <- crossprod(xx, adjustment %*% residuals(fit)[keep])
      meat <- meat + tcrossprod(score)
    }
    manual <- bread %*% meat %*% bread
    package <- clubSandwich::vcovCR(fit, cluster = d$statecode, type = "CR2")
    testthat::expect_equal(unname(manual), unname(as.matrix(package)),
      ignore_attr = TRUE, tolerance = 1e-7
    )
  })
})

testthat::test_that("planted effects recover the known paired contrast", {
  with_project({
    d <- read.csv("data/derived/main.csv")
    baseline <- as.numeric(factor(d$id))
    d$inparty <- 60 + baseline - 2 * d$post + .2 * d$relative_month
    d$outparty <- 30 + baseline - 5 * d$post - .1 * d$relative_month
    d$gap <- d$inparty - d$outparty
    for (outcome in c("inparty", "outparty", "gap")) {
      fit <- lm(as.formula(paste(outcome, "~ post + relative_month + factor(id)")), d)
      truth <- c(inparty = -2, outparty = -5, gap = 3)[outcome]
      testthat::expect_equal(unname(coef(fit)["post"]), unname(truth), tolerance = 1e-10)
    }
  })
})

testthat::test_that("fieldwork timing and matched controls respect source evidence", {
  with_project({
    source("R/approval_sources.R", local = TRUE)
    i <- read_inputs()
    i$approval <- enrich_approval(i$approval)
    panel <- build_panel(i)$panel
    d <- analysis_sample(panel, event_month = "fieldwork")
    testthat::expect_true(all(d$source_end_date[d$post == 0] < d$event_date[d$post == 0]))
    testthat::expect_true(all(d$source_start_date[d$post == 1] > d$event_date[d$post == 1]))
    testthat::expect_false(anyNA(d$source_end_date))
    pair <- read.csv("data/derived/paired_controls.csv")
    testthat::expect_equal(pair$source_start_date_treated, pair$source_start_date_control)
    testthat::expect_equal(pair$source_end_date_treated, pair$source_end_date_control)
    testthat::expect_true(all(pair$coding_status_control == "clean"))
    totals <- tapply(pair$analysis_weight, paste(pair$id_treated, pair$month_id), sum)
    testthat::expect_equal(as.numeric(totals), rep(1, length(totals)))
    testthat::expect_equal(pair$gap, pair$gap_treated - pair$gap_control)
  })
})

testthat::test_that("event-date evidence and all retained exposures are traceable", {
  with_project({
    i <- read_inputs()
    review <- read.csv("docs/event_date_review.csv")
    testthat::expect_equal(i$scandals$name[review$source_row], review$politician)
    main <- read.csv("data/derived/main.csv")
    testthat::expect_setequal(unique(main$politician), review$politician)
    supported <- read.csv("data/derived/supported_dates.csv")
    testthat::expect_setequal(
      unique(supported$politician),
      review$politician[review$retain_in_supported_month_sensitivity]
    )
    testthat::expect_equal(unique(supported$event_date[supported$politician == "Kit Bond"]), "2008-09-29")
    testthat::expect_equal(unique(supported$event_date[supported$politician == "John Kerry"]), "2006-10-31")
    testthat::expect_true(all(supported$comparable_party_definition))
    bounds <- read.csv("tabs/effect_size_bounds.csv")
    primary <- bounds[bounds$specification == "Primary: 12 months" & bounds$outcome == "inparty", ]
    testthat::expect_true(primary$below_interval[primary$threshold == -10])
    testthat::expect_true(primary$within_interval[primary$threshold == -5])
  })
})

testthat::test_that("explicit interaction reproduces the paired contrast and inference", {
  with_project({
    interaction <- read.csv("tabs/interaction.csv")
    models <- read.csv("tabs/models.csv")
    gap <- models[models$specification == "Primary: 12 months" & models$outcome == "gap", ]
    testthat::expect_equal(interaction$estimate, gap$estimate, tolerance = 1e-9)
    testthat::expect_equal(interaction$se, gap$se, tolerance = 1e-9)
    testthat::expect_equal(interaction$df, gap$df, tolerance = 1e-9)
    testthat::expect_equal(interaction$p_two_sided, gap$p, tolerance = 1e-9)
    testthat::expect_equal(interaction$p_directional,
      pt(-gap$estimate / gap$se, df = gap$df),
      tolerance = 1e-9
    )
    testthat::expect_equal(interaction$lower_one_sided,
      gap$estimate - qt(.95, gap$df) * gap$se,
      tolerance = 1e-9
    )
  })
})

testthat::test_that("Gaussian likelihood agrees with independent covariance algebra", {
  with_project({
    d <- read.csv("data/derived/main.csv")
    d <- d[order(d$id, d$relative_month), ]
    fit <- nlme::gls(gap ~ post + relative_month + factor(id),
      data = d,
      correlation = nlme::corCAR1(form = ~ relative_month | id), method = "ML"
    )
    rho <- as.numeric(coef(fit$modelStruct$corStruct, unconstrained = FALSE))
    value <- -nrow(d) / 2 * log(2 * pi) - nrow(d) * log(fit$sigma)
    residual <- as.numeric(residuals(fit))
    for (id in unique(d$id)) {
      ix <- which(d$id == id)
      correlation <- rho^abs(outer(d$relative_month[ix], d$relative_month[ix], "-"))
      logdet <- as.numeric(determinant(correlation, logarithm = TRUE)$modulus)
      quadratic <- drop(crossprod(residual[ix], solve(correlation, residual[ix])))
      value <- value - .5 * logdet - quadratic / (2 * fit$sigma^2)
    }
    testthat::expect_equal(value, as.numeric(logLik(fit)), tolerance = 1e-7)
    profile <- read.csv("tabs/likelihood_profiles.csv")
    testthat::expect_true(all(profile$relative_likelihood <= 1 + 1e-8))
    testthat::expect_true(all(profile$relative_likelihood > 0))
    summary <- read.csv("tabs/likelihood_summary.csv")
    testthat::expect_equal(summary$peak_to_zero_likelihood, exp(summary$lr_zero / 2))
  })
})
