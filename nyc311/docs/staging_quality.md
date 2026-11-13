# Separate request and duration validity

The initial validation_status column is preserved for compatibility and retains
the first issue in the original rule order. New request_validation_status and
duration_validation_status explain metric eligibility separately.

A request passes initial request rules when the JSON request ID matches its raw
key, creation parses, and agency is populated. This is a limited rule set, not a
claim that every field is correct. It does not deduplicate observations across
different batches; current-state selection will be implemented in core.

A duration requires a valid request, a parseable closure timestamp on or after
creation, and recorded status Closed. Missing closure on an open request is
ineligible for duration metrics, not automatically a bad request. Invalid
durations are NULL, never zero. A zero duration is retained only when valid
source timestamps are actually equal. Durations are nominal source-local seconds;
UTC normalization and daylight-saving ambiguity handling remain to be designed.

Both sample and complete successful batches remain visible in staging. Future
trusted analytics must exclude is_sample = 1 and select one current observation
per request. Do not count all staging observations as unique current requests.

Apply sql/020_staging.sql in SSMS, then sql/025_validate_staging.sql. For batch 1,
expect 100 total records and 100 passing the request rules based on the supplied
initial validation. The duration-eligible count depends on closure/status coverage;
do not assume it is 99. Request 70592679 should have is_valid_request = 1,
is_valid_duration = 0, and NULL closure_duration_seconds.

sql/026_test_staging_rules.sql provides transactional fixture tests for SQL Server.
It inserts test observations then rolls them back. Identity counters can advance
despite rollback. It is DEV-only and should run after the updated view is applied.
No SQL execution against the desktop server is claimed until the user runs it.
