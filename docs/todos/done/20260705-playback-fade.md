# Play/pause volume fade (Eara VolumeFader pattern)

- **Created**: 2026-07-05
- **Owner**: cursor-agent
- **Status**: done
- **Related Issue / PR**:

---

## 1. Goal

Linear volume fade on pause/resume (default ~300ms), matching Eara `VolumeFader` / `FadingPlayer` ASMR feel; configurable duration or disable in Settings.

## 2. Scope

**In scope:**
- Play/pause fade via `AudioPlayerService` + `VolumeFader`
- Settings: enable/disable fade, duration ms
- `setVolume(persist: false)` during fade; restore saved volume after

**Out of scope:**
- (none listed)

## 3. Acceptance

- [x] Pause: volume ramps to 0 over `playbackFadeMs`, then `pause()`; player internal volume restored to `playbackVolume`
- [x] Resume: `play()` from 0, then fade in to `playbackVolume`
- [x] When fade disabled in settings, behavior matches pre-change
- [x] Fade does not write `playback_volume` SharedPreferences
- [x] `flutter analyze` no new warnings; unit tests pass

## 4. Steps

- [x] **Steps 1–6**: see related commit

---

## ✅ Done

- Completed at: 2026-07-05 09:40
- Command run: `/init` (manual CLAUDE.md update)
- CLAUDE.md update summary: Added play/pause fade settings and `VolumeFader`/`AudioPlayerService` invariants
- Related commit: `ef75351`
