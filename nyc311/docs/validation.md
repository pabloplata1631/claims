# Foundation validation

## Core desktop validation confirmed November 12 2026

The user executed scripts 030 and 031 successfully, then 032 reported batch 1
Processed with 100 accepted, zero rejected, 100 new, zero changed and zero
unchanged. Core held 100 current sample requests and 100 initial versions.
Request 70592679 retained request validity and its NULL ineligible duration.
Repeating batch 1 returned Already processed, with both counts unchanged at 100.

The user executed 033_test_core_history.sql; the supplied result showed Passed
with scenario_count 7. The script's seven controlled scenarios cover new,
repeated, unchanged, changed, invalid, sample/full separation, and retention
invariants. Test data is rolled back. These observations establish the tested
scenarios, not concurrency, older-batch rejection or full production readiness.

Analytics scripts 040 and 041 are the next milestone; desktop execution pending.

## Subsequent desktop validation confirmed November 12 2026

The user executed the updated staging view and SQL validations in SSMS:
batch 1 contains 100 sample observations and 100 valid requests, with 95 eligible
durations, 4 without a recorded closure, and 1 closure preceding creation.
Request 70592679 retains valid-request eligibility, has is_valid_duration = 0,
and NULL closure_duration_seconds. Original timestamps were preserved.
The user executed 026_test_staging_rules.sql and reported Passed with 9 fixtures.
These are user-reported desktop integration results, distinct from hosted CI.
Core execution was subsequently verified as recorded above.

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
