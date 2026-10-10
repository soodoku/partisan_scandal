# Publicity analysis: implemented extension

The manuscript now reports the 2004 Swift Boat/Olympics comparison using 146
ABC/CBS/NBC evening-news programs and 15,109 NAES interviews. Scripts 13--15
produce coverage models, network-by-party rating contrasts, awareness counts,
and audience-composition checks. All 81,422 original NAES respondents match
across the public source and the historical extract; no race restriction is imposed.

The broadcast comparison estimates NBC minus the equal ABC/CBS mean on the
41 dates with all three programs. Survey comparisons use 53 daily cells per
party contrast. Primary models include Olympics and post-Games indicators and
a calendar trend; no-trend results are reported alongside them. Calendar HAC
uses elapsed days, preserving gaps between observed broadcasts. Frozen source
responses, download manifests, codebook, topic decisions and the retrospective
analysis plan are included in the replication materials. Equal respondent weights
follow the original unweighted NAES release; historical analyst-created weights
are not mislabeled as official survey weights.

The results show more Olympic coverage on NBC but do not establish displacement
of Swift Boat allegations. Audience awareness is similar across networks just
after opening. Opinion comparisons are descriptive: contemporaneous network
choice, changing composition, conventions and one Olympics prevent a causal
publicity interpretation. The main-text tables report estimates and intervals;
complete specification outputs are in `tabs/publicity_*`.

## Earlier approval-cohort support check

The [dynamics recommendation](scandal-dynamics.md) distinguishes revelation,
coverage duration and persistence of approval effects, audits polling resolution,
and specifies the media records needed before estimating a publicity model.

The mechanism is plausible and has clear precedents, but the original approval
cohort has no initial-publicity Olympics treatment variation. This is a measured
support failure, not a nonsignificant estimate. The generated
[overlap table](../tabs/olympic_support.csv) counts onset, first-seven-day and
first-fourteen-day windows, including onset and counting forward only. Every
case is in [the event-level file](../tabs/olympic_event_overlap.csv).

Summer and Winter Games are included using Olympic committee dates in
`data/external/olympic_dates.csv`. The archive's `olympics.txt` covers only Summer
Games and omits the month for its 2008 line. No historical estimation code was
found supporting the original abstract's publicity-effect claim.

Heller, Paterson, and Merkley have recorded onsets during the Games. Adding the
following six days also includes Menendez; adding thirteen days includes Palin
and Herbert. None enters the main sample. Heller, Palin, and Herbert have no
matched approval records; Merkley lacks pre-event observations; Paterson and
Menendez lack sufficient nearby post-event observations. Lautenberg's February
2006 event occurs after the Games; symmetric date padding would incorrectly
count it as crowdout of subsequent reporting. Repeated-event and supported-date
samples also have no first-fourteen-day Olympics overlap.

## Broader identification considerations

1. Assemble allegations independently of observed publicity, using official
   releases, audits, court filings, and a documented search protocol. Separate
   occurrence, first revelation, indictment, admission, and exit dates. A
   catalog selected for major-media attention conditions on the intended
   publicity outcome and can omit precisely the cases crowded out.
2. Measure daily local scandal coverage with case-specific queries, archived
   article identifiers, duplicate rules, and total outlet output. First test
   whether the Games reduce coverage. National Olympic airtime need not crowd
   out local coverage by the same amount. Fix a seven-day exposure window and
   a fourteen-day sensitivity before looking at approval results.
3. With additional supported events, regress pre/post approval changes on
   scandal publicity, interacting publicity with co-partisanship. If Olympic
   exposure is a valid instrument, instrument both publicity and its partisan
   interaction with the corresponding Olympic variables. Include all lower-order
   terms and use the paired contrast to test the difference in publicity slopes.
4. Report the reduced form and the coverage first stage before interpreting an
   IV effect. Allow dependence within officials, states and shared publicity
   shocks as justified by the expanded design; three Games do not supply many
   independent shocks merely because many polls are observed. Weak-instrument
   uncertainty is consequential. Do not promise identification from a large
   number of article or respondent records alone.

Predetermined Games dates do not make revelation timing random. Officials or
sources may time releases around predictable news congestion; Durante and
Zhuravskaya (2018) provide evidence of strategic timing in another setting.
Olympic attention can also affect survey participation, national mood, and
other political information. Same-poll clean-official comparisons help with
common changes but do not establish the exclusion restriction. Natural
disasters are not automatically safer instruments for approval because officials'
responses can affect their ratings directly.

An ongoing-scandal design is another possibility: test whether daily coverage
falls when the Games begin for controversies already underway, then connect
that interruption to sufficiently frequent opinion measures. This asks about
sustained attention rather than initial exposure. It requires daily coverage and
more precise polling dates; a post-scandal × Olympic-month regression on this
panel would mix several different questions.

The 2004 ongoing-controversy comparison above implements the coverage and
audience measurements in a separate sample. See [verified literature](literature.md).
