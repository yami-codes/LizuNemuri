# DB Concurrent-Open Guard + Migration Framework — Eliminate Double Handles, Schema Evolution Safety Net

- **Created**: 2026-05-15
- **Owner**: WuMe-sicx
- **Status**: done
- **Related Issue / PR**: Local persistence optimization checklist item 5 (Codex SESSION 019e2c0c…2962 analysis C4)

---

## 1. Goal

`DatabaseService.database` uses `_database ??= await _initDatabase();` — between `??=` and `await` is a suspension point; concurrent first access (`UserSubtitleRepository` find/upsert/remove/listByWork each independently `await _db.database`, track change/query may overlap) lets multiple callers see `_database == null` and each `openDatabase()`, producing duplicate handles (leak + potential lock conflicts). `_onUpgrade` is empty, no safe migration for future schema changes. This task: cache **Future** not resolved `Database` (no await between null-check and assignment, atomic under single-threaded event loop), clear cache on open failure for retry; add **version-ordered migration framework** (empty steps, mechanism only).

## 2. Scope

**In scope:**
- `database` getter → `_databaseFuture ??= _open()`: all concurrent callers share same in-flight Future; `_open()` `try { await _initDatabase() } catch { _databaseFuture = null; rethrow; }` so one failed open does not permanently poison later access.
- `close()` adaptation: await in-flight open (if any) then `db.close()`, set `_databaseFuture = null` for later reopen.
- `_onUpgrade` → version-ordered loop over `_migrations` (ordered Map `{version: (db) async {...}}`, currently empty + usage comment); `_databaseVersion` stays 1 (no actual migration).

**Out of scope:**
- No new tables/columns, no schema change, no `_databaseVersion` bump (no functional migration need).
- No migration library beyond sqflite; no down-migration (mobile one-way upgrade sufficient).
- No `UserSubtitleRepository` caller changes (getter signature `Future<Database>` unchanged).

## 3. Acceptance

- [x] Concurrent multiple `await db.database` triggers only one `_open()`/`openDatabase()`, shares same in-flight Future (Codex confirmed getter has no await suspension point).
- [x] After `_initDatabase()` failure `_databaseFuture` cleared, next access retries; concurrent waiters consistently receive exception, no poisoned cache.
- [x] `close()` waits for in-flight open then closes and resets; getter still returns `Future<Database>`, zero caller changes (`close()` no callers repo-wide, definition only).
- [x] `_onUpgrade` version-ordered loop `(oldVersion, newVersion]`, multi-version jump safe; version=1 never triggers, empty `_migrations`, zero behavior change.
- [x] `flutter analyze lib/core/database/` — only pre-existing `path` info (import untouched), no new warnings.
- [x] Related unit / widget tests pass (31 pass; `test/widget_test.dart` pre-existing stale unrelated).
- [x] Codex review ✅ PASS (SESSION 019e2c0c…2962, round 1 pass).

## 4. Steps

- [x] **Step 1**: `_database` → `_databaseFuture`; `database` expression-bodied getter atomized + `_open()` failure clears cache
- [x] **Step 2**: `close()` adapts to Future cache (take and null → await → close → catch log)
- [x] **Step 3**: `_onUpgrade` version-ordered migration framework (empty `_migrations` Map + `(oldVersion,newVersion]` loop + usage comment)
- [x] **Step 4**: `flutter analyze` (only pre-existing path info) + `flutter test` (31 pass, 1 pre-existing stale) full regression
- [x] **Step 5**: Codex review — round 1 ✅ PASS (confirmed no await suspension point, failure does not poison, multi-version migration safe)

## 5. Risks

- **Risk**: Future cache correctness depends on no suspension point between `??=` and `_open()` sync segment (before first await) — holds under Dart single-threaded event loop. `close()` during in-flight open must serialize correctly. Empty migration framework is mechanism for future, zero behavior change now.
- **Rollback**: revert commit (single-file pure logic, no model/generated artifacts/schema change).

## 6. Notes / Decision Log

- Chose "cache Future" over lock/Completer: simplest Dart idiom, `??=` does not await before assignment = atomic. Clear cache on failure avoids poisoning.
- Migration framework "mechanism not speculative features": only ordered loop + empty Map + comment, no pre-written speculative migrations (constraint: Simplicity > Over-engineering, but multi-version-safe mechanism required per task).

---

## ✅ Done

- Completed at: 2026-05-15 19:35
- Command run: `/init`
- CLAUDE.md update summary: added `DatabaseService` invariants — `database` caches Future (`??= _open()` no await suspension, concurrent first access opens once), `_open()` failure clears `_databaseFuture` against poisoning, `close()` adapted, `_onUpgrade` walks version-ordered `_migrations` loop (new migrations must bump version and add step to map).
- Related commit: not committed (user did not request commit; pending unified commit timing)
