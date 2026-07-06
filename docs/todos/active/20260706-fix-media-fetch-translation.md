# Fix playback, subtitle preview, and track translation failures

- **Created**: 2026-07-06
- **Owner**: cursor-agent
- **Status**: active
- **Related Issue / PR**: user report (RJ01503719)

---

## 1. Goal

Fix detail-page playback, subtitle preview, and track-name translation failing with generic network/translation errors when presigned CDN URLs are stale or media fetch lacks browser-like headers.

## 2. Scope

**In scope:**
- Refresh `mediaDownloadUrl` from `/tracks/{id}` before play/preview when needed
- Shared media fetch headers (User-Agent) for subtitle + audio streaming
- Metadata translation: LLM→Google fallback when API key missing; clearer failure logging
- Better user-facing playback error mapping

**Out of scope:**
- Offline-only playback without network
- LLM model quality / prompt tuning

## 3. Acceptance

- [ ] Tapping audio refreshes URL then plays (or shows specific error)
- [ ] Subtitle preview loads after URL refresh + headers
- [ ] Track translate falls back to Google when LLM key missing
- [ ] `flutter analyze` clean on touched files
- [ ] Unit tests for WorkMediaUtils + Google multi-batch parse

## 4. Plan

- [ ] Add `WorkMediaUtils` + `WorkMediaUrlRefresher`
- [ ] Wire refresh into `DetailViewModel.playFile`, subtitle preview
- [ ] Headers on SubtitleLoader + AudioCacheManager
- [ ] Metadata translation fallback + error surfacing
- [ ] Tests, analyze, commit
