# Sidebar First-Open 256ms Jank Fix (Remove Redundant BackdropFilter)

- **Created**: 2026-05-15
- **Owner**: claude
- **Status**: done <!-- active | done | cancelled -->
- **Related Issue / PR**: Independent of Phase 1 in [`20260515-flutter-performance-optimization.md`](20260515-flutter-performance-optimization.md) (high-frequency refresh noise reduction); this task targets a specific single-frame hitch observed in real-device PerfDog data.

---

## 1. Goal

Eliminate the "first sidebar open = 256ms frame" hitch. The hitch was caused by `BackdropFilter(blur 18)` in `sidebar_menu.dart`: first draw triggers Impeller offscreen layer allocation + shader compilation, and **the blur contributes zero visually** — the `_DrawerBackground` beneath it is a fully opaque gradient.

## 2. Scope

**In scope:**
- `lib/widgets/sidebar/sidebar_menu.dart`: Remove `BackdropFilter` and its wrapping 18% black overlay; keep gradient background, soft glow, right-edge highlight, semi-transparent group cards, and profile-card shadow.
- Visual compensation: If removal makes the drawer feel too bright (the 18% black overlay was removed too), **only if needed** deepen `_DrawerBackground` gradient endpoint colors one step (still const, zero runtime cost).

**Out of scope:**
- No changes to `SidebarHeader` / `SidebarGroup` / `SidebarTile`.
- No changes to drawer width / corner radius / breakpoints.
- No changes to local dark `Theme` override.
- No shader warmup, `precacheImage`, or isolate tricks — over-engineering for a visual dead layer that should be deleted.

## 3. Acceptance

- [x] `BackdropFilter` removed from `sidebar_menu.dart`.
- [x] Visual difference on drawer open is barely noticeable (gradient + glow + cards remain).
- [ ] User re-records PerfDog on device: first sidebar open Max FrameTime should drop from 256ms to < 50ms.
- [x] `fvm flutter analyze lib/widgets/sidebar/` → `No issues found!`.

## 4. Steps

- [x] **Step 1**: Remove `BackdropFilter` + 18% black overlay from `Stack`; fold 18% darkening into `_DrawerBackground` gradient via 0.82 coefficient on three color stops (`0x0E0B1F→0x0B0919`, `0x1A1136→0x150E2C`, `0x241445→0x1E1039`). Remove `dart:ui` import (`ImageFilter` unused).
- [x] **Step 2**: `fvm flutter analyze lib/widgets/sidebar/` → `No issues found!`.
- [ ] **Step 3**: User re-records PerfDog on device (sidebar first-open, 30s) → compare Max FrameTime and UI/Raster thread usage.

## 5. Risks

- **Risk**: Drawer feels too bright / less "glassy" after removal.
  - **Mitigation**: Gradient endpoints are already deep purple-black; semi-transparent cards still provide depth. If insufficient, adjust `LinearGradient` stop colors in `_DrawerBackground` (still const, no runtime cost).
- **Risk**: Future need for blur that actually works (e.g. blurring main content behind the sliding drawer) requires redesign.
  - **Mitigation**: Commit message and this TODO serve as decision record.
- **Rollback**: Single-file `git revert`.

## 6. Notes / Decision Log

- **Decision**: No shader warmup / `precacheImage` preheat. Rationale: the layer should not exist; delete it. Warmup is for effects that actually matter.
- **Data basis**: `/Users/xiaoxuya/Downloads/Xuro 2026-05-15 06-32-56.csv` row 14: FPS=89, JANK=1, BigJANK=1, Max FrameTime=256.00ms, GPU=84%. User verbally confirmed "256ms frame is the sidebar."

### Review

- **Round 1** (⚠️ OPTIMIZE): Comment "same final pixel values" not strictly true for `_SoftGlow` — 18% black overlay also darkened glow, but only gradient was darkened → fixed.
- **Round 2** (⚠️ OPTIMIZE): Scaling alpha by 0.82 is not equivalent to "final composite × 0.82" (changes source-over blend weights vs uniform darkening). Correct approach: scale glow RGB channels, keep alpha. Math: `final = 0.82*(glow.rgb*α + bg*(1-α))` iff bg was pre-scaled by 0.82.
- **Round 3** (✅ PASS): RGB scale + alpha preserved + pre-darkened gradient strictly satisfy the equation. `dart:ui` removed; no `BackdropFilter` / `ImageFilter` left in source.

---

## ✅ Done

- Completed at: 2026-05-15
- Command run: `/init`
- CLAUDE.md update summary: Added anti-footgun note in `widgets/sidebar/` — do not add fullscreen `BackdropFilter` to drawer + data-source reference.
- Related commit: (pending commit)
- Codex review: SESSION_ID `019e2873-2990-72e2-bc68-ba47328971b7`, three rounds ⚠️→⚠️→✅ PASS.
- Runtime acceptance (Step 3): Still pending user PerfDog re-record on device.
