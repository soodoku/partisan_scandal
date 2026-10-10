clean_codes <- function(x, valid, missing = numeric()) {
  stopifnot(is.numeric(x))
  if (any(!is.na(x) & !x %in% c(valid, missing))) {
    stop("Unexpected response code")
  }
  x[x %in% missing] <- NA_real_
  x
}

coalesce_checked <- function(a, b) {
  both <- !is.na(a) & !is.na(b)
  if (any(a[both] != b[both])) {
    stop("Conflicting outcome branches")
  }
  ifelse(is.na(a), b, a)
}

party7 <- function(x) {
  x <- clean_codes(x, 1:9, c(98, 99))
  out <- rep("Unaligned", length(x))
  out[x %in% 1:3] <- "Democrat"
  out[x %in% 5:7] <- "Republican"
  out[x %in% 4] <- "Independent"
  out[is.na(x)] <- NA_character_
  out
}

trait_score <- function(x, positive = TRUE) {
  x <- clean_codes(x, 1:5, c(8, 9))
  if (positive) {
    25 * (x - 1)
  } else {
    25 * (5 - x)
  }
}

available_mean <- function(x) {
  ans <- rowMeans(as.matrix(x), na.rm = TRUE)
  ans[is.nan(ans)] <- NA_real_
  ans
}

read_mturk <- function(path = "data/raw/mturk.csv") {
  d <- read.csv(path, na.strings = "")
  stopifnot(nrow(d) == 930L, !anyDuplicated(d$row_id))
  d$party <- NA_character_
  d$party[d$pid %in% 1] <- "Democrat"
  d$party[d$pid %in% 2] <- "Republican"
  d$party[d$pid %in% c(3, 4) & d$pid_i %in% 3] <- "Democrat"
  d$party[d$pid %in% c(3, 4) & d$pid_i %in% 1] <- "Republican"
  d$party[d$pid %in% c(3, 4) & d$pid_i %in% 2] <- "Independent"
  d$strong <- (d$pid %in% 1 & d$pid_d %in% 1) |
    (d$pid %in% 2 & d$pid_r %in% 1)
  a <- d[, paste0("attn_check_", 1:10)]
  stopifnot(all(is.na(as.matrix(a)) | as.matrix(a) == 1))
  d$attention_loose <- !is.na(a[[3]]) & !is.na(a[[5]])
  d$attention <- d$attention_loose & rowSums(!is.na(a[, -c(3, 5)])) == 0
  assignment <- d[, c("q48", "dt", "dc", "rt", "rc")]
  stopifnot(all(is.na(as.matrix(assignment)) | as.matrix(assignment) == 1))
  n_assigned <- rowSums(!is.na(assignment))
  if (any(n_assigned > 1)) {
    stop("Multiple assigned stories")
  }
  d$article <- NA_character_
  labels <- c(
    "Control", "Democrat stable", "Democrat decline", "Republican stable",
    "Republican decline"
  )
  for (i in seq_along(labels)) d$article[!is.na(assignment[[i]])] <- labels[i]
  d$assigned <- n_assigned == 1
  d$dem_ft <- clean_codes(coalesce_checked(d$ft_1, d$q53_1), 0:100)
  d$rep_ft <- clean_codes(coalesce_checked(d$ft_2, d$q53_2), 0:100)
  for (side in c("dem", "rep")) {
    items <- lapply(1:8, function(i) {
      x <- coalesce_checked(d[[paste0(side, "_traits_", i)]], d[[paste0(
        side,
        "_traits_", i, ".1"
      )]])
      trait_score(x, i %in% c(2, 3, 6, 7))
    })
    d[[paste0(side, "_traits")]] <- available_mean(as.data.frame(items))
  }
  d$arm <- ifelse(d$article == "Control", "Control", NA_character_)
  for (p in c("Democrat", "Republican")) {
    for (behavior in c("stable", "decline")) {
      sel <- d$article %in% paste(p, behavior) & d$party %in% c(
        "Democrat",
        "Republican"
      )
      d$arm[sel] <- paste(ifelse(d$party[sel] == p, "In", "Out"), behavior)
    }
  }
  d <- orient_party_outcomes(d)
  d$weight <- 1
  d$study <- "MTurk 2013"
  d
}

orient_party_outcomes <- function(d) {
  partisan <- d$party %in% c("Democrat", "Republican")
  for (outcome in c("ft", "traits")) {
    dem <- d[[paste0("dem_", outcome)]]
    rep <- d[[paste0("rep_", outcome)]]
    d[[paste0("in_", outcome)]] <- ifelse(d$party == "Democrat", dem, rep)
    d[[paste0("out_", outcome)]] <- ifelse(d$party == "Democrat", rep, dem)
    d[!partisan, c(paste0("in_", outcome), paste0("out_", outcome))] <- NA_real_
    d[[paste0("gap_", outcome)]] <- d[[paste0("in_", outcome)]] - d[[paste0(
      "out_",
      outcome
    )]]
  }
  d
}

read_yougov <- function(path = "data/raw/yougov.csv") {
  d <- read.csv(path, na.strings = "")
  stopifnot(nrow(d) == 1500L, !anyDuplicated(d$row_id), all(d$weight > 0))
  d$party <- party7(d$pid7pre)
  d$current_party <- party7(d$pid7)
  d$article_treat <- clean_codes(d$article_treat, 1:5, c(8, 9))
  d$arm <- c("Control", "Unbiased", "Biased", "Unbiased", "Biased")[d$article_treat]
  eligible <- list(Democrat = c(1, 3, 4), Republican = c(1, 2, 5), Independent = c(
    1,
    4, 5
  ), Unaligned = c(1, 4, 5))
  for (p in names(eligible)) {
    if (any(!d$article_treat[d$party == p] %in% eligible[[p]])) {
      stop("Ineligible article assignment")
    }
  }
  d$assigned <- !is.na(d$arm)
  d$relative_bias <- clean_codes(ifelse(
    d$article_treat %in% c(2, 3), d$dem_check, d$rep_check
  ), 1:4, c(8, 9))
  d$relative_bias[d$arm == "Control"] <- NA_real_
  d$dem_ft <- clean_codes(d$ftdems, 0:100, 998)
  d$rep_ft <- clean_codes(d$ftreps, 0:100, 998)
  traits <- c("ignorant", "sincere", "open_reason", "smug", "patriotic", "hypocritical")
  for (side in c("dem", "rep")) {
    prefix <- if (side == "rep") {
      "gop"
    } else {
      "dem"
    }
    items <- lapply(traits, function(t) {
      trait_score(d[[paste0(
        prefix, "_",
        t
      )]], t %in% c("sincere", "open_reason", "patriotic"))
    })
    items <- as.data.frame(items)
    names(items) <- traits
    d[[paste0(side, "_traits")]] <- available_mean(items)
    d[[paste0(side, "_nitems")]] <- rowSums(!is.na(items))
    d[[paste0(side, "_complete")]] <- ifelse(rowSums(!is.na(items)) == 6,
      rowMeans(items), NA_real_
    )
    d[[paste0(side, "_lower")]] <- rowSums(items, na.rm = TRUE) / 6
    completed_high <- rowSums(items, na.rm = TRUE) + 100 * rowSums(is.na(items))
    d[[paste0(side, "_upper")]] <- completed_high / 6
    for (t in traits) d[[paste0(side, "_score_", t)]] <- items[[t]]
  }
  d <- orient_party_outcomes(d)
  for (q in c("complete", "nitems", "lower", "upper", paste0("score_", traits))) {
    d[[paste0("out_", q)]] <- ifelse(d$party == "Democrat", d[[paste0(
      "rep_",
      q
    )]], d[[paste0("dem_", q)]])
    d[[paste0("in_", q)]] <- ifelse(d$party == "Democrat", d[[paste0(
      "dem_",
      q
    )]], d[[paste0("rep_", q)]])
  }
  d$target_traits <- ifelse(d$party == "Democrat", d$rep_traits, d$dem_traits)
  nonpartisan <- d$party %in% c("Independent", "Unaligned")
  d$target_traits[nonpartisan] <- d$rep_traits[nonpartisan]
  d$target_ft <- ifelse(d$party == "Democrat", d$rep_ft, d$dem_ft)
  d$target_ft[nonpartisan] <- d$rep_ft[nonpartisan]
  d$study <- "YouGov 2018"
  d
}
