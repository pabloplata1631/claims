USE [NYC_Operations_Dev];
GO
CREATE OR ALTER PROCEDURE core.usp_load_request_batch
    @batch_id BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @lock_result INT;
        EXEC @lock_result = sys.sp_getapplock
            @Resource = N'NYC311.core.load', @LockMode = 'Exclusive',
            @LockOwner = 'Transaction', @LockTimeout = 15000;
        IF @lock_result < 0 THROW 51100, 'Could not acquire core load lock.', 1;

        IF EXISTS (SELECT 1 FROM audit.core_load_batch WHERE batch_id = @batch_id)
        BEGIN
            SELECT 'Already processed' AS result, *
            FROM audit.core_load_batch WHERE batch_id = @batch_id;
            COMMIT TRANSACTION;
            RETURN;
        END;

        DECLARE @expected BIGINT;
        SELECT @expected = loaded_row_count FROM audit.load_batch
        WHERE batch_id = @batch_id AND load_status = 'Succeeded'
          AND source_name IN ('NYC311', 'NYC311_DEV_SAMPLE')
          AND source_dataset_id = 'erm2-nwe9';
        IF @expected IS NULL THROW 51101, 'A successful NYC311 raw batch is required.', 1;
        IF @expected <> (SELECT COUNT_BIG(*) FROM raw.request_payload WHERE batch_id = @batch_id)
            THROW 51102, 'Raw count does not reconcile to the batch audit.', 1;

        DECLARE @now DATETIME2(7) = SYSUTCDATETIME();
        -- Track normalized reporting attributes plus original date text.
        -- Audit timestamps and validation flags do not create source versions.
        SELECT s.request_id, s.is_sample, s.raw_record_id,
            CONVERT(BINARY(32), HASHBYTES('SHA2_256', CONVERT(NVARCHAR(MAX), (
                SELECT s.request_id AS request_id,
                    JSON_VALUE(r.payload_json, '$.created_date') AS created_date,
                    JSON_VALUE(r.payload_json, '$.closed_date') AS closed_date,
                    s.agency AS agency, s.problem AS problem,
                    s.request_status AS request_status, s.borough AS borough,
                    s.incident_zip AS incident_zip
                FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
            )))) AS business_hash
        INTO #accepted
        FROM stg.vw_request_typed AS s
        JOIN raw.request_payload AS r ON r.raw_record_id = s.raw_record_id
        WHERE s.batch_id = @batch_id AND s.is_valid_request = 1;

        IF EXISTS (
            SELECT 1 FROM #accepted AS s JOIN core.request_current AS c
              ON c.request_id = s.request_id AND c.is_sample = s.is_sample
            WHERE c.last_batch_id >= @batch_id
        ) THROW 51103, 'An older batch cannot overwrite a newer accepted observation.', 1;

        DECLARE @accepted BIGINT = (SELECT COUNT_BIG(*) FROM #accepted);
        DECLARE @new BIGINT = (
            SELECT COUNT_BIG(*) FROM #accepted AS s
            WHERE NOT EXISTS (SELECT 1 FROM core.request_current AS c
                WHERE c.request_id = s.request_id AND c.is_sample = s.is_sample));
        DECLARE @changed BIGINT = (
            SELECT COUNT_BIG(*) FROM #accepted AS s
            JOIN core.request_current AS c ON c.request_id = s.request_id AND c.is_sample = s.is_sample
            JOIN core.request_version AS v ON v.request_version_id = c.request_version_id
            WHERE v.business_hash <> s.business_hash);

        UPDATE v SET observed_to_utc = @now
        FROM core.request_version AS v
        JOIN core.request_current AS c ON c.request_version_id = v.request_version_id
        JOIN #accepted AS s ON s.request_id = c.request_id AND s.is_sample = c.is_sample
        WHERE v.business_hash <> s.business_hash;

        INSERT INTO core.request_version
            (request_id, is_sample, raw_record_id, batch_id, business_hash, observed_from_utc)
        SELECT s.request_id, s.is_sample, s.raw_record_id, @batch_id, s.business_hash, @now
        FROM #accepted AS s
        LEFT JOIN core.request_current AS c ON c.request_id = s.request_id AND c.is_sample = s.is_sample
        LEFT JOIN core.request_version AS v ON v.request_version_id = c.request_version_id
        WHERE c.request_id IS NULL OR v.business_hash <> s.business_hash;

        UPDATE c SET request_version_id = COALESCE(v.request_version_id, c.request_version_id),
            last_raw_record_id = s.raw_record_id, last_batch_id = @batch_id, last_seen_utc = @now
        FROM core.request_current AS c
        JOIN #accepted AS s ON s.request_id = c.request_id AND s.is_sample = c.is_sample
        LEFT JOIN core.request_version AS v ON v.request_id = s.request_id
            AND v.is_sample = s.is_sample AND v.batch_id = @batch_id;

        INSERT INTO core.request_current
            (request_id, is_sample, request_version_id, last_raw_record_id,
             last_batch_id, first_seen_utc, last_seen_utc)
        SELECT s.request_id, s.is_sample, v.request_version_id, s.raw_record_id, @batch_id, @now, @now
        FROM #accepted AS s
        JOIN core.request_version AS v ON v.request_id = s.request_id
            AND v.is_sample = s.is_sample AND v.batch_id = @batch_id
        WHERE NOT EXISTS (SELECT 1 FROM core.request_current AS c
            WHERE c.request_id = s.request_id AND c.is_sample = s.is_sample);

        INSERT INTO audit.core_load_batch
            (batch_id, processed_at_utc, accepted_records, rejected_records,
             new_requests, changed_requests, unchanged_requests)
        VALUES (@batch_id, @now, @accepted, @expected - @accepted,
            @new, @changed, @accepted - @new - @changed);
        COMMIT TRANSACTION;
        SELECT 'Processed' AS result, * FROM audit.core_load_batch WHERE batch_id = @batch_id;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER VIEW core.vw_request_current
AS
SELECT c.request_version_id, c.first_seen_utc, c.last_seen_utc, s.*
FROM core.request_current AS c
JOIN stg.vw_request_typed AS s ON s.raw_record_id = c.last_raw_record_id;
GO
