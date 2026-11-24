# Mesa Patch Drawer

Mesa patch와 review/test 기록을 SQLite에 넣고 SQL로 꺼내보는 작은 DB 실습이다.
백엔드나 화면은 없고 `schema -> seed -> query -> result`만 남긴다.

DB를 따로 운영하지 않는다. Python 3의 표준 `sqlite3` 모듈이 SQLite 파일 하나를
만들고, `verify.py`가 과제 실행과 결과 캡처를 전부 맡는다.

## 구조

```text
schema.sql      4개 table, PK/FK/constraint
seed.sql        table마다 10행 이상의 sample data
queries.sql     기본/조인/집계/서브쿼리/UPDATE/DELETE/INDEX 16개
verify.py       DB 재생성 + 16개 query 실행 + result 캡처
cts.py          제출 조건 검사
results/        Q01.txt ... Q16.txt
```

runtime DB인 `mesa_drawer.db`는 재생성 가능한 산출물이라 git에는 넣지 않는다.

## 관계

```text
developers 1 ─── N patches
                    │
                    ├── 1 ─── N test_runs
                    │
                    └── 1 ─── N reviews

developers 1 ─────────── N reviews   (reviewer)
```

테이블은 네 개다.

- `developers`: 개발자. `name`은 `UNIQUE`, 주요 필드는 `NOT NULL`이다.
- `patches`: patch 메타데이터. `developer_id -> developers.id`.
- `test_runs`: patch별 test 결과. `patch_id -> patches.id`.
- `reviews`: patch review. `patch_id -> patches.id`, `reviewer_id -> developers.id`.

`PK`는 한 행을 구분하는 ID이고, `FK`는 다른 테이블의 PK를 참조하는 연결이다.
예를 들어 한 developer row를 여러 patch row가 `developer_id`로 가리키므로
`developer 1 : N patch` 관계가 된다.

엑셀처럼 한 표에 개발자 이름, patch, test, review를 전부 반복해서 넣지 않은 이유도
여기 있다. 개발자 정보는 한 번 저장하고 FK로 연결하므로 중복을 줄이고, 없는
개발자를 patch가 참조하는 것도 DB가 막을 수 있다.

## 실행

설치할 Python package는 없다.

```sh
python3 verify.py
```

이 명령은 매번 `mesa_drawer.db`를 새로 만들고 다음 순서로 실행한다.

```text
schema.sql
   ↓
seed.sql
   ↓
queries.sql Q01 ~ Q16
   ↓
results/Q01.txt ~ Q16.txt
```

제출 전 검사는:

```sh
python3 cts.py
```

CTS는 각 table 10행 이상, FK/NOT NULL/UNIQUE, 필요한 query 종류, 결과 파일 개수를
검사한다. `verify.py`는 존재하지 않는 developer를 참조하는 patch INSERT도 일부러
시도해서 FK가 실제로 거부하는지 확인한다.

## Query 구성

16개를 아래처럼 나눴다.

```text
Q01-Q04  기본 조회: WHERE / ORDER BY / LIMIT
Q05-Q08  JOIN: INNER JOIN / LEFT JOIN
Q09-Q11  집계: COUNT / AVG / SUM + GROUP BY
Q12-Q13  subquery / NOT EXISTS
Q14      UPDATE
Q15      DELETE
Q16      CREATE INDEX
```

`Q16`의 `idx_patches_component_status`는 component/status 조건으로 patch를 반복
검색할 때 전체 row를 모두 확인하는 일을 줄이기 위한 인덱스다.

각 query 바로 위에 “무엇을 확인하는지” 한 줄 설명이 있고, 실행 결과는 같은 번호의
`results/Qxx.txt`에 SQL과 함께 저장된다. 따라서 별도 screenshot 없이 결과 텍스트를
제출 증빙으로 사용할 수 있다.

## SQL을 최소한으로 읽는 법

평가 때는 이 다섯 개만 구분하면 충분하다.

```sql
SELECT ... FROM ... WHERE ...;   -- 가져오기
INSERT INTO ... VALUES ...;      -- 넣기
UPDATE ... SET ... WHERE ...;    -- 바꾸기
DELETE FROM ... WHERE ...;       -- 지우기
JOIN ... ON ...                  -- FK로 연결된 표를 같이 보기
```

`GROUP BY`는 같은 종류끼리 묶어서 `COUNT`, `SUM`, `AVG` 같은 집계를 하기 위한
구문이다. subquery는 SQL 안에서 다른 `SELECT` 결과를 조건으로 다시 쓰는 형태다.

## 제출 파일

필수 제출물은 그대로 대응된다.

```text
schema.sql
seed.sql
queries.sql
results/
README.md
```

`verify.py`, `cts.py`는 재현과 검증을 편하게 하려고 추가한 파일이다. 선택 과제인 ERD
이미지는 넣지 않았다. 위 관계 그림으로 구조를 확인할 수 있고, 고급 View/trigger/
procedure도 사용하지 않는다.
