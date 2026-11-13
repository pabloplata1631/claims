-- DEV only. Preserve existing objects; guards are not migrations.
USE [NYC_Operations_Dev];
GO
IF OBJECT_ID(N'core.request_version', N'U') IS NULL
BEGIN
    CREATE TABLE core.request_version (
        request_version_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        request_id NVARCHAR(50) NOT NULL,
        is_sample BIT NOT NULL,
        raw_record_id BIGINT NOT NULL,
        batch_id BIGINT NOT NULL,
        business_hash BINARY(32) NOT NULL,
        observed_from_utc DATETIME2(7) NOT NULL,
        observed_to_utc DATETIME2(7) NULL,
        CONSTRAINT FK_request_version_raw FOREIGN KEY (raw_record_id)
            REFERENCES raw.request_payload(raw_record_id),
        CONSTRAINT FK_request_version_batch FOREIGN KEY (batch_id)
            REFERENCES audit.load_batch(batch_id),
        CONSTRAINT CK_request_version_interval CHECK
            (observed_to_utc IS NULL OR observed_to_utc >= observed_from_utc)
    );
    CREATE UNIQUE INDEX UX_request_version_open
        ON core.request_version(request_id, is_sample)
        WHERE observed_to_utc IS NULL;
END;
GO
IF OBJECT_ID(N'core.request_current', N'U') IS NULL
BEGIN
    CREATE TABLE core.request_current (
        request_id NVARCHAR(50) NOT NULL,
        is_sample BIT NOT NULL,
        request_version_id BIGINT NOT NULL,
        last_raw_record_id BIGINT NOT NULL,
        last_batch_id BIGINT NOT NULL,
        first_seen_utc DATETIME2(7) NOT NULL,
        last_seen_utc DATETIME2(7) NOT NULL,
        CONSTRAINT PK_request_current PRIMARY KEY (request_id, is_sample),
        CONSTRAINT FK_request_current_version FOREIGN KEY (request_version_id)
            REFERENCES core.request_version(request_version_id),
        CONSTRAINT FK_request_current_raw FOREIGN KEY (last_raw_record_id)
            REFERENCES raw.request_payload(raw_record_id),
        CONSTRAINT FK_request_current_batch FOREIGN KEY (last_batch_id)
            REFERENCES audit.load_batch(batch_id)
    );
END;
GO
IF OBJECT_ID(N'audit.core_load_batch', N'U') IS NULL
BEGIN
    CREATE TABLE audit.core_load_batch (
        batch_id BIGINT PRIMARY KEY,
        processed_at_utc DATETIME2(7) NOT NULL,
        accepted_records BIGINT NOT NULL,
        rejected_records BIGINT NOT NULL,
        new_requests BIGINT NOT NULL,
        changed_requests BIGINT NOT NULL,
        unchanged_requests BIGINT NOT NULL,
        CONSTRAINT FK_core_load_batch_raw_batch FOREIGN KEY (batch_id)
            REFERENCES audit.load_batch(batch_id)
    );
END;
GO
