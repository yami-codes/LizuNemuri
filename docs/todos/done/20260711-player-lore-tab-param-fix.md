# Player lore tab + live param projection fix

- **Created**: 2026-07-11
- **Owner**: mirai
- **Status**: done
- **Related Issue / PR**:

---

## 1. Goal

> Fix playback lore params stuck at 0, move the detailed param view into a full player tab, and let users hide the compact overlay HUD.

## 2. Scope

**In scope:**
- `LoreStateProjector`: cross-track carry + fuzzy trackKey resolve (alt hash / 无效果音 / ext)
- Player third surface tab: Cover | Lyrics | Lore (full param + timeline)
- Hideable compact overlay (`AppSettingsService` + HUD toggle)
- Unit tests for projection regressions

**Out of scope:**
- Regenerating existing lore packs
- Changing LLM prompts / ontology

## 3. Acceptance

- [x] On a later track, params reflect prior-track end state before local events
- [x] Playing a no-SFX / alt-hash sibling still projects the matching lore track
- [x] Player has a Lore tab with full param list + timeline
- [x] Overlay can be hidden and stays hidden across sessions
- [x] `flutter analyze` clean on touched files; lore tests pass

## 4. Steps

- [x] **Step 1**: Red tests for cross-track + fuzzy track resolve
- [x] **Step 2**: Fix `LoreStateProjector` (+ track resolve helper)
- [x] **Step 3**: Player Lore tab + hideable overlay setting/UI
- [x] **Step 4**: Strings/l10n + analyze + close TODO

## 5. Risks

- **Risk**: Fuzzy title match could collide on similarly named tracks
- **Rollback**: Revert projector + player_screen changes

## 6. Notes / Decision Log

> Real pack `1489095`: events keyed by main hashes (`…/1860684`…); no-SFX remasters use different hashes and have no events. Projector only applied *current* track events onto base params still at 0 → HUD frozen. Fixed with prior-track accumulation + normalizeTitle resolve.

---

## ✅ Done

- Completed at: 2026-07-11 12:05
- Command run: `/init` (manual CLAUDE.md lore projector / player tab note)
- CLAUDE.md update summary: Documented cross-track projection, no-SFX track resolve, Lore player tab, and hideable HUD setting.
- Related commit: (pending user commit)
