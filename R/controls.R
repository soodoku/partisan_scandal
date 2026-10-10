paired_control_sample <- function(main, panel) {
  use <- panel$coding_status == "clean" & panel$eligible & panel$office %in% c("G", "S")
  controls <- panel[which(use), ]
  pair <- merge(main, controls,
    by = c("statecode", "party_r", "month_id", "source_poll_key"),
    suffixes = c("_treated", "_control")
  )
  pair$id <- paste(pair$id_treated, pair$id_control, sep = ":")
  pair$post <- pair$post_treated
  pair$relative_month <- pair$relative_month_treated
  support <- tapply(pair$post, pair$id, function(x) sum(x == 0) >= 2 && sum(x == 1) >= 2)
  pair <- pair[pair$id %in% names(support)[support], ]
  for (outcome in c("inparty", "outparty", "gap")) {
    pair[[outcome]] <- pair[[paste0(outcome, "_treated")]] -
      pair[[paste0(outcome, "_control")]]
  }
  key <- paste(pair$id_treated, pair$month_id)
  pair$analysis_weight <- 1 / as.numeric(table(key)[key])
  pair
}
