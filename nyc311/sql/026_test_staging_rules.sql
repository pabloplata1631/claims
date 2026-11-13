-- DEV-only integration test. Fixture inserts are rolled back.
-- Identity counters may advance even though test records do not persist.
USE [NYC_Operations_Dev];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF DB_NAME() <> N'NYC_Operations_Dev'
    THROW 51000, 'Run staging fixture tests only in NYC_Operations_Dev.', 1;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @batch_id BIGINT;
    INSERT INTO audit.load_batch
        (source_name, source_dataset_id, run_id, load_status)
    VALUES ('NYC311_DEV_SAMPLE', 'erm2-nwe9',
        CONCAT('quality-test-', CONVERT(NVARCHAR(36), NEWID())), 'Succeeded');
    SET @batch_id = SCOPE_IDENTITY();

    DECLARE @fixtures TABLE (
        request_id NVARCHAR(50), source_id NVARCHAR(50),
        created_text NVARCHAR(50), closed_text NVARCHAR(50),
        agency NVARCHAR(50), status NVARCHAR(50),
        expected_request BIT, expected_duration BIT, expected_seconds BIGINT
    );
    INSERT INTO @fixtures VALUES
        ('qa-valid', 'qa-valid', '2026-10-01T00:00:00', '2026-10-01T00:01:00', 'DEP', 'Closed', 1, 1, 60),
        ('qa-negative', 'qa-negative', '2026-10-01T00:28:21', '2026-10-01T00:28:00', 'DEP', 'Closed', 1, 0, NULL),
        ('qa-open', 'qa-open', '2026-10-01T00:00:00', NULL, 'DEP', 'Open', 1, 0, NULL),
        ('qa-created', 'qa-created', 'invalid', '2026-10-01T00:01:00', 'DEP', 'Closed', 0, 0, NULL),
        ('qa-closed', 'qa-closed', '2026-10-01T00:00:00', 'invalid', 'DEP', 'Closed', 1, 0, NULL),
        ('qa-agency', 'qa-agency', '2026-10-01T00:00:00', '2026-10-01T00:01:00', NULL, 'Closed', 0, 0, NULL),
        ('qa-id', 'different', '2026-10-01T00:00:00', '2026-10-01T00:01:00', 'DEP', 'Closed', 0, 0, NULL),
        ('qa-zero', 'qa-zero', '2026-10-01T00:00:00', '2026-10-01T00:00:00', 'DEP', 'Closed', 1, 1, 0),
        ('qa-status', 'qa-status', '2026-10-01T00:00:00', '2026-10-01T00:01:00', 'DEP', 'Open', 1, 0, NULL);

    INSERT INTO raw.request_payload (batch_id, request_id, payload_json)
    SELECT @batch_id, f.request_id,
        (SELECT f.source_id AS unique_key, f.created_text AS created_date,
            f.closed_text AS closed_date, f.agency AS agency, f.status AS status
         FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
    FROM @fixtures AS f;

    IF (SELECT COUNT_BIG(*) FROM stg.vw_request_typed WHERE batch_id = @batch_id) <> 9
        THROW 51001, 'Staging did not retain all nine fixture observations.', 1;

    IF EXISTS (
        SELECT 1 FROM @fixtures AS f
        LEFT JOIN stg.vw_request_typed AS s
            ON s.batch_id = @batch_id AND s.request_id = f.request_id
        WHERE s.raw_record_id IS NULL
           OR s.is_valid_request <> f.expected_request
           OR s.is_valid_duration <> f.expected_duration
           OR (s.closure_duration_seconds <> f.expected_seconds)
           OR (s.closure_duration_seconds IS NULL AND f.expected_seconds IS NOT NULL)
           OR (s.closure_duration_seconds IS NOT NULL AND f.expected_seconds IS NULL)
    )
        THROW 51002, 'Staging eligibility or duration differs from expected results.', 1;

    ROLLBACK TRANSACTION;
    SELECT 'Passed' AS test_status, 9 AS fixture_count;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
