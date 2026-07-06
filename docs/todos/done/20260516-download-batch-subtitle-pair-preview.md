# Download Refactor: Folder Batch Download + Audio/Subtitle Pairing + Subtitle Preview

- **Created**: 2026-05-16
- **Owner**: WuMe-sicx
- **Status**: done
- **Related Issue / PR**: feature/perf-and-local-media-download

---

## 1. Goal

Refactor downloads from "tap one file at a time" to: ① folder / whole-work "download all"; ② automatically download matching subtitles with audio, and prefer downloaded subtitles for offline playback; ③ tap a subtitle file in the file tree for a read-only timeline preview. Addresses user feedback: "single-file download is tedious + subtitles can't be downloaded together + subtitles can't be previewed."

## 2. Scope

**In scope:**
- `DetailViewModel`: recursively collect (audio, matched subtitle?) pairs under a subtree; `downloadFolder` sequential batch download (aggregate progress + cancel); single-file `downloadFile` becomes "audio + matched subtitle".
- UI: "Download all (whole work)" button in `WorkFilesList` header; folder "Download all" button on `WorkFolderItem` title row; new `BatchDownloadDialog` (confirm → aggregate progress → result summary).
- Offline subtitles: `PlayerViewModel._loadSubtitleIfAvailable` auto-match tier — if that subtitle `Child` is already downloaded locally, read the local file; otherwise keep existing URL loading.
- Subtitle preview: `WorkFileItem` makes .vtt/.lrc/.srt/.txt tappable; new `SubtitlePreviewScreen` (read local if downloaded, else fetch `mediaDownloadUrl`, parse and list read-only by timeline; show raw text if unparseable).
- `strings.dart`: add related copy (no hardcoded strings).

**Out of scope:**
- No multi-select mode (user chose "folder / whole-work button" approach).
- No concurrent downloads (sequential, reusing existing atomic-write / LRU invariants).
- Do not change `DownloadService` disk layout / `fileKey` / atomic-write logic (closed in previous TODO).
- Subtitle preview does not offer "set as subtitle for an audio track" (user chose read-only preview only).
- No MediaStore integration; no storage permissions.

## 3. Acceptance

- [ ] Folder row has "Download all" button; tap sequentially downloads all audio under that subtree (with matched subtitles), shows `i/N + filename + progress`, cancellable, with success/skip/fail summary at end.
- [ ] File list header "Download all" works the same for the whole work.
- [ ] Single audio download button: after audio completes, its matched subtitle is also downloaded (subtitle failure does not affect audio result).
- [ ] Offline (no network / VPN off) playback of downloaded audio: if its subtitle is downloaded, subtitles display normally.
- [ ] Tap .vtt/.lrc/.srt/.txt in file tree → open read-only preview, listed by timeline; parse failure shows raw text.
- [ ] Preview of downloaded subtitles does not require network.
- [ ] `fvm flutter analyze` passes with no new warnings.
- [ ] New pure-logic tests (recursive audio collection + pairing, local-first subtitle selection).
- [ ] Codex review passes.

## 4. Steps

- [x] **Step 1**: Add batch/preview strings to `strings.dart` (including 3 dynamic `static String` helpers)
- [x] **Step 2**: `DetailViewModel` pure static `collectAudioWithSubtitles` + `downloadFolder` + `downloadFile` pairing + 3 unit tests (nested flatten / sibling pairing / no cross-directory pairing)
- [x] **Step 3**: `BatchDownloadDialog` + `onFolderDownload` wiring (list header "Download all" + folder title row IconButton) + `detail_screen.runBatch` + result snackbar
- [x] **Step 4**: `downloadFile` changed to async; after audio completes, best-effort download of matched subtitle
- [x] **Step 5**: `PlayerViewModel._loadSubtitleIfAvailable` priority: user import > downloaded local > online URL (keep `_loadVersion` guard)
- [x] **Step 6**: `SubtitlePreviewScreen` + tappable subtitles in `WorkFileItem` + screen route + `SubtitleLoader.loadRawContent` / `parseOrNull`
- [x] **Step 7**: `flutter analyze` — only unrelated pre-existing withOpacity; `flutter test` all 50 pass; Codex review ❌ → ✅ PASS
- [x] **Step 8**: `/init` refresh CLAUDE.md (`download/` entry expanded with batch/pairing/offline/preview invariants), archive to done/

## 5. Risks

- **Risk**: ViewModel dispose during long batch download (user leaves detail page).
  - **Mitigation**: batch uses independent CancelToken; cancel on dispose; progress callbacks guarded by `_disposed`.
- **Risk**: new "local-first" offline subtitle tier may conflict with user-import priority.
  - **Mitigation**: keep order「user import > downloaded local > online URL」; do not change import-tier logic.
- **Risk**: .srt/.txt parsers may not support all formats.
  - **Mitigation**: parse failure falls back to raw text display, no error screen.
- **Rollback**: UI buttons + new dialog/screen can be reverted independently; offline subtitle tier is additive — reverting does not affect existing online/import paths.

## 6. Notes / Decision Log

- Decision (user confirmed): folder + whole-work button approach, not multi-select; read-only timeline subtitle preview; download audio with matched subtitle + prefer downloaded subtitles offline.
- Reuse: `FilePath.getSiblings` + `SubtitleMatcher.findMatchingSubtitle` for pairing; `SubtitleParserFactory` for preview parsing; `DownloadService.download` idempotent dedup.

## 8. Review

- **Round 4** (❌ CHANGE): 3 medium issues — ① `downloadFolder` last audio item cancelled during subtitle best-effort phase not marked `cancelled` (false "complete") ② `parseOrNull` parse exception bubbles to preview page as "load failed" instead of raw-text fallback ③ `BatchDownloadDialog` no `dispose` safeguard; programmatic page removal leaves batch writing in background.
- **Round 5** (✅ PASS): ① catch subtitle `sr`, cancelled → break + per-iteration tail cancel check; ② `parseOrNull` fully wrapped in try/catch returns null; ③ `dialog.dispose()` cancels token (null-safe in confirm phase, duplicate cancel harmless, token drives loop head/tail + dio cancel). Confirmed user-import priority / clear-on-missing semantics unchanged; best-effort does not pollute audio result.

---

## ✅ Done

- Completed at: 2026-05-16
- Command run: `/init` (direct refresh of `download/` entry, including batch/pairing/offline/preview invariants)
- CLAUDE.md update summary: expanded `lib/core/download/` entry — `DetailViewModel` pure static collect + pair, sequential batch + cancel propagation, single-file pairing, `PlayerViewModel` offline subtitle priority (import > downloaded local > online), `SubtitlePreviewScreen` / `parseOrNull` raw-text fallback.
- Related commit: (pending commit)
- Codex review: SESSION_ID `019e2ce9-97ab-7e01-98fb-8a2c3bb3ea63`, Round 4 ❌ → Round 5 ✅ PASS.
- Runtime verification (pending user device): ① folder/whole-work "Download all" sequential download + cancel + summary; ② after single audio download its subtitle is present; ③ offline playback of downloaded audio shows subtitles; ④ tap .vtt/.lrc/.srt/.txt opens read-only timeline preview; unsupported formats show raw text.
