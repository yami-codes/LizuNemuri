# Player backdrop clarity slider

- **Created**: 2026-07-05
- **Owner**: cursor-agent
- **Status**: active
- **Related Issue / PR**: Eara player polish (Milestone A)

---

## 1. Goal

Let users adjust player cover background clarity (0–100%) in Settings, persisted to SharedPreferences; `CoverArtworkBackground` listens to `AppSettingsService` for live updates.

## 2. Scope

**In scope:**
- `AppSettingsService.playerBackdropClarity` (0.0–1.0, default 0.35)
- `CoverArtworkBackground` reads setting via `ListenableBuilder`
- Settings → Playback section slider
- l10n (en/zh/th) + `Strings`
- Unit / widget test extensions

**Out of scope:**
- `player_screen.dart`, `mini_player/*`, `player_lyric_view.dart`
- `PlayerImmersiveScope` lyric color estimation (still uses constant; future milestone)

## 3. Acceptance

- [x] Settings slider adjustable 0–100%; persists across restart
- [x] Player background updates immediately when setting changes (no need to leave page)
- [x] `fvm flutter analyze` no new warnings
- [x] `immersive_player_backdrop_test` + settings persistence tests pass

## 4. Steps

- [x] **Step 1**: `AppSettingsService` field + getter/setter
  - Files: `lib/core/settings/app_settings_service.dart`
  - Verify: default 0.35, clamp 0–1
- [x] **Step 2**: `CoverArtworkBackground` listens to setting
  - Files: `lib/widgets/player/cover_artwork_background.dart`
  - Verify: ListenableBuilder rebuild
- [x] **Step 3**: Settings page slider + l10n
  - Files: `settings_screen.dart`, `app_*.arb`, `strings.dart`
  - Verify: `gen-l10n` succeeds
- [x] **Step 4**: Tests + analyze
  - Files: `test/widgets/player/immersive_player_backdrop_test.dart`
  - Verify: `fvm flutter test` / `analyze`

## 5. Risks

- **Risk**: `player_screen` still passes `kPlayerCoverBackdropClarity` constant — component prefers setting internally, ignores param
- **Rollback**: Revert this branch commit

## 6. Notes

- Default 0.35 matches `kPlayerCoverBackdropClarity`; existing users see no visual jump on upgrade.

## ✅ Done

- Moved during 2026-07-09 system audit (shipped or superseded by M3 player).
- /init: skipped (batch housekeeping)
- Timestamp: 2026-07-09
