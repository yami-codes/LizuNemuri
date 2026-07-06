# Dual subtitles (original + LLM translation)

- **Created**: 2026-07-05
- **Owner**: cursor-agent
- **Status**: active
- **Related Issue / PR**: https://github.com/yami-codes/Xuro/pull/11

---

## 1. Goal

Stack original and translated subtitle lines in the player (and Android floating overlay) so users can read both at once — must-have per product roadmap.

## 2. Scope

**In scope:**
- `LlmSubtitleDisplayMode` setting (`translationOnly` | `dual`)
- `AppSettingsService` persistence + settings UI
- `PlayerLyricView` / `LyricLine` dual-line rendering
- `PlayerViewModel` original-line lookup from `_subtitleSourceList`
- Android `LyricOverlayManager` two-line text when dual active
- L10n (en / zh / th) + unit test

**Out of scope:**
- Lock-screen notification dual lines
- Re-translate on language change (separate roadmap item)

## 3. Acceptance

- [x] When LLM translation is active and display mode is dual, each lyric row shows translation (primary) + original (secondary).
- [x] `translationOnly` mode shows current single-line behavior.
- [x] Setting persists across restart; player rebuilds without re-translate.
- [x] Floating overlay shows two lines when dual active (Android).
- [x] `flutter analyze` passes; new unit test passes.

## 4. Steps

- [x] **Step 1**: Add `LlmSubtitleDisplayMode` + `AppSettingsService` API
  - Files: `lib/core/settings/llm_subtitle_display_mode.dart`, `app_settings_service.dart`
- [x] **Step 2**: Expose dual helpers on `PlayerViewModel`
  - Files: `lib/presentation/viewmodels/player_viewmodel.dart`
- [x] **Step 3**: Render dual lines in `LyricLine` / `PlayerLyricView`
  - Files: `lib/widgets/lyrics/components/lyric_line.dart`, `player_lyric_view.dart`
- [x] **Step 4**: Settings UI + l10n strings
  - Files: `llm_translation_settings_screen.dart`, `app_*.arb`, `strings.dart`
- [x] **Step 5**: Overlay dual text + test
  - Files: `lyric_overlay_manager.dart`, `test/presentation/viewmodels/dual_subtitle_display_test.dart`

## 5. Risks

- **Risk**: Index mismatch if translation drops lines — mitigated by translation service preserving indices.
- **Rollback**: Revert commit; setting defaults to `translationOnly`.

## 6. Notes

- Primary line = translated (from `ISubtitleService`); secondary = `_subtitleSourceList` at same index.
- Default display mode: `dual` (user must-have).
