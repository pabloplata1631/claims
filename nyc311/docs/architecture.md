# Architecture and history

## Separate the two pipelines

The data pipeline retrieves and processes records daily. The deployment pipeline
promotes tested report/model changes between environments. Promoting a report
does not ingest data, migrate SQL schemas, or copy a complete database.

## Proposed database layers

| Layer | Objects | Purpose |
| --- | --- | --- |
| `audit` | `load_batch`, `quality_result` | Run state, bounds, counts, errors, reconciliation |
| `raw` | `request_payload` | Append-only returned JSON keyed by batch and request ID |
| `stg` | `vw_request_typed`, rejected records | Safe casts, standardization, validation |
| `core` | `request_current`, `request_version`, `request_daily_snapshot` | Trusted current state and observation history |
| `analytics` | Detail, demand, closure, aging, quality views | Stable Power BI and future agent contract |

`stg` and `analytics` can initially be views. Use tables where materialization,
history, or measured performance requires them. Keep business rules in versioned
SQL rather than duplicating them in each visual and agent prompt.

## History semantics

- Preserve every successful raw run so transformations can be reproduced.
- `request_version` records changed business payloads with observed-from/to UTC
  timestamps and a content hash. Exclude ingestion and source-system modification
  timestamps from the business hash. Source full republishing need not create
  false business changes.
- A daily snapshot records the trusted state as observed on that day. Reruns use
  a documented replace-for-that-day rule in one transaction to avoid duplicate days.
- Neither structure proves every intermediate source event occurred. History
  begins at first observation; source-side corrections and reversals are possible.
- Source calendar timestamps are NYC local time; retain their original values.
  Store extraction and observation timestamps in UTC. Handle daylight-saving
  ambiguity explicitly when deriving exact elapsed hours; disclose the rule.
- Missing records are not automatically deletions. Reconcile a complete scoped
  extract before investigating missing keys; never close them just because an API
  call failed or the date window changed.

## Daily strategy

Phase 1 uses full extracts of a bounded Brooklyn cohort for correctness and a
simple reconciliation baseline. Freeze the initial created-date start; advance
the end each day and keep tracking loaded requests after they age past 90 days.
Only use the rolling 90-day filter for report demand analysis, not for deleting
previously tracked records. Label backlog as the backlog of the tracked cohort,
not the full historical Brooklyn backlog.

When scale justifies it, add incremental extraction using verified API system
modification fields, an overlap window and a checkpoint that advances only after
a successful database commit. Do not use Created Date alone, and do not assume
Resolution Action Updated Date captures all changes. Periodic complete cohort
reconciliation remains necessary. System modification timestamps may move for
every record if the publisher replaces the dataset.

Daily execution should initially use a Windows scheduler on the machine that
can reach SQL Server. Confirm SQL edition before assuming SQL Server Agent exists.
A hosted GitHub runner cannot automatically reach a private desktop database.
Choose gateway and scheduler configuration after inspecting the actual environment.

## Source references

- https://dev.socrata.com/docs/system-fields.html
- https://www.nyc.gov/opendata/news/all-news/311-Service-Requests-Updates
- https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-overview
- https://learn.microsoft.com/en-us/fabric/cicd/deployment-pipelines/get-started-with-deployment-pipelines
