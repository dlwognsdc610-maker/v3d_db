-- Fictional sample data. Parent rows are inserted before rows that reference them.
INSERT INTO developers (id, name, role, joined_at) VALUES
(1,  'Jae',  'driver',   '2024-03-01'),
(2,  'Mina', 'compiler', '2023-07-12'),
(3,  'Alex', 'driver',   '2022-11-02'),
(4,  'Iris', 'reviewer', '2021-06-20'),
(5,  'Sam',  'compiler', '2024-01-15'),
(6,  'Noah', 'ci',       '2023-09-08'),
(7,  'Lena', 'driver',   '2022-02-17'),
(8,  'Jun',  'reviewer', '2020-12-03'),
(9,  'Maya', 'ci',       '2024-05-22'),
(10, 'Theo', 'driver',   '2023-04-10');

INSERT INTO patches (id, developer_id, title, component, status, created_at, lines_changed) VALUES
(1,  1, 'v3dv render pass compatibility',       'v3dv',     'review',    '2026-08-28 10:00:00', 184),
(2,  2, 'v3d incremental liveness',             'v3d',      'review',    '2026-09-01 09:20:00', 241),
(3,  3, 'vc4 release blit temporary resource',  'vc4',      'merged',    '2026-08-18 14:10:00', 32),
(4,  5, 'softpipe NIR execution cleanup',        'softpipe', 'merged',    '2026-08-21 11:40:00', 126),
(5,  7, 'v3dv host cached memory import',        'v3dv',     'merged',    '2026-08-24 16:30:00', 96),
(6,  10,'v3d int64 lowering',                    'v3d',      'open',      '2026-09-03 13:15:00', 318),
(7,  1, 'v3dv input attachment TLB read',        'v3dv',     'review',    '2026-09-05 08:05:00', 402),
(8,  2, 'v3d register allocation spill cost',   'v3d',      'open',      '2026-09-06 23:27:00', 211),
(9,  3, 'vc4 flush resource context cleanup',    'vc4',      'merged',    '2026-08-19 15:45:00', 44),
(10, 5, 'softpipe interpreter branch cleanup',   'softpipe', 'abandoned', '2026-08-25 12:00:00', 73),
(11, 7, 'v3dv dynamic rendering local read',     'v3dv',     'open',      '2026-09-07 18:43:00', 287),
(12, 10,'v3d tessellation patch id mapping',     'v3d',      'review',    '2026-09-08 10:30:00', 159);

INSERT INTO test_runs (id, patch_id, device, suite, passed, failed, duration_sec, run_at) VALUES
(1,  1,  'RPi5', 'vkcts-renderpass', 9367, 1,  93.2,  '2026-09-07 19:00:00'),
(2,  1,  'RPi4', 'vkcts-renderpass', 7633, 4,  102.8, '2026-09-07 19:20:00'),
(3,  2,  'RPi5', 'shader-db',        327,  0,  47.3,  '2026-09-02 12:00:00'),
(4,  3,  'RPi4', 'piglit',           820,  0,  31.1,  '2026-08-18 16:00:00'),
(5,  4,  'x86',  'nir-exec',         36092,1,  66.0,  '2026-08-21 12:30:00'),
(6,  5,  'RPi5', 'memory-bench',     24,   0,  12.5,  '2026-08-24 18:00:00'),
(7,  6,  'RPi5', 'vkcts-int64',      811,  7,  55.4,  '2026-09-04 09:00:00'),
(8,  7,  'RPi5', 'vkcts-input',      9367, 1,  96.4,  '2026-09-07 20:00:00'),
(9,  8,  'RPi5', 'shader-db',        327,  0,  39.8,  '2026-09-07 01:00:00'),
(10, 9,  'RPi4', 'piglit',           821,  0,  30.7,  '2026-08-19 17:00:00'),
(11, 10, 'x86',  'nir-exec',         36090,3,  70.2,  '2026-08-25 14:00:00'),
(12, 11, 'RPi5', 'vkcts-dynamic',    9360, 8,  95.9,  '2026-09-08 08:00:00'),
(13, 12, 'RPi5', 'vkcts-tess',       2014, 2,  43.6,  '2026-09-08 13:00:00'),
(14, 12, 'RPi4', 'vkcts-tess',       1988, 5,  51.2,  '2026-09-08 13:30:00');

INSERT INTO reviews (id, patch_id, reviewer_id, verdict, comment, reviewed_at) VALUES
(1,  1,  4, 'changes_requested', 'Clarify compatible render pass mapping.', '2026-08-30 10:00:00'),
(2,  2,  8, 'approved',          'Looks good modulo small nits.',           '2026-09-03 11:00:00'),
(3,  3,  4, 'approved',          'Resource lifetime is correct.',          '2026-08-18 18:00:00'),
(4,  4,  8, 'comment',           'Please keep the interpreter path small.','2026-08-22 09:00:00'),
(5,  5,  4, 'approved',          'Benchmark result is clear.',             '2026-08-26 13:00:00'),
(6,  6,  8, 'changes_requested', 'Need more CTS coverage.',                '2026-09-05 16:00:00'),
(7,  7,  4, 'changes_requested', 'Reuse the existing TLB read helper.',     '2026-09-07 09:00:00'),
(8,  8,  8, 'comment',           'Explain spill candidate ordering.',      '2026-09-07 15:00:00'),
(9,  9,  4, 'approved',          'Small cleanup, behavior unchanged.',      '2026-08-20 10:00:00'),
(10, 10, 8, 'comment',           'No need to keep this experiment.',       '2026-08-26 11:00:00'),
(11, 12, 4, 'comment',           'Check primitive id behavior.',           '2026-09-09 09:30:00'),
(12, 2,  4, 'approved',          'CI results look consistent.',            '2026-09-04 14:00:00');
