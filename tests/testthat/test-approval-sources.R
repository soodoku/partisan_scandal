source(file.path(root, "R/approval_sources.R"))

testthat::test_that("Schweitzer affiliation is corrected without recoding independent senators", {
  with_project({
    a <- read_inputs()$approval
    s <- a[which(a$statecode == "MT" & a$office == "G" & a$lastname == "schweitzer"), ]
    testthat::expect_equal(nrow(s), 18L)
    testthat::expect_true(all(s$party == 328))
    testthat::expect_true(all(s$party_r == "D"))
    testthat::expect_equal(sum(complete.cases(s[c("inparty", "outparty")])), 16L)
    testthat::expect_equal(s$inparty, s$dem.approve)
    j <- a[which(a$office == "S" & a$lastname == "jeffords"), ]
    testthat::expect_true(all(is.na(j$party_r)))
  })
})

testthat::test_that("source enrichment preserves all historical observations and restores December", {
  with_project({
    original <- read_inputs()$approval
    enriched <- enrich_approval(original)
    testthat::expect_identical(enriched[seq_len(nrow(original)), names(original)], original)
    restored <- enriched[enriched$record_provenance != "historical", ]
    testthat::expect_equal(nrow(restored), 44L)
    testthat::expect_equal(sum(restored$office == "S"), 28L)
    testthat::expect_equal(sum(restored$office == "G"), 16L)
    testthat::expect_false(anyDuplicated(enriched$row_id) > 0)
    testthat::expect_true(all(restored$month_id == 2006L * 12L + 12L))
    testthat::expect_false(anyNA(restored[c("key", "party_r", "inparty", "outparty")]))
    testthat::expect_true(all(is.na(restored$cfscore)))
    testthat::expect_true(all(is.na(restored$dwnom1)))
    testthat::expect_equal(restored$gap, restored$inparty - restored$outparty)
  })
})

testthat::test_that("source dates and party definitions retain their uncertainty", {
  with_project({
    data <- enrich_approval(read_inputs()$approval)
    california <- data[data$source_poll_id %in% "17884", ]
    testthat::expect_equal(nrow(california), 4L)
    testthat::expect_true(all(!california$comparable_party_definition))
    testthat::expect_equal(sum(!data$comparable_party_definition), 4L)
    missing_end <- data[data$source_poll_id %in% "15265", ]
    testthat::expect_equal(nrow(missing_end), 4L)
    testthat::expect_true(all(is.na(missing_end$source_end_date)))
    testthat::expect_true(all(missing_end$source_start_date == as.Date("2009-04-13")))
    monthly <- data[data$source_date_precision == "month", ]
    testthat::expect_true(all(format(monthly$source_start_date, "%d") == "01"))
    testthat::expect_true(all(format(monthly$source_end_date + 1, "%d") == "01"))
    testthat::expect_true(all(is.na(monthly$source_sample_n)))
    duplicate <- data[data$source_poll_id %in% "12242" & data$office == "P", ]
    testthat::expect_equal(nrow(duplicate), 2L)
    testthat::expect_true(all(duplicate$source_duplicate))
  })
})

testthat::test_that("source reconciliation fails on corrupt outcomes or unmatched identities", {
  with_project({
    original <- read_inputs()$approval
    changed <- original
    changed$rep.approve[1] <- changed$rep.approve[1] + 1L
    testthat::expect_error(enrich_approval(changed), "differs from source")
    changed <- original
    changed$name[1] <- "unknown official"
    testthat::expect_error(enrich_approval(changed), "lacks source match")
  })
})
