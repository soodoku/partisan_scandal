options(timeout = 600)
base <- "data/external/publicity"
manifest <- read.csv(file.path(base, "vanderbilt/manifest.csv"))
for (i in seq_len(nrow(manifest))) {
  destination <- file.path(base, "vanderbilt/raw", manifest$file[i])
  if (!file.exists(destination)) {
    download.file(manifest$url[i], destination, mode = "wb", quiet = TRUE)
    Sys.sleep(.2)
  }
  stopifnot(identical(digest::digest(file = destination, algo = "sha256"), manifest$sha256[i]))
}
metadata <- jsonlite::read_json(file.path(base, "naes/naes2004_media_provenance.json"))
args <- commandArgs(trailingOnly = TRUE)
source_path <- if (length(args)) args[1] else tempfile(fileext = ".dta")
if (!file.exists(source_path)) download.file(metadata$source_url, source_path, mode = "wb")
stopifnot(identical(digest::digest(file = source_path, algo = "sha256"), metadata$source_sha256))
destination <- file.path(base, "naes/naes2004_media.csv")
fields <- names(metadata$definitions)
raw <- haven::read_dta(source_path, col_select = tidyselect::all_of(tolower(fields)))
raw <- raw[, tolower(fields)]
names(raw) <- fields
data <- as.data.frame(lapply(raw, as.numeric))
stopifnot(nrow(data) == metadata$rows, !anyDuplicated(data$cKEY))
temporary <- tempfile(fileext = ".csv")
write.csv(data, temporary, row.names = FALSE, na = "")
stopifnot(identical(digest::digest(file = temporary, algo = "sha256"), metadata$output_sha256))
file.copy(temporary, destination, overwrite = TRUE)
unlink(temporary)
if (!length(args)) unlink(source_path)
