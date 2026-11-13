-- DEV-only integration checks. All fixture data is rolled back.
-- Identity values may advance. Run after 030 and 031.
USE [NYC_Operations_Dev];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME() <> N'NYC_Operations_Dev'
    THROW 51200, 'Use only NYC_Operations_Dev.', 1;
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @id NVARCHAR(50) = CONCAT('qa-', CONVERT(NVARCHAR(36), NEWID()));
    DECLARE @payload NVARCHAR(MAX) = (
        SELECT @id AS unique_key, '2026-10-01T00:00:00' AS created_date,
            'DEP' AS agency, 'History test' AS complaint_type,
            'Open' AS status, 'BROOKLYN' AS borough
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
    DECLARE @batch BIGINT, @first BIGINT, @latest BIGINT;

    INSERT audit.load_batch (source_name, source_dataset_id, run_id, load_status, loaded_row_count)
    VALUES ('NYC311_DEV_SAMPLE', 'erm2-nwe9', CONCAT(@id, '-1'), 'Succeeded', 1);
    SET @batch = SCOPE_IDENTITY(); SET @first = @batch;
    INSERT raw.request_payload (batch_id, request_id, payload_json) VALUES (@batch, @id, @payload);
    EXEC core.usp_load_request_batch @batch_id = @batch;
    IF (SELECT new_requests FROM audit.core_load_batch WHERE batch_id = @batch) <> 1
        THROW 51201, 'New request was not recorded.', 1;

    EXEC core.usp_load_request_batch @batch_id = @batch;
    IF (SELECT COUNT_BIG(*) FROM core.request_version WHERE request_id = @id) <> 1
        THROW 51202, 'Repeat batch created an extra version.', 1;

    INSERT audit.load_batch (source_name, source_dataset_id, run_id, load_status, loaded_row_count)
    VALUES ('NYC311_DEV_SAMPLE', 'erm2-nwe9', CONCAT(@id, '-2'), 'Succeeded', 1);
    SET @batch = SCOPE_IDENTITY();
    INSERT raw.request_payload (batch_id, request_id, payload_json) VALUES (@batch, @id, @payload);
    EXEC core.usp_load_request_batch @batch_id = @batch;
    IF (SELECT unchanged_requests FROM audit.core_load_batch WHERE batch_id = @batch) <> 1
       OR (SELECT COUNT_BIG(*) FROM core.request_version WHERE request_id = @id) <> 1
       OR (SELECT last_batch_id FROM core.request_current WHERE request_id = @id AND is_sample = 1) <> @batch
        THROW 51203, 'Unchanged observation did not retain one version and advance last seen.', 1;

    SET @payload = JSON_MODIFY(@payload, '$.closed_date', '2026-10-01T00:01:00');
    SET @payload = JSON_MODIFY(@payload, '$.status', 'Closed');
    INSERT audit.load_batch (source_name, source_dataset_id, run_id, load_status, loaded_row_count)
    VALUES ('NYC311_DEV_SAMPLE', 'erm2-nwe9', CONCAT(@id, '-3'), 'Succeeded', 1);
    SET @batch = SCOPE_IDENTITY(); SET @latest = @batch;
    INSERT raw.request_payload (batch_id, request_id, payload_json) VALUES (@batch, @id, @payload);
    EXEC core.usp_load_request_batch @batch_id = @batch;
    IF (SELECT changed_requests FROM audit.core_load_batch WHERE batch_id = @batch) <> 1
       OR (SELECT COUNT_BIG(*) FROM core.request_version WHERE request_id = @id) <> 2
       OR (SELECT closure_duration_seconds FROM core.vw_request_current WHERE request_id = @id AND is_sample = 1) <> 60
        THROW 51204, 'Changed request history or current value is incorrect.', 1;

    INSERT audit.load_batch (source_name, source_dataset_id, run_id, load_status, loaded_row_count)
    VALUES ('NYC311_DEV_SAMPLE', 'erm2-nwe9', CONCAT(@id, '-4'), 'Succeeded', 1);
    SET @batch = SCOPE_IDENTITY();
    INSERT raw.request_payload (batch_id, request_id, payload_json)
    VALUES (@batch, @id, JSON_MODIFY(@payload, '$.created_date', 'invalid'));
    EXEC core.usp_load_request_batch @batch_id = @batch;
    IF (SELECT rejected_records FROM audit.core_load_batch WHERE batch_id = @batch) <> 1
       OR (SELECT last_batch_id FROM core.request_current WHERE request_id = @id AND is_sample = 1) <> @latest
        THROW 51205, 'Invalid observation replaced the accepted current state.', 1;

    -- Full-source namespace is simulated only inside this rolled-back test.
    INSERT audit.load_batch (source_name, source_dataset_id, run_id, load_status, loaded_row_count)
    VALUES ('NYC311', 'erm2-nwe9', CONCAT(@id, '-5'), 'Succeeded', 1);
    SET @batch = SCOPE_IDENTITY();
    INSERT raw.request_payload (batch_id, request_id, payload_json) VALUES (@batch, @id, @payload);
    EXEC core.usp_load_request_batch @batch_id = @batch;
    IF (SELECT COUNT_BIG(*) FROM core.request_current WHERE request_id = @id) <> 2
       OR (SELECT new_requests FROM audit.core_load_batch WHERE batch_id = @batch) <> 1
        THROW 51206, 'Sample and full-source namespaces are not separate.', 1;

    IF (SELECT COUNT_BIG(*) FROM core.request_version WHERE request_id = @id AND observed_to_utc IS NULL) <> 2
       OR (SELECT COUNT_BIG(*) FROM raw.request_payload WHERE request_id = @id) <> 5
        THROW 51207, 'Open-version or raw-retention invariant failed.', 1;

    ROLLBACK TRANSACTION;
    SELECT 'Passed' AS test_status, 7 AS scenario_count;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
