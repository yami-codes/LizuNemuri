# Fix playback for non-mp3/wav audio files

- **创建时间**：2026-07-05
- **负责人**：cursor-agent
- **状态**：active
- **关联 Issue / PR**：

---

## 1. 目标（Goal）

Tapping an audio file (m4a/flac/opus/aac) on the detail screen should start playback instead of failing with an empty playlist.

## 2. 范围（Scope）

**包含：**
- Shared audio-file classifier in core layer
- `PlaybackContext` playlist builder aligned with `DetailViewModel.isAudioFile`
- Unit test for playlist building
- Fallback single-track playlist when siblings cannot be resolved

**不包含：**
- Web CORS / desktop audio_session changes
- Refactoring all duplicate video-extension checks project-wide

## 3. 验收标准（Acceptance）

- [ ] m4a/flac/opus/aac files produce a non-empty playlist
- [ ] mp3/wav still work
- [ ] `flutter analyze` passes
- [ ] Unit test covers m4a playlist build

## 4. 步骤（Plan）

- [x] Identify root cause (`PlaybackContext` mp3/wav-only filter)
- [ ] Add `AudioFileClassifier` util
- [ ] Fix `PlaybackContext._getPlaylistFromSameDirectory`
- [ ] Add unit test
- [x] Add `just_audio_windows` dependency (required native plugin for Windows playback)
