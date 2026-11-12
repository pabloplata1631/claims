# SQL implementation sequence (planned)

Use an isolated NYC 311 database initially, or dedicated schemas in the existing
database after confirming its name and existing objects. Do not alter the legacy
claims tables. DEV/UAT/PROD should use separate databases where practical, with
identical object names and environment-specific connection configuration.

1. `001_schemas.sql`: `audit`, `raw`, `stg`, `core`, `analytics`.
2. `010_ingestion.sql`: audit batch and append-only raw JSON payload tables.
3. `020_staging.sql`: typed cleaning views plus a rejected-record table.
4. `030_history.sql`: current requests, hash-based observed versions, daily snapshots.
5. `040_analytics.sql`: request detail, demand, closures, aging and data quality views.
6. `050_validation.sql`: uniqueness, date logic, reconciliation and idempotency checks.

These filenames specify the intended order; SQL execution scripts are not
implemented yet. The loader should use parameterized statements and transactions,
advance successful-load state only on commit, and retain failed-batch evidence.
