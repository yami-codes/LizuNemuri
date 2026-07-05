# LLM translate UI / auto-translate feedback

- **创建时间**：2026-07-05
- **负责人**：cursor-agent
- **状态**：active

## 1. 目标

Expose manual "Translate with LLM" in the player, re-run auto-translate when the toggle is enabled mid-track, and surface API/config errors instead of silent no-ops.

## 2. 范围

**包含：**
- Player subtitle menu: translate now / show original / open LLM settings
- `SubtitleTranslationResult` + service `translateNow` / API-key precheck
- `PlayerViewModel` settings listener + failure fallback to original subs + snackbar feedback
- zh/en/th strings

**不包含：**
- Subtitle preview screen translate
- Re-translate on target-language change without user action

## 3. 验收标准

- [x] Player → subtitle (⋮) shows "Translate subtitles with LLM" when subs loaded
- [x] Auto toggle re-triggers on current track when enabled
- [x] Missing API key / network errors show SnackBar; originals still display
- [x] `flutter test` pass

## 4. 步骤

- [x] `SubtitleTranslationResult` + service refactor
- [x] PlayerViewModel + PlayerScreen menu
- [x] L10n + failure fallback + auto feedback
- [x] Analyze + tests + PR
