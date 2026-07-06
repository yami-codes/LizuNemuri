# Subtitle Import Atomicity — Eliminate "Delete Old → Copy → Upsert" Data Loss and Orphans

- **Created**: 2026-05-15
- **Owner**: WuMe-sicx
- **Status**: done
- **Related Issue / PR**: Local persistence optimization checklist item 4 (Codex SESSION 019e2c0c…2962 analysis C3)

---

## 1. Goal

`SubtitleImportService.importSubtitle` runs「delete old file → `file.copy(destPath)` → DB `upsert`」— any step failure leaves orphan files or stale DB rows; especially **delete old then copy fails = user loses old subtitle with no new subtitle**; `file.copy` is non-atomic, same-name re-import mid-failure yields truncated file. `removeImportedSubtitle` deletes file then DB row and swallows exceptions overall — file deleted but DB delete fails leaves stale row pointing at missing file. This task changes import to **temp file + atomic rename + delete old only after success + on failure only clean temp (never touch old file)**, and deletion to **DB first, file delete best-effort independent**.

## 2. Scope

**In scope:**
- `importSubtitle` steps 5–7 reordered atomically: copy to same-dir temp → `File.rename(tmp → destPath)` (same-filesystem atomic replace) → DB `upsert` → delete "old file at different path" only after success (exists only on extension change); any failure in `finally`/catch cleans temp, **does not touch old file** (preserves existing user subtitle), still returns `ImportResult.ioError`.
- `removeImportedSubtitle` reordered: `_repository.remove` first (consistency-critical, log failure separately) → best-effort delete local file (failure only logs, no DB rollback, does not affect caller).

**Out of scope:**
- Do not change `importSubtitle` / `removeImportedSubtitle` method signatures or return contracts (`ImportResponse` kept; `removeImportedSubtitle` still `Future<void>` — callers don't consume return; surfacing "remove failed" to user is UI scope, deferred).
- No DB transaction spanning filesystem + SQLite (SQLite cannot manage FS; atomic rename + ordering eliminates data loss and stale rows).
- No startup `.import_tmp` residue scan (process-killed small temps harmless; next same-name import `copy` overwrites). Deferred optional.
- Do not touch `loadLocalSubtitle` / `findImported` / `_getDestPath` / validation-parse logic (steps 1–4).

## 3. Acceptance

- [x] Old file deleted only after rename + upsert both succeed; same-path re-import adds `.import_bak` backup — any copy/rename/upsert failure restores old subtitle content and old DB row (no data loss).
- [x] `destPath` never half-written: write via `tmp` then atomic `rename`; same-path re-import mid-failure restored via bak, no truncated file.
- [x] Failure path cleans temp + restores backup; orphans limited to harmless `.import_tmp`/`.import_bak`; returns `ImportResult.ioError` unchanged.
- [x] `removeImportedSubtitle`: DB row deleted first, `dbRemoved` flag protects — **delete file only if DB delete succeeded** (no stale rows), DB failure keeps file with separate error log, signature unchanged.
- [x] `player_viewmodel.dart:275/326` two call sites behavior unchanged (Codex confirmed).
- [x] `flutter analyze lib/core/subtitle/` — only pre-existing `path` info (import untouched in diff), no new warnings.
- [x] Related unit / widget tests pass (31 pass; `test/widget_test.dart` pre-existing stale unrelated).
- [x] Codex review ✅ PASS (SESSION 019e2c0c…2962, round 1 ❌ 2 high → fixed → round 2 PASS).

## 4. Steps

- [x] **Step 1**: `importSubtitle` atomic sequence (copy→tmp / old dest→bak / tmp→dest / upsert; on success delete bak + old different-path file; on failure clean tmp + restore bak)
- [x] **Step 2**: `removeImportedSubtitle` DB-first + `dbRemoved` guard (delete file only if DB succeeded) + separate failure logging
- [x] **Step 3**: `flutter analyze` (only pre-existing path info) + `flutter test` (31 pass, 1 pre-existing stale) full regression
- [x] **Step 4**: Codex review — round 1 ❌ 2 high (same-path upsert failure overwrites old subtitle / remove deletes file when DB delete fails) → fixed (bak backup restore / dbRemoved gate) → round 2 ✅ PASS

## 5. Risks

- **Risk**: `File.rename` atomic on same directory (same filesystem), Android/iOS use POSIX `rename(2)`, reliable; if rename fails in extreme environment, failure path cleans tmp, old file unchanged (degrades to "import failed", no corruption). DB deleted then file delete fails → orphan file (disk only, app won't think subtitle exists, no consistency issue).
- **Rollback**: revert this commit (pure logic, no model/generated artifacts).

## 6. Notes / Decision Log

- Ordering principle: user's existing data (old subtitle file + old DB row) **never destroyed before new import confirmed**; consistency-critical ops (DB upsert / DB remove) ordered relative to file ops per "stale DB row worse than orphan file" — on import, DB destPath must be complete before upsert (rename before upsert); on remove, DB row removed first (orphan file harmless, stale row misleads loading).
- Codex round 1 two high fixes: (1) same-path re-import rename already replaced old file, upsert failure then old subtitle unrecoverable — add `.import_bak`: after copy→tmp, rename old destPath to bak (`backedUp`), on upsert failure `bakFile.rename(destPath)` restores; delete bak only on success. (2) remove deleted file when DB delete failed still left stale row — add `dbRemoved` gate, delete local file only if DB delete succeeded.

---

## ✅ Done

- Completed at: 2026-05-15 18:55
- Command run: `/init`
- CLAUDE.md update summary: added subtitle import/remove atomicity invariants — import via tmp + atomic rename, same-path re-import uses `.import_bak` backup and restores on failure (any step failure old subtitle + old DB row unchanged), delete old file only after full success; remove gated by `dbRemoved`, DB row deleted first and local file deleted only on DB success (no stale rows).
- Related commit: not committed (user did not request commit; pending unified commit timing)
