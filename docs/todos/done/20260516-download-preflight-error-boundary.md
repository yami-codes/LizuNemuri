# Download Preflight IO/DB Failures Inside Error Boundary (Codex Pre-Merge HIGH Blocker)

- **Created**: 2026-05-16
- **Owner**: WuMe-sicx
- **Status**: done
- **Related Issue / PR**: PR #4 pre-merge Codex review (SESSION_ID `019e2dfd-621a-7652-a5a0-eb75b483bbd8`) ❌ CHANGE HIGH item; must re-review ✅ before merge

## 1. Goal

> `DownloadService.download()` dedup query `findCompleted()`, target path resolution `_destPath()`, tmp/bak path construction run **outside** `try` — DB open/migration failure, `path_provider`/dir create failure, `File.exists()` permission exceptions throw uncaught async errors; both download dialogs `await widget.download(...)` without catch fallback, leaving dialog stuck on non-dismissible progress and bypassing download service's promised ioError + cleanup path. Move preflight IO/DB into same `try` (nullable tmp/bak/destPath for cleanup), add last-resort catch to both dialogs.

## 2. Scope

**In scope:**
- `lib/core/download/download_service.dart` `download()`: move `findCompleted`/`_destPath`/tmp-bak construction into `try`; `destPath/tmpFile/bakFile` nullable declared before `try`, assigned inside; catch cleanup null-guarded; `alreadyExists` early return still inside try (normal return skips catch). **Atomic write order and rollback semantics unchanged** (tmp→bak→rename→upsert; failure deletes tmp, restores bak, never destroys existing good file — CLAUDE.md invariant).
- `lib/widgets/detail/media_download_dialog.dart` `_start()`: wrap `await widget.download` in try/catch, exception → `pop(DownloadResult(DownloadStatus.ioError))` (defense in depth).
- `lib/widgets/detail/batch_download_dialog.dart` `_start()`: same, exception → `pop(BatchDownloadOutcome(ok:0,skipped:0,failed:audioCount,cancelled:false))`.
- Process consistency (Codex MEDIUM): `20260516-local-media-download-and-video.md` (all steps checked) completion block and move to done; `20260516-startup-loading-performance.md` stays active with note "code optimizations shipped with PR, device before/after metrics pending" (no fabricated performance data).

**Out of scope:**
- No change to atomic write order/rollback/capacity LRU/classification logic (Codex confirmed those invariants intact).
- No other download/subtitle flow changes.

## 3. Acceptance

- [ ] Preflight `findCompleted`/`_destPath`/`File.exists` errors return `DownloadStatus.ioError` from `download()` (not uncaught exception), tmp/bak cleanup null-safe no NPE.
- [ ] Both dialogs pop with failure result on exception, no longer stuck on non-dismissible progress.
- [ ] Atomic write order and rollback unchanged; `fvm flutter analyze` no new warnings; full `fvm flutter test` zero regression.
- [ ] Codex re-review (same SESSION_ID) HIGH item → ✅; process MEDIUM items resolved.
- [ ] Merge PR #4 only after Codex ✅ (user "merge after confirmed correct").

## 4. Steps

- [x] **Step 1** This TODO ✅ 2026-05-16.
- [x] **Step 2** ✅ 2026-05-16: `download_service.dart` preflight (findCompleted/_destPath/tmp-bak) moved into try; `destPath/tmpFile/bakFile` nullable pre-declared, assigned in try; catch uses local `tf/bf/dp` + `backedUp && bf!=null && dp!=null` guards; atomic write/rollback order line-by-line unchanged.
- [x] **Step 3** ✅ 2026-05-16: `media_download_dialog`/`batch_download_dialog` `_start()` wrapped in try/catch, exceptions pop `DownloadResult.ioError` / `pop(BatchDownloadOutcome(failed:audioCount))`.
- [x] **Step 4** ✅ 2026-05-16: `local-media-download-and-video.md` completion block + move to done; `startup-loading-performance.md` stays active + device metrics pending note (no fabrication).
- [x] **Step 5** ✅ 2026-05-16: `flutter analyze` (3 files No issues) + full `flutter test` **103/103 zero regression**.
- [x] **Step 6** ✅ 2026-05-16: Codex re-review (SESSION_ID `019e2dfd-621a-7652-a5a0-eb75b483bbd8`) → **✅ PASS** (HIGH resolved, atomic write/rollback intact, dialog fallback correct, two MEDIUM process items acceptable, no remaining blockers).
- [x] **Step 7** ✅ 2026-05-16: fix commit `a8ca248` pushed; PR #4 merged to `main` (merge commit `5d28a5f`, state MERGED).

## 5. Risks

- **Risk**: moving preflight into try accidentally changes atomic write order/rollback.
  - **Mitigation**: only move「dedup query / path resolution / tmp-bak construction」three segments; download→backup→rename→upsert→cleanup order line-by-line preserved; catch restore logic only adds null guards.
- **Risk**: `destPath` inside try, catch cannot restore `bak→destPath`.
  - **Mitigation**: `String? destPath` declared before try, assigned inside; catch uses `backedUp && bakFile!=null && destPath!=null` guard (`backedUp` only true after destPath assigned).
- **Rollback**: focused single-file changes, revert per file with `git revert`.

## 6. Notes / Decision Log

- 2026-05-16: Codex pre-merge review (PR #4) ❌, HIGH=download preflight error boundary. User "Codex reviews for me, merge when confirmed" → fix + re-review, no merge without ✅ ([[feedback-codex-review-loop]]). startup-perf metrics not fabricated, stays active as follow-up.

---

## ✅ Done

- Completed at: 2026-05-16 18:36
- Command run: `/init` (CLAUDE.md download section already notes: entire `download()` including preflight dedup/path/tmp-bak in single try, nullable pre-declare + catch null guards → preflight failure converges to ioError; both dialogs await fallback, no stuck PopScope progress sheet)
- CLAUDE.md update summary: download subsystem atomic write section adds「preflight IO/DB failure error boundary + dialog fallback」invariant.
- Related commit: `a8ca248` (fix); PR #4 merge `5d28a5f`; this doc finalized as subsequent doc-only commit

---

## ⛔ Cancelled

> Fill only for cancelled tasks (mutually exclusive with Done above). **Do not run `/init`**. Move file to `docs/todos/cancelled/`.

- Cancelled at: YYYY-MM-DD HH:mm
- Reason: <...>
- Follow-up: <...>
