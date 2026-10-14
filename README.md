# Partisan Asymmetry in Responses to Scandal

A research draft and reproducible analysis of partisan approval around cataloged
political scandals. The [paper](ms/main.pdf) uses `know_hidden`'s manuscript layout
and presentation conventions. The editable source is [ms/main.tex](ms/main.tex).

The main estimates show modest average approval losses, larger among opposing
partisans. The predicted partisan difference is supported by a one-sided test;
two-sided intervals and the full specification family remain available. The
[computed summary](tabs/summary.md) gives current estimates and likelihood
comparisons. These observational results depend on event dates, trend assumptions,
and the officials with usable before-and-after polling.

The companion `partisan_principled` contains the same experiment described in
the archived manuscript. Its public data reproduce the original interaction
regression. The [experimental bridge](docs/experiment_bridge.md) reports direct
contrasts, attention and weighting sensitivities, and outcome-scale differences.
Strong partisans report more polarized trait evaluations after an out-party
nonresponse story than after the corresponding response story.

The [inventory audit](docs/inventory.md) traces the catalog's category mix and
polling attrition. A new publicity analysis combines 146 evening-news broadcasts
with 15,109 NAES interviews around the 2004 Olympics. NBC covered much more
Olympic news, but its viewers reported similar Swift Boat awareness to ABC/CBS
viewers; the comparative coverage models do not establish scandal displacement. The
[verified literature review](docs/literature.md) distinguishes existing evidence
on scandal penalties, partisan protection, news crowdout, and party evaluations;
the [bibliography](ms/references.bib) includes those sources.

The manuscript defines scandals following Hayes (2025), distinguishing specific
misconduct allegations, broader controversies, and organizational spillovers.
The [source-backed expansion](docs/scandal-inventory-expansion.md) links each
researched milestone to its sources and polling support. Its dates separate
initial reports from subsequent revelations and clearances. The
[timing recommendation](docs/scandal-dynamics.md) develops impulse, recovery,
and publicity measurements. Downloaded external inventories, reproduced governor models, and a frozen
ANES panel extract are retained in the replication materials. The manuscript
reports the approval analysis, the 2004 broadcast/NAES study, and the experiment.
The frozen ANES extract can be reimported with `Rscript scripts/import_anes_panel.R`
when the sibling `partisan_campaigns` source is available; ordinary builds use the frozen extract.

## Reproduce

With R and XeLaTeX/latexmk installed:

```sh
make restore
make check
```

`make check` rebuilds the analyses, tables, figures, numerical macros and PDF,
then runs lint and statistical/data tests. `make format` applies styler. R package
versions are frozen in `renv.lock`; `docs/session-info.txt` records the environment
used for the delivered results. No remote data retrieval occurs during the build.

The original broadcast responses and full-sample NAES media extract are frozen
in `data/external/publicity/`, with download URLs, codebook, and source hashes.
`Rscript scripts/fetch_publicity.R` refetches missing broadcast files and recreates
the media extract from the public Dataverse source (a 581 MB download). Supply
a local source `.dta` path as its argument to avoid downloading it again.
Scripts 13--15 rebuild program measures, audience comparisons, figures, and
manuscript tables. `data/research/publicity_analysis_plan.json` records choices
before new estimates were inspected; the analysis is explicitly exploratory.

## Inputs and outputs

- `data/raw/` contains the original approval series, scandal coding files, and
  scandal codebook. Its manifest records original filenames and SHA256 hashes.
- `data/external/` freezes source approval files recovered from
  `partisan_accountability`; there is no runtime dependency on that repository.
- `data/derived/` holds the joined panel, main sample, same-poll comparisons,
  repeated-event observations and supported-date subset.
- `R/` contains transformations, estimators and exhibit helpers.
- `scripts/` rebuilds analyses, date sensitivities, bootstrap inference,
  effect-size comparisons and exhibits.
- `tabs/` and `figs/` contain generated results; `ms/main.pdf` is the compiled draft.
- `docs/` contains the [audit](docs/audit.md), [design decisions](docs/design.md),
  [claim ledger](docs/claim_ledger.csv), [event-date review](docs/event_date_review.csv),
  and source/checksum manifests.

The frozen public experimental input and recoding helper are in
`data/external/principled/`, with source hashes. The 2018 YouGov experiment and
`partisan_accountability`'s CCES/candidate-choice analyses answer different
questions and are not pooled with the approval panel.

<!-- adjacent:start -->

<!-- adjacent:end -->
