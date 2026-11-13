# SQL build order

Run in SSMS on SQL Server 2019, compatibility 150:

1. 000_dev_database.sql creates NYC_Operations_Dev if absent.
2. 001_schemas.sql creates audit, raw, stg, core, analytics if absent.
3. 010_ingestion.sql creates load audit and raw tables if absent.
4. 020_staging.sql creates or updates the typed staging view.
5. 025_validate_staging.sql reads counts, eligibility, and the known negative-duration case.
6. 026_test_staging_rules.sql tests nine cases with rolled-back DEV fixture inserts.
7. 030_core_tables.sql creates current/version pointers and the core load audit.
8. 031_core_load.sql creates the transactional core loader and current view.
9. 032_validate_core.sql processes batch 1, checks results, and verifies a safe rerun.
10. 033_test_core_history.sql tests seven transactional history scenarios and rolls back fixtures.
11. 040_analytics_views.sql creates separate sample/full detail and summary views, plus load quality.
12. 041_validate_analytics.sql reconciles reporting counts and checks five groups of invariants.

The user executed initial equivalents in SSMS and verified 100 sample records.
Existing database and tables are preserved by guards, not migrated. Rerun only
the view script when its definition changes. All scripts explicitly target DEV.
The user has verified core scripts 030-033, including all seven scenarios.
Analytics scripts 040-041 still require desktop execution. Legacy claims tables
remain separate. UAT and PROD will be separate databases.

The user has applied and verified the updated staging view and passed all nine
staging fixture cases. See docs/validation.md for results. Publishing subsequent
core code does not establish that it has been executed against SQL Server.
