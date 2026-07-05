# Bulk LLM translate + cache status + progress feedback

- **创建时间**：2026-07-05
- **负责人**：cursor-agent
- **状态**：active

## 1. 目标

Per-work bulk/pre-translate with checkboxes, visible per-track cache status (skip re-translate), and live progress feedback during single and batch LLM translation.

## 2. 范围

**包含：**
- `SubtitleTranslationService.isCached` + batch progress callbacks
- Detail screen: selection dialog (check-all) + progress dialog
- Player: translation status line while in progress / cache hit
- zh/en/th strings

**不包含：**
- Subtitle preview screen bulk translate
- Re-translate on target-language change without user action

## 3. 验收标准

- [x] Detail → file list → bulk translate opens checklist with cached badges
- [x] Select all / deselect all; only checked items run
- [x] Cached tracks skip LLM; progress shows phase per track
- [x] Player manual/auto translate shows status text (batch N/M, cached)
- [x] `flutter test` + analyze on touched files pass

## 4. 步骤

- [x] Core: cache probe + progress types + service callbacks
- [x] DetailViewModel bulk translate + selection prep
- [x] Selection + progress dialogs + WorkFilesList entry
- [x] Player status UI + l10n
- [x] Tests, analyze, commit, PR
