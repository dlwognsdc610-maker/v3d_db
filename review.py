#!/usr/bin/env python3
"""Run the SQL examples used in the review notes and screenshots."""

import argparse
from pathlib import Path
import sqlite3

from verify import format_table, parse_queries


ROOT = Path(__file__).resolve().parent
QUERIES = {
    number: sql
    for number, description, sql in parse_queries((ROOT / "queries.sql").read_text())
}


def show(conn, sql):
    print(sql)
    cursor = conn.execute(sql)
    rows = cursor.fetchall()
    if rows:
        print("\n".join(line.rstrip() for line in format_table(cursor, rows).splitlines()))
    else:
        print("(no rows)")
    print()
    return rows


def schema(conn):
    show(conn, """SELECT 'developers' AS table_name, name AS column_name, type
FROM pragma_table_info('developers')
UNION ALL
SELECT 'patches', name, type FROM pragma_table_info('patches')
UNION ALL
SELECT 'test_runs', name, type FROM pragma_table_info('test_runs')
UNION ALL
SELECT 'reviews', name, type FROM pragma_table_info('reviews');""")
    rows = show(conn, """SELECT 'developers' AS table_name, COUNT(*) AS rows FROM developers
UNION ALL SELECT 'patches', COUNT(*) FROM patches
UNION ALL SELECT 'test_runs', COUNT(*) FROM test_runs
UNION ALL SELECT 'reviews', COUNT(*) FROM reviews;""")
    assert rows == [('developers', 10), ('patches', 12), ('test_runs', 14), ('reviews', 12)]


def joins(conn):
    print("INNER JOIN: developers with matching patches\n")
    inner = show(conn, QUERIES['07'].replace('LEFT JOIN', 'INNER JOIN'))
    print("LEFT JOIN: all developers\n")
    left = show(conn, QUERIES['07'])
    assert len(inner) == 6 and len(left) == 10
    assert dict(left)['Iris'] == 0
    print("COUNT(*) and COUNT(p.id) for Iris\n")
    rows = show(conn, """SELECT d.name, COUNT(*) AS joined_rows, COUNT(p.id) AS patch_count
FROM developers AS d
LEFT JOIN patches AS p ON p.developer_id = d.id
WHERE d.name = 'Iris'
GROUP BY d.id, d.name;""")
    assert rows == [('Iris', 1, 0)]


def subqueries(conn):
    print("Q12 step 1: calculate the average\n")
    show(conn, 'SELECT AVG(lines_changed) AS avg_lines FROM patches;')
    print("Q12 step 2: compare each patch against the average\n")
    rows = show(conn, QUERIES['12'])
    assert [row[0] for row in rows] == [7, 6, 11, 2, 8, 1]
    print("Q13 step 1: inspect reviews for patch 1 and patch 11\n")
    assert show(conn, 'SELECT 1 FROM reviews AS r WHERE r.patch_id = 1;')
    assert not show(conn, 'SELECT 1 FROM reviews AS r WHERE r.patch_id = 11;')
    print("Q13 step 2: NOT EXISTS keeps the patch with no review\n")
    rows = show(conn, QUERIES['13'])
    assert [row[0] for row in rows] == [11]


def constraints(conn):
    assert show(conn, 'PRAGMA foreign_keys;') == [(1,)]
    cases = [
        ('FOREIGN KEY', "INSERT INTO patches VALUES (999, 999, 'FK example', 'v3d', 'open', '2026-11-24', 1);",
         sqlite3.SQLITE_CONSTRAINT_FOREIGNKEY),
        ('NOT NULL', "INSERT INTO developers VALUES (11, 'Example', NULL, '2026-11-24');",
         sqlite3.SQLITE_CONSTRAINT_NOTNULL),
        ('UNIQUE', "INSERT INTO developers VALUES (11, 'Jae', 'driver', '2026-11-24');",
         sqlite3.SQLITE_CONSTRAINT_UNIQUE),
        ('CHECK', "INSERT INTO patches VALUES (999, 1, 'CHECK example', 'v3d', 'open', '2026-11-24', -1);",
         sqlite3.SQLITE_CONSTRAINT_CHECK),
    ]
    for name, sql, error_code in cases:
        print(sql)
        try:
            conn.execute(sql)
        except sqlite3.IntegrityError as error:
            assert error.sqlite_errorcode == error_code
            print(f'{name}: {error}\n')
        else:
            raise AssertionError(f'{name}: expected rejection')

    print('LEFT JOIN aggregate: COALESCE converts NULL to zero\n')
    rows = show(conn, """SELECT d.name, SUM(p.lines_changed) AS raw_sum,
       COALESCE(SUM(p.lines_changed), 0) AS total_lines_changed
FROM developers AS d
LEFT JOIN patches AS p ON p.developer_id = d.id
WHERE d.name = 'Iris'
GROUP BY d.id, d.name;""")
    assert rows == [('Iris', None, 0)]


SECTIONS = {'schema': schema, 'joins': joins, 'subqueries': subqueries, 'constraints': constraints}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('section', nargs='?', default='all', choices=['all', *SECTIONS])
    args = parser.parse_args()
    print(f'python3 review.py {args.section}')
    print(f'SQLite {sqlite3.sqlite_version} / Python sqlite3')
    print('Each section starts with schema.sql + seed.sql, before Q14/Q15.\n')

    for name, run in SECTIONS.items():
        if args.section not in ('all', name):
            continue
        print(f'=== {name} ===\n')
        conn = sqlite3.connect(':memory:')
        try:
            conn.execute('PRAGMA foreign_keys = ON')
            conn.executescript((ROOT / 'schema.sql').read_text())
            conn.executescript((ROOT / 'seed.sql').read_text())
            run(conn)
            print(f'PASS {name}\n')
        finally:
            conn.close()


if __name__ == '__main__':
    main()
