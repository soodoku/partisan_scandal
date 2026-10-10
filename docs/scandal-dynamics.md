# Scandal onset, publicity, and the persistence of approval effects

Recommendation, October 10, 2026: model an initial revelation with possible
renewed information shocks, and allow the approval response to dissipate or
persist. Do not equate the last news story with the end of treatment. Start with
a few event-time bins supported by the polls; use daily media data to measure
attention and its renewal. A freely estimated daily impulse response is premature.
This is a retrospective design recommendation after seeing the existing results,
not a preregistration. No new approval coefficients were fitted for this note.

## What the current model does

`R/data.R::analysis_sample()` keeps observations within 12 calendar months of
the first cataloged event, omits the event month, requires two observations on
each side, and censors at the next distinct cataloged scandal month.
`R/models.R::fit_model()` regresses approval, or the partisan approval gap, on
an official fixed effect, a common linear event-time trend, and a post indicator.
It fits a constant post-onset displacement within that window. It neither estimates
coverage duration nor distinguishes a short shock from a lasting shift. Separate
pre/post slopes and shorter windows are existing sensitivity checks, not a
measured coverage model. The CAR(1) likelihood exercise models correlated errors;
it does not supply a decay model for the scandal's effect.

An onset date is a recorded revelation or milestone, not evidence that everyone
heard the story that day. Omitting the whole onset month avoids ambiguous order
for monthly polls but can also discard the strongest immediate response. A
small post-period average does not rule out a sharp response followed by recovery.
Conversely, a lasting response need not require continuing coverage.

## Three clocks, three questions

1. **Revelation:** when an allegation becomes public, and when materially new
   evidence, an indictment, an admission, or a clearance follows. This requires
   source-backed milestone dates and date uncertainty. An indictment months into
   an affair is not necessarily the beginning of public exposure.
2. **Attention:** the daily flow of scandal reporting and its prominence in the
   relevant electorate's media. Attention can surge, subside, and return.
3. **Evaluation:** the approval trajectory following those revelations and that
   attention. Learning, memory, changed beliefs, and partisan responses can outlast
   the reporting itself.

The primary estimand should be the episode-average change in co-partisan and
opposition approval at each supported horizon after a sourced revelation,
relative to the no-revelation counterfactual, and their difference. Equal episode
weights target episodes; equal official weights target officials and are a
separate sensitivity if some officials have several episodes. Report percentage
points, onset uncertainty, and the officials contributing at each horizon.
Without a credible counterfactual this is an adjusted temporal association.

## What others do

There is no single treatment duration to inherit from this literature.

| Study | Timing approach | Relevance here |
| --- | --- | --- |
| [Mitchell (2014)](https://doi.org/10.1111/pops.12095) | A ten-week panel experiment varies early/late scandal information and repetition; evaluations are repeatedly measured. | Timing and decay matter. Repeated reminders can saturate; new details can prolong damage. Collect novelty separately from volume. |
| [Onishi (2026)](https://doi.org/10.1177/20531680261428570) | Seven days on each side of the December 7 Partygate video release; the initial report was November 30. | The estimand is the incremental effect of stronger evidence, not all effects of the affair. The window follows the event sequence and daily survey fieldwork. |
| [Warner (2023)](https://doi.org/10.1177/10659129221114145) | Daily scandal-related tweeting by media, legislators, and public groups; Granger tests and impulse-response functions. | A direct impulse-response precedent for attention. It does not identify an exogenous effect of news on approval; common shocks and feedback require separate identification. |
| [Rottinghaus (2014)](https://doi.org/10.1017/S1049096513001509) | Duration analysis of executive scandals, with institutional and political predictors. | An institutional ending or an official's departure is a different endpoint from coverage fading or voters recovering their prior opinions. |

Mitchell's publisher record and full article, Onishi's full publisher article,
Warner's publisher abstract/metadata, and Rottinghaus's publisher abstract/metadata
were checked. Claims about the latter two are limited to those accessible materials;
this is not a replication of their implementations. The three new bibliography
entries have been added to `ms/references.bib` and the validation ledger.

## A feasible first analysis with our polls

The generated [support table](../tabs/timing_support.csv) counts observations,
not independent events or statistical power. In the existing main cohort:

- Months 1–3 have 52 records across all 18 officials; months 4–6 have 42 across
  16; months 7–12 have 58 across 14. All 18 have observations in months −3 to −1.
- Of the 319 main records, 167 have day-level fieldwork dates and 152 have only
  month precision. Month boundaries stored in date fields are not actual
  month-long fieldwork. See [date precision](../tabs/timing_precision.csv).
- Returning to all eligible polls for these same officials, retaining current
  adjacent-event censoring, only four officials have a day-precise poll entirely
  within days 0–7. Days 0–30 have nine records across eight officials. These
  counts use archived onset dates, which themselves still require source checks;
  they do not establish usable pre/post pairs or a valid daily design.

I would make months 1–3 the proposed primary horizon, months 4–6 the recovery
contrast, and months 7–12 a secondary persistence check. Show the nearest
pre-period and earlier leads. These are **calendar event months**, not exact
30-day blocks. Also show the first post month where supported. Recompute support
for the expanded, source-validated ledger before locking the specification.
The principal comparison of recovery should use a common cohort with observations
in both post bins and a pre-period: changing officials across horizons can
otherwise resemble recovery. Report the broader unbalanced trajectory alongside
it, with composition and exit clearly shown. This common-cohort contrast is
recovery conditional on remaining observable, not recovery for all original
episodes. Missing polls and approval becoming undefined after an official leaves
office are different problems. Reporting exits does not remove survivor selection.

Use exact fieldwork dates in a complementary analysis to retain usable onset-month
polls. Flag fieldwork crossing the revelation; exclude it for the primary precise
analysis and assess fractional exposure only as a sensitivity. Interview-day
weights are needed to average a daily exposure over a multi-day poll accurately;
uniform interviews are an assumption, not observed data. Date-uncertain events
get interval/sensitivity treatment rather than invented day precision.

For causal interpretation, use screened comparison officials observed in the
same calendar periods, an event-specific baseline, and controls not already
exposed to their own relevant episode. Never-treated status cannot simply be
inferred from the old 'clean' label. Estimate event-specific contrasts before
aggregation so already-exposed officials are not implicit untreated controls.
A stacked design must track repeated uses of polls and dependence; a stack does
not create new information. Compare common-trend and no-trend assumptions.
Shared state-party shocks, differential trends, spillovers, and endogenous
revelation remain substantive concerns. Opposition respondents are an outcome
group, not an untreated group for estimating the level effect of the scandal.

Interact horizon with co-partisanship, or fit the paired gap directly, to test
whether parties differ initially and whether they recover differently. Test the
between-horizon contrast itself, using its covariance: one significant coefficient
and one nonsignificant coefficient do not establish recovery. Preselect the
primary gap horizon; report two-sided intervals and a directional test for the
stated co-partisan-protection hypothesis. Treat the rest of the trajectory as
joint/exploratory inference, rather than searching for a significant horizon.
Retain state CR2/Satterthwaite and wild-cluster sensitivity where supported;
reassess dependence when events share national publicity shocks. Small treated
samples constrain precision even when article counts are huge.

## Where an impulse model belongs

For a single revelation, a parsimonious descriptive curve would be

    effect_g(h) = persistent_g + transient_g * exp(-h / tau_g), h >= 0.

This nests recovery toward a lasting penalty; setting the persistent component
to zero imposes complete recovery. For h < 0 the event's contribution is zero.
A pulse is the new information at onset; this curve is the subsequent response.
With current data, estimate coarse horizon effects first. A nonlinear decay
constant and a persistent component can be hard to distinguish over a short,
irregular panel. If we later compare these curves, use the same observations,
profile likelihood intervals and predictive checks, not a preferred shape chosen
for significance. Do not estimate separate decay constants for every scandal.

With media data, the analogous model is a distributed lag of daily reporting:

    approval_g(t) = baseline_g(t) + sum_lag b_g(lag) * coverage(t - lag) + error.

Daily lags should be pooled into a few bins or constrained with a simple decay
kernel; monthly approval does not identify dozens of independent daily slopes.
New evidence and repeated reminders may have different associations. A decaying
stock of publicity is a useful sensitivity, but its half-life should be estimated
with uncertainty or varied over declared values, not asserted as known. A media
impulse response mixes news persistence and voter memory unless the design can
separate them. More data points in the news series alone cannot solve that.

Coverage is partly a mediator of revelation and partly a response to severity,
political conflict, and audience interest. Do not control for it when estimating
the total revelation effect, then label that coefficient the total scandal effect.
A coverage–approval relationship can be informative descriptively; a causal
publicity effect needs independent exposure variation or a credible experiment.

## Media collection and schema recommendation

Collect daily records from 90 days before to 180 days after each provisional
onset as an initial retrieval window, expanding backward if earlier reporting
appears. This is a collection boundary, not a claim that treatment lasts 180 days.
Before interpreting months 7–12, extend milestone and media ascertainment through
the last included poll; otherwise renewed coverage can masquerade as persistence.
Keep low-coverage cases and days with verified zero reporting. Separate missing
archive access from zero news. Use a fixed outlet basket and report local and
national coverage separately; a national count need not measure state exposure.

Extend the event ledger with onset lower/upper bounds, `milestone_type`,
`new_information`, and a linked source for the date and allegation. Keep stable
person, episode, and milestone IDs. Link a new article table with article ID,
publication timestamp/precision, outlet, URL/archive ID, geography, query version,
relevance decision, prominence where available, and duplicate/syndication group.
An article may cover multiple episodes, so use an article–episode link table.
Keep within-outlet duplicates distinct from legitimate publication by several
outlets: syndicated reach and unique story production are different measures.

Generate an episode–outlet–day table with relevant counts, observed outlet output,
availability, and optional audience weights fixed from pre-event data. Retain
counts as well as shares: Olympic coverage can increase the denominator even
without displacing scandal articles. Hand-check relevance and missed articles on
a stratified sample, including low-coverage days and ambiguous names. Store
corrections, denials, exonerations and new allegations as different content;
sentiment alone does not distinguish them. Audience consumption remains unobserved
unless the media data actually measure it.

Use the first seven days (days 0–6) as the primary initial-publicity measure and
fourteen (0–13) as sensitivity, as already proposed in `publicity-design.md`.
Those windows summarize exposure; they do not define the lifetime of its effect.
Only news published before an interview can explain that interview's response.
A completed seven-day total must not be assigned to a poll on day three. Measure
later coverage in fixed windows too. An observed quiet spell can summarize a
news cycle, but do not turn the treatment off at an outcome-selected threshold.

For Olympics, first ask whether coverage falls within these fixed windows.
The current main cohort has no first-fourteen-day Games overlap. An expanded
inventory may change support, but a date interaction alone does not establish
publicity or its effect. Retain the separate first-stage, timing, exclusion and
few-shock concerns in the [publicity design](publicity-design.md).

Finally, retain later milestones within an episode rather than mechanically
censoring an affair at its indictment. Other episodes can contaminate a window;
show their timing and use declared exclusion/censoring sensitivity. Resignation,
removal, or the disappearance of polling must be recorded as outcomes/attrition,
not coded as recovered approval or zero effect. The inventory expansion should
supply this chronology before choosing a final dynamic estimation sample.

With later milestones retained, the primary trajectory describes the evolving
episode following onset. It is not an isolated first-revelation impulse response.
Separating the latter from subsequent shocks requires additional assumptions
and adequate timing variation, even when every milestone is observed.

An independent econometric review checked this recommendation. Its two material
concerns—selection in common-cohort recovery and ascertainment beyond day 180—
are incorporated above. Neither was resolved by claiming the current data offer
more precision or identification than they do.
