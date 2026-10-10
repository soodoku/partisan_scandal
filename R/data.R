normalize_surname <- function(x) {
  x <- tolower(trimws(x))
  x <- sub(",? (jr\\.?|sr\\.?|ii|iii)$", "", x)
  x <- sub(".* ", "", x)
  x[x == "kulongowski"] <- "kulongoski"
  x
}

read_inputs <- function() {
  a <- read.csv("data/raw/approval/polldwcf.csv")
  s <- read.csv("data/raw/scandals/scandal_coding.csv")
  s[] <- lapply(s, trimws)
  s$source_row <- seq_len(nrow(s))
  s$date <- as.Date(s$date_scandal_broke, "%m/%d/%Y")
  s$month_id <- as.integer(format(s$date, "%Y")) * 12L +
    as.integer(format(s$date, "%m"))
  s$surname <- normalize_surname(s$name)
  s$key <- paste(s$state, s$office, s$surname, sep = "|")
  # John and Mark Warner held the same office; party separates their records.
  s$key[s$surname == "warner"] <- paste0(
    s$key[s$surname == "warner"], "|", s$party[s$surname == "warner"]
  )
  a$row_id <- seq_len(nrow(a))
  a$party_r <- ifelse(a$party %in% c("100", "Democrat"), "D",
    ifelse(a$party %in% c("200", "Republican"), "R", NA_character_)
  )
  a$office <- ifelse(a$type == "Governor", "G",
    ifelse(a$type == "Senator", "S", "P")
  )
  # The merged code 328 conflicts with Schweitzer's Democratic affiliation in the NGA record.
  schweitzer <- a$statecode == "MT" & a$office == "G" & a$lastname == "schweitzer"
  a$party_r[which(schweitzer)] <- "D"
  a$key <- paste(a$statecode, a$office, a$lastname, sep = "|")
  warner <- !is.na(a$lastname) & a$lastname == "warner"
  a$key[warner] <- paste0(a$key[warner], "|", a$party_r[warner])
  a$month_id <- a$year * 12L + match(a$month, month.name)
  stopifnot(all(a$month.n == match(a$month, month.name)))
  a$inparty <- ifelse(a$party_r == "R", a$rep.approve, a$dem.approve)
  a$outparty <- ifelse(a$party_r == "R", a$dem.approve, a$rep.approve)
  a$gap <- a$inparty - a$outparty
  list(approval = a, scandals = s)
}

build_panel <- function(inputs) {
  a <- inputs$approval
  s <- inputs$scandals
  catalog <- do.call(rbind, lapply(split(s, s$key), function(x) {
    dated <- x[!is.na(x$date), ]
    dated <- dated[order(dated$date, dated$source_row), ]
    first <- if (nrow(dated)) dated[1, ] else x[1, ]
    later <- sort(unique(dated$month_id[dated$month_id > first$month_id]))
    data.frame(
      key = first$key, politician = first$name, event_date = first$date,
      event_month = first$month_id, next_month = if (length(later)) later[1] else NA,
      event_party = first$party, event_type = first$scandal_type,
      source_row = first$source_row, events = length(unique(dated$date)),
      coding_status = if (nrow(dated)) {
        "dated"
      } else if (
        all(x$scandal_type == "clean.")
      ) {
        "clean"
      } else {
        "incomplete"
      }
    )
  }))
  stopifnot(!anyDuplicated(catalog$key))
  panel <- merge(a, catalog, by = "key", all.x = TRUE, sort = FALSE)
  panel <- panel[order(panel$row_id), ]
  stopifnot(nrow(panel) == nrow(a), identical(panel$row_id, a$row_id))
  panel$coding_status[is.na(panel$coding_status)] <- "unmatched"
  panel$relative_month <- panel$month_id - panel$event_month
  panel$post <- as.integer(panel$relative_month > 0)
  panel$id <- panel$key
  panel$complete <- complete.cases(panel[c("inparty", "outparty", "party_r")])
  panel$eligible <- panel$complete
  if ("comparable_party_definition" %in% names(panel)) {
    panel$eligible <- panel$eligible & panel$comparable_party_definition
  }
  list(panel = panel, catalog = catalog)
}

analysis_sample <- function(panel, window = 12, censor = TRUE,
                            event_month = "omit", min_side = 2) {
  take <- panel$office %in% c("G", "S") & panel$eligible &
    panel$coding_status == "dated" & !is.na(panel$relative_month) &
    abs(panel$relative_month) <= window & panel$party_r == panel$event_party
  if (censor) {
    take <- take & (is.na(panel$next_month) | panel$month_id < panel$next_month)
  }
  if (event_month == "omit") take <- take & panel$relative_month != 0
  if (event_month == "fieldwork") {
    disjoint <- panel$source_end_date < panel$event_date | panel$source_start_date > panel$event_date
    take <- take & !is.na(panel$source_end_date) & disjoint
  }
  d <- panel[which(take), ]
  d$post <- as.integer(d$relative_month >= if (event_month == "post") 0 else 1)
  if (event_month == "fieldwork") d$post <- as.integer(d$source_start_date > d$event_date)
  support <- tapply(d$post, d$id, function(x) {
    sum(x == 0) >= min_side && sum(x == 1) >= min_side
  })
  d <- d[d$id %in% names(support)[support], ]
  stopifnot(!anyDuplicated(d[c("id", "month_id")]))
  d
}

legacy_sample <- function(inputs) {
  a <- inputs$approval
  s <- inputs$scandals
  # These are deliberate reproductions of the archived second-token join.
  old_key <- paste(vapply(strsplit(tolower(s$name), " "), `[`, "", 2), s$state)
  idx <- match(paste(a$lastname, a$statecode), old_key)
  a$scandal_row <- idx
  a$event_date <- s$date[idx]
  a$time <- as.Date(sprintf("%04d-%02d-01", a$year, match(a$month, month.name)))
  a$event_time <- as.Date(format(a$event_date, "%Y-%m-01"))
  a$relative_day <- as.numeric(a$time - a$event_time) + 30
  a$post <- as.integer(a$relative_day > 0)
  a$name[a$name == "murkowski"] <- "frank murkowski"
  a <- a[which(!is.na(a$party_r) & !is.na(a$relative_day)), ]
  a
}
