# Numerical and source provenance

`data/raw/manifest.csv` identifies the original approval and scandal inputs,
their source filenames, and SHA256 hashes. These files were copied without
modification from the supplied ZIP. Historical drafts, notes, slides, collected
papers, unused source datasets, and duplicate downloads were removed at the
user's request. The analysis has no dependency on that historical folder.
`docs/approval_source_manifest.csv` identifies and hashes supplemental approval
inputs. Pipeline outputs use no live downloads.

All computed manuscript numbers enter through generated `tabs/*macros.tex` files or generated
LaTeX table bodies. Their CSV sources are emitted by the same build. The claim
ledger maps prose and exhibits to those sources and estimands.

The mechanical LaTeX provenance scan reports no scoped near-miss. It cannot
resolve a unique table source where a same-stem CSV and TeX both exist; those
are generated together, rather than competing manual versions. Its apparent
orphan numerals are deliberate literals:

- 17884 is the original SurveyUSA identifier for the incomparable-party poll.
- Numerals inside DOJ URLs identify archived source documents, not estimates.
- Font size, margins, spacing and figure dimensions are typesetting constants.
- Calendar years are source-period, historical-event, citation or draft dates.
- Confidence levels, window lengths, minimum support, the zero null, and
  two/five/ten-point comparison thresholds specify the method, not computed results.

The stated daily event dates in the source-review table are documented evidence
judgments. They remain separate from the original coding file. The analysis
changes only the explicitly recorded Bond/Kerry alternatives in that sensitivity;
ambiguous month-only bounds are not silently imputed as exact disclosure dates.

The original scholarly references were checked against publisher or author records:
Stoker (Springer), Puglisi and Snyder (Journal of Politics/author record),
Pustejovsky and Tipton (author record), and Eggers (author-hosted paper and DOI).
The software APIs were checked against official documentation for
[clubSandwich](https://jepusto.github.io/clubSandwich/reference/coef_test.html),
[CR2 for lm](https://jepusto.github.io/clubSandwich/reference/vcovCR.lm.html), and
[fwildclusterboot](https://s3alfisc.github.io/fwildclusterboot/reference/boottest.lm.html).

Gaussian likelihood APIs were checked against the official R documentation for
[`gls`](https://stat.ethz.ch/R-manual/R-devel/library/nlme/html/gls.html) and
[`corCAR1`](https://stat.ethz.ch/R-manual/R-devel/library/nlme/html/corCAR1.html).

The expanded references and their relevance are recorded in [literature.md](literature.md). Publisher issue years are used rather than online-first years. Olympic dates cite national Olympic committee records. The experimental public export and recoder are frozen and hashed in `data/external/principled/manifest.csv`; the bibliography labels the companion note as unpublished.

The experimental polarization transformation deliberately uses the constants 50, 100, and 2; its trait-gap endpoints are scale definitions rather than computed findings. These account for the additional mechanical numeral flags.


The source-backed extension uses three linked files: `research_events.csv` has
one row per milestone (`event_id`) and connects related milestones through
`episode_id`; `research_sources.csv` has one or more supporting URLs per milestone;
`official_roster.csv` supplies unique person/office keys. `date_lower` and
`date_upper` preserve uncertainty, while `reported_date` is a storage anchor for
month-only records. `inclusion_scope` distinguishes core misconduct, broad-only
controversies, context, and uncertain eligibility. `subject_scope` distinguishes
individual, staff, and administration allegations. Source retrieval status records
whether the source was read, available only in excerpts, or located by citation.
Search coverage is in `research_search_log.csv`. These files describe research
coverage, not a complete set of scandal-free officials or validated initial dates.

`data/external/scandal_studies/manifest.csv` preserves download URLs, source
licenses where supplied, and SHA256 hashes. External joins conserve source rows
and flag matches without treating an identity match as a usable event. The
Preuss reference join uses trimmed name and first-report date; two conflicting
major-news dates remain visible. Nyhan's state numbering is internal, not FIPS.
The source appendix supplies the AP dates; the annual file alone cannot. The
Rakich Year field remains undated discovery evidence. The scandal definition is in the manuscript; external-study replication
outputs remain in the replication materials.

Schweitzer's derived party is corrected to Democrat, consistent with the
[National Governors Association](https://www.nga.org/governor/brian-schweitzer/).
The merged source's raw party code 328 is retained. This correction is confined
to Montana's governor and does not coerce Jeffords's independent affiliation.
It restores 16 paired observations to the eligible roster but does not change
the main event cohort or its estimates.

The ANES extract and its variable mappings, missing-value rules, original source
hash, export hash, survey-documentation URLs, and eligibility counts are frozen
in `data/external/anes2008/`. `scripts/import_anes_panel.R` rebuilds the extract
from the sibling source; ordinary builds do not require that sibling. The
feasibility numbers and tables are generated by `scripts/12_extension_exhibits.R`;
they are no longer presented as findings in the public manuscript.
Nyhan's published article-count total of 435 is a cited source value, rather
than a computed claim; the supplied data's total is generated separately.


## Broadcast and audience evidence

`data/external/publicity/vanderbilt/manifest.csv` identifies every public API
response and SHA256. The 96 calendar responses select 256 ABC/CBS/NBC evening
programs across separate 2004 and 2008 windows, yielding 4,027 segments. Only the
146 programs in 2004 enter the current manuscript. All segment/topic decisions
are retained in `data/research/broadcast_topic_codes.csv`; candidate review
records retain supporting abstract text and explicit exclusions. Segment minutes
include other topics discussed in the same segment.

NAES2004 media fields come from Macdonald's public Dataverse source file 10917573
(DOI 10.7910/DVN/LQ1TDN). All 81,422 IDs, dates, Bush ratings and Kerry ratings match
the historical extract exactly. All 39 recovered fields also match Darr's separate
public source for its 63,513 shared respondents. That source's non-Hispanic-white
restriction is not imposed on the analysis. Official codebook p. 47 confirms the
unweighted release. Page 353 verifies education codes 1--9; codes 7--9 denote at
least a four-year college degree. Special missing codes remain missing, including
structurally unasked awareness questions. The codebook and input/export hashes
are frozen alongside the data. The optional importer reproduces the exact CSV hash.

`R/publicity.R` and scripts 13--15 produce all new manuscript numbers and exhibits.
Daily contrasts use actual calendar distance in Bartlett HAC; regular-grid and
weighted results agree with sandwich::NeweyWest, while irregular dates agree
with an independent explicit pair-sum. The independently reconstructed Python
coverage and opinion estimates agree to numerical precision. All analyses are
retrospective and exploratory; the JSON plan was written before inspecting the
new coefficients, with source-driven weighting/measurement changes recorded.
