testthat::test_that("inventory preserves coding rows and reconciles selection", {
  with_project({
    s <- read_inputs()$scandals
    other <- read.csv("data/raw/scandals/Political Scandals - 2005-2011 - Sheet1.csv")
    testthat::expect_equal(unname(as.matrix(s[seq_len(8)])), unname(as.matrix(data.frame(lapply(other, trimws)))))
    rows <- read.csv("data/derived/inventory_rows.csv")
    testthat::expect_identical(rows$source_row, seq_len(nrow(s)))
    testthat::expect_equal(rows$date, as.character(s$date))
    main <- read.csv("data/derived/main.csv")
    testthat::expect_setequal(rows$key[rows$main_event], main$id)
    types <- read.csv("tabs/inventory_types.csv")
    testthat::expect_equal(sum(types$main_events), length(unique(main$id)))
    coverage <- read.csv("tabs/inventory_coverage.csv")
    testthat::expect_setequal(coverage$key[coverage$reason == "Included"], main$id)
    testthat::expect_equal(coverage$reason == "Included", coverage$pre >= 2 & coverage$post >= 2)
  })
})

testthat::test_that("Olympics overlap counts inclusive forward days, not proximity", {
  with_project({
    events <- read.csv("tabs/olympic_event_overlap.csv")
    games <- read.csv("data/external/olympic_dates.csv")
    game_days <- do.call(c, lapply(seq_len(nrow(games)), function(j) {
      seq(as.Date(games$start[j]), as.Date(games$end[j]), by = "day")
    }))
    for (days in c(1, 7, 14)) {
      expected <- vapply(events$date, function(date) {
        sum((as.Date(date) + seq.int(0, days - 1)) %in% game_days)
      }, 0L)
      testthat::expect_equal(events[[paste0("olympic_days_", days)]], unname(expected))
    }
    testthat::expect_true(all(events$olympic_days_14[events$main_event] == 0))
    testthat::expect_setequal(
      events$name[events$olympic_days_1 > 0],
      c("Dean Heller", "David Paterson", "Jeff Merkley")
    )
  })
})
