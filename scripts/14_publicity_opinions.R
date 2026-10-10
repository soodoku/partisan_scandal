source("R/publicity.R")
meta <- jsonlite::read_json("data/external/publicity/naes/naes2004_media_provenance.json")
path <- "data/external/publicity/naes/naes2004_media.csv"
stopifnot(identical(digest::digest(file = path, algo = "sha256"), meta$output_sha256))
media <- read.csv(path)
d <- read.csv("data/external/publicity/naes/naes2004.csv")
m <- match(d$respondent_id, media$cKEY)
stopifnot(!anyDuplicated(media$cKEY), !anyNA(m), nrow(media) == nrow(d))
stopifnot(all(d$cdatestr == media$cDATE[m]))
stopifnot(isTRUE(all.equal(d$cab01, media$cAB01[m])))
stopifnot(isTRUE(all.equal(d$caa01, media$cAA01[m])))
d <- cbind(d, media[m, setdiff(names(media), "cKEY")])
d$date <- d$interview_date
d <- d[d$date >= "2004-07-22" & d$date <= "2004-09-12", ]
d$network <- c("ABC", "CBS", "NBC")[match(d$cEA02, 1:3)]
d$rating <- ifelse(d$cab01 %in% 0:10, 10 * d$cab01, NA_real_)
d$aware <- ifelse(d$cDA12 %in% 1:3, 100 * (d$cDA12 %in% 1:2), NA_real_)
d$medals <- ifelse(d$cDA08 %in% 1:2, 100 * (d$cDA08 == 1), NA_real_)
d$medals_dk <- ifelse(d$cDA08 %in% c(1, 2, 998), 100 * (d$cDA08 == 998), NA_real_)
d$college_pct <- ifelse(d$edu %in% 1:9, 100 * (d$edu >= 7), NA_real_)
d$female_pct <- 100 * (d$female == "female")
d$democrat_pct <- ifelse(is.na(d$pid3), NA_real_, 100 * (d$pid3 == "Democrat"))
d$party_leaners <- ifelse(d$pid7 %in% 1:3, "Republican",
  ifelse(d$pid7 %in% 5:7, "Democrat", NA_character_)
)
write.csv(d, "data/derived/naes2004_publicity.csv", row.names = FALSE)

gaps <- list()
cells <- list()
for (definition in c("Strict party", "Including leaners", "All viewers")) {
  party <- switch(definition,
    "Strict party" = d$pid3,
    "Including leaners" = d$party_leaners,
    "All viewers" = rep("All", nrow(d))
  )
  for (group in if (definition == "All viewers") "All" else c("Democrat", "Republican")) {
    take <- !is.na(party) & party == group & !is.na(d$network)
    z <- d[take, ]
    outcomes <- if (definition == "All viewers") {
      c("rating", "aware", "medals", "medals_dk", "age", "female_pct", "edu", "college_pct", "democrat_pct")
    } else {
      c("rating", "medals", "age", "female_pct", "college_pct")
    }
    for (outcome in outcomes) {
      z1 <- z[!is.na(z[[outcome]]), ]
      means <- do.call(rbind, lapply(split(z1, interaction(z1$date, z1$network, drop = TRUE)), function(a) {
        data.frame(date = a$date[1], network = a$network[1], n = nrow(a), mean = mean(a[[outcome]]))
      }))
      means$outcome <- outcome
      means$definition <- definition
      means$group <- group
      cells[[length(cells) + 1L]] <- means
      wide <- reshape(means[c("date", "network", "mean")], idvar = "date", timevar = "network", direction = "wide")
      wide <- wide[complete.cases(wide), ]
      out <- data.frame(
        date = wide$date, gap = wide$mean.NBC - (wide$mean.ABC + wide$mean.CBS) / 2,
        outcome = outcome, definition = definition, group = group
      )
      gaps[[length(gaps) + 1L]] <- out
    }
  }
}
gaps <- do.call(rbind, gaps)
cells <- do.call(rbind, cells)
for (definition in c("Strict party", "Including leaners")) {
  for (outcome in c("rating", "medals")) {
    z <- gaps[gaps$definition == definition & gaps$outcome == outcome, ]
    wide <- reshape(z[c("date", "group", "gap")], idvar = "date", timevar = "group", direction = "wide")
    wide <- wide[complete.cases(wide), ]
    gaps <- rbind(gaps, data.frame(
      date = wide$date, gap = wide$gap.Democrat - wide$gap.Republican,
      outcome = outcome, definition = definition, group = "Democrat minus Republican"
    ))
  }
}
audience <- d[!is.na(d$network), ]
share <- aggregate(100 * (audience$network == "NBC"), list(date = audience$date), mean)
names(share)[2] <- "gap"
share$outcome <- "nbc_share"
share$definition <- "All viewers"
share$group <- "All"
gaps <- rbind(gaps, share)
gaps$olympics <- as.integer(gaps$date >= "2004-08-13" & gaps$date <= "2004-08-29")
gaps$after <- as.integer(gaps$date > "2004-08-29")
gaps$day <- as.numeric(as.Date(gaps$date) - as.Date("2004-08-13"))
write.csv(gaps, "data/derived/naes2004_network_gaps.csv", row.names = FALSE)
write.csv(cells, "data/derived/naes2004_network_cells.csv", row.names = FALSE)

models <- list()
for (z in split(gaps, interaction(gaps$outcome, gaps$definition, gaps$group, drop = TRUE))) {
  if (z$outcome[1] == "aware") next
  for (specification in c("Linear trend", "No trend")) {
    z <- z[order(z$date), ]
    fit <- lm(reformulate(c("olympics", "after", if (specification == "Linear trend") "day"), "gap"), data = z)
    for (lag in c(3L, 7L, 10L)) {
      out <- publicity_contrast(
        fit, calendar_hac(fit, z$date, lag), c(olympics = 1),
        nrow(z) - length(coef(fit))
      )
      out$outcome <- z$outcome[1]
      out$definition <- z$definition[1]
      out$group <- z$group[1]
      out$specification <- specification
      out$lag <- lag
      models[[length(models) + 1L]] <- out
    }
  }
}
models <- do.call(rbind, models)
write.csv(models, "tabs/publicity_opinion_models.csv", row.names = FALSE)
take <- models$outcome == "rating" & models$definition == "Strict party" &
  models$specification == "Linear trend" & models$lag == 7
print(models[take, ])

aware <- d[!is.na(d$aware) & !is.na(d$network) & d$date != "2004-08-13", ]
aware$period <- ifelse(aware$date < "2004-08-13", "August 9--12", "August 14--16")
counts <- do.call(rbind, lapply(split(aware, interaction(aware$period, aware$network, drop = TRUE)), function(z) {
  data.frame(
    network = z$network[1], period = z$period[1], n = nrow(z),
    seen = sum(z$cDA12 == 1), heard_only = sum(z$cDA12 == 2), neither = sum(z$cDA12 == 3),
    aware = mean(z$aware)
  )
}))
write.csv(counts, "tabs/publicity_awareness.csv", row.names = FALSE)
awareness <- gaps[gaps$outcome == "aware" & gaps$date != "2004-08-13", ]
awareness$period <- ifelse(awareness$date < "2004-08-13", "August 9--12", "August 14--16")
write.csv(aggregate(gap ~ period, awareness, mean), "tabs/publicity_awareness_gaps.csv", row.names = FALSE)
print(counts)
