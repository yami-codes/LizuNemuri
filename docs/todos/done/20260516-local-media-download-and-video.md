# Local Media — Download to Disk + Offline Playback + Video "Download Then Play" Compatibility

- **Created**: 2026-05-16
- **Owner**: WuMe-sicx
- **Status**: done <!-- active | done | cancelled -->
- **Related Issue / PR**: (none)

---

## 1. Goal

> Add real local download (audio + video media) for offline/repeat playback, request storage permissions only when needed; stop treating works with video formats as "cannot open" — prompt user to download video to local disk first (fixed prompt: 「打开该视频需要下载到本地磁盘，是否同意？」). (Subtitle offline explicitly out of scope this round; see §2 Out of scope and Step 9.)

## 2. Scope

**In scope:**
- `DownloadService` + `DownloadRepository`: download files (audio/video) via `mediaDownloadUrl` to app-private dir `getApplicationDocumentsDirectory()/downloads/<workId>/<safeName>`, SQLite tracking; progress, cancel, dedup; capacity cap/LRU discipline aligned with `AudioCacheManager`.
- Atomic write: replicate `SubtitleImportService` invariants — `tmp → rename(dest) → upsert`, rollback on failure; **never delete/overwrite existing good file before new file confirmed**.
- Offline-aware playback: when a file has completed local download, build audio source from local file not remote URL (reuse existing `PlaybackContext`).
- Video compatibility: at existing rejection points, detect `type == 'video'` (or video extension), no longer throw; show confirm dialog with **exact** copy 「打开该视频需要下载到本地磁盘，是否同意？」. Confirm → download flow → open local file with external player (`open_filex`). Video rows in `work_file_item.dart` become tappable.
- Storage permission: request via `permission_handler` only **when truly needed** (app-private dir on modern Android needs no permission — document that); if requested, rationale first; graceful degrade on deny, no crash.

**Out of scope:**
- In-app video player UI / progress bar (external player; separate TODO later).
- Export to public gallery/Downloads (stay app-private; possible future item).
- Change streaming cache behavior (streaming still uses `LockCachingAudioSource`).
- Background/queued batch multi-file download manager (on-demand single file first; batch later).
- **Dedicated "download remote subtitle with work" pipeline — explicitly out this round**. Rationale: subtitles already offline after first online play via existing `SubtitleCacheManager` (`SubtitleLoader.loadSubtitleContent` hits then `cacheContent`); shallow dedicated pipeline adds fragility. Listed as Doc 2 follow-up (Step 9 note), separate schedule, not this acceptance.

## 3. Acceptance

- [x] User can trigger download for one audio and one video file; progress shown; cancellable; re-entry deduped. — Video row tap→confirm download; audio row trailing download button; `MediaDownloadDialog` progress+cancel; `findCompleted` idempotent dedup. **(Real-device interaction pending manual test)**
- [x] Downloads persist across restart, SQLite tracked; interrupted/failed downloads never leave corrupt files (atomic tmp→backup→rename→upsert→rollback on failure). — Replicates `SubtitleImportService`. **(Kill-process boundary pending manual test)**
- [x] Playing fully downloaded audio reads from local disk; undownloaded still streams. — `PlaylistBuilder` via `workId` + `localPathIfDownloaded` prefers local `AudioSource.uri(Uri.file())`. **(Airplane mode pending manual test)**
- [x] Video tap prompt **exactly** 「打开该视频需要下载到本地磁盘，是否同意？」; reject no-op; accept→download→viewer open; video no longer "unsupported file type". — `Strings.videoNeedsDownloadPrompt` exact; `detail_screen` branch. **(Real-device OpenFilex pending manual test)**
- [x] App-private downloads on Android 13+ require no storage permission. — Decision: `getApplicationDocumentsDirectory()`, no `permission_handler`, no manifest change; `open_filex` includes FileProvider.
- [x] ~~Downloaded work subtitles offline~~ — **explicitly out this round** (see Out of scope and Step 9): subtitles offline via existing `SubtitleCacheManager` after first online play; dedicated download pipeline future item.
- [x] `flutter analyze` passes no new warnings; pure-logic network-free unit tests. — Doc 2 all 11 files analyze clean; `test/core/download/download_service_test.dart` 4 `sanitizeFileName` pure tests pass; models pure classes, no build_runner.
- [x] Related unit/widget tests pass. — 35 pass; only failure `widget_test.dart` (flutter create boilerplate) also fails on clean HEAD, not regression.

## 4. Steps

- [x] **Step 1**: Decision recorded (see Notes) — app-private `downloads/<workId>/`; video via `open_filex`; no broad storage permission.
- [x] **Step 2**: Spike verified by code (no network) — `PlaylistBuilder`→`AudioCacheManager.createAudioSource`→`LockCachingAudioSource(Uri.parse(url))` **no headers**; app already streams audio without token, so `mediaDownloadUrl` needs no bearer. DownloadService uses independent `Dio()` without interceptors.
- [x] **Step 3**: `pubspec.yaml` add `open_filex: ^4.5.0` + `path: ^1.9.0` (path was only in `dependency_overrides`, declared to clear `depend_on_referenced_packages` info), `pub get` OK.
- [x] **Step 4**: Create `lib/core/download/{download_service,models/download_entry,storage/i_download_repository,storage/download_repository}.dart`; `database_service.dart` v1→v2 add `downloads` table. **Corrected original "don't change `_onCreate`"**: new table must be in both `_onCreate` (fresh install only calls onCreate) + `_migrations[2]` (v1 upgrade), shared schema to avoid drift. Dedup key = `file_key` (md5(hash|url|title) stable identity, **not display name** — same-name files in different dirs must be distinct downloads), `UNIQUE(work_id, file_key)`; on-disk name = `file_key`+extension (avoid path collision). Atomic write replicates `SubtitleImportService`; capacity LRU replicates `AudioCacheManager` (stat fail uses DB size; undeletable still counted; exclude just-finished file). `dio.download` independent Dio.
- [x] **Step 5**: `service_locator.dart` register `IDownloadRepository`/`DownloadService` (lazy, after DB).
- [x] **Step 6**: `Strings` add exact video prompt + audio download prompts + progress/cancel/success/fail/unsupported, no hardcoding.
- [x] **Step 7**: `playlist_builder.dart` optional `workId`, local download hit uses `AudioSource.uri(Uri.file())`, else original streaming; `playback_controller.dart` passes `work.id`. `GetIt.I<DownloadService>()` direct to avoid core/audio↔core/di cycle (same as `audio_player_service`).
- [x] **Step 8**: `detail_viewmodel` add `isVideoFile/isAudioFile/downloadFile` (no hard throw); `work_file_item.dart` audio+video rows tappable, audio trailing download button; add/rename `media_download_dialog.dart` (confirm+progress+cancel, exact video copy as default); `detail_screen` extract `runDownload` branches audio play / video download open / audio offline download / unsupported prompt.
- [x] **Step 9 (out of round, see Out of scope)**: Subtitle offline not done shallowly. Current: `SubtitleCacheManager` offline after first online play. Future: download unmatched subtitles with work (separate schedule).
- [x] **Step 10**: Permissions — app-private dir, **no** `permission_handler`, **no** manifest change; `open_filex` includes FileProvider. No degrade code needed (correct outcome).
- [x] **Step 11**: `flutter analyze` (Doc 2 all 11 files) clean; `test/core/download/download_service_test.dart` pass; full 35 pass, 1 boilerplate fail not regression; pure models no build_runner. Real-device manual test (audio offline / video download open / kill-process atomicity) **pending user device verification**.

## 5. Risks

- **Risk**: Media URLs may be authenticated CDN redirects — Step 2 spike first; if token needed, attach but don't reuse node-rotating interceptor.
- **Risk**: DB migration must follow `database_service.dart` `_migrations` ordered map (multi-version jump safe) — never edit `_onCreate` alone for existing installs.
- **Risk**: Atomicity — replicate `SubtitleImportService`: don't delete/overwrite good file before new confirmed; `tmp→rename→upsert`; rollback on failure.
- **Risk**: Disk bloat — downloads need same LRU/capacity as `AudioCacheManager` (undeletable files must stay in capacity accounting).
- **Risk**: External video viewer needs device player — fallback `url_launcher` file URI / clear error.
- **Rollback**: Additive feature; video rejection revert via `detail_viewmodel` branch; download service isolated after DI, whole feature independently revertible.

## 6. Notes / Decision Log

> - Verified rejection points (file:line): `detail_viewmodel.dart:169-171` hard throw unsupported file type; `work_file_item.dart:20,43-46` non-audio `onTap:null`; `playback_context.dart:77-83` playlist mp3/wav only. `Child`(`child.dart`) has `type/title/mediaStreamUrl/mediaDownloadUrl/size/hash` — video files **have** `mediaDownloadUrl`.
> - Verified deps: `permission_handler ^11.3.1`, `path_provider ^2.1.5`, `dio ^5.4.0`, `url_launcher ^6.3.0`, `file_picker ^8.0.0` in pubspec; **no download manager package** — use `dio.download`.
> - Verified permissions: AndroidManifest only INTERNET/FOREGROUND_SERVICE(_MEDIA_PLAYBACK)/WAKE_LOCK/POST_NOTIFICATIONS/SYSTEM_ALERT_WINDOW, no storage; existing storage all app-private (no runtime permission).
> - Decision: download location = app-private ("local disk" = app private storage, avoids scoped storage); external video viewer = `open_filex`.
> - **Media URL auth conclusion (Step 2 spike)**: No bearer token. Evidence: `PlaylistBuilder`→`AudioCacheManager.createAudioSource`→`LockCachingAudioSource(Uri.parse(url))` no headers; app already tokenless streams `mediaDownloadUrl`; video same API tree shape → same tokenless. DownloadService independent `Dio()`, no `AuthInterceptor`, no node rotation.
> - **Dedup identity decision (Codex round 1 HIGH)**: DB dedup/query/delete/on-disk name all use `fileKey = md5(hash|url|title)`, **not** display `file_name`; `downloads` table `UNIQUE(work_id, file_key)`, `file_name` display only. Else same-work different-dir same-name files (two `01.mp3`) false hit. `downloads` new table (v2 unreleased), schema finalized.
> - **DB v2 decision**: New table in both `_onCreate` (fresh install) + `_migrations[2]` (v1 upgrade); corrected Step 4 "don't change `_onCreate`" (wrong for new table, fresh install missing table). `user_subtitles` untouched on upgrade path.
>
> **Codex review (SESSION_ID `019e2c83-d6d9-7583-928e-2f3a589037e5`, continued from Doc 1)**:
> - Round 1 ❌ CHANGE (5 items) → all addressed: ①path collision→`fileKey` identity; ②no audio download entry→`onFileDownload` + audio row button + `runDownload` reuse; ③stat fail not counted→DB size fallback; ④eviction deletes just-finished→`exceptWorkId/exceptFileKey` exclude; ⑤subtitle offline not delivered→explicit de-scope in doc.
> - Round 2 ❌ CHANGE (2 items) → addressed: ①dedup identity only physical name, DB still by title→`file_key` in schema + repo + service; ②doc not truly de-scoped→updated Goal/Scope/Acceptance/Step 9.
> - Round 3 (re-review, same SESSION_ID): ⚠️ OPTIMIZE — ships. 2 lows applied: ①Goal sync remove subtitle wording; ②add `fileKey`/`diskFileName` identity pure tests (same hash→same key, no hash same name different url→different key, same url→same key, extension preserved/no extension). `download_service_test.dart` 9 cases pass. Per [[feedback-codex-review-loop]]: OPTIMIZE = ships, closed.
> - Changelog: new `lib/core/download/*`, `lib/widgets/detail/media_download_dialog.dart`, `test/core/download/download_service_test.dart`; changed `database_service / di / playlist_builder / playback_controller / detail_viewmodel / detail_screen / work_file_item / work_files_list / work_folder_item / strings`, `pubspec`.

---

## ✅ Done

- Completed at: 2026-05-16 18:36
- Command run: `/init` (CLAUDE.md already has full download subsystem invariants; refreshed this session)
- CLAUDE.md update summary: `lib/core/download/*` download subsystem (external dir / fileKey isolation / atomic write / capacity LRU / extension-first classification / batch subtitle pairing / subtitle preview) documented in root CLAUDE.md.
- Related commit: Implementation merged via `244c3ff`/`8f226e4`/`b745b6f`/`cf510dd`/`258c7db`; preflight error boundary fix in follow-up TODO `20260516-download-preflight-error-boundary.md`
