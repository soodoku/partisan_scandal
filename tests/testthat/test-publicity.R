source(file.path(root, "R/publicity.R"))

testthat::test_that("calendar HAC agrees with Newey-West and retains actual day gaps", {
  set.seed(8604)
  x <- seq_len(60)
  d <- data.frame(y = 2 + .4 * x + sin(x / 5) + rnorm(60), x = x, z = as.integer(x >= 30))
  dates <- as.Date("2004-01-01") + 0:59
  for (weights in list(rep(1, 60), seq(.4, 2, length.out = 60))) {
    fit <- lm(y ~ x + z, d, weights = weights)
    testthat::expect_equal(calendar_hac(fit, dates),
      sandwich::NeweyWest(fit, lag = 7, prewhite = FALSE, adjust = TRUE),
      tolerance = 1e-10
    )
  }
  take <- c(1:22, 27:60)
  fit <- lm(y ~ x + z, d[take, ])
  dates <- dates[take]
  x <- model.matrix(fit)
  scores <- x * residuals(fit)
  meat <- matrix(0, ncol(x), ncol(x))
  for (i in seq_len(nrow(x))) {
    for (j in seq_len(nrow(x))) {
      distance <- abs(as.numeric(dates[i] - dates[j]))
      if (distance <= 7) meat <- meat + (1 - distance / 8) * tcrossprod(scores[i, ], scores[j, ])
    }
  }
  bread <- solve(crossprod(x))
  manual <- bread %*% meat %*% bread * nrow(x) / (nrow(x) - ncol(x))
  testthat::expect_equal(unname(calendar_hac(fit, dates)), unname(manual), tolerance = 1e-10)
  compressed <- sandwich::NeweyWest(fit, lag = 7, prewhite = FALSE, adjust = TRUE)
  testthat::expect_gt(max(abs(calendar_hac(fit, dates) - compressed)), 1e-8)
})

testthat::test_that("broadcast joins conserve raw segments and distinguish absent programs", {
  with_project({
    raw <- read_broadcasts("data/external/publicity/vanderbilt")
    segments <- read.csv("data/derived/broadcast_segments.csv")
    programs <- read.csv("data/derived/broadcast_programs.csv")
    testthat::expect_equal(nrow(segments), 4027L)
    testthat::expect_setequal(segments$segment_id, raw$segments$segment_id)
    testthat::expect_equal(nrow(programs), nrow(raw$programs))
    testthat::expect_equal(sum(segments$swiftboat_allegation), 29L)
    testthat::expect_equal(sum(segments$troopergate), 6L)
    testthat::expect_equal(
      sum(programs$swiftboat_allegation_minutes),
      sum(segments$segment_duration[segments$swiftboat_allegation]) / 60
    )
    unnamed <- c("rg63NMXC06", "VwSNqxl3va", "qoAR3ClYnK")
    testthat::expect_true(all(segments$swiftboat_allegation[match(unnamed, segments$segment_id)]))
    testthat::expect_false(any(segments$swiftboat_literal[match(unnamed, segments$segment_id)]))
    gaps <- read.csv("data/derived/broadcast_network_gaps.csv")
    testthat::expect_equal(sum(gaps$complete), 41L)
    testthat::expect_true(anyNA(gaps$swiftboat_allegation_present))
  })
})

testthat::test_that("full NAES join preserves respondents, raw values, and awareness routing", {
  with_project({
    media <- read.csv("data/external/publicity/naes/naes2004_media.csv")
    original <- read.csv("data/external/publicity/naes/naes2004.csv")
    meta <- jsonlite::read_json("data/external/publicity/naes/naes2004_media_provenance.json")
    testthat::expect_identical(digest::digest(
      file = "data/external/publicity/naes/naes2004_media.csv",
      algo = "sha256"
    ), meta$output_sha256)
    m <- match(original$respondent_id, media$cKEY)
    testthat::expect_false(anyNA(m))
    testthat::expect_equal(nrow(media), nrow(original))
    testthat::expect_equal(original$cab01, media$cAB01[m])
    testthat::expect_equal(original$caa01, media$cAA01[m])
    testthat::expect_equal(as.character(original$cdatestr), as.character(media$cDATE[m]))
    testthat::expect_equal(sum(!is.na(media$cDA12)), 2209L)
    testthat::expect_equal(sum(media$cDA12 %in% 1:3), 2156L)
    testthat::expect_true(all(media$cEA01[media$cEA02 %in% 1:4] %in% 1:7))
    d <- read.csv("data/derived/naes2004_publicity.csv")
    testthat::expect_true(all(is.na(d$aware[!d$cDA12 %in% 1:3])))
    testthat::expect_true(all(is.na(d$rating[!d$cab01 %in% 0:10])))
    nbc <- d$network == "NBC" & d$date >= "2004-08-14" & d$date <= "2004-08-16" & !is.na(d$aware)
    nbc[is.na(nbc)] <- FALSE
    testthat::expect_equal(sum(nbc), 172L)
    testthat::expect_equal(mean(d$aware[nbc]), 100 * 115 / 172)
    fits <- read.csv("tabs/publicity_opinion_models.csv")
    take <- fits$outcome == "rating" & fits$definition == "Strict party" &
      fits$specification == "Linear trend" & fits$lag == 7
    fits <- fits[take, ]
    b <- setNames(fits$estimate, fits$group)
    testthat::expect_equal(unname(b["Democrat minus Republican"]), unname(b["Democrat"] - b["Republican"]))
  })
})
