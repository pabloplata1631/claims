# SQL build order

Run in SSMS on SQL Server 2019, compatibility 150:

1. 000_dev_database.sql creates NYC_Operations_Dev if absent.
2. 001_schemas.sql creates audit, raw, stg, core, analytics if absent.
3. 010_ingestion.sql creates load audit and raw tables if absent.
4. 020_staging.sql creates or updates the typed staging view.
5. 025_validate_staging.sql reads counts, eligibility, and the known negative-duration case.
6. 026_test_staging_rules.sql tests nine cases with rolled-back DEV fixture inserts.

The user executed initial equivalents in SSMS and verified 100 sample records.
Existing database and tables are preserved by guards, not migrated. Rerun only
the view script when its definition changes. All scripts explicitly target DEV.
Core history and analytics implementation follow later. Legacy claims tables
remain separate. UAT and PROD will be separate databases.

The updated view retains the original validation_status and adds independent
request and duration eligibility. It must be applied in SSMS before running the
new checks. Desktop integration execution is pending; code publication is not
evidence that SQL Server has received a new view definition.
