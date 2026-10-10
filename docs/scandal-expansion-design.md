# Source-backed expansion of the scandal inventory

The research universe is the governors and senators observed in the approval
panel. Research uses names, offices and polling dates, not estimated approval
responses. Existing fitted results have already been seen; this is a retrospective
extension, not a preregistered or blinded collection.

Search the observed period and its immediate boundaries for each official,
including officials previously coded clean. Preserve historical allegations that
resurface as renewed coverage. Record early or late events as such instead of
moving their dates into the polling window. Broad political controversies may
be retained as candidates but are distinguished from allegations of misconduct.
Ordinary policy disagreement is not automatically a scandal.

## Extended schema

The [timing design](scandal-dynamics.md) also proposes onset uncertainty bounds,
new-information flags, and linked article, article–episode and outlet–day tables.
These media fields are a collection plan; media data have not yet been ingested.
There is no single imposed scandal end date: institutional resolution, coverage
subsiding, and approval recovery are distinct quantities.

- `official_roster.csv`: one politician-office key, observed polling months,
  counts, affiliation and original coding status. This defines the search universe.
- Research JSONL files: one sourced event milestone with a stable `event_id`,
  `episode_id`, official `key`, label, category, allegation status, reported date,
  date precision, incident date when known, milestone type, description, date basis,
  original-catalog relationship, research status and notes. Each includes a list
  of supporting source records.
- Generated events CSV: one event milestone. Publication of an allegation,
  indictment, apology, clearance, and renewed coverage of the same affair share
  an episode ID. They are not counted as independent scandals.
- Generated sources CSV: one event-source link, with URL, title, publisher,
  publication date when known, source type, what it supports, retrieval status
  and access date. A news URL's publication date does not establish the first-ever
  revelation. Wikipedia can locate and corroborate an episode but retrospective
  text is not automatically a contemporaneous exposure measure.
- Search log: one official/query or reviewed resource, its result and remaining
  uncertainty. No candidate found is a documented search outcome, not a clean bill.
- Polling support: one event milestone, with usable pre/post records under stated
  windows. This measures feasibility and is separate from event validation.

## Join and analysis contract

The event table is the left universe for support summaries. Every event must
match exactly one roster key; unmatched identities are errors. Supporting sources
have a many-to-one event link. The source approval panel is never overwritten.
An event-by-poll exploration intentionally repeats polls across event windows and
must retain event, episode and official IDs. It cannot be analyzed as independent
new polls. Report support both without adjacent-event censoring and with other
documented episodes restricting the window; distinguish those from successive
milestones in the same episode.

The expanded research ledger does not silently replace the archived main model.
It supplies concrete, reviewable exposure definitions and source histories before
any change to the paper's preferred event universe or coefficient.
