# Eara-style advanced list filters

- **Created**: 2026-07-06
- **Owner**: cursor-agent
- **Status**: active
- **Related Issue / PR**: (pending)

---

## 1. Goal

Port EaraAsmrPlayer's quick filter chip UX to Lizunemu browse/search/hot lists while keeping asmr.one API compatibility.

## 2. Scope

**In scope:**
- Reusable `AdvancedFilterBar` (horizontal chips + expandable more sorts / direction)
- Home browse + Search + Hot tab wiring
- `FilterState` / ViewModels pass order+sort to `/works` and `/search`
- Popular tab uses `/works` when a sort chip is active (else keeps `/recommender/popular`)
- L10n strings (en/zh/th)

**Out of scope:**
- DLsite-only modes (purchased / presale / collected library) — no backend in Lizunemu
- Chinese-works server filter until asmr.one documents a `/works` param
- Recommend / Similar full sort (API subtitle-only)

## 3. Acceptance

- [x] Browse (Home) shows Eara-style chip row; sort + subtitle refresh the grid
- [x] Search shows same chip row; changing chips re-runs search
- [x] Hot tab chips include sort presets (not subtitle-only)
- [x] `flutter analyze` passes
- [x] Unit test for filter option ↔ order/sort mapping

## 4. Steps

- [x] Model + `AdvancedFilterBar` widget
- [x] Refactor `FilterPanel` / Hot / Search / Home integration
- [x] PopularViewModel `/works` fallback for sort chips
- [x] L10n + tests + analyze

## 5. Risks

- **Risk**: `/recommender/popular` ignores sort — mitigated by `/works` fallback when sort chip active
- **Rollback**: Revert branch; old `FilterPanel` restored

## 6. Notes

- Reference: `eValDoll/EaraAsmrPlayer` `SearchFilterOption.kt` (Collected/Purchased omitted)
