# Settings Icon Coherence Fix + Player Sleep Timer Quick Action

- **Created**: 2026-05-16
- **Owner**: WuMe-sicx
- **Status**: done <!-- active | done | cancelled -->
- **Related Issue / PR**: Continues `20260516-five-screen-layout-token-polish.md` (row metrics fixed), `20260516-sleep-timer-and-background-play.md` (`SleepTimerController` already implemented)
- **Visual baseline**: User-provided settings-specific reference image (blue-white / B&W dark / green-white three variants, `~/Downloads/ChatGPT Image 2026-05-16 16_49_10.png`)

## 0. Decision Log (Key)

- User feedback: "Overall UI plan is good, but settings page layout feels incoherent, needs layout adjustment (as in image)" + "Add sleep timer button to player for quick access."
- **Existing discipline**: User previously chose "pure layout/token polish, no invention." Reference has many **rows without backend** (auto-play next / after-play action / volume / sound mode / equalizer / language) — **all omitted** ([[feedback-reference-reskin-discipline]]).
- Settings "incoherence" **specific defect** (not subjective reskin): **duplicate leading icons within groups** — appearance `Icons.palette_outlined`×3, color `Icons.circle`×3 (all neutral gray, color picker doesn't show colors), network `Icons.lan_outlined`×N. Reference uses **distinct meaningful icons per row**; color rows should show **each variant's real accent**. Textbook list incoherence; fixing aligns with reference without inventing features.
- Player sleep timer shortcut: `SleepTimerController` exists (real feature); add one icon button to player AppBar **existing actions row**, **no new control row** ([[feedback-player-ui-minimal]]).

## 1. Goal

> Fix settings "duplicate same icon within group" incoherence (appearance three rows distinct semantic icons; color three rows show each real accent — color picker regains meaning), and add sleep timer as one-tap player AppBar entry; no invented reference rows without backend.

## 2. Scope

**In scope:**
- `settings_tile.dart`: optional `Color? leadingColor` (through private ctor + `.selection` factory; `null` keeps current `onSurfaceVariant` — existing behavior/`settings_d1_test` unaffected).
- `settings_screen.dart`:
  - Appearance group: follow system/light/dark → `Icons.brightness_auto_outlined`/`light_mode_outlined`/`dark_mode_outlined` (replace `palette_outlined`×3, semantic icons only).
  - Color group: leading solid `Icons.circle` + `leadingColor` = that variant's **real `primary` for current brightness** (`AppColors.lightSchemeFor/darkSchemeFor(variant).primary`) — blue/mono/green show true colors, picker regains semantics.
- `player_screen.dart`: AppBar `actions` add `IconButton` (`Icons.bedtime`/`bedtime_outlined`, tint `primary` when `SleepTimerController.isActive`), opens existing `SleepTimerDialog`; `ListenableBuilder` listens controller (mirrors wakelock action). Reuse `Strings.sleepTimer`.

**Out of scope (no invention):**
- No reference rows without backend: auto-play next, after-play action, volume, sound mode, equalizer, language — none added.
- No settings group semantic restructure (user meant incoherence = duplicate icons/no semantic color, not "wrong groups"; aggressive regroup is churn without specific defect, omitted per discipline).
- Network group keeps single `lan` icon (homogeneous node list, single icon is convention, not significant defect).
- Don't break three-variant invariant: colored leading on color rows is **color-picker content data** (intentional per-variant color, semantic exception), other leading stays neutral.
- Player: no new control row / no playback logic changes.

## 3. Acceptance

- [x] Settings→Appearance three distinct meaningful icons; color three rows show blue/mono/green real accent (correct across three variants × brightness; mono white dot dark / black dot light).
- [x] Other settings rows leading still neutral `onSurfaceVariant` (`leadingColor` default unchanged).
- [x] Player AppBar has sleep timer button, opens `SleepTimerDialog`; active tints accent; on expiry pauses (reuses controller, no new logic).
- [x] No invented reference rows without backend.
- [x] `flutter analyze` no new warnings; full `flutter test` zero regression (`settings_d1_test`/`atom_three_variant_test` still pass — `leadingColor` default null preserves assertions).
- [x] Codex review ✅ PASS.
- [x] User visual check settings coherent + player button works across three variants × brightness → `/init` close.

## 4. Steps

- [x] **Step 1** This TODO doc ✅ 2026-05-16.
- [x] **Step 2** ✅ 2026-05-16: `settings_tile.dart` optional `leadingColor` (default null→onSurfaceVariant, through `.selection`); `settings_screen` appearance `brightness_auto/light_mode/dark_mode` semantic icons, color rows `leadingColor=_variantSwatch(real primary for current brightness)`, import `AppColors`.
- [x] **Step 3** ✅ 2026-05-16: `player_screen.dart` AppBar actions first slot `ListenableBuilder`→sleep timer `IconButton` (active tints primary), opens `SleepTimerDialog`; no new control row.
- [x] **Step 4** ✅ 2026-05-16: `flutter analyze` (settings/player No issues) + full `flutter test` **103/103 zero regression** (`settings_d1_test`/`atom_three_variant_test` pass).
- [x] **Step 5** ✅ 2026-05-16: Codex review (SESSION_ID `019e2dfd-621a-7652-a5a0-eb75b483bbd8`) → **✅ PASS** (leadingColor backward compatible / semantic icons / variant colors correct / player single action reuses controller / no fiction verified).
- [x] **Step 6** ✅ 2026-05-16: User confirmed, agreed formal close → Done block + `/init` + move to done.

## 5. Risks

- **Risk**: `leadingColor` breaks `settings_d1_test` (asserts leading==onSurfaceVariant).
  - **Mitigation**: optional default `null`→onSurfaceVariant; only color rows opt in; full test verification.
- **Risk**: Colored leading on color rows misread as three-variant invariant violation.
  - **Mitigation**: color-picker **content** (each row should show its color), not component chrome; TODO/comment marks semantic exception; other leading neutral.
- **Risk**: Player AppBar actions crowded.
  - **Mitigation**: only +1 icon, same actions row (no new row), same level as wakelock/lyrics; [[feedback-player-ui-minimal]] compliant.
- **Rollback**: Small independent file changes, revert per file.

## 6. Notes / Decision Log

- 2026-05-16: User cited settings incoherence (settings reference image) + player sleep timer shortcut. Continues: pure layout/no invention ([[feedback-reference-reskin-discipline]]), minimal player row extension ([[feedback-player-ui-minimal]]), Coder not enabled Claude direct edit + Codex review ([[feedback-codex-review-loop]]).

---

## ✅ Done

- Completed at: 2026-05-16 17:40
- Command run: `/init`
- CLAUDE.md update summary: `SettingsTile` optional `leadingColor` (default neutral); settings appearance three semantic icons, color rows show each variant real accent (color picker semantics restored); player AppBar sleep timer quick entry. No invented backend-less rows.
- Related commit: Not committed (user did not request commit; pending user decision)
