# Raw extracts

Runtime data lives in `run_<UTC timestamp>_<unique suffix>/` directories. Each
successful run holds original API records, CSV, source schema, and a manifest.
Never overwrite earlier runs. Full data files are excluded from Git; retain them
on the machine or selected durable storage alongside SQL backups.

A `_FAILED.json` marker means extraction failed or did not reconcile. That run
must not be loaded. Only a successful manifest is eligible for loading, and a
sample manifest is never eligible for a production load.
