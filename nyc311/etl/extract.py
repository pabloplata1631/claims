"""Extract a bounded NYC 311 cohort without overwriting previous observations."""
import argparse
import csv
import datetime as dt
import hashlib
import json
import os
import ssl
from pathlib import Path
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid

ROOT = Path(__file__).resolve().parents[1]
ENDPOINT = "https://data.cityofnewyork.us/resource/erm2-nwe9.json"
METADATA = "https://data.cityofnewyork.us/api/views/erm2-nwe9.json"


def quote(value):
    return "'" + str(value).replace("'", "''") + "'"


def cohort_filter(borough, start, end):
    start_date = dt.date.fromisoformat(start)
    end_date = dt.date.fromisoformat(end)
    if start_date >= end_date:
        raise ValueError("Start must precede exclusive end date")
    return (f"borough={quote(borough)} AND created_date >= "
            f"{quote(start + 'T00:00:00')} AND created_date < "
            f"{quote(end + 'T00:00:00')}")


def fetch(url, params=None, attempts=4, timeout=60):
    context = None
    if os.name == "nt":
        import truststore
        context = truststore.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
    if params:
        url += "?" + urllib.parse.urlencode(params)
    headers = {"User-Agent": "nyc311-portfolio/0.1"}
    token = os.environ.get("SOCRATA_APP_TOKEN")
    if token:
        headers["X-App-Token"] = token
    for attempt in range(attempts):
        try:
            with urllib.request.urlopen(
                urllib.request.Request(url, headers=headers), timeout=timeout, context=context
            ) as response:
                return json.load(response)
        except urllib.error.HTTPError as exc:
            if exc.code not in (429, 500, 502, 503, 504) or attempt == attempts - 1:
                raise
            time.sleep(min(30, 2 ** attempt))
        except (urllib.error.URLError, TimeoutError):
            if attempt == attempts - 1:
                raise
            time.sleep(min(30, 2 ** attempt))


def pages(where, page_size, max_records, get):
    """Keyset pagination on created date with request ID as a stable tie-breaker."""
    last_key = None
    last_date = None
    seen = set()
    while True:
        limit = page_size if max_records is None else min(page_size, max_records - len(seen))
        if limit <= 0:
            return
        filtered = where
        if last_key is not None:
            filtered += (f" AND (created_date > {quote(last_date)} OR "
                         f"(created_date = {quote(last_date)} AND unique_key > {quote(last_key)}))")
        rows = get({"$where": filtered, "$order": "created_date ASC, unique_key ASC", "$limit": limit})
        if not isinstance(rows, list):
            raise ValueError("API did not return a list")
        if not rows:
            return
        for row in rows:
            key = row.get("unique_key")
            created = row.get("created_date")
            if not isinstance(key, str) or not key or key in seen:
                raise ValueError("Missing, invalid or duplicate request ID")
            if not isinstance(created, str) or not created:
                raise ValueError("Missing created date")
            if last_key is not None and (created, key) <= (last_date, last_key):
                raise ValueError("Non-increasing source pagination key")
            seen.add(key)
            last_key = key
            last_date = created
        yield rows
        if len(rows) < limit:
            return


def validate_count(expected, actual, sample):
    if not sample and expected != actual:
        raise ValueError(f"Source reconciliation failed: expected {expected}, got {actual}")


def run(args):
    config = json.loads((ROOT / "config/extract.json").read_text())
    where = cohort_filter(args.borough or config["borough"], args.start, args.end)
    if args.max_records is not None and args.max_records <= 0:
        raise ValueError("--max-records must be positive")
    sample = args.max_records is not None
    started = dt.datetime.now(dt.timezone.utc)
    run_id = started.strftime("%Y%m%dT%H%M%S%fZ") + "_" + uuid.uuid4().hex[:8]
    base = ROOT / "data" / ("samples" if sample else "raw")
    output = base / ("run_" + run_id)
    output.mkdir(parents=True, exist_ok=False)
    get = lambda params: fetch(ENDPOINT, params, config["retry_attempts"], config["timeout_seconds"])
    try:
        metadata = fetch(METADATA)
        (output / "schema.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
        expected = int(get({"$select": "count(*) AS n", "$where": where})[0]["n"])
        count = 0
        fields = set()
        digest = hashlib.sha256()
        with (output / "records.jsonl").open("w", encoding="utf-8", newline="\n") as handle:
            for batch in pages(where, config["page_size"], args.max_records, get):
                for row in batch:
                    line = json.dumps(row, sort_keys=True, ensure_ascii=False) + "\n"
                    handle.write(line)
                    digest.update(line.encode("utf-8"))
                    fields.update(row)
                    count += 1
        expected_after = int(get({"$select": "count(*) AS n", "$where": where})[0]["n"])
        validate_count(expected, count, sample)
        validate_count(expected_after, count, sample)
        names = ["unique_key"] + sorted(fields - {"unique_key"})
        with (output / "records.csv").open("w", newline="", encoding="utf-8-sig") as csv_file:
            writer = csv.DictWriter(csv_file, fieldnames=names)
            writer.writeheader()
            with (output / "records.jsonl").open(encoding="utf-8") as rows:
                for line in rows:
                    row = json.loads(line)
                    writer.writerow({k: json.dumps(v, ensure_ascii=False) if isinstance(v, (dict, list)) else v
                                     for k, v in row.items()})
        manifest = {
            "run_id": run_id, "status": "sample" if sample else "extracted",
            "dataset_id": config["dataset_id"], "endpoint": ENDPOINT,
            "filter": where, "started_at_utc": started.isoformat(),
            "finished_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
            "source_count_before": expected, "source_count_after": expected_after,
            "extracted_distinct_requests": count, "sample_limit": args.max_records,
            "eligible_for_sql_load": not sample,
            "jsonl_sha256": digest.hexdigest(),
            "consistency": "Observed API extract, not transactionally frozen source history",
        }
        (output / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
        print(json.dumps({"output": str(output), **manifest}, indent=2))
    except (Exception, KeyboardInterrupt) as exc:
        (output / "_FAILED.json").write_text(json.dumps({"run_id": run_id, "error": str(exc)}), encoding="utf-8")
        raise


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--start", required=True, help="Inclusive NYC created date YYYY-MM-DD")
    parser.add_argument("--end", required=True, help="Exclusive NYC created date YYYY-MM-DD")
    parser.add_argument("--borough")
    parser.add_argument("--max-records", type=int, help="Sample only; omit for a complete cohort extract")
    run(parser.parse_args())
