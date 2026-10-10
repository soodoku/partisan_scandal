# Econometric and data audit

The reconstructed data support a directional finding of larger opposing-partisan
approval declines, with magnitude and uncertainty sensitive to timing and the
counterfactual trend. Confidence intervals exclude large co-partisan penalties
in the main, no-trend and supported-date analyses, while retaining modest ones.
The [generated summary](../tabs/summary.md) and [effect-size comparisons](../tabs/effect_size_bounds.csv)
provide the exact estimates. The analysis does not require a literally zero
co-partisan response to assess relative accountability.

## Reproduction and repairs

The historical table reproduces to all reported digits. Its state/second-name-token
join ignores office, handles suffixes incorrectly, conflates the Murkowskis, and
selects an event by file order. A thirty-day offset also changes which calendar
months are called post-event. The current join preserves every source row and
selects events chronologically. Historical and current estimators are separately
reported because local windows, support and censoring change the estimand.

Conventional historical OLS uncertainty is narrow. Re-estimating that same model
with state-clustered CR2 shows how much inference alone changes; see
[legacy_clustered.csv](../tabs/legacy_clustered.csv). The current primary result
uses CR2/Satterthwaite inference and directly estimates the paired partisan gap.
Independent residualization and matrix-sandwich calculations reproduce the OLS
coefficient and CR2 covariance. A null-imposed WCR11 bootstrap is a reference-
distribution sensitivity, not a replacement chosen for a smaller probability.

The source approval files agree on every original nonmissing approve/disapprove
percentage. Historical missing values remain missing, even when a source contains
a presidential percentage omitted from the old combined file. Original source
poll keys identify shared surveys more accurately than the synthetic historical
IDs. Duplicate source presidential records are verified before lookup collapse;
the historical duplicate remains flagged, outside the senator/governor analysis.

## Check matrix

| Check | Evidence and result |
|---|---|
| Units and denominators | Poll percentages, politician-poll rows, source polls, event windows and officials are distinguished. Exact partisan counts are absent; no invented binomial precision or respondent totals. |
| Missing versus zero | No missing approval filled with zero. Missingness by office and pre/post period is retained in `tabs/missingness.csv`; post-event governor availability is selective. |
| Joins and silent loss | Row-count and order conservation, explicit source keys, matching aliases, office separation and source reconciliation tested. Unmatched/incomplete coding is not clean. |
| Numerical provenance | Tables and inline results are generated; independent macro checks and manuscript compilation verify references. Mechanical audit candidates are resolved in `provenance.md`. |
| Internal consistency | Identical rows for both partisan outcomes and the gap; the gap coefficient equals the difference of coefficients. |
| EDA | Uniqueness, bounds, grouped missingness and trajectories checked. `data-audit.txt` records mechanical candidates; missing unused ideology/office-specific metadata is expected. |
| Raw comparison levels | Pre/post group means and equal-official raw gap changes are shown. Model shifts are not mislabeled as raw means. |
| Estimand and weighting | Equal-record primary, equal-official sensitivity, explicitly weighted pair comparisons. None is claimed to estimate a national citizen average. |
| Interaction and likelihood | Explicit stacked interaction agrees with the paired contrast; Gaussian CAR(1) profile likelihood estimates and LR comparisons are independently checked. Likelihood assumptions are stated, and ratios are not labeled posterior odds. |
| Dependence and inference | State CR2/Satterthwaite; politician alternative; WCR11; direct paired contrast. National party shocks remain possible. |
| Functional form | No trend, common/separate/official slopes, calendar effects and window family retained. Primary fitted approval predictions stay within logical bounds. |
| Leverage and skew | Every leave-one-official-out result retained; raw official trajectories expose heterogeneous changes. No log transformation of signed gaps. |
| Exposure and measurement | Main-event date review finds later milestones and uncertain first publicity. Exact poll bounds used where known; source-supported alternatives and restricted sample reported. |
| Selection | Both-side support and censoring documented. Same-sample treated-only comparison separates control-sample selection from adjustment. No claim that complete cases are missing at random. |
| Placebo | Break within preperiod estimated with its interval; failure to reject does not establish stability. |
| Panel identification | Within-official post-versus-pre variation is identified algebraically. A causal counterfactual is not established by fixed effects. |
| Repeated events | Event windows and reused polls explicitly counted; state dependence retained. Earlier exposures can affect later baselines. |
| Subgroups and multiplicity | Exploratory groups with intervals; no cross-group inference from separate p-values. No retrospective declaration of a primary hypothesis registration. |
| Experiment | Recovered from public partisan_principled inputs. Archived interaction coefficients reproduce; direct contrasts, HC3, attention rules, party standardization, trait scaling and strength moderation checked. See experiment_bridge.md. |
| IV and publicity | Olympics mechanism reviewed against primary literature; zero onset/forward-window overlap in main cohort means initial-publicity interaction is not identified. No publicity coefficient reported. |
| Generated regressors/scales | No estimated ideology score used. Gap is a deterministic paired outcome; covariance handled in the outcome model. |
| Interpretation | Assess excluded effect sizes, not just rejection of zero. Relative approval accountability is distinct from electoral punishment, processing mechanisms and affective polarization. |

## Event dates and competing explanations

The [event review](event_date_review.csv) gives a row-by-row evidence trail.
Bond's alternative public report date is supported by the
[DOJ release](https://www.justice.gov/archive/opa/pr/2008/September/08-opa-859.html)
and [report chapter](https://oig.justice.gov/sites/default/files/archive/special/s0809a/chapter4.htm).
Kerry's controversy was already public in the
[October White House briefing](https://georgewbush-whitehouse.archives.gov/news/releases/2006/10/20061031-7.html).
Other records cannot be treated as onset merely because they contain a precise date.

The supported-month subset was selected on source evidence before estimating
that subset. Its membership is still a retrospective review judgment, and the
subset changes the event population. Its smaller asymmetry does not isolate the
causal contribution of correcting dates. Likewise, same-poll clean controls can
share scandal spillovers and differ in their own trajectories.

## Claims that withstand the checks

- The original table is computationally reproducible.
- Correctly paired approval outcomes generally produce a positive main partisan
  contrast, and out-party approval declines are substantively larger in the
  principal fitted specification.
- Large co-partisan declines and large reverse asymmetries can be excluded under
  stated models; modest co-partisan declines and approximate equality remain in the two-sided intervals. The main directional test rejects a nonpositive gap at 5%.
- The direction is more stable across the main specification family than its
  magnitude or conventional significance classification.
- Causal exposure effects, co-partisan immunity, individual updating, and effects
  on affect toward ordinary partisans are not established by these aggregate records.

The design choices are documented in [design.md](design.md). Results are a
research draft, not a declaration that the underlying observational design has
become a randomized experiment.

The expanded [inventory audit](inventory.md) and [publicity design](publicity-design.md) distinguish missing empirical support from estimated null effects. The [experiment bridge](experiment_bridge.md) corrects the initial inference that the archived experimental data were unavailable: they are present in the newly inspected companion repository.
