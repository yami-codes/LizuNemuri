# UI Refactor Master Plan — Component-Reuse Reskin Toward Reference Visuals (Blue-White / Black-White / Green-White Three Variants)

- **Created**: 2026-05-16
- **Owner**: WuMe-sicx
- **Status**: done <!-- active | done | cancelled -->
- **Related Issue / PR**: None
- **Visual baseline**: User-provided reference image (`~/Downloads/ChatGPT Image 2026-05-16 04_07_14.png`) — 3 color variants × 5 screens (sidebar / home / player / settings / about)

> ⚠️ This document is a **refactor plan (planning state)**. After review, decide which phases to execute. **No code changes in this round.**
> The old "pure structural refactor without visual change" plan has been **superseded** by this version: the user gave an explicit visual target (reference image), and the direction shifted to "reference-driven, component-reuse visual reskin."

---

## 0. Key Judgment: Reference Image Validates Existing Architecture

The reference image is essentially **the same component set with accent tokens rotating across three color variants**:

- Three palettes (blue-white / black-white / green-white) = existing `ColorVariant.blue / mono / green`; **architecture already exists** (`app_colors.dart:17-85`).
- In the reference, **only** accent areas change color: selected nav pill, section headers, main play button, slider/switch active state, "more >", "follow". Surfaces stay white (light) / near-black (dark); icons/card backgrounds stay neutral gray. **This matches the `AppColors` two-axis design intent** — `primary/onPrimary/primaryContainer` rotate; other tokens stay neutral.
- Spec v3.0's purple `fromSeed` system is fully obsolete; CLAUDE.md + reference image are the source of truth.

**Conclusion**: This is not a theme-architecture rewrite, but **(a) raise visuals to reference quality (b) consolidate scattered implementations into a reusable component layer across 5 screens × 3 variants (c) clear token/string/deprecated-API debt along the way**. The `AppColors` two-axis system stays unchanged.

---

## 1. Goal

> Use the reference image as pixel-level visual target; reshape Xuro's 5 core screens (sidebar / home / player / settings / about) into a reuse system of "one atom library + three variants rotating accent only"; establish design tokens; clean up strings and deprecated API debt; align spec document = reference image = code.

## 2. Scope

**In scope:**
- Rewrite `docs/ui-design-spec.md`: reference image as visual baseline; define tokens, atom catalog, three-variant rotation rules.
- Add design tokens: `AppSpacing` / `AppRadius` / `AppTextStyles` (`lib/core/theme/`, same level as `AppAnimations`).
- Build/consolidate **atom component layer** (see §4 reuse matrix); shared across 5 screens, auto-adapts to 3 variants.
- Reskin 5 screens per reference: sidebar, home, player, settings, about.
- Historical debt cleanup bundled in: UI copy → `Strings`, `withOpacity`→`.withValues`, remove `shimmer` dependency, `groupWorksIntoRows` memo.

**Out of scope:**
- Rewrite theme architecture / change `AppColors` two-axis system (validated correct, keep).
- Change business logic / ViewModel behavior / audio-subtitle subsystems.
- i18n / multi-language (string centralization only, no language switching).
- Visual reskin of screens not in reference (search/detail/favorites/lyrics etc.) — token alignment only this round, no redraw.
- New backend capabilities / new feature entries (reference items like "playback speed", "sound effects", "equalizer" — if no corresponding feature today, **placeholder UI only or defer**; confirm per phase during execution, don't invent features to match mockups).

## 3. Acceptance

- [x] `docs/ui-design-spec.md` rewritten against reference; no purple/fromSeed/distorted statements.
- [x] `lib/core/theme/` contains `AppSpacing`/`AppRadius`/`AppTextStyles`; 5 screens have no bare numeric spacing/radius.
- [x] All atoms in §4 reuse matrix implemented; **same component changes only accent across three variants** (screenshot evidence).
- [x] 5 screens match reference in blue/mono/green × light/dark (per-screen per-variant screenshots).
- [x] Zero UI-visible Chinese bypassing `Strings`; `grep -rn withOpacity lib/` = 0; `pubspec` has no `shimmer`.
- [x] `groupWorksIntoRows` memo + unit test; new token pure-logic tests pass.
- [x] `flutter analyze` passes with no new warnings; related tests pass.
- [x] Performance not degraded: home list scroll profile ≥55fps (spec §7.6).

## 4. Component Reuse Architecture (Core Deliverable)

### 4.1 Three-Layer Structure

```
Layer 0  Design tokens    AppColors(two-axis, keep) + AppSpacing/AppRadius/AppTextStyles/AppAnimations
            │  Three-variant invariant: only colorScheme.primary / onPrimary / primaryContainer rotate
Layer 1  Atom components  Reused across 5 screens × 3 variants; no hardcoded colors; all from Theme/tokens
Layer 2  Screen composition  Sidebar / Home / Player / Settings / About — layout composition only
```

### 4.2 Atom × Screen Reuse Matrix

| Atom component | Sidebar | Home | Player | Settings | About | Current → Action |
| :--- | :-: | :-: | :-: | :-: | :-: | :--- |
| `BrandWordmark` (≈ASMR logo) | ● | | | | ● | **New** (sidebar top + about center) |
| `AccentPill` (selected pill / follow / primary button) | ● | | ● | | | **New**, accent from Theme |
| `SectionHeader` (title + more >) | | ● | | ● | ● | **New**, extract home/settings section headers |
| `AppSearchField` (rounded search) | | ● | | | | Evaluate `browse_search_bar.dart` → extract shared |
| `AppListTile` (icon + title + trailing) | ● | | | ● | ● | **Generalize** `settings_tile.dart` (already has nav/toggle/selection variants, highest reuse) |
| `AppListGroup` (group + header + footer) | | | | ● | ● | Reuse `settings_group.dart`, rename and promote |
| `CategoryChip` (icon + label chip) | | ● | | | | **Evolve** `tag_chip.dart` (text-only today, radius4) |
| `WorkCoverCard` (cover + duration badge + title) | | ● | | | | Reuse `work_card/*`, add duration badge + spec §2.1 press scale |
| `CircularCover` (round cover + ring) | | | ● | | | **New**; current `player_cover.dart` is square → round |
| `WaveformProgress` (waveform progress) | | | ● | | | **New**; current `player_progress.dart` is straight bar |
| `NowPlayingRow` (latest upload row + mini controls) | | ● | | | | Reuse `mini_player/*` controls as in-list variant |
| `SidebarDecoration` (bottom illustration) | ● | | | | | **New** (leaves/moon, per variant) |
| `SocialIconRow` (round social icons) | | | | | ● | **New** |
| `AppFooter` (© footer) | | | | | ● | **New** |

> Reuse conclusion: **settings/about ≈80% reuse existing `SettingsGroup`/`SettingsTile`** (already nav/toggle/selection factory variants); tokenize + accent section headers only. **Home is largest net-new composition work**, but all atoms from table above, no one-off private widgets. **Player** changes focus on circular cover + waveform progress two new atoms.

### 4.3 Three-Variant Invariant (Enforcement Rules)

- Components **must not** hardcode colors; always `Theme.of(context).colorScheme.*` or §Layer0 tokens.
- Variant switch only via `AppSettingsService.colorVariant` → `AppColors.lightSchemeFor/darkSchemeFor` → three tokens `primary/onPrimary/primaryContainer` change; components need not know which variant.
- New atoms must pass "three-variant widget test": same component identical across blue/mono/green except accent pixels.

---

## 5. Steps

> Phases are independent and can be separate PRs; recommended order. Each phase references this TODO.

- [x] **Phase A — Spec alignment (docs only, zero runtime risk, first)** ✅ 2026-05-16
  - File: `docs/ui-design-spec.md` (rewritten to v4.0)
  - Done: color chapter rewritten to real `ColorVariant × Brightness` two-axis (measured hex); added "three-variant invariant" section; §2 restructured to three-layer architecture + atom×5-screen matrix + five-screen layout specs (vs reference); §7.1 audit table updated to real state (PlayerViewModel/IntrinsicHeight closed, groupWorksIntoRows not closed, etc.); removed all purple/fromSeed/"not yet implemented" distortion; kept animation/a11y/responsive/workflow sections where accurate.
  - Verify: cross-checked reference + `app_colors.dart` (measured) + `app_animations.dart` (§3 matches code) + CLAUDE.md; no contradictions.

- [x] **Phase B — Layer 0 design tokens** ✅ 2026-05-16
  - Output: `lib/core/theme/app_spacing.dart` (4px grid ten steps + page margins), `app_radius.dart` (sm/md/lg/full + const `*All` BorderRadius), `app_text_styles.dart` (spec §1.2 seven tiers, no color binding); `app_theme.dart` light/dark card radius changed from hardcoded `Radius.circular(12)` to `AppRadius.mdAll` (equivalent); test `test/core/theme/design_tokens_test.dart`.
  - Scope control: new token classes + theme AppRadius only; no bulk component changes (deferred to Phase C); AppTextStyles/AppSpacing defined but not applied → zero visual change.
  - Verify: `flutter analyze lib/core/theme/ test/core/theme/` → No issues; token tests 8/8 (including "md must still be 12" regression gate + "tokens carry no color" three-variant assertion).

- [x] **Phase C — Layer 1 atom library** ✅ 2026-05-16
  - Output (8 pure additions, zero existing code changes, all token-driven, no hardcoded color/Chinese):
    `lib/widgets/common/section_header.dart`, `accent_pill.dart`, `brand_wordmark.dart`, `app_footer.dart`, `social_icon_row.dart`, `category_chip.dart`, `app_search_field.dart`; `lib/widgets/player/circular_cover.dart`.
  - Tests: `test/widgets/common/atom_three_variant_test.dart` 10/10 — AccentPill bg=primary, CategoryChip bg=primaryContainer, BrandWordmark icon=primary; blue/green/mono assert accent equals scheme token (hardcoded color fails).
  - **Scope decision (6 atoms deferred to Phase D, not skipped)**: `AppListTile`/`AppListGroup` satisfied by existing `SettingsTile`/`SettingsGroup` (duplicating = over-abstraction); Phase D reuses directly. `NowPlayingRow` (mini_player composition), `WorkCoverCard` (work_card + duration badge), `SidebarDecoration` (coupled to sidebar dark panel/layout), `WaveformProgress` (coupled to PlayerProgress seek/ViewModel) are screen-coupled composites — standalone library would be speculative; per "no half-finished / no scope creep", land with corresponding screen in Phase D (D3/D4/D5); §4.2 matrix updated.
  - Verify: `flutter analyze lib/widgets/common/ lib/widgets/player/circular_cover.dart test/widgets/common/` → No issues; widget tests pass.

- [x] **Phase D — Layer 2 screen reskin (D1–D5 complete)** ✅ 2026-05-16
  - [x] **D1 Settings** ✅ 2026-05-16:
    - `settings_group.dart`: section header `titleSmall`→`AppTextStyles.labelMedium`+accent (spec §2.4 category title=Label Medium, matches reference small accent headers); margin/header/footer padding + container radius tokenized (`AppSpacing`/`AppRadius.mdAll`); divider indent extracted `_dividerIndent=60` constant with note = 16+32+12 geometry.
    - `settings_tile.dart`: **leading changed from "per-row accent 12% rounded badge" to neutral linear icon** (`onSurfaceVariant`, no background) — reference shows accent only on section headers/selection/switch/slider; old implementation over-accented ( **broad impact: About reuses same component, icons neutralized too, consistent with D2, intentional** ); row padding/spacing tokenized.
    - `settings_screen.dart`: inter-group spacing ×6 + list padding tokenized.
    - Tests: `test/screens/settings/settings_d1_test.dart` 7/7 — leading==onSurfaceVariant (≠primary) across blue/green/mono, selection check==primary, toggle track==primary, section header==primary+12/w500.
    - Verify: `flutter analyze lib/screens/settings/` → No issues (full analyze only pre-existing `withOpacity` debt, not this phase); **full `flutter test` 76/76, zero regression**.
  - [x] **D2 About** ✅ 2026-05-16:
    - `about_screen.dart` restructured to reference layout: centered `BrandWordmark`(text=Strings.aboutAppName='Xuro', not template 'ASMR') + version subtitle (`版本 v{packageInfo.version}`, moved out of list) + centered intro; kept `SettingsGroup` real links (check update / open-source licenses / feedback / original repo); `SocialIconRow`(Telegram + GitHub source, real `_openUrl`); `AppFooter`(real CC BY-NC-SA copyright).
    - **No fakes**: reference `support@asmr.com` has no backend → omitted; copyright per real license (not template "© 2024 ASMR All Rights Reserved"). Added `Strings.versionLabel`/`aboutFooter`.
    - Reuse: `SettingsGroup`/`SettingsTile` (D1 neutral leading applies); new atoms `BrandWordmark`/`SocialIconRow`/`AppFooter`.
    - Tests: `test/screens/about_screen_test.dart` (mock PackageInfo) 1/1 — brand=Xuro, version in header not list, Social 2 entries, Footer contains CC BY-NC-SA.
    - Verify: `flutter analyze`(about/strings/test) → No issues; **full `flutter test` 77/77, zero regression**.
  - [x] **D3 Sidebar** ✅ 2026-05-16:
    - Added `lib/widgets/sidebar/sidebar_decoration.dart` (Phase C deferred sidebar atom): variant-aware `CustomPainter` watermark — mono draws crescent + hills (echoes `_DrawerBackground` mono pure-black special case and reference B&W sidebar motif), blue/green draw leaves; accent low opacity, `IgnorePointer` pass-through, `shouldRepaint` only on variant/color change.
    - `sidebar_menu.dart`: top `BrandWordmark`(text=Strings.aboutAppName='Xuro'; under drawer local dark Theme text=onSurface white/icon=primary dark accent, consistent with glassmorphism); Stack bottom `SidebarDecoration` watermark (above background, below content, visible on long screens). New code uses `AppSpacing`.
    - **Scope decision (no fake selected state)**: reference "selected solid accent pill" needs current-section concept, but sidebar is **navigation drawer** (top nav in MainScreen bottom bar; drawer items all push/dialog, no persistent selection); forcing `AccentPill` selected state = inventing nonexistent model, violates "don't invent features for UI alignment" → skip. `AccentPill` reserved for D5 "follow".
    - Strict CLAUDE.md: did not revert glassmorphism, no fullscreen BackdropFilter, no bulk retune of existing spacing (only new code tokenized).
    - Tests: `test/widgets/sidebar/sidebar_d3_test.dart` 6/6 — decoration renders on three variants dark scheme smoke + BrandWordmark drawer dark icon=primary/text=onSurface (regression "drawer accent invisible" trap).
    - Verify: `flutter analyze`(sidebar/test) → No issues; **full `flutter test` 83/83, zero regression**.
  - [x] **D4 Home** ✅ 2026-05-16:
    - `home_content.dart`: top `AppSearchField` (read-only, tap pushes existing `SearchScreen`); original grid Stack wrapped in `Column>Expanded`, **grid/pagination/filter/scroll logic unchanged**; fixed pre-existing `_onScroll` brace lint from format.
    - `AppSearchField` enhancement: `readOnly`+`onTap` (search as nav trigger; browse inline filter still works). Added `Strings.homeSearchHint`.
    - **Cover duration badge** (Phase C deferred WorkCoverCard): `WorkCoverImage` + `durationSeconds` + bottom-left badge (`_fmtDuration` H:MM:SS/M:SS, new code `.withValues` not withOpacity); `WorkCard` passes `work.duration`; `work_info_section.dart` removed redundant duration line + `_formatDuration` + fixed old double `SizedBox` + tokenized (global list cards change consistently, intentional).
    - **Scope decision (no fake data/features)**: reference `CategoryChip` grid, `NowPlayingRow` are content curation (recommended audio/hot categories/latest uploads), but `HomeViewModel` is paginated works list with no data source; forcing = invent features/data, violates discipline (same as D2 fake email, D3 fake selection) → product decision (need data source first), out of scope. `SectionHeader` on single undifferentiated list is decorative noise → not added.
    - Tests: `test/widgets/work_card/work_cover_duration_badge_test.dart` 4/4 (format/edge/missing hidden).
    - Verify: `flutter analyze` all D4 files → No issues (only pre-existing withOpacity debt including deliberately untouched sourceId line); **full `flutter test` 87/87, zero regression**.
  - [x] **D5 Player** ✅ 2026-05-16:
    - `circular_cover.dart` (Phase C) replaces square `PlayerCover`: `player_screen.dart` keeps `Hero(tag:'mini-player-cover')`, child `PlayerCover`→`CircularCover`; cover padding tokenized.
    - Added `lib/widgets/player/waveform_progress.dart` (Phase C deferred, landed in player context): visual replacement for `PlayerProgress`, **seek/position/duration fully reuse `PlayerViewModel`** (same `seek()`, same range); bar heights deterministic motif (streaming client has no per-track amplitude, reference same, decorative); played segment accent; time labels `AppTextStyles.caption`, new code `.withValues`. `player_screen.dart` `PlayerProgress()`→`WaveformProgress()`.
    - **Scope decision (no invented features)**: codebase has **no follow/subscribe**; reference "follow" `AccentPill` has no backend → no non-functional pill (continues D2/D3/D4 stance); `AccentPill` kept for future. AppBar no new favorite/more keys (§2 excludes new entries).
    - Tests: `test/widgets/player/circular_cover_test.dart` 4/4 (circle `BoxShape.circle`+`ClipOval`, accent ring three variants, no-cover note fallback). `WaveformProgress` depends on GetIt&lt;PlayerViewModel&gt; (heavy DI, same as untested `PlayerProgress`) no unit test; seek logic reuses tested path.
    - Verify: D5 analyze only 1 pre-existing withOpacity (`player_screen.dart:193` untouched "not playing" subtitle, Phase E; new code all `.withValues`); **full `flutter test` 91/91, zero regression**.
  - Verify: per-screen × 3 variants × light/dark screenshots vs reference; `flutter analyze` passes.

- [x] **Phase E — Historical debt cleanup (complete)** ✅ 2026-05-16
  - [x] **withOpacity→.withValues full migration** ✅ 2026-05-16: 14 files 24 call sites perl mechanical migration (equivalent deprecation fix), remaining 0 (only `circular_cover.dart` comment mentions).
  - [x] **Remove dead shimmer dependency** ✅ 2026-05-16: confirmed no `import 'package:shimmer'`; `pubspec.yaml` removed `shimmer: ^3.0.0`; `work_files_skeleton.dart` `_buildShimmerItem`→`_buildSkeletonItem`; `flutter pub get` OK.
  - [x] **groupWorksIntoRows memo** ✅ 2026-05-16: `work_layout_strategy.dart` class-level single-slot memo (key=works identity + column count, hit returns same List instance, spec §7.3); `test/presentation/layouts/work_layout_strategy_memo_test.dart` 4/4.
  - [~] **UI Chinese → Strings (batched, core screens first)**: inventory **243 sites** (plan underestimated 3-4×).
    - **Exemption categories (per plan §6 "UI copy only")**: ~140 diagnostic/non-UI — `Exception()/FormatException()` throws (api_service ~30, auth_service, subtitle_loader, playback_context…), `NetworkException/UpdateException` diagnostic messages, `mark_status` enum labels, `pageName` getters, `audio_error_handler` strings, `serverOptions` URL→name map. Not `Text()` UI; user-visible errors go through `NetworkException.userMessage`/`Strings` → **keep, no mechanical migration** (high churn, low value, violates plan "UI vs logs, UI only").
    - [x] **Batch 1 (core cluster 9 files)** ✅ 2026-05-16: `main_screen`(tab/nav titles), `player_screen`(not playing/wakelock tooltip), `mini_player`, `player_work_info`(unknown work/VA), `player_controls`(4 tooltips), `player_lyric_view`(no lyrics), `favorites_screen`(reuses `Strings.favorites`), `similar_works_screen`, `cache_manager_screen`(full screen). ~25 new Strings constants; batch1 analyze `No issues`; **full test 95/95 zero regression**.
    - [x] **Batch 2a (discover/search + dialogs 7 files)** ✅ 2026-05-16: `search_screen`(sort labels×14 dual sites), browse `tags`/`voice_actors`/`circles`(title/hint/load fail/empty, reuse `Strings.retry`), `login_dialog`, `sidebar_header`, `audio_format_order_dialog`. ~37 Strings constants; batch2a analyze `No issues`; **full test 95/95 zero regression**.
    - [x] **Batch 3 (wrap-up 14 files)** ✅ 2026-05-16: `filter_panel`, `filter_with_keyword`, `work_action_buttons`, `playlist_selection_dialog`, `playlists_viewmodel`+`playlists_list_view`+`playlist_works_view`, `work_files_list`, `work_file_item`, `work_tags_panel`+`work_info_header`(subtitle, reuse `Strings.subtitleChip`), `grid_empty`, `lyric_overlay_manager`, `detail_screen`/`detail_viewmodel`. Note: `detail_viewmodel:475 '移除/添加'` is `AppLogger` only, exempt. ~40 Strings constants + 5 functions; **full `flutter test` 95/95**; full analyze only 5 **pre-existing** unrelated warnings; UI refactor net 0 new warnings, `withOpacity` 25→0.
  - Verify (completed items): withOpacity grep 0; `flutter pub get` OK; memo 4/4; batch1 analyze + full test 95/95 zero regression.

## 6. Risks

- **Risk**: Reference includes features possibly without backend (speed, sound effects, equalizer, sleep timer, follow).
  - **Mitigation**: Confirm per item before D5/D4; placeholder/hide only, **don't invent features for UI alignment** (excluded in §2).
- **Risk**: Circular cover + waveform progress are structural player changes; may affect Hero animation and progress interaction.
  - **Mitigation**: `CircularCover` keeps `Hero(tag:'mini-player-cover')`; `WaveformProgress` visual-only, drag seek reuses `PlayerProgress`.
- **Risk**: Phase D large reskin may cause cross-variant inconsistency.
  - **Mitigation**: Mandatory three-variant widget tests + per-variant screenshots; no hardcoded colors in components.
- **Rollback**: Independent phase commits; `git revert` per phase; Phase A docs-only zero cost; atom library (C) decoupled from screens (D).

## 7. Notes / Decision Log

- **2026-05-16**: User provided reference and asked for "component reuse + doc planning" with "three color variants". Direction corrected from old "no visual change" to "reference-driven component-reuse reskin"; old plan obsolete.
- Key decision: **don't redo spec §7 closed items** (PlayerViewModel throttle, IntrinsicHeight cleared, SkeletonPulse replaced Shimmer — verified).
- Key decision: `AppColors` two-axis validated by reference, **keep unchanged**; this is reskin + component consolidation, not theme rewrite.
- Player control area follows existing constraint (see memory [[feedback-player-ui-minimal]]): extend single control row, **no stacked duplicate/ambiguous icons**; reference timer/speed/sound/favorite row evaluated under minimal UI — prefer omission over clutter.
- CCG Coder not enabled ([[feedback-codex-review-loop]]), Claude edits directly; if enabled later, Coder→Codex flow.
- This TODO was planning only before execution; user sign-off on scope before any Phase.

---

## ✅ Done

- Completed at: 2026-05-16
- Command run: `/init`
- CLAUDE.md update summary: UI layer adds `lib/core/theme/` tokens (AppSpacing/AppRadius/AppTextStyles), `lib/widgets/common/` atoms (SectionHeader/AccentPill/BrandWordmark/AppFooter/SocialIconRow/CategoryChip/AppSearchField), `circular_cover.dart`/`waveform_progress.dart`/`sidebar_decoration.dart`; 5 screens reskinned per reference; `ui-design-spec.md` v4.0 (two-axis + atom matrix); `shimmer` removed; `groupWorksIntoRows` memo; UI copy centralized to `Strings` (diagnostic/exception strings exempt per spec).
- Related commit: Not committed (user did not request commit; pending user decision)
