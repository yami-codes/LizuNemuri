# Sidebar Drawer Visual Redesign (Dark Glassmorphism)

- **Created**: 2026-05-15
- **Owner**: claude
- **Status**: done
- **Related Issue / PR**: N/A

---

## 1. Goal

Refactor the left drawer from default Material Drawer to dark glassmorphism style: dark blue-purple gradient background + frosted glass + semi-transparent grouped cards + colored rounded icons, improving visual hierarchy and quality; add expected entries "Recent plays / Rankings / Dark mode / About us".

## 2. Scope

**In scope:**
- Refactor `lib/widgets/sidebar/sidebar_menu.dart`: drawer width ~72% screen, right-side top/bottom corners only, dark blue-purple gradient + lower-frequency frosted glass overlay.
- Refactor `lib/widgets/sidebar/sidebar_header.dart`: large profile card (circular gradient avatar + primary/secondary copy + right circular arrow button).
- Refactor `lib/widgets/sidebar/sidebar_group.dart`: group title + semi-transparent card + subtle glow border.
- Refactor `lib/widgets/sidebar/sidebar_tile.dart`: colored square icons, white Chinese labels, light chevron.
- Three sections (Content / Discover / System), new entries: Recent plays, Rankings, Dark mode, About us.
- "Dark mode" calls `ThemeController.toggleThemeMode()` directly, trailing badge shows current mode.
- "About us" navigates to `SettingsScreen` (about section already exists).
- "Recent plays / Rankings" no backend yet — tap shows "Coming soon" SnackBar placeholder.
- Drawer bottom version from `pubspec.yaml` actual version (`PackageInfo`).

**Out of scope:**
- No new RankingScreen / RecentPlayScreen / standalone AboutScreen.
- No ViewModel / Service / data model changes.
- No change to `MainScreen` Drawer integration (still `Scaffold.drawer`).
- No changes outside drawer (top bar, bottom bar, content area).

## 3. Acceptance

- [ ] Drawer open ~72% width, obvious right top/bottom corners (≥24px), left edge flush.
- [ ] Background dark blue→dark purple vertical gradient + frosted glass texture; right scrim dims main content.
- [ ] Profile card: circular gradient avatar + "Log in now / Sync favorites and history" (logged out) or username (logged in), circular arrow button on right.
- [ ] Three group titles (Content / Discover / System) light gray outline; group cards semi-transparent with 1px glow border.
- [ ] Each menu item: colored rounded square icon left, white text, chevron right; subtle press feedback.
- [ ] "Dark mode" tap toggles ThemeMode, trailing shows current mode text (System/Light/Dark).
- [ ] "Recent plays / Rankings" tap shows "Coming soon" SnackBar, no crash.
- [ ] "About us" navigates to SettingsScreen.
- [ ] "Favorites / Tags / Circles / Voice actors / Settings" keep existing navigation.
- [ ] Light mode drawer still dark glass style (forced dark scheme over drawer, avoid global theme inversion).
- [ ] `flutter analyze` passes with no new warnings.

## 4. Steps

- [x] **Step 1**: Refactor `sidebar_tile.dart`, support custom trailing (dark mode status text) + transparent background, white text, colored icons.
  - Output: `lib/widgets/sidebar/sidebar_tile.dart`
- [x] **Step 2**: Refactor `sidebar_group.dart` to semi-transparent rounded card + glow border.
  - Output: `lib/widgets/sidebar/sidebar_group.dart`
- [x] **Step 3**: Refactor `sidebar_header.dart` to large profile card, logged out shows "Log in now / Sync favorites and history" + circular arrow button.
  - Output: `lib/widgets/sidebar/sidebar_header.dart`
- [x] **Step 4**: Refactor `sidebar_menu.dart`: 72% width, large right corners, dark blue-purple gradient + BackdropFilter glass overlay, three menu groups, bottom version.
  - Output: `lib/widgets/sidebar/sidebar_menu.dart`
- [x] **Step 5**: `flutter analyze` passes.
  - Verify: `fvm flutter analyze lib/widgets/sidebar/` → `No issues found!`. Full project only 33 pre-existing `withOpacity` deprecations, none in changed files.

## 5. Risks

- **Risk**: BackdropFilter may hurt drawer open frame rate on low-end devices.
  - **Mitigation**: blur sigma ≤18, single overlay inside drawer only.
- **Risk**: forced dark scheme over drawer may contrast oddly with light global theme.
  - **Mitigation**: drawer is separate layer, scrim masks transition naturally.
- **Rollback**: four single-file refactors, `git revert` restores.

## 6. Notes / Decision Log

- "Recent plays / Rankings" — replace onTap when dedicated screens added later.
- Version via `package_info_plus` already a project dependency (`settings_screen` uses it), no new dep.

---

## ✅ Done

- Completed at: 2026-05-15
- Command run: `/init`
- CLAUDE.md update summary: added FVM commands, `lib/core/{database,image,settings}`, `lib/presentation/{layouts,models,widgets}`, `lib/utils/` directory descriptions and test status; `lib/widgets/sidebar/` paragraph notes dark Theme local override.
- Related commit: `feat(sidebar): glassmorphism dark drawer redesign` (hash see git log)
- Codex review: SESSION_ID `019e2873-2990-72e2-bc68-ba47328971b7`, three rounds ⚠️→⚠️→✅ PASS (see unreleased CHANGELOG.md section).

## 7. Runtime Verification Notes

Items requiring user manual check after `fvm flutter run`: drawer width ratio, glass blur feel, login card shadow/glow, dark mode badge toggle, unimplemented entry SnackBar. All implemented at code level.
