# Player immersive clarity — live settings sync

- **Created**: 2026-07-05
- **Owner**: cursor-agent
- **Status**: active
- **Related Issue / PR**: PR #11

---

## 1. Goal

`PlayerImmersiveColors` lyric contrast must follow `AppSettingsService.playerBackdropClarity` live (backdrop already does).

## 2. Scope

**In scope:**
- `player_screen.dart` ListenableBuilder + clarity pass-through
- Tests if needed

**Out of scope:**
- Milestone C global Monet theme

## 3. Acceptance

- [x] Changing clarity slider updates lyric colors without leaving player
- [x] Existing immersive backdrop tests pass

## 4. Steps

- [x] **Step 1**: Wire clarity in `PlayerImmersiveColors.resolve` call
- [x] **Step 2**: Run `immersive_player_backdrop_test.dart`
