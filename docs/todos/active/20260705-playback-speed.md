# Playback speed (player audio controls)

- **Created**: 2026-07-05
- **Owner**: cursor-agent
- **Status**: active
- **Related Issue / PR**: https://github.com/yami-codes/Xuro/pull/11

---

## 1. Goal

Add cross-platform playback speed control via `just_audio` `setSpeed()`.

## 2. Scope

**In scope:**
- Persisted `playbackSpeed` in `AppSettingsService`
- `IAudioPlayerService` / `AudioPlayerService` / `PlayerViewModel`
- Player AppBar speed picker (preset chips)
- L10n + unit test for clamp/presets

**Out of scope:**
- L/R stereo balance (`just_audio` / no cross-platform API)
- EQ / AndroidEqualizer pipeline
- Real-time spectrum visualizer (decorative waveform already exists)

## 3. Acceptance

- [x] User can pick preset speeds; persists across restart
- [x] Speed applied on cold start restore
- [x] Tests + analyze pass

## 4. Steps

- [x] Settings + audio service speed API
- [x] PlayerViewModel + speed button UI + l10n
- [x] Tests
