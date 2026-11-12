import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('load_raw', Path(__file__).resolve().parents[1] / 'etl/load_raw.py')
loader = importlib.util.module_from_spec(spec)
spec.loader.exec_module(loader)


class LoadValidationTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.folder = Path(self.tmp.name)
        self.write([{'unique_key': '123'}])

    def write(self, rows):
        data = ''.join(json.dumps(r) + '\n' for r in rows).encode()
        (self.folder / 'records.jsonl').write_bytes(data)
        (self.folder / 'manifest.json').write_text(json.dumps({
            'status': 'sample', 'eligible_for_sql_load': False, 'dataset_id': 'erm2-nwe9',
            'run_id': 'test-run', 'source_count_before': 10,
            'extracted_distinct_requests': len(rows), 'jsonl_sha256': hashlib.sha256(data).hexdigest()}))

    def test_explicit_dev_sample_accepted(self):
        manifest, rows, sample = loader.validate_run(self.folder, 'NYC_Operations_Dev', True)
        self.assertEqual(len(rows), 1)
        self.assertTrue(sample)

    def test_sample_requires_explicit_flag(self):
        with self.assertRaises(ValueError): loader.validate_run(self.folder, 'NYC_Operations_Dev', False)

    def test_prod_target_rejected(self):
        with self.assertRaises(ValueError): loader.validate_run(self.folder, 'NYC_Operations_Prod', True)

    def test_tampered_file_rejected(self):
        (self.folder / 'records.jsonl').write_text('{"unique_key":"changed"}\n')
        with self.assertRaises(ValueError): loader.validate_run(self.folder, 'NYC_Operations_Dev', True)

    def test_duplicate_ids_rejected(self):
        self.write([{'unique_key': '123'}, {'unique_key': '123'}])
        with self.assertRaises(ValueError): loader.validate_run(self.folder, 'NYC_Operations_Dev', True)

    def test_legacy_windows_line_endings_accepted(self):
        path = self.folder / 'records.jsonl'
        path.write_bytes(path.read_bytes().replace(b'\n', b'\r\n'))
        self.assertEqual(len(loader.validate_run(self.folder, 'NYC_Operations_Dev', True)[1]), 1)

    def test_failed_marker_rejected(self):
        (self.folder / '_FAILED.json').write_text('{}')
        with self.assertRaises(ValueError): loader.validate_run(self.folder, 'NYC_Operations_Dev', True)


if __name__ == '__main__': unittest.main()
