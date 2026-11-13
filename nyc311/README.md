# NYC 311 Operations Intelligence

Portfolio simulation using actual public service-request records. This is not
work commissioned by NYC or a previous employer. Stakeholder exercises will be
labeled simulated unless an actual reviewer participates.

## Business problem

A manager can see request volumes in an operational report but needs a consistent
way to investigate incoming demand, aging requests, and time to recorded closure.
This project will add a daily, auditable data process and governed analytics,
then an evidence-based AI assistant.

## Current delivery status

Implemented and locally checked: API extractor, immutable per-run file layout,
sample mode, raw-field preservation, source schema capture, reconciliation
manifest, unit tests, and CI configuration.

Also implemented: a DEV-only raw loader with explicit sample opt-in, manifest and
checksum checks, a transaction for batch plus raw rows, and duplicate-run rejection.
Windows extraction uses the OS certificate store through truststore.

Initial typed staging SQL and an enhancement separating request and duration
eligibility are now versioned under sql/. The user verified the original view
on 100 desktop sample records; the enhanced view and fixture tests still require
execution in SSMS. See docs/staging_quality.md and docs/data_quality_case_001.md.

Designed, not implemented or deployed: core history
tables, daily scheduling, Power BI report, workspace promotion, app, and agent.
Confirmed user environment: SQL Server 2019, compatibility 150, Windows
authentication, and NYC_Operations_Dev with audit.load_batch and raw.request_payload
created through SSMS. The user loaded and reconciled 100 sample rows in batch 1.
Local Python connectivity succeeded. This development
environment does not have direct access to that desktop database.

## Source and scope

- [NYC official dataset](https://data.cityofnewyork.us/Social-Services/311-Service-Requests-from-2020-to-Present/erm2-nwe9)
- API: `https://data.cityofnewyork.us/resource/erm2-nwe9.json`
- Dataset metadata: `https://data.cityofnewyork.us/api/views/erm2-nwe9.json`
- Initial scope: Brooklyn, beginning with a 90-day created-date cohort.
- Source publishes daily; execution of our daily job is not configured yet.
- Display labels now use Problem and Problem Detail. API names remain
  `complaint_type` and `descriptor`.

## Folder map

| Folder | Purpose |
| --- | --- |
| `config/` | Non-secret extraction settings |
| `data/raw/` | Local full extracts partitioned by observation time; ignored by Git |
| `data/samples/` | Local limited extracts for connection and import checks |
| `etl/` | API extraction now; SQL load/orchestration to follow |
| `sql/` | Schema, cleaning, history, and reporting SQL implementation stages |
| `powerbi/` | Report source, theme, and semantic-model documentation |
| `tests/` | Automated data-process checks |
| `docs/` | Architecture, metric definitions, change requests, UAT, release evidence |
| `agent/` | Future agent tools, instructions, and evaluation cases |

## Run a small extract

Python 3.10+. Install dependencies with `python -m pip install -r nyc311/requirements.txt`.
Run from the repository root:

```bash
python nyc311/etl/extract.py --start 2026-10-01 --end 2026-10-02 --max-records 100
python -m unittest discover -s nyc311/tests -v
```

The fixed dates above are a reproducible sample, not a daily refresh schedule.
Outputs are `records.jsonl`, `records.csv`, `schema.json`, and `manifest.json`
inside a unique run directory printed by the command. Limited extracts are
explicitly marked `sample`; they must never populate production analytics.
CSV is for SSMS import inspection; JSONL preserves the returned values.

For a complete extraction of the selected cohort, omit `--max-records`. Set
`SOCRATA_APP_TOKEN` in the process environment if available; it is never written
to output. Run-level checks require API row count = extracted distinct keys.
Source mutations during extraction can cause reconciliation to fail; rerun rather
than loading a partial result. The API does not provide a transactionally frozen
snapshot, so equal counts alone cannot prove no records changed mid-extract.

## Design and delivery

- [Architecture and history](docs/architecture.md)
- [Metric definitions](docs/metrics.md)
- [Delivery stages and release example](docs/delivery.md)
- [Connection checklist](docs/connections.md)
- [Foundation validation evidence](docs/validation.md)

Raw data is not the same as a report source. Future Power BI access will use
`analytics` views; source fields remain available in `raw` for audit and reprocessing.
No credentials, complete raw dumps, or fabricated approvals belong in Git.
