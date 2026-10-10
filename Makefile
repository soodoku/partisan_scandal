.PHONY: restore analysis manuscript paper format lint test check clean

export R_LIBS_USER := $(CURDIR)/.Rlib

restore:
	Rscript --vanilla -e 'dir.create(".Rlib", showWarnings = FALSE); .libPaths(c(normalizePath(".Rlib"), .libPaths())); if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv", lib = ".Rlib", repos = "https://cloud.r-project.org"); renv::restore(library = ".Rlib", prompt = FALSE)'

analysis:
	Rscript --vanilla scripts/01_analyze.R
	Rscript --vanilla scripts/04_date_checks.R
	Rscript --vanilla scripts/03_bootstrap.R
	Rscript --vanilla scripts/05_effect_sizes.R
	Rscript --vanilla scripts/06_likelihood.R
	Rscript --vanilla scripts/07_inventory.R
	Rscript --vanilla scripts/08_experiment.R
	Rscript --vanilla scripts/09_timing_support.R
	Rscript --vanilla scripts/10_research_inventory.R
	Rscript --vanilla scripts/11_external_studies.R
	Rscript --vanilla scripts/12_extension_exhibits.R
	Rscript --vanilla scripts/13_publicity.R
	Rscript --vanilla scripts/14_publicity_opinions.R
	Rscript --vanilla scripts/15_publicity_exhibits.R
	Rscript --vanilla scripts/02_exhibits.R

manuscript:
	cd ms && latexmk -xelatex -interaction=nonstopmode -halt-on-error main.tex

paper: analysis manuscript

format:
	Rscript --vanilla -e 'styler::cache_deactivate(); for (p in c("R", "scripts", "tests")) styler::style_dir(p)'

lint:
	Rscript --vanilla -e 'l <- unlist(lapply(c("R", "scripts", "tests"), lintr::lint_dir), recursive = FALSE); print(l); quit(status = as.integer(length(l) > 0))'

test:
	Rscript --vanilla -e 'testthat::test_dir("tests/testthat", stop_on_failure = TRUE)'

check: paper lint test

clean:
	cd ms && latexmk -c main.tex
