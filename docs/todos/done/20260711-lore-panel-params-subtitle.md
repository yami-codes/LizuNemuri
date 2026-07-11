# Player lore panel: all secret params + current subtitle

- **Created**: 2026-07-11
- **Owner**: mirai
- **Status**: done

## 1. Goal

> On the player Lore tab, show all character params when secrets are revealed (not a truncated chip strip), and show the current subtitle line so listening + lore stay in sync.

## 2. Scope

**In scope:**
- `PlayerLorePanel` param strip (show all / respect `explicitRevealed`)
- Current subtitle line on Lore tab
- Compact chip overflow (Wrap scrollable)
- Timeline lane hard-cap removed

**Out of scope:**
- HUD overlay rewrite
- Detail work lore panel

## 3. Acceptance

- [x] When lore has secrets / `explicitRevealed`, Lore tab chips show all projected params (not only pinned/active ≤8)
- [x] Timeline still has usable height (params scroll if many)
- [x] Current subtitle line visible on Lore tab (updates with playback)
- [x] `flutter analyze` clean on touched files

## 4. Steps

- [x] **Step 1**: Rewrite param strip + subtitle banner in `player_lore_panel.dart`; drop timeline `.take(16)`
- [x] **Step 2**: analyze + close TODO

## 5. Risks

- **Risk**: Many params squeeze timeline — mitigated with max-height scroll
- **Rollback**: Revert panel + timeline lane change

## 6. Notes

> Root cause: panel used `preferred.take(8)` (pinned ∪ active only), so inactive secret ontology keys lived only in the timeline lanes.

---

## ✅ Done

- Completed at: 2026-07-11 16:50
- Command run: `/init` (manual CLAUDE.md player lore panel note)
- CLAUDE.md update summary: Documented all-params-when-revealed + current subtitle on Lore tab.
- Related commit: (pending user commit)
