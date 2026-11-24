-- Mesa patch tracker schema (SQLite)
PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS test_runs;
DROP TABLE IF EXISTS patches;
DROP TABLE IF EXISTS developers;

CREATE TABLE developers (
    id          INTEGER PRIMARY KEY,
    name        TEXT NOT NULL UNIQUE,
    role        TEXT NOT NULL,
    joined_at   TEXT NOT NULL
);

CREATE TABLE patches (
    id            INTEGER PRIMARY KEY,
    developer_id  INTEGER NOT NULL,
    title         TEXT NOT NULL UNIQUE,
    component     TEXT NOT NULL,
    status        TEXT NOT NULL CHECK (status IN ('open', 'review', 'merged', 'abandoned')),
    created_at    TEXT NOT NULL,
    lines_changed INTEGER NOT NULL CHECK (lines_changed >= 0),
    FOREIGN KEY (developer_id) REFERENCES developers(id)
);

CREATE TABLE test_runs (
    id           INTEGER PRIMARY KEY,
    patch_id     INTEGER NOT NULL,
    device       TEXT NOT NULL,
    suite        TEXT NOT NULL,
    passed       INTEGER NOT NULL CHECK (passed >= 0),
    failed       INTEGER NOT NULL CHECK (failed >= 0),
    duration_sec REAL NOT NULL CHECK (duration_sec >= 0),
    run_at       TEXT NOT NULL,
    FOREIGN KEY (patch_id) REFERENCES patches(id) ON DELETE CASCADE
);

CREATE TABLE reviews (
    id          INTEGER PRIMARY KEY,
    patch_id    INTEGER NOT NULL,
    reviewer_id INTEGER NOT NULL,
    verdict     TEXT NOT NULL CHECK (verdict IN ('comment', 'approved', 'changes_requested')),
    comment     TEXT NOT NULL,
    reviewed_at TEXT NOT NULL,
    FOREIGN KEY (patch_id) REFERENCES patches(id) ON DELETE CASCADE,
    FOREIGN KEY (reviewer_id) REFERENCES developers(id)
);
