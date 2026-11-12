"""Validate an extract and load original observations into the DEV database."""
import argparse
import hashlib
import json
from pathlib import Path


def validate_run(folder, database, allow_sample):
    if not database.lower().endswith('_dev'):
        raise ValueError('This initial loader supports only databases ending in _Dev.')
    if (folder / '_FAILED.json').exists():
        raise ValueError('Failed or canceled extracts cannot be loaded.')
    manifest = json.loads((folder / 'manifest.json').read_text(encoding='utf-8'))
    sample = manifest.get('status') == 'sample'
    if sample:
        if not allow_sample or manifest.get('eligible_for_sql_load') is not False:
            raise ValueError('Sample loads require --allow-dev-sample and an ineligible sample manifest.')
    elif manifest.get('status') != 'extracted' or manifest.get('eligible_for_sql_load') is not True:
        raise ValueError('Manifest does not identify a completed eligible extract.')
    if manifest.get('dataset_id') != 'erm2-nwe9':
        raise ValueError('Unexpected source dataset.')
    run_id = manifest.get('run_id')
    if not isinstance(run_id, str) or not run_id or len(run_id) > 100:
        raise ValueError('Invalid run ID.')
    data = (folder / 'records.jsonl').read_bytes()
    # Older Windows extracts wrote CRLF while hashing the generated LF text.
    if (hashlib.sha256(data).hexdigest() != manifest.get('jsonl_sha256') and
            hashlib.sha256(data.replace(b'\r\n', b'\n')).hexdigest() != manifest.get('jsonl_sha256')):
        raise ValueError('Raw file checksum does not match manifest.')
    records = []
    seen = set()
    for line in data.decode('utf-8').splitlines():
        row = json.loads(line)
        if not isinstance(row, dict):
            raise ValueError('Raw record must be a JSON object.')
        key = row.get('unique_key')
        if not isinstance(key, str) or not key or len(key) > 50 or key in seen:
            raise ValueError('Invalid or duplicate request ID.')
        seen.add(key)
        records.append((key, line))
    if len(records) != manifest.get('extracted_distinct_requests'):
        raise ValueError('Record count does not match manifest.')
    if not records:
        raise ValueError('Empty extracts are not supported by this initial loader.')
    if not sample and any(manifest.get(k) != len(records) for k in
                          ('source_count_before', 'source_count_after')):
        raise ValueError('Complete extract does not reconcile to source counts.')
    count = manifest.get('source_count_before')
    if not isinstance(count, int) or count < len(records):
        raise ValueError('Invalid source count.')
    return manifest, records, sample


def odbc_value(value):
    return '{' + value.replace('}', '}}') + '}'


def load(args):
    manifest, records, sample = validate_run(Path(args.run_dir), args.database, args.allow_dev_sample)
    import pyodbc
    connection_string = (
        'DRIVER={ODBC Driver 18 for SQL Server};'
        f'SERVER={odbc_value(args.server)};DATABASE={odbc_value(args.database)};'
        'Trusted_Connection=yes;Encrypt=yes;'
        f'TrustServerCertificate={"yes" if args.trust_server_certificate else "no"};'
    )
    conn = pyodbc.connect(connection_string, timeout=15, autocommit=False)
    try:
        cursor = conn.cursor()
        cursor.execute('SET XACT_ABORT ON; SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;')
        actual_db = cursor.execute('SELECT DB_NAME()').fetchone()[0]
        if actual_db.lower() != args.database.lower():
            raise ValueError('Connected database differs from requested target.')
        prior = cursor.execute(
            'SELECT batch_id FROM audit.load_batch WITH (UPDLOCK, HOLDLOCK) WHERE run_id = ?',
            manifest['run_id']).fetchone()
        if prior:
            raise ValueError(f'Run already exists as batch {prior[0]}; no duplicate load performed.')
        source = 'NYC311_DEV_SAMPLE' if sample else 'NYC311'
        batch = cursor.execute('''
            INSERT INTO audit.load_batch
                (source_name, source_dataset_id, run_id, source_row_count)
            OUTPUT INSERTED.batch_id VALUES (?, ?, ?, ?)
        ''', source, manifest['dataset_id'], manifest['run_id'], manifest['source_count_before']).fetchone()[0]
        cursor.executemany('''
            INSERT INTO raw.request_payload (batch_id, request_id, payload_json)
            VALUES (?, ?, ?)
        ''', [(batch, key, payload) for key, payload in records])
        loaded = cursor.execute('SELECT COUNT_BIG(*) FROM raw.request_payload WHERE batch_id = ?', batch).fetchone()[0]
        if loaded != len(records):
            raise ValueError('Inserted count does not match validated record count.')
        cursor.execute('''
            UPDATE audit.load_batch SET load_status = 'Succeeded',
                completed_at_utc = SYSUTCDATETIME(), loaded_row_count = ?
            WHERE batch_id = ?
        ''', loaded, batch)
        conn.commit()
        print(json.dumps({'database': actual_db, 'batch_id': batch, 'source_name': source,
                          'loaded_records': loaded, 'status': 'Succeeded'}, indent=2))
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run-dir', required=True)
    parser.add_argument('--server', required=True)
    parser.add_argument('--database', required=True)
    parser.add_argument('--allow-dev-sample', action='store_true')
    parser.add_argument('--trust-server-certificate', action='store_true',
                        help='Explicit certificate trust exception for the local DEV SQL server only')
    load(parser.parse_args())
