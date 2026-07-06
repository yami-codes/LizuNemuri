# Fix playback for non-mp3/wav audio files

- **Created**: 2026-07-05
- **Owner**: cursor-agent
- **Status**: active
- **Related Issue / PR**:

---

## 1. Goal

Tapping an audio file (m4a/flac/opus/aac) on the detail screen should start playback instead of failing with an empty playlist.

## 2. Scope

**In scope:**
- Shared audio-file classifier in core layer
- `PlaybackContext` playlist builder aligned with `DetailViewModel.isAudioFile`
- Unit test for playlist building
- Fallback single-track playlist when siblings cannot be resolved

**Out of scope:**
- Web CORS / desktop audio_session changes
- Refactoring all duplicate video-extension checks project-wide

## 3. Acceptance

- [ ] m4a/flac/opus/aac files produce a non-empty playlist
- [ ] mp3/wav still work
- [ ] `flutter analyze` passes
- [ ] Unit test covers m4a playlist build

## 4. Steps

- [x] Identify root cause (`PlaybackContext` mp3/wav-only filter)
- [ ] Add `AudioFileClassifier` util
- [ ] Fix `PlaybackContext._getPlaylistFromSameDirectory`
- [ ] Add unit test
- [x] Add `just_audio_windows` dependency (required native plugin for Windows playback)
