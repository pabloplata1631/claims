-- Guards preserve existing tables; they do not migrate incompatible schemas.
USE [NYC_Operations_Dev];
GO
IF OBJECT_ID(N'audit.load_batch', N'U') IS NULL
BEGIN
    CREATE TABLE audit.load_batch (
        batch_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        source_name NVARCHAR(100) NOT NULL,
        source_dataset_id NVARCHAR(50) NOT NULL,
        run_id NVARCHAR(100) NOT NULL,
        started_at_utc DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
        completed_at_utc DATETIME2(3) NULL,
        load_status VARCHAR(20) NOT NULL DEFAULT 'Started',
        source_row_count BIGINT NULL,
        loaded_row_count BIGINT NULL,
        error_message NVARCHAR(MAX) NULL,
        CONSTRAINT UQ_load_batch_run_id UNIQUE (run_id),
        CONSTRAINT CK_load_batch_status CHECK
            (load_status IN ('Started', 'Succeeded', 'Failed')),
        CONSTRAINT CK_load_batch_counts CHECK (
            (source_row_count IS NULL OR source_row_count >= 0) AND
            (loaded_row_count IS NULL OR loaded_row_count >= 0))
    );
END;
GO
IF OBJECT_ID(N'raw.request_payload', N'U') IS NULL
BEGIN
    CREATE TABLE raw.request_payload (
        raw_record_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        batch_id BIGINT NOT NULL,
        request_id NVARCHAR(50) NOT NULL,
        payload_json NVARCHAR(MAX) NOT NULL,
        ingested_at_utc DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_request_payload_batch FOREIGN KEY (batch_id)
            REFERENCES audit.load_batch (batch_id),
        CONSTRAINT UQ_request_payload_batch_request UNIQUE (batch_id, request_id),
        CONSTRAINT CK_request_payload_valid_json CHECK (ISJSON(payload_json) = 1)
    );
END;
GO
