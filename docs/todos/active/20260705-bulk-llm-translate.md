# Bulk LLM translate + cache status + progress feedback

- **Created**: 2026-07-05
- **Owner**: cursor-agent
- **Status**: active
- **Related Issue / PR**:

---

## 1. Goal

Per-work bulk/pre-translate with checkboxes, visible per-track cache status (skip re-translate), and live progress feedback during single and batch LLM translation.

## 2. Scope

**In scope:**
- `SubtitleTranslationService.isCached` + batch progress callbacks
- Detail screen: selection dialog (check-all) + progress dialog
- Player: translation status line while in progress / cache hit
- zh/en/th strings

**Out of scope:**
- Subtitle preview screen bulk translate
- Re-translate on target-language change without user action

## 3. Acceptance

- [x] Detail → file list → bulk translate opens checklist with cached badges
- [x] Select all / deselect all; only checked items run
- [x] Cached tracks skip LLM; progress shows phase per track
- [x] Player manual/auto translate shows status text (batch N/M, cached)
- [x] `flutter test` + analyze on touched files pass

## 4. Steps

- [x] Core: cache probe + progress types + service callbacks
- [x] DetailViewModel bulk translate + selection prep
- [x] Selection + progress dialogs + WorkFilesList entry
- [x] Player status UI + l10n
- [x] Tests, analyze, commit, PR
