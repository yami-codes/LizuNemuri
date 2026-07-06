# Subtitle Filter State — Consolidate to Single Store (Eliminate dispose Write-Back Stale Values)

- **Created**: 2026-05-15
- **Owner**: WuMe-sicx
- **Status**: done <!-- active | done | cancelled -->
- **Related Issue / PR**: Local persistence optimization checklist item 2 (Codex SESSION 019e2c0c…2962 analysis C5)

---

## 1. Goal

The shared `subtitle_filter` bool was read/written independently by 4 ViewModels (Recommend / Popular / Home / SimilarWorks) via `SharedPreferences.getInstance()` with `dispose()` write-back of cached local values — a later-disposed VM could **overwrite** a freshly written value from another VM, causing cross-screen filter inconsistency. Consolidate to a single injected store (reuse existing `AppSettingsService` sync pattern); remove `getInstance()` and all `dispose()` write-backs from VMs.

## 2. Scope

**In scope:**
- `AppSettingsService`: Add `hasSubtitleFilter` (sync read `subtitle_filter` in ctor, getter + `setHasSubtitleFilter()` persists + `notifyListeners()`, write only on change), following existing `setServerUrl` pattern.
- `RecommendViewModel` / `PopularViewModel` / `SimilarWorksViewModel` / `HomeViewModel`: Remove local `_hasSubtitle` cache, `_subtitleFilterKey`, `SharedPreferences` subtitle read/write, and `_load/_saveFilterState` (subtitle parts); `hasSubtitle` getter delegates to `getIt<AppSettingsService>().hasSubtitleFilter`; toggle/update call `setHasSubtitleFilter()`.
- **Remove all `dispose()` filter write-backs in 4 VMs** (Recommend/Popular/SimilarWorks `dispose` overrides removed entirely; Home `dispose` no longer calls `_saveFilterState()`).
- Public API unchanged: `hasSubtitle` getter, `toggleSubtitleFilter()`/`updateSubtitle()`, `filterState` signatures preserved — zero widget/Provider changes.

**Out of scope:**
- `home_filter_state` (sort `FilterState` JSON) is **Home-private, single-writer** — no cross-VM race; **keep existing prefs persistence and onInit one-shot load**; only remove redundant dispose write-back. Do not put `FilterState` (presentation model) into `AppSettingsService` (core layer) — avoids core→presentation reverse dependency.
- No cross-screen live sync (VMs do not listen to `AppSettingsService`): each screen reads shared value at init and applies on refresh — behavior equivalent to today, bug removed.
- No changes to `SearchViewModel` etc. that do not share this key.

## 3. Acceptance

- [x] Toggle subtitle filter on any screen, switch to another and back — value not overwritten by stale VM dispose (core bug fixed — Codex confirmed single writer).
- [x] No `SharedPreferences.getInstance()` read/write of `subtitle_filter` in 4 VMs; no `dispose()` write-back of that state.
- [x] `subtitle_filter` still persisted (survives kill/restart), owned solely by `AppSettingsService`.
- [x] Widget/screen layer compiles with no changes (public getter/method signatures unchanged).
- [x] `home_filter_state` sort persistence unchanged (save on update, restore on restart); only redundant dispose write removed.
- [x] `flutter analyze lib/presentation/viewmodels/ lib/core/settings/` = No issues found (no new warnings).
- [x] Related unit/widget tests pass (31 passed; stale `test/widget_test.dart` template unrelated).
- [x] Codex review ✅ PASS (SESSION 019e2c0c…2962, first round pass).

## 4. Steps

- [x] **Step 1**: `AppSettingsService` add `hasSubtitleFilter` getter/setter + ctor sync read
- [x] **Step 2**: `RecommendViewModel` delegate + remove dispose write-back + ctor triggers first load
- [x] **Step 3**: `PopularViewModel` delegate + remove dispose/onInit async load (also cleaned unused logger import)
- [x] **Step 4**: `SimilarWorksViewModel` delegate + remove dispose write-back
- [x] **Step 5**: `HomeViewModel` subtitle delegate; keep `home_filter_state` persistence, only remove dispose write-back
- [x] **Step 6**: `flutter analyze` (No issues found) + `flutter test` (31 passed, 1 pre-existing stale unrelated) full regression
- [x] **Step 7**: Codex review — first round ✅ PASS (confirmed single writer, equivalent behavior, no reverse layering dependency)

## 5. Risks

- **Risk**: Initial filter load in 4 VMs changes from "async getInstance then trigger list" to "sync read settings then trigger" — confirm first-load timing does not regress (PaginatedWorks base loads page(1) after onInit; Recommend/Similar explicitly trigger in ctor).
- **Rollback**: Revert this commit (pure logic, no model/generated artifacts).

## 6. Notes / Decision Log

- Chose `AppSettingsService` over new store: already prefs-backed singleton + ChangeNotifier + ctor sync read + setter persist pattern; zero new DI registration; minimal change surface (constraint.md: Simplicity > Over-engineering).
- `home_filter_state` not moved to core: `FilterState` is presentation layer; core importing it creates reverse dependency (constraint.md: No circular dependencies). Single-writer, no race — keep as-is.

---

## ✅ Done

- Completed at: 2026-05-15 17:05
- Command run: `/init`
- CLAUDE.md update summary: Documented `AppSettingsService` as single owner of shared `subtitle_filter` (`hasSubtitleFilter`); 4 list VMs delegate through it, no per-VM `getInstance()`/dispose write-back; `home_filter_state` remains Home-private prefs.
- Related commit: Not committed (user did not request commit; pending unified commit timing)
