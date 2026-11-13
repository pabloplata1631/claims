USE [NYC_Operations_Dev];
GO
EXEC core.usp_load_request_batch @batch_id = 1;
GO
SELECT is_sample, COUNT_BIG(*) AS current_requests
FROM core.request_current GROUP BY is_sample;
SELECT is_sample, COUNT_BIG(*) AS version_records
FROM core.request_version GROUP BY is_sample;

SELECT request_id, is_valid_request, is_valid_duration, closure_duration_seconds
FROM core.vw_request_current
WHERE is_sample = 1 AND request_id = N'70592679';

-- Rerun should return Already processed and leave both counts unchanged.
EXEC core.usp_load_request_batch @batch_id = 1;
GO
SELECT is_sample, COUNT_BIG(*) AS current_requests_after_rerun
FROM core.request_current GROUP BY is_sample;
SELECT is_sample, COUNT_BIG(*) AS versions_after_rerun
FROM core.request_version GROUP BY is_sample;
