# Validation record

Validated October 10, 2026.

The complete analysis pipeline and XeLaTeX/BibTeX build ran successfully.
After formatting fixes, `make lint test` passed: 175 assertions, zero failures,
warnings, or skips; lint returned no findings. The final exhibit refresh and
`make manuscript lint` also passed. Compilation has no unresolved citations,
references, or overfull boxes. The 21-page PDF was rendered and visually checked.

The original approval estimates are unchanged. Tests cover paired/stacked
interaction equivalence, independent CR2 covariance algebra, directional tests,
likelihood calculations, source-row conservation, event timing, experimental
contrasts, and external-inventory joins. Original analytical inputs and frozen-source
hashes match their manifests. All 23 bibliography keys match the validation ledger.

New broadcast checks conserve 4,027 segments and 256 evening-news programs
across separate 2004 and 2008 windows; only the 146 programs in 2004 enter the
new manuscript analysis. Missing programs remain missing. Independent Python
reconstruction reproduces all 48 coverage models from the frozen raw JSON and
topic codes to numerical precision.

All 81,422 NAES2004 respondent IDs, dates, and Bush/Kerry ratings match the public
source and historical extract. All 39 recovered media/source fields also agree
with Darr's independent replication for its 63,513 shared respondents. The full
source imposes no race restriction. The awareness module contains 2,209 recorded
answers and 2,156 substantive seen/heard/neither answers, consistent with its
questionnaire schedule. The optional public-source importer recreated the exact
frozen CSV SHA256 from the original downloaded Stata file.

Independent Python reconstruction reproduces all 4,008 final daily opinion/
composition cells, 1,549 network gaps, and all opinion-model coefficients,
standard errors and intervals (maximum interval difference below 1.4e-13).
Regular-grid calendar HAC agrees with official sandwich::NeweyWest for both
unweighted and weighted regressions. Irregular-date HAC agrees with an explicit
dated pair-sum and correctly differs from compressed observation lags. The new
statistical tests retain these checks alongside routing, units, missing-program,
source-join, and direct partisan-contrast checks.

The public manuscript now reports measured coverage, awareness, and candidate
ratings. Exploratory comparisons use contemporaneous network preference and
one Olympics; they do not claim a causal publicity effect. The analysis plan
records decisions made before inspecting the new estimates and source-driven
measurement corrections. External-study replications and ANES feasibility
outputs remain in the replication materials rather than the public results.

The supplied ZIP and historical archive were removed. Required original data
and the scandal codebook remain in `data/raw/`, with original filenames and
checksums. Unused external datasets, duplicate downloads, and stale page renders
were also removed.

Final PDF SHA256: `6484a14aaf72c574865e6e5d8a9ecef9e2b67ffa77ea584683259795bb6b68f1`.

The public package passes the complete `make check` with no historical archive
present. Git attributes preserve all frozen data bytes across checkout; staged
source hashes agree with the manifests.
