#!/usr/bin/env bash
# Ground-truth reader for the Things 3 database.
#
# The Things MCP tools cannot be trusted for review work: they do not filter by
# parent-project status, they emit headings as if they were tasks, and their
# Age/Modified strings describe creation and modification rather than how long an
# item has actually sat. This script reads the SQLite database directly with
# explicit filters and verified date decoding.
#
# Shared by the shape-today, unbury, and things-review skills.
#
# Usage:
#   things-db.sh check                 # integrity gate — run before presenting any number
#   things-db.sh buckets               # reconciled bucket counts
#   things-db.sh today                 # the real Today list, rituals flagged
#   things-db.sh inbox                 # untriaged captures
#   things-db.sh onme                  # the 🟠 On Me pool, with stamp age
#   things-db.sh sql "SELECT ..."      # arbitrary query against the lt / proj views
#
# Views created:
#   lt    live open to-dos (parent project active, not trashed, not a heading)
#   proj  active projects
set -euo pipefail

SNAP=/tmp/things_review_snapshot.sqlite

find_db() {
  local d
  d=$(ls -d ~/Library/Group\ Containers/JLMPQHK86H.com.culturedcode.ThingsMac/ThingsData-*/Things\ Database.thingsdatabase 2>/dev/null | head -1)
  [ -n "$d" ] || { echo "FATAL: Things database not found" >&2; exit 1; }
  echo "$d/main.sqlite"
}

snapshot() {
  local db; db=$(find_db)
  rm -f "$SNAP" "$SNAP-wal" "$SNAP-shm"
  cp "$db" "$SNAP"
  # WAL and SHM must come along or the snapshot silently predates recent edits.
  [ -f "$db-wal" ] && cp "$db-wal" "$SNAP-wal"
  [ -f "$db-shm" ] && cp "$db-shm" "$SNAP-shm"
  sqlite3 "$SNAP" <<'SQL'
DROP VIEW IF EXISTS proj;
CREATE VIEW proj AS
  SELECT uuid, title, area FROM TMTask
  WHERE type=1 AND status=0 AND trashed=0;

DROP VIEW IF EXISTS lt;
CREATE VIEW lt AS
SELECT t.uuid, t.title, t.start, t.rt1_repeatingTemplate AS rep,
  -- startDate and deadline are PACKED BITFIELDS, not timestamps.
  -- Decoding them as unix epoch yields 1974 for every row.
  CASE WHEN t.startDate IS NULL THEN NULL ELSE
    printf('%04d-%02d-%02d',(t.startDate>>16),(t.startDate>>12)&15,(t.startDate>>7)&31) END AS start_d,
  CASE WHEN t.deadline IS NULL THEN NULL ELSE
    printf('%04d-%02d-%02d',(t.deadline>>16),(t.deadline>>12)&15,(t.deadline>>7)&31) END AS due_d,
  -- creationDate and userModificationDate ARE unix epoch seconds.
  date(t.creationDate,'unixepoch','localtime') AS created,
  date(t.userModificationDate,'unixepoch','localtime') AS modified,
  COALESCE(NULLIF(t.project,''), h.project) AS proj_uuid,
  (SELECT title FROM TMTask p WHERE p.uuid=COALESCE(NULLIF(t.project,''),h.project)) AS project,
  (SELECT a.title FROM TMArea a WHERE a.uuid=COALESCE(
      NULLIF(t.area,''),
      (SELECT p2.area FROM TMTask p2 WHERE p2.uuid=COALESCE(NULLIF(t.project,''),h.project))
   )) AS area,
  (SELECT group_concat(tg.title,', ') FROM TMTaskTag tt JOIN TMTag tg ON tg.uuid=tt.tags
     WHERE tt.tasks=t.uuid) AS tags,
  t.notes AS notes,
  -- `unbury` writes a single "Unburied YYYY-MM-DD" line. It REPLACES that line rather
  -- than appending, so this extraction stays unambiguous.
  CASE WHEN instr(t.notes,'Unburied ')>0
       THEN substr(t.notes, instr(t.notes,'Unburied ')+9, 10) END AS unburied_on
FROM TMTask t
LEFT JOIN TMTask h ON h.uuid=t.heading AND h.type=2
WHERE t.type=0            -- 0=to-do, 1=project, 2=heading. Headings are NOT tasks.
  AND t.status=0          -- 0=open, 2=cancelled, 3=completed
  AND t.trashed=0
  AND ( COALESCE(NULLIF(t.project,''),h.project) IS NULL
     OR COALESCE(NULLIF(t.project,''),h.project)=''
     OR EXISTS (SELECT 1 FROM proj p WHERE p.uuid=COALESCE(NULLIF(t.project,''),h.project)) );
SQL
}

case "${1:-check}" in
  check)
    snapshot
    echo "=== INTEGRITY GATE ==="
    sqlite3 "$SNAP" <<'SQL'
.mode list
-- 1. Date decoding self-test. Every scheduled item must decode to a sane year.
SELECT 'FAIL: startDate decoded outside 2000-2100 (' || COUNT(*) || ' rows)'
FROM lt WHERE start_d IS NOT NULL
  AND (CAST(substr(start_d,1,4) AS INT) < 2000 OR CAST(substr(start_d,1,4) AS INT) > 2100)
HAVING COUNT(*) > 0;

-- 2. The naive decode must DISAGREE with the bitfield decode. If they agree,
--    the encoding changed and every date in this review is suspect.
SELECT 'FAIL: bitfield and epoch decode agree — encoding assumption is stale'
FROM TMTask WHERE startDate IS NOT NULL
  AND date(startDate,'unixepoch') = printf('%04d-%02d-%02d',(startDate>>16),(startDate>>12)&15,(startDate>>7)&31)
LIMIT 1;

-- 3. No task in lt may belong to a dead parent.
SELECT 'FAIL: ' || COUNT(*) || ' tasks have an inactive parent project'
FROM lt WHERE proj_uuid IS NOT NULL AND proj_uuid<>''
  AND proj_uuid NOT IN (SELECT uuid FROM proj)
HAVING COUNT(*) > 0;

-- 4. No headings may appear as tasks.
SELECT 'FAIL: ' || COUNT(*) || ' headings leaked into lt'
FROM lt WHERE uuid IN (SELECT uuid FROM TMTask WHERE type=2)
HAVING COUNT(*) > 0;

-- 5. Buckets must sum to the total, or an item is double-counted or missing.
SELECT CASE WHEN inbox+today+upcoming+anytime+someday = total
            THEN 'ok: buckets reconcile (' || total || ' live tasks)'
            ELSE 'FAIL: buckets sum to ' || (inbox+today+upcoming+anytime+someday) || ' but total is ' || total END
FROM (SELECT
  SUM(CASE WHEN start=0 THEN 1 ELSE 0 END) inbox,
  SUM(CASE WHEN start_d IS NOT NULL AND start_d<=date('now','localtime') THEN 1 ELSE 0 END) today,
  SUM(CASE WHEN start_d IS NOT NULL AND start_d>date('now','localtime') THEN 1 ELSE 0 END) upcoming,
  SUM(CASE WHEN start=1 AND start_d IS NULL THEN 1 ELSE 0 END) anytime,
  SUM(CASE WHEN start=2 AND start_d IS NULL THEN 1 ELSE 0 END) someday,
  COUNT(*) total FROM lt);
SQL
    echo "(no FAIL lines above means the gate passed)"
    ;;

  buckets)
    snapshot
    sqlite3 "$SNAP" <<'SQL'
.mode column
.headers on
SELECT
 SUM(CASE WHEN start=0 THEN 1 ELSE 0 END) inbox,
 SUM(CASE WHEN start_d IS NOT NULL AND start_d<=date('now','localtime') THEN 1 ELSE 0 END) today,
 SUM(CASE WHEN start_d IS NOT NULL AND start_d>date('now','localtime') THEN 1 ELSE 0 END) upcoming,
 SUM(CASE WHEN start=1 AND start_d IS NULL THEN 1 ELSE 0 END) anytime,
 SUM(CASE WHEN start=2 AND start_d IS NULL THEN 1 ELSE 0 END) someday,
 SUM(CASE WHEN rep IS NOT NULL THEN 1 ELSE 0 END) repeaters,
 COUNT(*) total
FROM lt;
SELECT COUNT(*) AS active_projects FROM proj;
SQL
    ;;

  today)
    snapshot
    sqlite3 -column -header "$SNAP" "
      SELECT CASE WHEN rep IS NOT NULL THEN 'ritual' ELSE '' END kind,
             start_d, COALESCE(project,COALESCE(area,'-')) bucket,
             COALESCE(due_d,'-') due, COALESCE(tags,'') tags, title
      FROM lt WHERE start_d IS NOT NULL AND start_d <= date('now','localtime')
      ORDER BY (rep IS NOT NULL), start_d;
      SELECT COUNT(*) AS substantive_today FROM lt
      WHERE start_d IS NOT NULL AND start_d <= date('now','localtime') AND rep IS NULL;"
    ;;

  inbox)
    snapshot
    sqlite3 -column -header "$SNAP" \
      "SELECT uuid, created, title FROM lt WHERE start=0 ORDER BY created;"
    ;;

  onme)
    snapshot
    sqlite3 -column -header "$SNAP" "
      SELECT uuid, created, COALESCE(unburied_on,'never') last_surfaced,
             COALESCE(start_d,'-') sched, COALESCE(project,COALESCE(area,'-')) bucket, title
      FROM lt WHERE tags LIKE '%On Me%' ORDER BY COALESCE(unburied_on,'0000-00-00'), created;
      SELECT COUNT(*) AS on_me_total FROM lt WHERE tags LIKE '%On Me%';"
    ;;

  sql)
    snapshot
    sqlite3 -column -header "$SNAP" "$2"
    ;;

  *)
    echo "usage: things-db.sh {check|buckets|today|inbox|onme|sql \"<query>\"}" >&2; exit 2 ;;
esac
