# Apple Music player polish — swipe, art, lyric wobble

- **Created**: 2026-07-06
- **Owner**: cursor-agent
- **Status**: active

## 1. Goal

Polish the player toward Apple Music Now Playing: swipe between cover/lyrics, smoother surface transitions, album-art crossfade on track change, and fix kinetic lyric size wobble on the active line.

## 2. Scope

**In scope:**
- Vertical swipe (narrow layout) cover ↔ lyrics
- Surface transition tuning (slide/fade/scale)
- Album art `AnimatedSwitcher` on track change + subtle play pulse
- Lyric line: fixed typography; animate opacity/blur/scale only (no fontSize wobble)
- Full twist backdrop GLSL shader (four stacked art layers)

**Out of scope:** Word-level karaoke, animated album motion video

## 3. Acceptance

- [x] Swipe up/down toggles cover/lyrics on narrow player
- [x] Track change crossfades album art
- [x] Active lyric line no longer pulses font size during scroll
- [x] Twist backdrop shader registered and wired
- [x] Tests updated; `flutter analyze` clean (pre-existing warnings only)

## 4. Steps

- [x] LyricLine fixed-size kinetic emphasis — `lib/widgets/lyrics/components/lyric_line.dart`
- [x] PlayerSurfaceSwitcher + swipe gesture — `player_screen.dart`, `player_surface_transition.dart`
- [x] Album art animated switcher + play pulse — `circular_cover.dart`, `player_art_panel.dart`
- [x] Twist backdrop shader — `shaders/twist_backdrop.frag`, `twist_backdrop_shader.dart`, `cover_artwork_background.dart`
- [x] Tests + analyze — `test/widgets/lyrics/*`, `test/widgets/player/*`
