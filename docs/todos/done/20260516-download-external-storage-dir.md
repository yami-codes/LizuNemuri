# Download Storage — External App-Specific Dir Android/data/<pkg>/

- **Created**: 2026-05-16
- **Owner**: WuMe-sicx
- **Status**: done <!-- active | done | cancelled -->
- **Related Issue / PR**: feature/perf-and-local-media-download

---

## 1. Goal

Move local download storage for audio / video / subtitles from app-internal private dir
`getApplicationDocumentsDirectory()` (`/data/user/0/com.xuro/app_flutter/...`,
not accessible in file managers / other apps without root) to **Android external app-specific directory**
`getExternalStorageDirectory()` (`/storage/emulated/0/Android/data/com.xuro/files/...`).
This directory requires **no storage permission on any Android version** and is accessible via USB/MTP on PC.

## 2. Scope

**In scope:**
- Only change `DownloadService._workDir`: Android uses `getExternalStorageDirectory()`,
  null fallback `getApplicationDocumentsDirectory()`; non-Android unchanged
  (`getExternalStorageDirectory()` throws `UnsupportedError` on iOS).
- Update class doc comments (storage location + "no storage permission" rationale).

**Out of scope:**
- No migration of existing internal-dir downloads (DB stores absolute paths; old files still hit
  `findCompleted` and play offline, harmless; new downloads land external).
- No storage permissions, no MediaStore (external app-specific dir needs neither).
- No repository / DownloadEntry / offline playback lookup logic changes (all use DB absolute paths).

## 3. Acceptance

- [x] Android new downloads land in `/storage/emulated/0/Android/data/com.xuro/files/downloads/<workId>/`.
- [x] Old internal-dir downloads still play offline (DB absolute path hit, no regression — Codex confirmed).
- [x] iOS / desktop never call `getExternalStorageDirectory()`, behavior unchanged.
- [x] `fvm flutter analyze lib/core/download/` passes, no new warnings.
- [x] Existing `test/core/download/download_service_test.dart` (sanitize/fileKey/diskFileName) 9 cases pass.
- [x] Codex review: ⚠️ OPTIMIZE (mergeable), `download()` method comment updated per suggestion.

## 4. Steps

- [x] **Step 1**: Change `lib/core/download/download_service.dart` `_workDir`
  - File: `lib/core/download/download_service.dart`
  - Verify: `flutter analyze lib/core/download/` clean; device download under `Android/data/...` (pending user device)
- [x] **Step 2**: Update class + `download()` method doc comments
  - Verify: comments match actual storage location
- [x] **Step 3**: Codex review
  - Verify: ⚠️ OPTIMIZE (mergeable), method comment fixed per suggestion

## 5. Risks

- **Risk**: External app-specific dir and internal dir may differ volumes; atomic `tmp.rename(destPath)`
  still holds (tmp/dest under same `_workDir`, same volume), no cross-volume rename issue.
- **Risk**: Old internal and new external downloads coexist; DB absolute paths each hit —
  Codex confirmed `findCompleted` / `localPathIfDownloaded` / `enforceCapacity` work by DB path, no regression, no re-download.
- **Rollback**: Single-file `git revert` (`download_service.dart` only);
  after revert new downloads back to internal; external files still play via DB absolute paths.

## 6. Notes / Decision Log

- **Decision**: No migration of internal downloads. DB absolute paths; old files still hit offline play, migration adds risk for no gain.
- **Decision**: `getExternalStorageDirectory()` (external app-specific) not public `Music/` + MediaStore. Former needs no permission, avoids scoped storage, uninstall cleanup, meets "visible on PC"; latter needs permission + MediaStore + SAF, disproportionate cost.
- **Scope clarification**: User-imported subtitles (`SubtitleImportService` → `user_subtitles/`)
  separate flow, out of "download" scope, remain internal.

---

## ✅ Done

- Completed: 2026-05-16
- Command: `/init`
- CLAUDE.md summary: Updated `lib/core/download/` section — storage moved to Android external app-specific dir (no permission, PC-visible) + non-Android fallback to internal dir invariant.
- Related commit: (pending commit)
- Codex re-review: SESSION_ID `019e2ce9-97ab-7e01-98fb-8a2c3bb3ea63`, ⚠️ OPTIMIZE → method comment fixed per suggestion.
- Runtime acceptance (Step 1): Still pending user device download one audio, confirm path under `/storage/emulated/0/Android/data/com.xuro/files/downloads/...`.

## 7. Follow-up Change: On-Disk Filename = API Original Title (2026-05-16)

User follow-up: download filename should match API file list, not md5 naming (otherwise PC sees `edc2423….mp3`, defeating "external visibility").

- [x] `diskFileName` changed from `fileKey+ext` (md5) to `sanitizeFileName(title)`.
- [x] `sanitizeFileName` rewritten Unicode-safe (keep JP/CN; old ASCII-only regex mangled ASMR titles and was dead code): replace FS-illegal chars only,
  strip leading/trailing dots/spaces, Windows reserved names `_` prefix, UTF-8 byte clamp ≤180 (FAT/exFAT 255 limit headroom).
- [x] `_destPath` → `<root>/downloads/<workId>/<fileKey>/<original title>`:
  per-file `<fileKey>/` subdir isolates same-work-tree different-folder same-name `01.mp3` collisions;
  tmp/bak/dest same subdir, atomic write invariant preserved.
- [x] Added `_pruneEmptyDir`: best-effort remove empty `<fileKey>/` dir after file delete.
- [x] `fileKey` (md5 identity) unchanged, DB dedup correct; old downloads not migrated, still hit by DB absolute path.
- [x] Tests: old `diskFileName` contract updated + CJK/clamp/long extension/reserved names/leading dot cases, 16 pass; `fvm flutter analyze` clean.

## 8. Review

- **Round 1** (⚠️ OPTIMIZE, mergeable): external dir change — Codex read-only verified
  no regression: old downloads kept (`findCompleted` by DB absolute path), offline play OK
  (`PlaylistBuilder` builds `Uri.file()` from DB path), LRU still full-table
  `listAllOldestFirst()`, Android-only fallback reasonable. Suggestion: stale `download()` comment → fixed.
- **Round 2** (⚠️ OPTIMIZE, mergeable): original-title filenames — same-name `<fileKey>/`
  isolation holds, atomic same-volume invariant holds, old downloads still hit. Three suggestions: ①`_clampNameBytes`
  long extension can exceed 180 (medium) ②Windows reserved names ③leading-dot hidden files.
- **Round 3** (✅ PASS, merge as-is): all three closed — long extension empty fallback guarantees
  ≤180; `_reservedStem` anchored won't hit `console`/`COMmon`; leading-dot strip order
  correct with empty fallback/trailing strip. No new boundary issues.

---

## ✅ Done (re-confirmed after follow-up changes)

- Completed: 2026-05-16
- Command: `/init` (direct refresh of `download/` entry)
- CLAUDE.md summary: `lib/core/download/` synced — external app-specific dir +
  on-disk name = API original title + `<fileKey>/` subdir isolation + Unicode-safe sanitize/byte
  clamp/reserved names/leading-dot invariants + `_pruneEmptyDir`.
- Related commit: (pending commit, includes external dir + filename two changes)
- Codex re-review: SESSION_ID `019e2ce9-97ab-7e01-98fb-8a2c3bb3ea63`, three rounds ⚠️→⚠️→✅ PASS.
- Runtime acceptance (still pending user device): download one audio, confirm under
  `/storage/emulated/0/Android/data/com.xuro/files/downloads/<workId>/<fileKey>/<API original filename>`
  visible on PC (USB/MTP) with API list filename.
