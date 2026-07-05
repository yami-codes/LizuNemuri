# Milestone A: Eara player motion + shared backdrop + lyrics toggle

- **创建时间**：2026-07-05
- **负责人**：cursor-agent
- **状态**：active
- **父文档**：[`docs/eara_ui_north_star.md`](../eara_ui_north_star.md) (grill-me 12A)
- **关联 PR**：https://github.com/yami-codes/Xuro/pull/11

---

## 1. 目标（Goal）

Match Eara’s player shell: **one shared cover backdrop** across mini → full player and **player ↔ lyrics** surfaces, with **Eara-level motion** (5D).

## 2. 范围（Scope）

**包含：**
- Hero / motion transition mini player cover → full player
- `PlayerScreen` player vs lyrics as **two surfaces** on same `CoverArtworkBackground` stack (4D)
- Backdrop **clarity slider** in settings (today `kPlayerCoverBackdropClarity` constant)
- Motion curves/durations aligned with `AppAnimations` / Eara `NowPlayingMotion` (~300–400ms)

**不包含（Milestone B）：**
- Apple kinetic lyrics (6B)
- Global Monet theme / drop ColorVariant (2D)
- Bottom nav Library/Search/Hot (3B)
- Local library / DLsite

## 3. 验收标准（Acceptance）

- [x] Opening full player from mini player: cover/backdrop continuity (no white flash)
- [x] Toggling lyrics: same palette/backdrop; animated cross-fade or slide
- [ ] Clarity slider persists; live update on player *(deferred — settings agent)*
- [x] `flutter analyze` + player widget tests pass

## 4. 拆解步骤（Steps）

- [x] Audit Eara `NowPlayingMotion.kt` / `PlayerSharedBackdrop.kt` timings → `AppAnimations.medium` (300ms) surface / `long` (450ms) route
- [x] `Hero` tag on mini + full cover; custom route or expand transition → `player_surface_transition.dart` + `createPlayerScreenRoute()`
- [x] Refactor `PlayerScreen` body into `PlayerSurface` / `LyricsSurface` on shared `Stack` → `PlayerSurfaceSwitcher`
- [ ] `AppSettingsService.playerBackdropClarity` + settings tile *(deferred — settings agent)*
- [x] Tests: clarity math, hero tag contract → `test/widgets/player/player_surface_transition_test.dart`

## 5. 风险（Risks）

- Hero + immersive `Stack` may jank on low-end Android — profile with PerfDog pattern from sidebar jank todo
- Wide layout player already splits cover/lyrics — motion spec must handle tablet
