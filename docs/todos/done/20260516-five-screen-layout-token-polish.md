# Five-Screen Pure Layout/Token Polish (No Invention, Zero Fictional Features)

- **Created**: 2026-05-16
- **Owner**: WuMe-sicx
- **Status**: done <!-- active | done | cancelled -->
- **Related**: Continues `docs/todos/done/20260516-ui-refactor-plan.md` (Phase D aligned 5-screen structure to reference); parallel to `docs/todos/active/20260516-reskin-sidebar-settings-to-reference.md`
- **Visual baseline**: User re-provided reference image (ChatGPT direct link, 3 variants × sidebar/home/player/settings/about 5 screens)

---

## 0. Decision Log (Key)

- User asked to "go through all 5 reference screens and re-optimize UI layout."
- Audit: gap vs reference is **mostly fictional features without backend** (home recommend/category/latest curation, settings sleep timer/volume/sound/equalizer/language, about ToS/privacy/support email, sidebar selected state, player follow/sound row). These were **deliberately and correctly** excluded in `ui-refactor-plan` Phase D ([[feedback-reference-reskin-discipline]]: don't invent features/data for mockups).
- **User explicitly chose "pure layout/token polish"**: only real layout/token items, **zero fiction, zero churn without defects**. No new features, data sources, or control rows ([[feedback-player-ui-minimal]]).

## 1. Goal

> Without inventing any feature/data, close **real spec/token drift** across 5 screens to `docs/ui-design-spec.md`: unify list row rhythm (spec §2.3), remove player hardcoded spacing (spec §1.3 "no bare numbers" invariant), replace ad-hoc alpha colors with semantic tokens (spec §1.1). Visually closer to reference whitespace/hierarchy without reference elements that lack backend.

## 2. Scope

**In scope (all spec compliance fixes, not churn):**
- `settings_tile.dart`: row `minHeight` 48→56 (spec §2.3 "single-line list item 56"); leading slot 32→40 (spec §2.3 "leading 40 icon").
- `settings_group.dart`: `_dividerIndent` 60→68 (coupled correction = left 16 + leading 40 + gap 12, divider aligns with title text).
- `sidebar_tile.dart`: row `minHeight` add 56 constraint (spec §2.3), sidebar list rhythm matches settings ("5-screen pass" = cross-screen rhythm).
- `about_screen.dart`: intro text `cs.onSurface.withValues(alpha:0.7)` → `cs.onSurfaceVariant` (spec §1.1 secondary text semantic token; remove ad-hoc alpha).
- `player_screen.dart`: hardcoded `32/8/12` spacing literals → `AppSpacing.space32/space8/space12` (CLAUDE.md/spec §1.3 "UI no bare numbers"); track subtitle `onSurface.withValues(alpha:0.7)` → `onSurfaceVariant` (same as about, spec §1.1).

**Out of scope (no invention):**
- Home recommend/category/latest curation, greeting header — no data source, Phase D decision holds; **home zero changes by design** this round.
- Settings sleep timer/volume/sound/equalizer/language rows — no backend, not added.
- About ToS/privacy/support email — no pages/backend, not fabricated.
- Sidebar selected solid pill — drawer has no current-section model, don't invent model.
- Player follow pill / bottom action row / AppBar new keys — no backend / §2 excludes new entries / [[feedback-player-ui-minimal]].
- Don't change `AppSpacing/AppRadius/AppTextStyles` token values (`design_tokens_test.dart` locked).
- No fullscreen BackdropFilter / glassmorphism revert.

## 3. Acceptance

- [ ] Settings/about list rows ≥56dp, leading slot 40dp, dividers still align with title text (no misalignment).
- [ ] Sidebar menu rows ≥56dp, rhythm matches settings; three variants accent-only, not broken.
- [ ] `about_screen`/`player_screen` no longer use `onSurface.withValues(alpha: 0.7)`; use `onSurfaceVariant`.
- [ ] `player_screen.dart` no bare numeric spacing (grep only tokens / noted non-spacing constants).
- [ ] Home **zero changes** (explicit by design, not omission).
- [ ] `flutter analyze` no new warnings; **full `flutter test` zero regression**; `settings_d1_test`/`sidebar_d3_test`/`design_tokens_test` pass.
- [ ] Codex review ✅ PASS (Coder not enabled, Claude direct edit; user requested Codex review).
- [ ] User visual check three variants × brightness closer to reference whitespace/hierarchy → `/init` close.

## 4. Steps

- [x] **Step 1 TODO doc** (this file) ✅ 2026-05-16.
- [x] **Step 2 Settings row metrics** ✅ 2026-05-16: `settings_tile.dart` minHeight 48→56 (`_kRowMinHeight=56`) + leading slot `space32`→`space40`; `settings_group.dart` `_dividerIndent` 60→68 + comment. `flutter analyze lib/screens/settings/` → No issues.
- [x] **Step 3 Sidebar row rhythm** ✅ 2026-05-16: `sidebar_tile.dart` `ConstrainedBox(minHeight:_kRowMinHeight=56)` between InkWell/Padding + named constant; `flutter analyze lib/widgets/sidebar/` → No issues.
- [x] **Step 4 Off-token color cleanup** ✅ 2026-05-16: `about_screen.dart` intro + `player_screen.dart` track subtitle `onSurface.withValues(alpha:0.7)` → `onSurfaceVariant` (`cs` still referenced).
- [x] **Step 5 Player spacing tokenization** ✅ 2026-05-16: `player_screen.dart` literals `12/32/8` → `AppSpacing.space12/32/8`; grep confirms no bare spacing literals left.
- [x] **Step 6 Full verification** ✅ 2026-05-16: `flutter analyze` (5 files No issues) + full `flutter test` **95/95 zero regression** (`design_tokens`/`settings_d1`/`sidebar_d3` pass).
- [x] **Step 7 Codex review** ✅ 2026-05-16: SESSION_ID `019e2dfd-621a-7652-a5a0-eb75b483bbd8` → **✅ PASS**. Independently verified divider geometry 16+40+12=68 aligns title, sidebar `ConstrainedBox` brackets/no overflow, `onSurfaceVariant` no unused vars, `AppSpacing.space*` const valid, no fictional features.
- [x] **Step 8 Wrap-up** ✅ 2026-05-16: User confirmed OK, agreed formal close → Done block + `/init` + move to done.

## 5. Risks

- **Risk**: Row height/leading slot increase misaligns dividers or truncates text.
  - **Mitigation**: `_dividerIndent` synced 60→68 (geometry consistent); taller rows add whitespace only, single-line ellipsis unchanged.
- **Risk**: 56 has no `AppSpacing` token (4px grid lacks 56).
  - **Mitigation**: Follow `SettingsGroup._dividerIndent` precedent — file-local named constant + comment citing spec §2.3, matches existing style, don't add shared constant for one number (avoid over-abstraction).
- **Risk**: Mistaken for churn without defects.
  - **Mitigation**: Each item maps to existing `ui-design-spec` clause (§1.1/§1.3/§2.3) or documented invariant, not subjective reskin; home explicitly zero change.
- **Rollback**: Single focused commit, whole `git revert` possible; per-file changes independent.

## 6. Notes / Decision Log

- 2026-05-16: After user said sidebar "OK"/settings "OK", asked for 5-screen layout pass; audit showed gap mostly fictional features; user chose "pure layout/token polish". Continues discipline: no invention ([[feedback-reference-reskin-discipline]]), minimal player ([[feedback-player-ui-minimal]]), CCG Coder not enabled Claude direct edit + Codex review ([[feedback-codex-review-loop]]).

---

## ✅ Done

- Completed: 2026-05-16 17:40
- Command: `/init`
- CLAUDE.md summary: Settings/sidebar/about/player list row metrics aligned to spec §2.3 (56dp row, 40dp leading, divider indent 68), off-token colors → `onSurfaceVariant`, player spacing fully tokenized; home zero change by design.
- Related commit: Not committed (user did not request commit; pending user decision)

---

## ⛔ Cancelled (cancelled tasks only)

- Cancelled: YYYY-MM-DD HH:mm
- Reason: <...>
- Follow-up: <...>
