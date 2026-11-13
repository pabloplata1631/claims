# SQL build order

Run in SSMS on SQL Server 2019, compatibility 150:

1. 000_dev_database.sql creates NYC_Operations_Dev if absent.
2. 001_schemas.sql creates audit, raw, stg, core, analytics if absent.
3. 010_ingestion.sql creates load audit and raw tables if absent.
4. 020_staging.sql creates or updates the typed staging view.

The user executed initial equivalents in SSMS and verified 100 sample records.
Existing database and tables are preserved by guards, not migrated. Rerun only
the view script when its definition changes. All scripts explicitly target DEV.
Core history and analytics implementation follow later. Legacy claims tables
remain separate. UAT and PROD will be separate databases.
