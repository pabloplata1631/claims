# First reporting views

Prepared for desktop execution; not yet validated in SQL Server or Power BI.
Apply sql/040_analytics_views.sql, then sql/041_validate_analytics.sql.

## Power BI sources

- analytics.vw_request_detail_sample: one accepted current sample request per row.
- analytics.vw_request_summary_sample: counts grouped by created date, agency,
  problem, and borough. These are created-date cohorts, not daily closure events.
- analytics.vw_request_detail and analytics.vw_request_summary: corresponding
  full-source views that exclude samples. They should be empty until real complete
  extracts are loaded through core; an empty result now is expected.
- analytics.vw_load_quality: one row per recognized raw batch, including sample
  status, raw audit counts, staged eligibility, and core processing outcomes.
  This audit view deliberately includes both labeled namespaces.

Use the sample detail view for the first report prototype, clearly labeled as
100 sample requests from the October 1 Brooklyn cohort. It is not a representative
sample or a complete operational dashboard. Use full-source views later, without
changing their sample filter to populate an otherwise empty report.

## Metric semantics

Requests received counts eligible current requests by source creation date.
Recorded closed means the source status is Closed; it does not prove resolution.
Four missing closures are not automatically four open requests. Active-status
mapping and time-based backlog snapshots are still future work.

Closure hours derive only from eligible seconds; invalid durations remain NULL.
Values are nominal source-local durations and are not yet UTC-normalized across
daylight-saving transitions. Use seconds to compute averages; never average
group averages or rounded hours. For aggregated means divide summed eligible
seconds by summed eligible-duration counts. Empty duration totals remain NULL.
Median and P90 should be computed from detail, not reconstructed from summary.

Current means the last accepted observation of tracked requests. Display raw
ingestion and core observation times to assess freshness; neither is the source
publication timestamp. Quality counts reflect the current staging rules.
The full historical Brooklyn backlog and daily historical backlog cannot be
inferred from these views or the initial limited cohort.

## Initial validation expectations

Given only batch 1 persisted, sample detail should contain 100 valid requests,
95 eligible durations, 4 missing closures, and 1 negative-duration record.
Request 70592679 retains a NULL duration in both seconds and hours. Full-source
detail should contain zero rows. The validation script checks keys, namespace
separation, duration eligibility, summary reconciliation, and core reconciliation.
