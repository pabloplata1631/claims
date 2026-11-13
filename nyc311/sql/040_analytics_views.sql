-- DEV-only view definitions. Sample and full-source reporting stay separate.
USE [NYC_Operations_Dev];
GO
CREATE OR ALTER VIEW analytics.vw_request_detail
AS
SELECT request_id, is_sample, batch_id, raw_record_id, request_version_id,
    source_name, created_at, closed_at,
    CAST(created_at AS DATE) AS created_date,
    CAST(closed_at AS DATE) AS recorded_closed_date,
    agency, problem, request_status, borough, incident_zip,
    CAST(CASE WHEN UPPER(request_status) = 'CLOSED' THEN 1 ELSE 0 END AS BIT)
        AS is_recorded_closed,
    is_valid_request, is_valid_duration, duration_validation_status,
    closure_duration_seconds,
    CAST(closure_duration_seconds / 3600.0 AS DECIMAL(18,4)) AS closure_duration_hours,
    ingested_at_utc AS raw_ingested_at_utc,
    first_seen_utc AS core_first_seen_utc,
    last_seen_utc AS core_last_seen_utc
FROM core.vw_request_current
WHERE is_sample = 0 AND is_valid_request = 1;
GO
CREATE OR ALTER VIEW analytics.vw_request_summary
AS
SELECT created_date, agency, problem, borough,
    COUNT_BIG(*) AS requests_received,
    SUM(CAST(is_recorded_closed AS BIGINT)) AS recorded_closed_in_created_cohort,
    SUM(CAST(is_valid_duration AS BIGINT)) AS eligible_durations,
    SUM(CASE WHEN duration_validation_status = 'No recorded closure'
             THEN CAST(1 AS BIGINT) ELSE CAST(0 AS BIGINT) END) AS requests_without_recorded_closure,
    SUM(CASE WHEN duration_validation_status IN ('Invalid closed date', 'Closure precedes creation')
             THEN CAST(1 AS BIGINT) ELSE CAST(0 AS BIGINT) END) AS invalid_closure_timestamps,
    SUM(CAST(closure_duration_seconds AS DECIMAL(28,0))) AS eligible_duration_seconds_total,
    MAX(raw_ingested_at_utc) AS latest_raw_ingestion_utc,
    MAX(core_last_seen_utc) AS latest_core_observation_utc
FROM analytics.vw_request_detail
GROUP BY created_date, agency, problem, borough;
GO
CREATE OR ALTER VIEW analytics.vw_request_detail_sample
AS
SELECT request_id, is_sample, batch_id, raw_record_id, request_version_id,
    source_name, created_at, closed_at,
    CAST(created_at AS DATE) AS created_date,
    CAST(closed_at AS DATE) AS recorded_closed_date,
    agency, problem, request_status, borough, incident_zip,
    CAST(CASE WHEN UPPER(request_status) = 'CLOSED' THEN 1 ELSE 0 END AS BIT)
        AS is_recorded_closed,
    is_valid_request, is_valid_duration, duration_validation_status,
    closure_duration_seconds,
    CAST(closure_duration_seconds / 3600.0 AS DECIMAL(18,4)) AS closure_duration_hours,
    ingested_at_utc AS raw_ingested_at_utc,
    first_seen_utc AS core_first_seen_utc,
    last_seen_utc AS core_last_seen_utc
FROM core.vw_request_current
WHERE is_sample = 1 AND is_valid_request = 1;
GO
CREATE OR ALTER VIEW analytics.vw_request_summary_sample
AS
SELECT created_date, agency, problem, borough,
    COUNT_BIG(*) AS requests_received,
    SUM(CAST(is_recorded_closed AS BIGINT)) AS recorded_closed_in_created_cohort,
    SUM(CAST(is_valid_duration AS BIGINT)) AS eligible_durations,
    SUM(CASE WHEN duration_validation_status = 'No recorded closure'
             THEN CAST(1 AS BIGINT) ELSE CAST(0 AS BIGINT) END) AS requests_without_recorded_closure,
    SUM(CASE WHEN duration_validation_status IN ('Invalid closed date', 'Closure precedes creation')
             THEN CAST(1 AS BIGINT) ELSE CAST(0 AS BIGINT) END) AS invalid_closure_timestamps,
    SUM(CAST(closure_duration_seconds AS DECIMAL(28,0))) AS eligible_duration_seconds_total,
    MAX(raw_ingested_at_utc) AS latest_raw_ingestion_utc,
    MAX(core_last_seen_utc) AS latest_core_observation_utc
FROM analytics.vw_request_detail_sample
GROUP BY created_date, agency, problem, borough;
GO
CREATE OR ALTER VIEW analytics.vw_load_quality
AS
SELECT b.batch_id, b.source_name, b.load_status, b.started_at_utc,
    b.completed_at_utc, b.source_row_count, b.loaded_row_count,
    CAST(CASE WHEN b.source_name = 'NYC311_DEV_SAMPLE' THEN 1 ELSE 0 END AS BIT) AS is_sample,
    COALESCE(q.staged_records, 0) AS staged_records,
    COALESCE(q.valid_requests, 0) AS valid_requests,
    COALESCE(q.eligible_durations, 0) AS eligible_durations,
    c.processed_at_utc AS core_processed_at_utc,
    c.accepted_records AS core_accepted_records,
    c.rejected_records AS core_rejected_records,
    c.new_requests, c.changed_requests, c.unchanged_requests
FROM audit.load_batch AS b
LEFT JOIN (
    SELECT batch_id, COUNT_BIG(*) AS staged_records,
        SUM(CAST(is_valid_request AS BIGINT)) AS valid_requests,
        SUM(CAST(is_valid_duration AS BIGINT)) AS eligible_durations
    FROM stg.vw_request_typed GROUP BY batch_id
) AS q ON q.batch_id = b.batch_id
LEFT JOIN audit.core_load_batch AS c ON c.batch_id = b.batch_id
WHERE b.source_name IN ('NYC311', 'NYC311_DEV_SAMPLE') AND b.source_dataset_id = 'erm2-nwe9';
GO
