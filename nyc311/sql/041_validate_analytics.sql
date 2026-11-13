-- Read-only checks. Apply 040 first.
USE [NYC_Operations_Dev];
GO
SELECT COUNT_BIG(*) AS sample_requests,
    SUM(CAST(is_valid_request AS BIGINT)) AS valid_requests,
    SUM(CAST(is_valid_duration AS BIGINT)) AS eligible_durations,
    SUM(CASE WHEN duration_validation_status = 'No recorded closure'
        THEN CAST(1 AS BIGINT) ELSE CAST(0 AS BIGINT) END) AS no_recorded_closure,
    SUM(CASE WHEN duration_validation_status = 'Closure precedes creation'
        THEN CAST(1 AS BIGINT) ELSE CAST(0 AS BIGINT) END) AS negative_duration_records
FROM analytics.vw_request_detail_sample;

SELECT COUNT_BIG(*) AS full_source_requests FROM analytics.vw_request_detail;

SELECT request_id, is_valid_request, is_valid_duration, closure_duration_seconds,
    closure_duration_hours, duration_validation_status
FROM analytics.vw_request_detail_sample WHERE request_id = N'70592679';

SELECT * FROM analytics.vw_load_quality WHERE batch_id = 1;

IF EXISTS (SELECT request_id FROM analytics.vw_request_detail_sample GROUP BY request_id HAVING COUNT_BIG(*) > 1)
   OR EXISTS (SELECT request_id FROM analytics.vw_request_detail GROUP BY request_id HAVING COUNT_BIG(*) > 1)
    THROW 51301, 'Duplicate current request IDs in reporting detail.', 1;

IF EXISTS (SELECT 1 FROM analytics.vw_request_detail WHERE is_sample <> 0)
   OR EXISTS (SELECT 1 FROM analytics.vw_request_detail_sample WHERE is_sample <> 1)
    THROW 51302, 'Reporting namespaces are mixed.', 1;

IF EXISTS (
    SELECT 1 FROM analytics.vw_request_detail_sample
    WHERE (is_valid_duration = 0 AND closure_duration_seconds IS NOT NULL)
       OR (is_valid_duration = 1 AND (closure_duration_seconds IS NULL OR closure_duration_seconds < 0))
) OR EXISTS (
    SELECT 1 FROM analytics.vw_request_detail
    WHERE (is_valid_duration = 0 AND closure_duration_seconds IS NOT NULL)
       OR (is_valid_duration = 1 AND (closure_duration_seconds IS NULL OR closure_duration_seconds < 0))
) THROW 51303, 'Invalid duration eligibility in reporting detail.', 1;

IF (SELECT COUNT_BIG(*) FROM analytics.vw_request_detail_sample)
   <> COALESCE((SELECT SUM(requests_received) FROM analytics.vw_request_summary_sample), 0)
   OR (SELECT COUNT_BIG(*) FROM analytics.vw_request_detail)
   <> COALESCE((SELECT SUM(requests_received) FROM analytics.vw_request_summary), 0)
    THROW 51304, 'Summary totals do not reconcile to detail.', 1;

IF (SELECT COUNT_BIG(*) FROM analytics.vw_request_detail_sample)
   <> (SELECT COUNT_BIG(*) FROM core.vw_request_current WHERE is_sample = 1 AND is_valid_request = 1)
   OR (SELECT COUNT_BIG(*) FROM analytics.vw_request_detail)
   <> (SELECT COUNT_BIG(*) FROM core.vw_request_current WHERE is_sample = 0 AND is_valid_request = 1)
    THROW 51305, 'Analytics does not reconcile to eligible core records.', 1;

SELECT 'Passed' AS test_status, 5 AS reporting_check_groups;
GO
