# Fix: API Mislabels Video as type=audio Causing Play Failure on Tap

- **Created**: 2026-05-16
- **Owner**: WuMe-sicx
- **Status**: done
- **Related Issue / PR**: feature/perf-and-local-media-download

---

## 1. Goal

asmr.one API returns `type: "audio"` for some videos (e.g. "intro video.mp4"). Current `isAudioFile` only checks `type=='audio'`, so such mp4 enters audio pipeline, playlist filtered by extension becomes empty → `PlaybackContext.validate` throws "playlist empty" → tap only shows "play failed", neither playable nor downloadable. Change to **known video extensions take priority over unreliable API `type` field**, routing such files through existing video "download locally and open in external player" flow.

## 2. Scope

**In scope:**
- `DetailViewModel`: extract static `_hasVideoExtension`; `isAudioFile` excludes video extensions; `collectAudioWithSubtitles` excludes videos (batch does not treat video as audio); `playFile` guard uses `isAudioFile` (defensive, clear error vs empty list).
- `WorkFileItem`: video extension first → mislabeled mp4 shows video icon, video download flow.
- `detail_screen` onFileTap: video check before audio (robust routing).
- Unit test: mislabeled `intro.mp4 (type=audio)` not collected as audio by `collectAudioWithSubtitles`.

**Out of scope:**
- No playback pipeline / `PlaybackContext` / playlist_builder changes (root cause is classification and routing).
- No API parsing changes (`type` field kept, extension wins at classification time only).
- No "no extension but actually video" edge cases API cannot detect.

## 3. Acceptance

- [ ] Tap mislabeled type=audio `.mp4` → video "download locally and play" confirm dialog, no "playlist empty / play failed".
- [ ] Normal audio (mp3/flac… type=audio) unchanged, plays normally.
- [ ] Real video (type=video or video extension) unchanged.
- [ ] Batch "Download all" no longer collects video files as audio.
- [ ] `fvm flutter analyze` passes; new unit test passes; `fvm flutter test` all pass.
- [ ] Codex review passes.

## 4. Steps

- [x] **Step 1**: `DetailViewModel` classification fix (static `_hasVideoExtension` + `_isAudioChild`/`isAudioFile`/`collectAudioWithSubtitles`/`playFile` guard) + unit test
- [x] **Step 2**: `WorkFileItem` video extension first (`isAudio=_isAudio&&!isVideo`, icon/tappable/routing consistent)
- [x] **Step 3**: `detail_screen` onFileTap video check before audio
- [x] **Step 4**: `flutter analyze` clean; `flutter test` all 51 pass; Codex ✅ PASS
- [x] **Step 5**: `/init` refresh CLAUDE.md (`download/` entry adds "extension over API type" classification invariant), archive to done/

## 7. Review

- **Round 6** (✅ PASS, merge-ready): Codex read-only verification — root cause closed (mislabeled `.mp4` no longer enters audio pipeline, uses download+external play), real audio (type=audio, non-video ext) / real video (type=video or video ext) no regression; `_hasVideoExtension` boundaries (multi-dot/case/`m4a` not misclassified) correct; VM classification, `WorkFileItem` icon&tappable, screen routing consistent; no remaining global "type==audio straight to play/batch" paths; `playFile` guard does not change valid audio error semantics. SESSION `019e2ce9-...`.

---

## ✅ Done

- Completed at: 2026-05-16
- Command run: `/init` (direct refresh of `download/` entry, new file classification invariant section)
- CLAUDE.md update summary: `lib/core/download/` entry adds "file type classification — extension over unreliable API `type`": asmr.one mislabels video as audio causes empty playlist, known video extensions always video download+external play; `isAudioFile`/`_isAudioChild` sole entry points, `detail_screen` checks `isVideoFile` first.
- Related commit: (pending commit)
- Codex review: SESSION_ID `019e2ce9-97ab-7e01-98fb-8a2c3bb3ea63`, Round 6 ✅ PASS.
- Runtime verification (pending user device): tap mislabeled type=audio `.mp4` → video "download locally and play" confirm, downloadable and opens externally, no "play failed/playlist empty"; normal audio and real video unchanged.

## 5. Risks

- **Risk**: misclassify legitimate audio as video. Mitigation: only known video set `{mp4,mkv,mov,avi,webm,m4v}` (excludes m4a etc.); audio extensions outside set unaffected.
- **Rollback**: single-point logic change, single-file revert, no data/persistence impact.

## 6. Notes / Decision Log

- Decision: extension more reliable than API `type` for video (API actually labels intro videos as audio). "Video extension first" only; did not reverse-use extension to override audio judgment (avoid over-tightening).
