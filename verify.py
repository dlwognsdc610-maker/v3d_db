#!/usr/bin/env python3
"""Rebuild the SQLite DB, execute every assignment query, and capture results."""

from pathlib import Path
import re
import sqlite3


ROOT = Path(__file__).resolve().parent
DB_PATH = ROOT / "mesa_drawer.db"
RESULTS = ROOT / "results"


def parse_queries(text):
    marker = re.compile(r"^-- Q(\d{2}): (.+)$", re.MULTILINE)
    matches = list(marker.finditer(text))

    for index, match in enumerate(matches):
        start = match.end()
        end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
        yield match.group(1), match.group(2), text[start:end].strip()


def format_table(cursor, rows):
    columns = [column[0] for column in cursor.description]
    values = [columns] + [[str(value) for value in row] for row in rows]
    widths = [max(len(row[i]) for row in values) for i in range(len(columns))]

    def line(row):
        return " | ".join(row[i].ljust(widths[i]) for i in range(len(columns)))

    output = [line(columns), "-+-".join("-" * width for width in widths)]
    output.extend(line(row) for row in values[1:])
    return "\n".join(output)


def main():
    DB_PATH.unlink(missing_ok=True)
    RESULTS.mkdir(exist_ok=True)
    for old in RESULTS.glob("Q*.txt"):
        old.unlink()

    conn = sqlite3.connect(DB_PATH)
    conn.execute("PRAGMA foreign_keys = ON")
    conn.executescript((ROOT / "schema.sql").read_text())
    conn.executescript((ROOT / "seed.sql").read_text())

    query_count = 0
    for number, description, sql in parse_queries((ROOT / "queries.sql").read_text()):
        query_count += 1
        cursor = conn.execute(sql)

        if cursor.description:
            rows = cursor.fetchall()
            result = format_table(cursor, rows) if rows else "(no rows)"
        elif sql.lstrip().upper().startswith(("UPDATE", "DELETE")):
            result = f"affected_rows: {cursor.rowcount}"
        else:
            result = "OK"

        text = f"Q{number}: {description}\n\nSQL:\n{sql}\n\nRESULT:\n{result}\n"
        (RESULTS / f"Q{number}.txt").write_text(text)
        print(f"PASS  Q{number}  {description}")

    conn.commit()

    counts = {}
    for table in ("developers", "patches", "test_runs", "reviews"):
        counts[table] = conn.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]

    # Q15 deletes one test row, so the seeded count was 14 and final count is 13.
    assert counts["developers"] >= 10
    assert counts["patches"] >= 10
    assert counts["test_runs"] >= 10
    assert counts["reviews"] >= 10
    assert query_count >= 15

    # Prove FK enforcement is actually active.
    try:
        conn.execute(
            "INSERT INTO patches(id, developer_id, title, component, status, created_at, lines_changed) "
            "VALUES(999, 999, 'invalid fk', 'v3d', 'open', '2026-09-11', 1)"
        )
        raise AssertionError("foreign key check did not fire")
    except sqlite3.IntegrityError:
        pass

    conn.close()
    print(f"\n{query_count}/{query_count} queries executed")
    print("table rows:", ", ".join(f"{name}={count}" for name, count in counts.items()))
    print("foreign key rejection: PASS")
    print(f"results: {RESULTS}")


if __name__ == "__main__":
    main()
