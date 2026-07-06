# Android audio fix + Apple Music player & lyrics refresh

- **创建时间**：2026-07-06
- **负责人**：cursor-agent
- **状态**：active
- **关联 Issue / PR**：

---

## 1. 目标（Goal）

Fix Android silent playback (fade race leaves volume at 0) and modernize the player + synced lyrics toward Apple Music patterns (full-bleed art, thin scrubber, glass dock, kinetic centered lyrics with depth).

## 2. 范围（Scope）

**包含：**
- Volume restore after interrupted play/pause fade
- `PlayerScrubber` thin progress bar (Apple Music style)
- Glass bottom control dock, larger album art, refined transport controls
- Lyrics: larger active line, stronger inactive dimming, improved spacing

**不包含：**
- Word-level karaoke / syllable timing
- Full AMLL-style WebGL fluid background
- iOS-specific blur materials

## 3. 验收标准（Acceptance）

- [ ] Interrupted fade no longer leaves `just_audio` volume at 0 while playing
- [ ] Player uses thin scrubber + glass dock on mobile
- [ ] Active lyric line visually dominant; inactive lines clearly recessed
- [ ] `flutter analyze` clean for touched files
- [ ] Unit tests for volume-restore helper + existing lyric tests pass

## 4. 拆解步骤（Steps）

- [x] Fix `AudioPlayerService` fade interrupt volume restore
- [x] Add `PlayerScrubber` + update `PlayerScreen` layout
- [x] Modernize controls, cover, lyrics
- [x] Run tests + analyze

---

## ✅ 完成标记

- 完成时间：2026-07-06
- Exa research: Apple Music full-bleed art, thin scrubber, kinetic centered lyrics with depth-of-field dimming
