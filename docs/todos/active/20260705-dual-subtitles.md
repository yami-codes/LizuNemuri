# Dual subtitles (original + LLM translation)

- **创建时间**：2026-07-05
- **负责人**：cursor-agent
- **状态**：active
- **关联 Issue / PR**：https://github.com/yami-codes/Xuro/pull/11

---

## 1. 目标（Goal）

Stack original and translated subtitle lines in the player (and Android floating overlay) so users can read both at once — must-have per product roadmap.

## 2. 范围（Scope）

**包含：**
- `LlmSubtitleDisplayMode` setting (`translationOnly` | `dual`)
- `AppSettingsService` persistence + settings UI
- `PlayerLyricView` / `LyricLine` dual-line rendering
- `PlayerViewModel` original-line lookup from `_subtitleSourceList`
- Android `LyricOverlayManager` two-line text when dual active
- L10n (en / zh / th) + unit test

**不包含：**
- Lock-screen notification dual lines
- Re-translate on language change (separate roadmap item)

## 3. 验收标准（Acceptance）

- [x] When LLM translation is active and display mode is dual, each lyric row shows translation (primary) + original (secondary).
- [x] `translationOnly` mode shows current single-line behavior.
- [x] Setting persists across restart; player rebuilds without re-translate.
- [x] Floating overlay shows two lines when dual active (Android).
- [x] `flutter analyze` passes; new unit test passes.

## 4. 拆解步骤（Steps）

- [x] **Step 1**：Add `LlmSubtitleDisplayMode` + `AppSettingsService` API
  - 涉及文件：`lib/core/settings/llm_subtitle_display_mode.dart`, `app_settings_service.dart`
- [x] **Step 2**：Expose dual helpers on `PlayerViewModel`
  - 涉及文件：`lib/presentation/viewmodels/player_viewmodel.dart`
- [x] **Step 3**：Render dual lines in `LyricLine` / `PlayerLyricView`
  - 涉及文件：`lib/widgets/lyrics/components/lyric_line.dart`, `player_lyric_view.dart`
- [x] **Step 4**：Settings UI + l10n strings
  - 涉及文件：`llm_translation_settings_screen.dart`, `app_*.arb`, `strings.dart`
- [x] **Step 5**：Overlay dual text + test
  - 涉及文件：`lyric_overlay_manager.dart`, `test/presentation/viewmodels/dual_subtitle_display_test.dart`

## 5. 风险与回滚（Risks）

- **风险**：Index mismatch if translation drops lines — mitigated by translation service preserving indices.
- **回滚**：Revert commit; setting defaults to `translationOnly`.

## 6. 备注 / 决策记录

- Primary line = translated (from `ISubtitleService`); secondary = `_subtitleSourceList` at same index.
- Default display mode: `dual` (user must-have).
