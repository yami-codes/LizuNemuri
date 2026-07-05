# Milestone B: Eara kinetic centered lyrics

- **创建时间**：2026-07-05
- **负责人**：cursor-agent
- **状态**：done
- **父文档**：[`docs/eara_ui_north_star.md`](../eara_ui_north_star.md) Milestone B (6B)

---

## 1. 目标（Goal）

Bring Apple/Eara-style **kinetic centered lyrics** to the player: active line stays viewport-centered (`alignment: 0.5`), smooth scroll follow during playback, position-based scale/weight emphasis, dual-subtitle rows preserved.

## 2. 范围（Scope）

**包含：**
- `PlayerLyricView` — center alignment, smoother scroll, `ItemPositionsListener` kinetic emphasis, 3s manual-scroll debounce preserved
- `LyricLine` — animated scale/weight/opacity from emphasis token; dual `secondaryText` layout unchanged
- Widget / pure-function tests under `test/widgets/lyrics/`

**不包含：**
- `player_screen.dart`, `mini_player/*`, `app_settings_service.dart`
- Lock-screen / floating overlay lyric changes

## 3. 验收标准（Acceptance）

- [x] Active lyric line scrolls to vertical center (`alignment: 0.5`) with smooth animation after first paint
- [x] Manual drag disables auto-scroll; re-enables after 3s debounce (existing behavior)
- [x] Lines near viewport center gain subtle scale + weight emphasis; inactive/off-screen lines stay dimmer
- [x] Dual subtitle rows (translation + original) render and emphasize together
- [x] `flutter analyze lib/widgets/lyrics/` passes
- [x] New tests under `test/widgets/lyrics/` pass

## 4. 拆解步骤（Steps）

- [x] **Step 1**：Create TODO + branch `cursor/eara-kinetic-lyrics-1e9b`
  - 验证：doc in `docs/todos/active/`
- [x] **Step 2**：Add `lyricKineticEmphasis` + wire `ItemPositionsListener` in `PlayerLyricView`
  - 涉及文件：`player_lyric_view.dart`
  - 验证：`test/widgets/lyrics/lyric_kinetic_emphasis_test.dart`
- [x] **Step 3**：Animate scale/weight on `LyricLine` from `emphasis`
  - 涉及文件：`lyric_line.dart`
  - 验证：`test/widgets/lyrics/lyric_line_test.dart`
- [x] **Step 4**：Run `fvm flutter test test/widgets/lyrics/` + analyze — 10 passed, 0 issues
- [x] **Step 5**：Commit, push, complete marker + `/init`

## 5. 风险与回滚（Risks）

- **风险**：Extra rebuilds from `itemPositions` listener — mitigated by `RepaintBoundary` on `LyricLine`
- **回滚**：Revert branch commit

## 6. 备注 / 决策记录

- Eara ref: `AppleLyricsView.kt` — center-active + proximity emphasis
- Scroll duration: `AppAnimations.long` + `smoothScroll` for follow
- On manual-scroll debounce expiry: reset `_lastScrolledSubtitle` so re-center always runs
- `LyricLine` API: `opacity`/`isActive` replaced by single `emphasis` (0–1)

---

## ✅ 完成标记

- 完成时间：2026-07-05 09:30 UTC
- 执行命令：`/init`
- CLAUDE.md 更新摘要：Added kinetic lyrics invariants under `lib/widgets/` + `test/widgets/lyrics/` coverage in Tests section.
- 关联 commit：`87bbbb4`
