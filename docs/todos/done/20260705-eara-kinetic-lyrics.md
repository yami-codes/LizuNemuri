# Milestone B: Eara kinetic centered lyrics

- **Created**: 2026-07-05
- **Owner**: cursor-agent
- **Status**: done
- **Related Issue / PR**: [`docs/eara_ui_north_star.md`](../eara_ui_north_star.md) Milestone B (6B)

---

## 1. Goal

Bring Apple/Eara-style **kinetic centered lyrics** to the player: active line stays viewport-centered (`alignment: 0.5`), smooth scroll follow during playback, position-based scale/weight emphasis, dual-subtitle rows preserved.

## 2. Scope

**In scope:**
- `PlayerLyricView` — center alignment, smoother scroll, `ItemPositionsListener` kinetic emphasis, 3s manual-scroll debounce preserved
- `LyricLine` — animated scale/weight/opacity from emphasis token; dual `secondaryText` layout unchanged
- Widget / pure-function tests under `test/widgets/lyrics/`

**Out of scope:**
- `player_screen.dart`, `mini_player/*`, `app_settings_service.dart`
- Lock-screen / floating overlay lyric changes

## 3. Acceptance

- [x] Active lyric line scrolls to vertical center (`alignment: 0.5`) with smooth animation after first paint
- [x] Manual drag disables auto-scroll; re-enables after 3s debounce (existing behavior)
- [x] Lines near viewport center gain subtle scale + weight emphasis; inactive/off-screen lines stay dimmer
- [x] Dual subtitle rows (translation + original) render and emphasize together
- [x] `flutter analyze lib/widgets/lyrics/` passes
- [x] New tests under `test/widgets/lyrics/` pass

## 4. Steps

- [x] **Step 1**: Create TODO + branch `cursor/eara-kinetic-lyrics-1e9b`
  - Verify: doc in `docs/todos/active/`
- [x] **Step 2**: Add `lyricKineticEmphasis` + wire `ItemPositionsListener` in `PlayerLyricView`
  - Files: `player_lyric_view.dart`
  - Verify: `test/widgets/lyrics/lyric_kinetic_emphasis_test.dart`
- [x] **Step 3**: Animate scale/weight on `LyricLine` from `emphasis`
  - Files: `lyric_line.dart`
  - Verify: `test/widgets/lyrics/lyric_line_test.dart`
- [x] **Step 4**: Run `fvm flutter test test/widgets/lyrics/` + analyze — 10 passed, 0 issues
- [x] **Step 5**: Commit, push, complete marker + `/init`

## 5. Risks

- **Risk**: Extra rebuilds from `itemPositions` listener — mitigated by `RepaintBoundary` on `LyricLine`
- **Rollback**: Revert branch commit

## 6. Notes

- Eara ref: `AppleLyricsView.kt` — center-active + proximity emphasis
- Scroll duration: `AppAnimations.long` + `smoothScroll` for follow
- On manual-scroll debounce expiry: reset `_lastScrolledSubtitle` so re-center always runs
- `LyricLine` API: `opacity`/`isActive` replaced by single `emphasis` (0–1)

---

## ✅ Done

- Completed at: 2026-07-05 09:30 UTC
- Command run: `/init`
- CLAUDE.md update summary: Added kinetic lyrics invariants under `lib/widgets/` + `test/widgets/lyrics/` coverage in Tests section.
- Related commit: `87bbbb4`
