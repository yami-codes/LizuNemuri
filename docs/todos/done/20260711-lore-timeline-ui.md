# Player lore timeline UI polish

- **Created**: 2026-07-11
- **Owner**: mirai
- **Status**: done

## 1. Goal

> Make the player Lore timeline usable: auto-follow playhead, desktop scroll, and enough vertical space — organized layout.

## 2. Scope

**In scope:** `LoreTrackTimeline` + `PlayerLorePanel` layout + surface switcher fill  
**Out of scope:** Detail lore panel rewrite

## 3. Acceptance

- [x] Timeline auto-scrolls to keep playhead in view during playback
- [x] Desktop mouse drag + wheel can scroll the timeline horizontally
- [x] Timeline gets a dedicated Expanded region (not cramped under a long param list)
- [x] analyze clean

## 4. Steps

- [x] Rewrite timeline + panel layout (`lore_track_timeline.dart`, `player_lore_panel.dart`)
- [x] `PlayerSurfaceSwitcher` `StackFit.expand` + `SizedBox.expand` so lore Column gets height
- [x] analyze + close TODO

## 5. Risks

- **Risk**: Wheel→horizontal may feel odd when many lanes need vertical wheel — mitigated by only mapping dy when horizontal overflow exists
- **Rollback**: Revert the three widget files

---

## ✅ Done

- Completed at: 2026-07-11 16:20
- Command run: `/init` (manual CLAUDE.md player lore timeline layout note)
- CLAUDE.md update summary: Documented Expanded lore panel, playhead auto-follow, desktop scroll, surface switcher expand.
- Related commit: (pending user commit)
