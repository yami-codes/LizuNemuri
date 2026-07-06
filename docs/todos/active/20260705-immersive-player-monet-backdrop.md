# Immersive player + Monet cover backdrop

- **Created**: 2026-07-05
- **Owner**: cursor-agent
- **Status**: active
- **Related Issue / PR**:

---

## 1. Goal

Add an Eara-style immersive shell to the player page: blurred cover artwork backdrop + Monet tones extracted from cover, transparent AppBar, shared atmosphere background for lyrics and cover.

## 2. Scope

**In scope:**
- `CoverArtworkBackground` blurred cover + clarity layering
- Cover dominant-color extraction → player backdrop tint / accent
- `PlayerScreen` full-screen Stack layout, transparent chrome
- Lyric line readable colors on immersive background (`PlayerImmersiveScope`)
- Unit tests (backdrop style + hue derivation)

**Out of scope:**
- Settings clarity slider (default 0.35; can add later)
- Dual subtitles, sleep fade-out, spectrum, A–B loop
- Global Theme dynamic color (player canvas only)

## 3. Acceptance

- [ ] When cover URL exists, player shows blurred dynamic background; tint transitions on track change
- [ ] Without cover, falls back to neutral `colorScheme` background
- [ ] AppBar / controls remain readable; three variants still use `colorScheme` for chrome
- [ ] Narrow layout cover↔subtitle toggle and wide split layout both work
- [ ] `fvm flutter analyze` no new warnings
- [x] Related unit tests pass

## 4. Steps

- [x] **Step 1**: `palette_generator` + hue/backdrop pure functions
  - Files: `pubspec.yaml`, `lib/core/theme/player_hue_derivation.dart`, `lib/widgets/player/cover_artwork_backdrop_style.dart`
  - Verify: unit tests
- [x] **Step 2**: `CoverArtworkBackground` + palette loader
  - Files: `lib/widgets/player/cover_artwork_background.dart`, `player_cover_palette_loader.dart`, `player_immersive_scope.dart`
  - Verify: analyze
- [x] **Step 3**: Wire into `PlayerScreen` + lyric readable colors
  - Files: `lib/screens/player_screen.dart`, `lib/widgets/lyrics/components/lyric_line.dart`
  - Verify: analyze + test
- [x] **Step 4**: Commit and open PR
  - PR: https://github.com/yami-codes/Xuro/pull/11
  - commit: 4151944
  - Verify: CI local analyze/test

## 5. Risks

- **Risk**: Palette extraction adds async first-frame work; blur cost on low-end devices
- **Rollback**: Revert branch or `enabled: false` constant

## 6. Notes

- Reference: Eara `CoverArtworkBackground.kt` + `HueDerivation.kt` + `LyricReadableColors.kt`
- Dynamic color limited to player page; does not break three-variant global invariant

---

## ✅ Done

- Completed at:
- Command run: `/init`
- CLAUDE.md update summary:
- Related commit:
