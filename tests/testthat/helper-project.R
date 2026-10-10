root <- normalizePath("../..")
source(file.path(root, "R/data.R"))
source(file.path(root, "R/models.R"))
with_project <- function(expr) {
  previous <- setwd(root)
  on.exit(setwd(previous))
  force(expr)
}
