# Current records and observed versions

Implementation prepared; execution against the user's SQL Server is pending.
Apply 030_core_tables.sql then 031_core_load.sql before 032_validate_core.sql.
The last script loads batch 1 and verifies a repeat call makes no additional rows.

## Storage and keys

core.request_current has one accepted record per request_id and is_sample.
It points to the current modeled version and most recent accepted raw observation.
Sample records and full extracts are separate key spaces; trusted analytics must
filter is_sample = 0. All raw observations remain intact.

core.request_version stores a pointer to the starting raw observation of each
modeled version, SHA256 hash, and processing-time observation interval. The tracked
fields are request ID, original created/closed date text, normalized agency,
problem, status, borough, and ZIP. Changes in unmodeled fields such as resolution
description alone do not create modeled versions; they remain in raw observations.
The current view joins the latest accepted raw record to the staging definition.
Validation flags are recalculated by the current rules, not frozen rule history.

## Loading behavior

The procedure serializes core loads with a database application lock. Each batch
commits as one transaction and gets audit.core_load_batch counts. Repeated processed
batches return a no-op. Overlapping older batches are rejected rather than replacing
newer accepted observations. Batch IDs represent ingestion order, not source events.

Invalid requests remain in raw/staging and are counted as rejected by core. A later
invalid observation does not replace an earlier accepted current record. Current
therefore means last accepted observation, not necessarily latest source state;
monitor rejected counts and last-seen time before interpreting freshness. Missing
requests do not trigger deletions or closures.

Version boundaries are the time the core loader processed the change, not the
source's exact effective time, and not a complete event log. Daily snapshots,
as-of backlog reporting, incremental extraction, and durable failure-attempt
logging remain future work.

## First batch acceptance

Given the user's validated sample, expect 100 current sample requests, 100 initial
versions, 100 new requests, zero changes, and zero rejects. Repeating batch 1 must
leave 100 current rows and 100 versions. Request 70592679 must remain a valid request
with an ineligible NULL duration. Changed/unchanged/new-batch integration scenarios
are tested by 033_test_core_history.sql, which is prepared but not yet executed.
It covers new, repeated, unchanged, changed, invalid, namespace separation, and
retention invariants. It rolls back its data but can advance identity counters.
Older-batch rejection, concurrent sessions, and failure recovery require further
integration testing before a production-ready claim.
