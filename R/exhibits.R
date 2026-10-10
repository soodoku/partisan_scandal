fmt <- function(x, digits = 1) formatC(x, format = "f", digits = digits)
tex_escape <- function(x) gsub("&", "\\&", x, fixed = TRUE)
write_table <- function(headers, rows, path, alignment = NULL) {
  if (is.null(alignment)) alignment <- paste0("l", paste(rep("r", length(headers) - 1), collapse = ""))
  lines <- c(
    paste0("\\begin{tabular}{", alignment, "}"), "\\toprule",
    paste0(paste(headers, collapse = " & "), " \\\\"), "\\midrule",
    apply(rows, 1, function(row) paste0(paste(tex_escape(row), collapse = " & "), " \\\\")),
    "\\bottomrule", "\\end{tabular}"
  )
  writeLines(lines, path)
}

paper_theme <- function() {
  ggplot2::theme_minimal(base_size = 11, base_family = "serif") +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_blank(),
      axis.title.y = ggplot2::element_blank(),
      plot.margin = ggplot2::margin(8, 12, 8, 8)
    )
}
