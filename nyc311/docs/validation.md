# Foundation validation

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
