import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location("extract", Path(__file__).resolve().parents[1] / "etl/extract.py")
extract = importlib.util.module_from_spec(spec)
spec.loader.exec_module(extract)


class ExtractTests(unittest.TestCase):
    def test_keyset_pagination_and_sample_limit(self):
        calls = []
        def get(params):
            calls.append(params)
            return ([{"unique_key": "10", "created_date": "2026-10-01T00:00:00.000"},
                     {"unique_key": "11", "created_date": "2026-10-01T00:00:00.000"}] if len(calls) == 1
                    else [{"unique_key": "12", "created_date": "2026-10-02T00:00:00.000"}])
        rows = [row for page in extract.pages("borough='BROOKLYN'", 2, 3, get) for row in page]
        self.assertEqual([r["unique_key"] for r in rows], ["10", "11", "12"])
        self.assertEqual(calls[1]["$limit"], 1)
        self.assertIn("unique_key > '11'", calls[1]["$where"])

    def test_duplicate_or_reordered_ids_fail(self):
        with self.assertRaises(ValueError):
            list(extract.pages("true", 10, None, lambda _: [
                {"unique_key": "11", "created_date": "2026-10-01T00:00:00.000"},
                {"unique_key": "11", "created_date": "2026-10-01T00:00:00.000"}]))

    def test_id_order_can_reset_on_next_date(self):
        rows = [{"unique_key": "99", "created_date": "2026-10-01T00:00:00.000"},
                {"unique_key": "10", "created_date": "2026-10-02T00:00:00.000"}]
        self.assertEqual(list(extract.pages("true", 10, None, lambda _: rows)), [rows])

    def test_missing_id_fails(self):
        with self.assertRaises(ValueError):
            list(extract.pages("true", 10, None, lambda _: [{}]))

    def test_partial_extract_cannot_reconcile(self):
        with self.assertRaises(ValueError):
            extract.validate_count(100, 99, False)
        extract.validate_count(100, 10, True)

    def test_scope_dates_and_quoting(self):
        with self.assertRaises(ValueError):
            extract.cohort_filter("BROOKLYN", "2026-11-01", "2026-10-01")
        self.assertIn("created_date < '2026-11-01T00:00:00'", extract.cohort_filter("BROOKLYN", "2026-10-01", "2026-11-01"))
        self.assertEqual(extract.quote("O'Brien"), "'O''Brien'")


if __name__ == "__main__":
    unittest.main()
