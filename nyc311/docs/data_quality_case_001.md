# Case 001 Closure precedes creation

## Observed evidence

The user executed the DEV loader and verified batch 1 in SSMS: source name
NYC311_DEV_SAMPLE, source count 4172, loaded count 100, actual raw count 100.
This is a limited October 1, 2026 Brooklyn sample, not a full source reconciliation.

Initial staging returned 99 Passed and 1 Closure precedes creation.
Request 70592679, DEP, Water Maintenance, recorded status Closed:

- Created: 2026-10-01 00:28:21.000
- Recorded closed: 2026-10-01 00:28:00.000
- Nominal difference: negative 21 seconds.

The supplied resolution describes a duplicate of an earlier complaint. It does
not establish why the timestamps differ. Rounding or source conventions are
hypotheses, not confirmed causes. Closing a duplicate does not prove the water
issue was resolved.

## Agreed treatment

Preserve the original timestamps and request. Retain a valid request in demand
counts and preserve its recorded closed status. Exclude invalid duration from
closure-time metrics and surface the issue in quality reporting. Do not replace
the duration with zero or delete the raw record.

## Implementation tracking

Initial SQL scripts reproduce the objects executed by the user in SSMS.
The updated staging view adds separate request and duration validity flags.
The user must apply the new definition and run its validation before deployment
can be marked verified. Negative durations become NULL without changing raw data. The assistant
cannot execute SQL directly against the user's desktop database.
