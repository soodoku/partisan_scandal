source(file.path(root, "R/research.R"))

testthat::test_that("frozen external studies preserve source hashes", {
  with_project({
    manifest <- read.csv("data/external/scandal_studies/manifest.csv")
    hashes <- vapply(manifest$file, function(p) digest::digest(file = p, algo = "sha256"), character(1))
    testthat::expect_identical(unname(hashes), manifest$sha256)
  })
})

testthat::test_that("ANES branch recoding preserves missingness and longitudinal sample", {
  with_project({
    a <- read.csv("data/external/anes2008/palin.csv")
    testthat::expect_false(anyDuplicated(a$caseid) > 0)
    for (wave in c(9, 10)) {
      items <- if (wave == 9) c("w9e65", "w9e66", "w9e67") else c("w10e71", "w10e72", "w10e73")
      code <- rep(NA_integer_, nrow(a))
      code[a[[items[1]]] %in% 3] <- 3L
      like <- a[[items[1]]] %in% 1 & a[[items[2]]] %in% 1:3
      dislike <- a[[items[1]]] %in% 2 & a[[items[3]]] %in% 1:3
      code[like] <- c(6L, 5L, 4L)[a[[items[2]]][like]]
      code[dislike] <- c(0L, 1L, 2L)[a[[items[3]]][dislike]]
      testthat::expect_equal(a[[paste0("palin", wave)]], code * 100 / 6, tolerance = 1e-10)
    }
    testthat::expect_equal(sum(a$paired_ratings_dates), 2501L)
    take <- a$eligible_weighted_pair
    testthat::expect_equal(sum(take), 2065L)
    testthat::expect_true(all(a$w10date[take] != "2008-10-10" & a$w10date[take] < "2008-11-04"))
    testthat::expect_true(all(a$weight_longitudinal_9_10[take] > 0 & a$stratum[take] %in% 1:2))
    testthat::expect_true(all(a$pid9_code[take] %in% c(0:2, 4:6)))
  })
})

testthat::test_that("research joins reject duplicate milestones and unmatched people", {
  with_project({
    records <- read_research_jsonl("data/research/governor_events.jsonl")
    roster <- read.csv("data/research/official_roster.csv")
    testthat::expect_error(compile_research(c(records, records[1]), roster))
    changed <- records
    changed[[1]]$key <- "XX|G|unmatched"
    testthat::expect_error(compile_research(changed, roster))
    out <- compile_research(records, roster)
    month <- out$events[out$events$date_precision == "month", ]
    testthat::expect_equal(month$date_lower, "2005-05-01")
    testthat::expect_equal(month$date_upper, "2005-05-31")
    testthat::expect_setequal(out$events$event_id, out$sources$event_id)
  })
})

testthat::test_that("censoring distinguishes renewed milestones from other episodes", {
  events <- data.frame(
    event_id = c("first", "renewal", "other"), episode_id = c("a", "a", "b"), key = "A",
    date_lower = c("2020-06-12", "2020-08-01", "2020-10-01"),
    date_upper = c("2020-06-12", "2020-08-01", "2020-10-01"), inclusion_scope = "core"
  )
  panel <- data.frame(key = "A", month_id = 2020L * 12L + 1:12, eligible = TRUE)
  s <- research_support(events, panel, windows = 12)
  a <- s[s$event_id == "first", ]
  testthat::expect_equal(a$pre, c(5, 5))
  testthat::expect_equal(a$post, c(6, 3))
  events$inclusion_scope[3] <- "context"
  s <- research_support(events, panel, windows = 12)
  testthat::expect_equal(s$post[s$event_id == "first"], c(6, 6))
})

testthat::test_that("external reference joins conserve events and retain source disagreements", {
  with_project({
    p <- read.csv("data/derived/preuss_scandals_joined.csv", check.names = FALSE)
    testthat::expect_equal(nrow(p), 218L)
    testthat::expect_false(anyDuplicated(p$external_id) > 0)
    testthat::expect_false(anyNA(p[["Break date title"]]))
    testthat::expect_equal(sum(!p$major_date_agrees), 2L)
    testthat::expect_true(all(p$office[p$matched] == "S"))
    n <- read.csv("data/derived/nyhan_governor_year_joined.csv")
    testthat::expect_equal(nrow(n), 1729L)
    testthat::expect_equal(sum(n$aponset), 43)
    testthat::expect_equal(sum(n$apscandalcount), 436)
    testthat::expect_false(anyDuplicated(n[c("stateabbrev", "gov_name", "party", "year")]) > 0)
  })
})

testthat::test_that("independently reproduced Nyhan OLS headline coefficients agree", {
  with_project({
    x <- read.csv("tabs/nyhan_ols_replication.csv")
    a <- x[x$table == 1 & x$outcome == "aponset" & x$cluster == "statenum" & x$term == "lagpospct", ]
    b <- x[x$table == 2 & x$outcome == "aponset" & x$cluster == "statenum" & x$term == "disaster", ]
    testthat::expect_equal(a$n, 1684L)
    testthat::expect_equal(a$coefficient, -0.07454908756371327, tolerance = 1e-9)
    testthat::expect_equal(a$se, 0.049202662667389374, tolerance = 1e-9)
    testthat::expect_equal(b$n, 1442L)
    testthat::expect_equal(b$coefficient, -0.01998611443287018, tolerance = 1e-9)
    testthat::expect_equal(b$se, 0.008446615883747479, tolerance = 1e-9)
  })
})
