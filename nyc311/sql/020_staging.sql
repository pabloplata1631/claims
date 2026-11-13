USE [NYC_Operations_Dev];
GO
CREATE OR ALTER VIEW stg.vw_request_typed
AS
WITH extracted AS (
    SELECT r.raw_record_id, r.batch_id, r.request_id, r.ingested_at_utc,
        b.source_name,
        JSON_VALUE(r.payload_json, '$.unique_key') AS source_request_id,
        JSON_VALUE(r.payload_json, '$.created_date') AS created_date_text,
        JSON_VALUE(r.payload_json, '$.closed_date') AS closed_date_text,
        NULLIF(TRIM(JSON_VALUE(r.payload_json, '$.agency')), '') AS agency,
        NULLIF(TRIM(JSON_VALUE(r.payload_json, '$.complaint_type')), '') AS problem,
        NULLIF(TRIM(JSON_VALUE(r.payload_json, '$.status')), '') AS request_status,
        NULLIF(TRIM(JSON_VALUE(r.payload_json, '$.borough')), '') AS borough,
        NULLIF(TRIM(JSON_VALUE(r.payload_json, '$.incident_zip')), '') AS incident_zip
    FROM raw.request_payload AS r
    JOIN audit.load_batch AS b ON r.batch_id = b.batch_id
    WHERE b.load_status = 'Succeeded'
), typed AS (
    SELECT *, TRY_CONVERT(DATETIME2(3), created_date_text, 126) AS created_at,
        TRY_CONVERT(DATETIME2(3), NULLIF(TRIM(closed_date_text), ''), 126) AS closed_at
    FROM extracted
), request_checked AS (
    SELECT *, CASE
        WHEN source_request_id IS NULL OR source_request_id <> request_id THEN 'Request ID mismatch'
        WHEN created_at IS NULL THEN 'Missing or invalid created date'
        WHEN agency IS NULL THEN 'Missing agency'
        ELSE 'Passed'
    END AS request_validation_status
    FROM typed
), duration_checked AS (
    SELECT *, CASE
        WHEN request_validation_status <> 'Passed' THEN 'Request validation failed'
        WHEN NULLIF(TRIM(closed_date_text), '') IS NOT NULL AND closed_at IS NULL THEN 'Invalid closed date'
        WHEN closed_at IS NULL THEN 'No recorded closure'
        WHEN closed_at < created_at THEN 'Closure precedes creation'
        WHEN request_status IS NULL OR UPPER(request_status) <> 'CLOSED' THEN 'Status not closed'
        ELSE 'Passed'
    END AS duration_validation_status
    FROM request_checked
)
SELECT raw_record_id, batch_id, request_id, source_name,
    CAST(CASE WHEN source_name = 'NYC311_DEV_SAMPLE' THEN 1 ELSE 0 END AS BIT) AS is_sample,
    created_at, closed_at, agency, problem, request_status, borough, incident_zip,
    ingested_at_utc,
    CASE
        WHEN source_request_id IS NULL OR source_request_id <> request_id THEN 'Request ID mismatch'
        WHEN created_at IS NULL THEN 'Missing or invalid created date'
        WHEN NULLIF(TRIM(closed_date_text), '') IS NOT NULL AND closed_at IS NULL THEN 'Invalid closed date'
        WHEN closed_at < created_at THEN 'Closure precedes creation'
        WHEN agency IS NULL THEN 'Missing agency'
        ELSE 'Passed'
    END AS validation_status,
    request_validation_status,
    CAST(CASE WHEN request_validation_status = 'Passed' THEN 1 ELSE 0 END AS BIT) AS is_valid_request,
    duration_validation_status,
    CAST(CASE WHEN duration_validation_status = 'Passed' THEN 1 ELSE 0 END AS BIT) AS is_valid_duration,
    -- Nominal source-local seconds, not UTC-normalized elapsed time across DST.
    CASE WHEN duration_validation_status = 'Passed'
         THEN DATEDIFF_BIG(SECOND, created_at, closed_at)
         ELSE NULL END AS closure_duration_seconds
FROM duration_checked;
GO
