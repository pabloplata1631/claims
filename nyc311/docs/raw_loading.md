# First DEV raw load

Use the existing SSMS-created audit.load_batch and raw.request_payload tables.
Install nyc311/requirements.txt in the local virtual environment. Run
etl/load_raw.py with an explicit run directory, server, and database.

The initial loader accepts only database names ending in _Dev. Samples additionally
require --allow-dev-sample and are labeled NYC311_DEV_SAMPLE in source_name.
Keep them excluded from future trusted analytics. The sample manifest remains
ineligible for ordinary complete-data loading; do not edit its flag to bypass checks.

The batch and raw rows commit in one transaction. A repeated run ID is rejected
without adding rows. Failed transactions roll back both tables; failures are
currently returned to the caller, not persisted as separate failed audit rows.
Durable failed-attempt audit logging remains a later enhancement.

Checksum verification accepts legacy Windows CRLF representation when the manifest
was hashed as LF. New extraction explicitly writes LF for reproducible checksums.

Windows authentication uses the identity running Python. The optional
--trust-server-certificate flag is an explicit certificate trust exception for
the local DEV SQL server, not a setting for NYC API HTTPS requests.

Loader validation tests run without SQL Server. The actual desktop SQL insert,
transaction rollback, and concurrent-run behavior must be verified on SQL Server;
passing validation tests alone does not establish database integration success.
