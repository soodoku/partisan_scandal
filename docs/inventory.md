# Scandal inventory and usable comparisons

The catalog is a broad inventory of controversies involving politician-offices,
not a census of proven misconduct. Its codebook asks researchers to find serious
accusations reported by reputable media between 2005 and 2011, including gaffes
and inflammatory statements. It supplies no systematic search log, independent
second coding, coverage denominator, or quantitative publicity measure.

`scripts/07_inventory.R` preserves every coding row in
`data/derived/inventory_rows.csv`. The two CSV versions have identical cells
(apart from headers); the workbook also contains 295 rows on its sole sheet.
The generated counts distinguish clean entries, dated coding rows, official-date
combinations, and the main analysis's first recorded events. Multiple types on
one date are not independent scandals: David Vitter is coded twice on the same
date. Distinct dates can also represent developments in one continuing affair,
as with Jim Gibbons. The official-date count is therefore not a count of
independent episodes.

## Composition and selection

See [category counts](../tabs/inventory_types.csv),
[year counts](../tabs/inventory_years.csv),
[party counts](../tabs/inventory_parties.csv), and
[every dated official's polling support](../tabs/inventory_coverage.csv).

The retained events are dominated by corruption/misuse-of-office allegations.
No prostitution, sexual-assault, alcohol, or drug case enters the main comparison;
the sole noncriminal sexual-conduct entry is Cantwell. Consequently this sample
does not establish the average effect of the most severe or familiar sexual
scandals. Craig, Vitter, Spitzer, Ensign, Edwards, and Sanford appear in the
catalog but do not meet the main window/support rules. Those rules also remove
some officials whose departures may themselves represent accountability.

The attrition table is an accounting of observable support, not an explanation
of why each poll was absent. Do not infer that every missing post-event poll
reflects resignation. The project spans a gap in polling coverage, and some
catalog entries precede or follow the named politician-office's tenure.

[Category-specific estimates](../tabs/inventory_models.csv) apply the same
main regression to corruption and other categories, and add overall approval.
These exploratory comparisons retain small-cluster intervals. Comparing their
individual p-values would not test a difference between categories. Overall
approval includes independents and is taken directly from the source; it is
not the unweighted mean of the two partisan approval rates.

## Coding issues to resolve before expanding the universe

- Rubio's October 2011 entry omits state and office. It creates an incomplete
  key, not a distinct office. The same named politician's April 2010 entry
  supplies Florida and Senate. This does not affect the current main sample.
- Napolitano has source links but no date or category. She remains incomplete,
  rather than clean.
- The Schwarzenegger October 2003 and Kirk May 2012 entries fall outside the
  stated coding period. Kirk's November 2005 and Merkley's August 2008 events
  also precede their Senate service. An allegation can concern a candidate or
  a previous office; the date cannot automatically be assigned to a before/after
  comparison within the later office.
- The file labels Jay Nixon's office S and Kathleen Sebelius's party R. Those
  labels need review against the intended office/time definition before they
  are used in an expanded match. Clean labels also require date-specific review:
  they mean no qualifying episode was recorded, not that no controversy occurred.
- Sources range from major news organizations to partisan blogs and aggregator
  links. The main-event date review explicitly flags Cantwell's source threshold
  and several dates for controversies already underway.

These flags preserve the supplied coding. They are not silently applied recodes.
The first-event main analysis and its independently reviewed date sensitivity
remain reproducible as labeled.

## What the inventory means for the paper

The supported description is a modest average approval loss, larger among
opposing partisans, in this selected set of recorded controversies. A general
claim that scandals rarely matter would need an independently assembled event
universe, tenure-aware dates, and outcomes that include departure and electoral
defeat. Hayes (2025) offers a useful narrower benchmark: its inventory excludes
merely embarrassing or controversial remarks without clearly unethical conduct.
See [the literature review](literature.md).
