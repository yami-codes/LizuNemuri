# Color Palette Simplification: 3 Switchable Accent Colors (Blue/Mono/Green) + Theme Tokens + Sidebar Adaptation

- **Created**: 2026-05-15
- **Owner**: claude
- **Status**: done
- **Related Issue / PR**: Follow-up to `20260515-flutter-performance-optimization.md` (most P0 items already fixed); this task is user-driven UI simplification, outside performance scope.

---

## 1. Goal

Simplify the app's current purple Material 3 theme to **3 "accent + black/white" two-color schemes** (Blue+White / Mono / Green+White), user-switchable in Settings and persisted in `AppSettingsService`. Also clean up 8 hardcoded colored icon backgrounds in the sidebar, converging on theme-token-driven styling.

## 2. Scope

**In scope:**
- `lib/core/theme/app_colors.dart`: replace single fixed `lightColorScheme` / `darkColorScheme` with **3 light + dark schemes per `ColorVariant` enum** (6 ColorSchemes total).
- `lib/core/theme/app_theme.dart`: `AppTheme.light(variant)` / `AppTheme.dark(variant)` factory functions.
- `lib/core/theme/theme_controller.dart`: reuse `AppSettingsService` persistence (no separate ThemeController storage — avoid dual source); or add `colorVariant` getter listening to settings changes.
- `lib/core/settings/app_settings_service.dart`: add `ColorVariant` enum + `colorVariant` getter/setter + persistence key.
- `lib/main.dart`: `MaterialApp.theme` / `darkTheme` follow current `colorVariant`.
- `lib/screens/settings/settings_screen.dart`: new "Accent color" group after "Appearance", with 3 `SettingsTile.selection` rows.
- `lib/widgets/sidebar/sidebar_menu.dart`:
  - `_DrawerBackground` gradient → **neutral dark** (remove purple tint), compatible with all 3 schemes.
  - `_SoftGlow` × 2 → color from `Theme.of(context).colorScheme.primary` + low alpha.
  - All 9 `SidebarTile.iconBackgroundColor` unified to single neutral gray (eliminate 8 distinct colors).
  - Footer purple glow dot → theme `primary`.
- `lib/widgets/sidebar/sidebar_header.dart`:
  - `_ProfileAvatar` purple gradient → theme `primary` gradient (light/dark ends).
  - Shadow / glow colors → theme `primary`.
- `lib/common/constants/strings.dart`: add `colorVariantTitle`, `colorVariantBlue`, `colorVariantMono`, `colorVariantGreen`, `colorVariantDesc`.

**Out of scope:**
- Do not change `SidebarGroup` / `SidebarTile` (already white + alpha only, scheme-agnostic).
- No full-app color audit (30+ files with hardcoded colors) — per user decision, scope is "theme tokens + sidebar" only.
- Do not touch mini player, full-screen player, detail page, or list card hardcoded colors. These mostly use `Theme.of(context)` and should **auto-follow** the new theme; local hardcoded conflicts, if any, are a follow-up PR.
- Do not change dark Theme override mode — sidebar keeps forced dark glass look; only accent / glow follows the new scheme.

## 3. Acceptance

- [ ] `AppSettingsService` exposes `ColorVariant { blue, mono, green }` enum and `colorVariant` field, default `blue`.
- [ ] After switching `colorVariant`, entire app `colorScheme.primary` updates immediately; Light / Dark modes work independently.
- [ ] Settings page adds "Accent color" group below "Appearance", three-way selection matching existing "System/Light/Dark" interaction.
- [ ] Sidebar under all 3 schemes:
  - Gradient background = neutral dark (no purple residue)
  - Profile avatar / circular arrow button / footer dot = current `primary`
  - 9 icon backgrounds = same neutral gray (no 8 distinct colors)
- [ ] `fvm flutter analyze` passes.
- [ ] Persistence: cold start after kill process restores last selected `colorVariant`.

## 4. Steps

- [x] **Step 1**: `AppSettingsService` add `ColorVariant { blue, mono, green }` enum + `colorVariant` getter / `setColorVariant` setter + persistence (key `color_variant`, default `blue`).
- [x] **Step 2**: `AppColors.lightSchemeFor(variant)` / `darkSchemeFor(variant)` factories; 3×2 = 6 hand-written ColorSchemes (accent + onAccent + accentContainer tables; surfaces all neutral).
- [x] **Step 3**: `AppTheme.light(variant)` / `AppTheme.dark(variant)` factories; keep cardTheme / appBarTheme.
- [x] **Step 4**: `main.dart` assembled with `Consumer2<ThemeController, AppSettingsService>`; `AppSettingsService` provided via `ChangeNotifierProvider.value(getIt<AppSettingsService>())`.
- [x] **Step 5**: `Strings` add `colorVariantTitle / Desc / Blue / Mono / Green` (5 items).
- [x] **Step 6**: `SettingsScreen._colorVariantSection` inserted between "Appearance" and "Network", 3 `SettingsTile.selection` rows (leading: `Icons.circle`).
- [x] **Step 7**: `sidebar_menu.dart` — neutralized gradient (near-black three-stop), glows + footer dot use `Theme.of(context).colorScheme.primary`, 9 icon backgrounds unified to top-level `_kIconBgGray = 0xFF8E8E93`.
- [x] **Step 8**: `sidebar_header.dart` — avatar gradient uses `primary` + `Color.lerp(primary, black, 0.45)`; card shadow uses `primary.withValues(alpha: 0.18)`.
- [x] **Step 9**: `fvm flutter analyze` full project → 33 pre-existing `withOpacity` deprecations unchanged, no new issues.

## 5. Risks

- **Risk 1**: Hand-written ColorScheme may lack M3 derived tokens (`primaryContainer`, `onPrimaryContainer`, `tertiary`, etc.), causing some components to lose color.
  - **Mitigation**: reuse existing `AppColors.lightColorScheme` field set as minimum; extend tokens as needed.
- **Risk 2**: Sidebar without colored icons may look too flat.
  - **Mitigation**: keep gradient + border + shadow for depth; optional accent exception for "Favorites" if needed. Ship unified gray first, gather feedback.
- **Risk 3**: Out-of-scope pages (detail, player) may have hardcoded purple, causing visual disconnect under new theme.
  - **Mitigation**: this TODO does not fix those; open follow-up TODO if jarring.
- **Rollback**: all changed files listed; phased commits allow per-phase revert.

## 6. Notes / Decision Log

- **Decision A**: Hand-write 6 ColorSchemes, do not use `ColorScheme.fromSeed` — the latter derives secondary/tertiary introducing a second hue, violating the "two-color" simplification principle.
- **Decision B**: Persist `colorVariant` in `AppSettingsService` not `ThemeController` — `ThemeController` only manages light/dark/system; accent is user preference, same layer as existing settings (serverUrl / smartPath / audioFormatOrder).
- **Decision C**: Sidebar keeps forced dark glass appearance; only accent follows user choice. Rationale: always-dark drawer was intentional affordance; light-theme users should not lose it.
- **Decision D**: All 9 icon backgrounds unified to single neutral gray (remove 8 colors) — strictest "two-color" execution.

---

## ✅ Done

- Completed at: 2026-05-15
- Command run: `/init`
- CLAUDE.md update summary: noted in `core/theme/` paragraph that theme is determined by (`ThemeMode` × `ColorVariant`) dual axis; `widgets/sidebar/` paragraph adds pitfall: when sidebar forces local dark Theme, must explicitly use `AppColors.darkSchemeFor(variant)`, not just `copyWith(brightness: dark)`.
- Related commit: (pending commit)
- Codex review: SESSION_ID `019e2873-2990-72e2-bc68-ba47328971b7`, three rounds ⚠️→❌→✅ PASS.
- Runtime verification: still pending user device check of 3 accent colors × light/dark (6 combinations).

## 7. Review

- **Round 1** (❌ CHANGE):
  - **High**: `sidebar_menu.dart` uses `Theme.copyWith(brightness: dark)` which only toggles brightness flag, not primary — light + mono variant keeps black primary, making glow/avatar/footer invisible on near-black background. Fix: `copyWith(brightness: dark, colorScheme: AppColors.darkSchemeFor(variant))`, watch `AppSettingsService` for variant.
  - **Medium**: `lightSurfaceL1/L2` still old purple tint (`#F7F2FA / #F3EDF7`), consumed by `SettingsTheme` → purple leaks in mono/green light mode. Fix: neutralize to `#F7F7F7 / #F2F2F2`, dark L1/L2 to `#1F1F1F / #252525`.
- **Round 2** (❌ CHANGE):
  - **Medium**: `_ArrowButton` still fixed white, but `sidebar_menu.dart` comments and TODO acceptance say arrow should use primary — code/docs mismatch. Fix: background / border / icon all derived from `accent` (mono dark degrades to white, matching original look).
- **Round 3** (✅ PASS): all promised accent affordances (avatar / arrow / footer dot / glow / card shadow) derived from dark variant primary; local Theme dual-axis consistent; `SettingsTheme` neutralization compliant.
