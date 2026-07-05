# Playback speed (player audio controls)

- **创建时间**：2026-07-05
- **负责人**：cursor-agent
- **状态**：active
- **关联 Issue / PR**：https://github.com/yami-codes/Xuro/pull/11

---

## 1. 目标（Goal）

Add cross-platform playback speed control via `just_audio` `setSpeed()`.

## 2. 范围（Scope）

**包含：**
- Persisted `playbackSpeed` in `AppSettingsService`
- `IAudioPlayerService` / `AudioPlayerService` / `PlayerViewModel`
- Player AppBar speed picker (preset chips)
- L10n + unit test for clamp/presets

**跳过（just_audio / 无跨平台 API）：**
- L/R stereo balance
- EQ / AndroidEqualizer pipeline
- Real-time spectrum visualizer (decorative waveform already exists)

## 3. 验收标准（Acceptance）

- [x] User can pick preset speeds; persists across restart
- [x] Speed applied on cold start restore
- [x] Tests + analyze pass

## 4. 拆解步骤（Steps）

- [x] Settings + audio service speed API
- [x] PlayerViewModel + speed button UI + l10n
- [x] Tests
