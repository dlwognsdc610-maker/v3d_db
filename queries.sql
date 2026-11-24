-- Q01: review/open 상태인 patch를 확인한다. [기본 조회: WHERE]
SELECT id, title, component, status
FROM patches
WHERE status IN ('open', 'review')
ORDER BY id;

-- Q02: 변경 줄 수가 큰 patch 상위 5개를 확인한다. [기본 조회: ORDER BY, LIMIT]
SELECT id, title, lines_changed
FROM patches
ORDER BY lines_changed DESC
LIMIT 5;

-- Q03: v3dv component의 patch만 생성 순서로 확인한다. [기본 조회: WHERE, ORDER BY]
SELECT id, title, status, created_at
FROM patches
WHERE component = 'v3dv'
ORDER BY created_at;

-- Q04: 실패가 발생한 test run을 실패 개수 순으로 확인한다. [기본 조회: WHERE, ORDER BY]
SELECT id, patch_id, device, failed, run_at
FROM test_runs
WHERE failed > 0
ORDER BY failed DESC, id;

-- Q05: patch와 작성자를 연결해 누가 어떤 patch를 만들었는지 확인한다. [INNER JOIN]
SELECT p.id, p.title, d.name AS author, p.status
FROM patches AS p
INNER JOIN developers AS d ON d.id = p.developer_id
ORDER BY p.id;

-- Q06: test run과 patch를 연결해 실패한 test의 patch 제목을 확인한다. [INNER JOIN]
SELECT t.id, p.title, t.device, t.suite, t.failed
FROM test_runs AS t
INNER JOIN patches AS p ON p.id = t.patch_id
WHERE t.failed > 0
ORDER BY t.failed DESC, t.id;

-- Q07: patch가 없는 개발자도 포함해 개발자별 patch 개수를 확인한다. [LEFT JOIN]
SELECT d.name, COUNT(p.id) AS patch_count
FROM developers AS d
LEFT JOIN patches AS p ON p.developer_id = d.id
GROUP BY d.id, d.name
ORDER BY d.id;

-- Q08: review와 patch/reviewer를 연결해 review 이력을 확인한다. [INNER JOIN]
SELECT r.id, p.title, d.name AS reviewer, r.verdict
FROM reviews AS r
INNER JOIN patches AS p ON p.id = r.patch_id
INNER JOIN developers AS d ON d.id = r.reviewer_id
ORDER BY r.id;

-- Q09: 상태별 patch 개수를 센다. [집계: COUNT, GROUP BY]
SELECT status, COUNT(*) AS patch_count
FROM patches
GROUP BY status
ORDER BY status;

-- Q10: 장치별 평균 test 실행 시간을 구한다. [집계: AVG, GROUP BY]
SELECT device, ROUND(AVG(duration_sec), 2) AS avg_duration_sec
FROM test_runs
GROUP BY device
ORDER BY device;

-- Q11: 개발자별 총 변경 줄 수를 구한다. [집계: SUM, GROUP BY]
SELECT d.name, COALESCE(SUM(p.lines_changed), 0) AS total_lines_changed
FROM developers AS d
LEFT JOIN patches AS p ON p.developer_id = d.id
GROUP BY d.id, d.name
ORDER BY total_lines_changed DESC, d.id;

-- Q12: 평균보다 변경 줄 수가 큰 patch를 찾는다. [서브쿼리]
SELECT id, title, lines_changed
FROM patches
WHERE lines_changed > (SELECT AVG(lines_changed) FROM patches)
ORDER BY lines_changed DESC;

-- Q13: review가 아직 하나도 없는 patch를 찾는다. [서브쿼리: NOT EXISTS]
SELECT p.id, p.title
FROM patches AS p
WHERE NOT EXISTS (
    SELECT 1
    FROM reviews AS r
    WHERE r.patch_id = p.id
)
ORDER BY p.id;

-- Q14: review 중이던 patch 2를 merged 상태로 바꾼다. [UPDATE]
UPDATE patches
SET status = 'merged'
WHERE id = 2;

-- Q15: 재실행 대상이라고 가정한 test run 14를 삭제한다. [DELETE]
DELETE FROM test_runs
WHERE id = 14;

-- Q16: component/status 조건 검색을 위한 복합 인덱스를 만든다. [INDEX]
-- 적용 이유: component별 status 필터가 반복될 때 전체 patch scan을 줄이기 위해 사용한다.
CREATE INDEX idx_patches_component_status
ON patches(component, status);
