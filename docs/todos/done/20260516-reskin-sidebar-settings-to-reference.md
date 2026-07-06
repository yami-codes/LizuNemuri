# Sidebar / Settings Reskin to Reference (Overturn Glassmorphism Invariant)

- **Created**: 2026-05-16
- **Owner**: WuMe-sicx
- **Status**: done <!-- active | done | cancelled -->
- **Related**: Continues `docs/todos/done/20260516-ui-refactor-plan.md` (D1/D3 conservative choices superseded by this task)
- **Visual baseline**: User reference image (blue-white/green-white = light clean sidebar, black-white = dark)

---

## 0. Decision Log (Key)

- User feedback: D1/D3 conservative reskin "style doesn't match aesthetic"; request **direct reference reskin** of sidebar and settings.
- **User as product owner explicitly overturns CLAUDE.md "sidebar keeps glassmorphism dark, non-revertible" invariant**. That invariant had two parts: ①dark glass visual ②no fullscreen BackdropFilter (256ms real-device jank, PerfDog in `docs/todos/done/20260515-sidebar-first-open-jank.md`).
  - ①Visual: **overturned** — sidebar follows app theme (light mode = light clean, dark/mono = dark), aligned with reference.
  - ②Performance lesson: **kept** — reference is flat, no blur; still forbid fullscreen BackdropFilter.
- After task close, `/init` must update CLAUDE.md: replace "keep glassmorphism" with "theme-following clean sidebar (user 2026-05-16 overturned old glassmorphism)", keep no-BackdropFilter perf constraint.

## 1. Goal

> **Directly reskin sidebar and settings to reference visuals**: light clean (follows theme; mono/dark still dark), clean grouped lists, current item solid accent pill (reuse Phase C `AccentPill`), top `BrandWordmark`, bottom `SidebarDecoration`; remove forced dark glass Theme, gradient background, soft glow, glass cards, hardcoded white and colored icon badges.

## 2. Scope

**In scope:**
- `sidebar_menu.dart`: Remove `Theme(brightness:dark, darkSchemeFor)` override, `_DrawerBackground`(gradient+soft glow), `_RightEdgeHighlight`; background `colorScheme.surface`/Surface L1; follow app theme.
- `sidebar_tile.dart` / `sidebar_group.dart` / `sidebar_header.dart`: Remove hardcoded white and glass cards/colored badges → theme colors + neutral linear icons + clean groups; selected state via `AccentPill`.
- Sidebar "current page" highlight: lightweight current-section via `ModalRoute`/route name (**UI highlight only, not new business feature**); no highlight when indeterminate (no faking).
- `SidebarDecoration`: Confirm harmonious on light background (accent low opacity; tune light branch if needed).
- Settings: `settings_group`/`settings_tile`/`settings_screen` closer to reference (group card whitespace, section headers, row height, switch/slider look).
- Post-close `/init` rewrite CLAUDE.md glassmorphism invariant section.

**Out of scope:**
- Sidebar information architecture refactor (still account header + content/discover/system groups; don't force-cut to reference's 4 items).
- Business logic / ViewModel / navigation behavior changes.
- Reintroduce any fullscreen BackdropFilter (perf lesson kept).
- Reskin screens not in reference (home/detail/search etc.).

## 3. Acceptance

- [ ] Light mode sidebar light clean (white/Surface L1, no gradient/glow/glass card); mono/dark still dark — three variants accent-only change.
- [ ] Current page highlighted in sidebar with solid `AccentPill`; non-current items neutral linear.
- [ ] Top `BrandWordmark`, bottom `SidebarDecoration` harmonious in light/dark.
- [ ] Settings page clearly closer to reference (whitespace/section headers/rows).
- [ ] No fullscreen BackdropFilter anywhere.
- [ ] `flutter analyze` no new warnings; related widget tests pass; **full `flutter test` zero regression**.
- [ ] Screenshots three variants × light/dark vs reference.

## 4. Steps

- [x] **Step 1 Sidebar de-glass skeleton** ✅ 2026-05-16: `sidebar_menu.dart` full rewrite — removed `Theme(brightness:dark,darkSchemeFor)` override, `_DrawerBackground`(gradient+glow), `_RightEdgeHighlight`, `_SoftGlow`, `_kIconBgGray`; background `cs.surface` (follows theme); kept `BrandWordmark`/`SidebarDecoration`/no BackdropFilter; `_ThemeModeBadge`/`_SidebarFooter` theme-neutral chips.
- [x] **Step 2 tile/group/header theming** ✅ 2026-05-16: `sidebar_tile.dart` clean rows (neutral `onSurfaceVariant` linear icons + `onSurface` text, `selected` → solid accent pill `primary/onPrimary`, no dividers); `sidebar_group.dart` flat (silent section labels, no glass card); `sidebar_header.dart` glass card→clean account row (`surfaceContainerHighest` + accent round avatar), **dialog logic `_closeDrawerThenShowDialog`/`_dialogScheduled`/addPostFrameCallback preserved** (CLAUDE.md invariant). Verify: `flutter analyze lib/widgets/sidebar/` → No issues; full `flutter test` 95/95 zero regression.
- [x] **Step 3 Current-page AccentPill highlight — scope decision: no faking** ✅ 2026-05-16: Drawer only opens from MainScreen; menu items all push away (top tabs in bottom bar, not here), **no persistent "current section" model**. `SidebarTile.selected` param ready (correctness/future), but no persistent highlight this round — faking violates "don't invent features for UI alignment" (continues D2/D3/D5). Reference selected pill style implemented via `selected` path, lights up when real current-section exists.
- [x] **Step 4 SidebarDecoration light adaptation** ✅ 2026-05-16: decoration uses `primary` @ alpha 0.07–0.20, light background = faint accent watermark (design intent "quiet watermark"), harmonious in light/dark, no branch change needed.
- [x] **Step 5 Settings page** ✅ 2026-05-16: User later said settings "OK" but gave specific defect (duplicate icons in groups); fixed in follow-up TODO `20260516-settings-icon-coherence-and-player-timer.md` (semantic appearance icons + real variant colors) + `20260516-five-screen-layout-token-polish.md` (row metrics per spec). Settings structure OK in this TODO scope; polish in continuations.
- [x] **Step 6 Wrap-up** ✅ 2026-05-16: User confirmed sidebar "OK"/settings "OK" and agreed formal close → `/init` refresh CLAUDE.md (glassmorphism section auto-updated from de-glass code) + move to done.

## 5. Risks

- **Risk**: Sidebar was finely tuned glassmorphism; de-glass is large change, contrast issues possible on some variant/brightness.
  - **Mitigation**: All components use `colorScheme` (three-variant invariant), per-variant×brightness screenshots; independent commits per step.
- **Risk**: Accidentally remove performance "no BackdropFilter" constraint.
  - **Mitigation**: This task adds **no** BackdropFilter; TODO/CLAUDE.md explicitly keep perf constraint.
- **Rollback**: Independent step commits; old glass implementation revertible via `git revert` Step1-2.

## 6. Notes / Decision Log

- 2026-05-16: User "direct reskin like reference…current style doesn't match aesthetic" → overturn glassmorphism visual invariant (keep no-BackdropFilter perf lesson). Continues discipline ([[feedback-reference-reskin-discipline]]): no invented features (current-section highlight UI-only, don't fake), big changes stepwise + full test safety net, close with `/init`.

---

## ✅ Done

- Completed: 2026-05-16 17:40
- Command: `/init`
- CLAUDE.md summary: Sidebar rewritten from "dark glassmorphism non-revertible" to "theme-following clean list (user 2026-05-16 overturned old glassmorphism)", keep "no fullscreen BackdropFilter" perf constraint; settings structure aligned with sidebar style.
- Related commit: Not committed (user did not request commit; pending user decision)

---

## ⛔ Cancelled (cancelled tasks only)

- Cancelled: YYYY-MM-DD HH:mm
- Reason: <...>
- Follow-up: <...>
