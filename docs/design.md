# Analysis decisions

This is a retrospective reanalysis. The archived results were visible before
specification choices. No analysis is described as preregistered or blinded.

## Question and estimand

How does the fitted approval change among a politician's co-partisans compare
with the change among opposing partisans around a cataloged scandal? The main
quantity is the coefficient on a post-event indicator in an OLS model of the
paired co-minus-opposing approval gap, with politician-office fixed effects and
a common linear calendar-month distance from the event. Units are percentage
points. Each politician-poll record has equal weight. This is a conditional
association for officials with usable observations on both sides, not a
population-average citizen effect or a causal effect of randomly assigned scandal.

## Primary choices

- Preserve source outcomes and leave missing values missing. Major-party
  officeholder affiliation determines which group is co-partisan.
- Match scandals by state, office, and normalized surname. Disambiguate the two
  Virginia Senator Warners by recorded party. Explicit suffix removal and the
  Kulongowski/Kulongoski spelling alias are the only name normalization beyond
  lowercasing and whitespace. The incorrectly coded Jay Nixon Senate record is
  not silently moved to the governorship. Missing Arkansas coding remains unmatched.
- Use the chronologically earliest cataloged date. Multiple categories on the
  same date do not create duplicate polls. Next distinct event month censors
  follow-up. This defines catalog milestones, not verified first public exposure.
- Retain months within twelve months on either side, omit the event month,
  require at least two complete observations before and after, and retain the
  event's party affiliation. Exclude incomparable strong/weak party columns.
- Cluster by state using CR2 with coefficient-specific Satterthwaite degrees of
  freedom. The working covariance target is identity; aggregation weights are
  not inverse-variance weights. State clustering permits repeated-official and
  within-state dependence, while assuming independent residual processes across states.
- Directly estimate the paired gap. Do not infer an interaction from one group
  having a small p-value and the other having a large one.

## Why use the companion approval files?

The historical combined data are identical across the two projects after newline
normalization. The companion source files recover fieldwork metadata, original
poll identifiers, rounded composition shares and omitted December 2006 records.
They do not create an independent replication sample. Exact partisan denominators
remain unavailable. No ideology adjustment is added automatically: between-official
ideology is absorbed by official effects, and time-varying ideology or public
reactions can be endogenous to the controversy. CCES and the companion experiment
measure different samples, treatments and outcomes, so are not pooled.

## Sensitivity family

The generated results retain all examined variants: six/eighteen-month windows;
original coverage; known fieldwork pre/post classification; event-month pre/post
assignment; no trend, separate slopes, official-specific slopes and calendar-month
fixed effects; equal-official weights; politician clusters; one observation on each
side; leave-one-official-out; a preperiod placebo; party/office/type subgroups;
repeated cataloged events; same-source-poll clean comparisons; two documented
public-event date alternatives; and the supported-exposure-month subset.

Same-poll controls have the same state and party and are coded clean. Pair fixed
effects and inverse-number-of-controls weights give each treated poll equal total
weight. The treated-only model uses exactly the same pairs and weights, so sample
selection and control adjustment are distinguishable. Clean status and absence
of spillovers are unverified, so this is a descriptive benchmark.

Repeated-event samples use event fixed effects and calendar-month windows bounded
by adjacent recorded event months. Earlier scandals may already have changed the
baseline; reused polls remain dependent. Report event windows, distinct officials
and source records separately, and retain state clustering.

## Effect sizes

Two-, five-, and ten-point co-partisan penalties are illustrative benchmarks chosen
for transparent interpretation after estimation, not preregistered equivalence
margins. A benchmark is excluded only when outside the reported 95% confidence
interval. Absence of a statistically detectable change is not taken as evidence
of negligible response. The direct gap interval also bounds reversals of the
expected asymmetry. Every such statement remains conditional on the exposure
coding, sample, trend and covariance assumptions.

## Unresolved scientific limits

The date review validates evidence for events in the main sample, while recording
ambiguous and later milestones explicitly. It does not validate every event in
the full catalog or prove first lifetime exposure. The main analysis therefore
uses recorded dates transparently, with source-supported alternatives and selection
checks. Poll availability can depend on election defeat, departure from office or
the scandal itself. Earlier survey scales and weights are incompletely documented.
The approval outcomes do not identify changes in affect toward ordinary party supporters. The recovered MTurk experiment separately identifies responses to assigned story variants; it does not establish a population mechanism connecting real scandals to polarization.

## Interaction and likelihood extension

At the author's request, the analysis explicitly stacks group-specific approval
outcomes and interacts co-partisan status with post, time, and official effects.
This exactly reproduces the paired-gap coefficient, standard error and degrees
of freedom. The likelihood extension fits Gaussian GLS with a continuous AR(1)
process within officials, common outcome-specific residual variance/correlation,
and independence across officials. Maximum likelihood (not REML) is used for
comparisons of different mean specifications. For each fixed candidate post
coefficient the remaining parameters are re-estimated; subtracting that known
post contribution from the response avoids unsupported offsets in `gls`.

Profile-likelihood ratios compare each candidate with the best-fitting effect.
They are not posterior probabilities or Bayes factors. LR-test reference
probabilities use the asymptotic one-degree-of-freedom chi-square approximation.
The likelihood covariance assumptions are stronger than arbitrary state-clustered
dependence, so this is a model-based sensitivity. The code verifies the package
log likelihood against an independent Gaussian block-covariance calculation.

## Directional inference and recovered experimental evidence

The archived hypothesis and the author's stated prior expectation predict a
positive co-minus-opposing contrast. The main report therefore supplies the
one-sided test of a nonpositive gap, alongside the two-sided p-value and 95%
two-sided interval. This does not claim a preregistered choice of tail. The
bootstrap directional probability is calculated from its signed draws.

The [experimental bridge](experiment_bridge.md) reconstructs the archived
seven-trait outcome and strength interaction from public `partisan_principled`
data. It retains the original all-assigned sample and the companion's strict
pretreatment attention screen. Direct response/nonresponse contrasts are
reported alongside placebo contrasts, with pooled and party-standardized
estimates, unequal-variance cell inference, and HC3 checks. These subgroup
analyses are exploratory and do not substitute for the approval-panel estimand.

The [inventory audit](inventory.md) and [publicity design](publicity-design.md)
document scope and measured Olympic support before any publicity model. Overall
approval and category-specific models are exploratory additions using the same
main specification; overall approval is read directly from the source.
