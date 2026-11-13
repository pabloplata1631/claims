# Foundation validation

## Subsequent desktop validation confirmed November 12 2026

The user executed the updated staging view and SQL validations in SSMS:
batch 1 contains 100 sample observations and 100 valid requests, with 95 eligible
durations, 4 without a recorded closure, and 1 closure preceding creation.
Request 70592679 retains valid-request eligibility, has is_valid_duration = 0,
and NULL closure_duration_seconds. Original timestamps were preserved.
The user executed 026_test_staging_rules.sql and reported Passed with 9 fixtures.
These are user-reported desktop integration results, distinct from hosted CI.
Core-table creation and history loading below are the next unexecuted milestone.

## Earlier foundation check record

Executed November 11, 2026, America/Chicago (run timestamp November 12 UTC).

- Six local Python tests passed: pagination/sample limits, duplicate rejection,
  request-ID ordering across dates, missing ID rejection, partial-extract
  reconciliation, and scope/date quoting.
- `git diff --check` passed for tracked changes.
- Live API sample completed: Brooklyn requests created October 1, 2026, with
  exclusive upper date October 2, 2026. Retrieved 100 distinct request IDs.
- Source count before and after sample extraction was 4,172. This is a sample,
  not a full cohort reconciliation and not eligible for SQL production loading.
- Source metadata, original JSONL, SSMS-oriented CSV and manifest were generated.
- A broader preliminary sample query was slow and canceled. Pagination now
  orders by created date and request ID rather than request ID alone. Full-cohort
  performance is not validated.

Not executed: SQL Server load, history persistence, repeat-load recovery, daily
scheduler, hosted GitHub CI, Power BI Desktop, workspace deployment, gateway
refresh, UAT, app publication, or agent evaluation. At the time of these local
checks no remote GitHub publication had occurred; consult the pull request for
subsequent publication and hosted CI results.
