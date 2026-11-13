-- Read-only validation after applying 020_staging.sql.
USE [NYC_Operations_Dev];
GO
SELECT batch_id, is_sample, COUNT_BIG(*) AS total_records,
    SUM(CAST(is_valid_request AS BIGINT)) AS valid_requests,
    SUM(CAST(is_valid_duration AS BIGINT)) AS eligible_durations
FROM stg.vw_request_typed
GROUP BY batch_id, is_sample;

SELECT request_id, created_at, closed_at, request_status,
    validation_status, request_validation_status, is_valid_request,
    duration_validation_status, is_valid_duration, closure_duration_seconds
FROM stg.vw_request_typed
WHERE batch_id = 1 AND request_id = N'70592679';

-- Expected zero violations; these checks do not assume all closed rows are valid.
SELECT COUNT_BIG(*) AS invalid_duration_values
FROM stg.vw_request_typed
WHERE (is_valid_duration = 0 AND closure_duration_seconds IS NOT NULL)
   OR (is_valid_duration = 1 AND
       (closure_duration_seconds IS NULL OR closure_duration_seconds < 0
        OR is_valid_request = 0));
GO
