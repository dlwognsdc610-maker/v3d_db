#!/usr/bin/env python3
"""Requirement checks for the SQL assignment package."""

from pathlib import Path
import sqlite3
import subprocess


ROOT = Path(__file__).resolve().parent
DB = ROOT / "mesa_drawer.db"

subprocess.run(["python3", str(ROOT / "verify.py")], check=True)

conn = sqlite3.connect(DB)
conn.execute("PRAGMA foreign_keys = ON")

for table in ("developers", "patches", "test_runs", "reviews"):
    count = conn.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
    assert count >= 10, f"{table}: expected >= 10 rows, got {count}"
    print(f"PASS  {table}_rows >= 10")

fk_count = 0
for table in ("patches", "test_runs", "reviews"):
    fk_count += len(conn.execute(f"PRAGMA foreign_key_list({table})").fetchall())
assert fk_count >= 2
print(f"PASS  foreign_keys ({fk_count})")

schema = (ROOT / "schema.sql").read_text().upper()
assert "NOT NULL" in schema
assert "UNIQUE" in schema
assert "FOREIGN KEY" in schema
print("PASS  constraints")

queries = (ROOT / "queries.sql").read_text().upper()
for token in ("INNER JOIN", "LEFT JOIN", "GROUP BY", "COUNT(", "SUM(", "AVG(",
              "UPDATE ", "DELETE FROM", "CREATE INDEX", "SELECT AVG("):
    assert token in queries, token
print("PASS  required_query_categories")

result_files = list((ROOT / "results").glob("Q*.txt"))
assert len(result_files) >= 15
print(f"PASS  captured_results ({len(result_files)})")

conn.close()
print("\nSQL assignment CTS: PASS")
