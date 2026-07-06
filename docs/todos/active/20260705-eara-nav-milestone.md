# Milestone D — Eara 3-tab bottom navigation (Library / Search / Hot)

- **Created**: 2026-07-05
- **Owner**: cursor-agent
- **Status**: active
- **Related Issue / PR**: (Milestone D, `docs/eara_ui_north_star.md` §3B)

---

## 1. Goal

Replace `MainScreen` bottom navigation from 4 tabs (Favorites / Home / Recommend / Hot) with Eara-style **3 tabs: Library | Search | Hot**; Favorites and Recommend remain sidebar-only; MiniPlayer stays above `NavigationBar`.

## 2. Scope

**In scope:**
- `lib/screens/main_screen.dart` — 3-page `PageView`, new destinations, AppBar logic
- `lib/screens/contents/library_tab_content.dart` — thin shell, temporarily embeds `HomeContent`
- `lib/screens/contents/search_tab_content.dart` — embeds `SearchScreenContent`
- `lib/screens/contents/hot_tab_content.dart` — wraps `PopularContent`
- `lib/l10n/app_*.arb` + `strings.dart` — tab labels
- This TODO doc

**Out of scope:**
- `sidebar_menu.dart` changes (Favorites/Recommend already in drawer; this task does not modify sidebar)
- Download, audio, player files
- Milestone F local scan library (Library temporarily uses online `HomeContent` as placeholder)

## 3. Acceptance

- [x] Bottom bar shows only 3 tabs: Library, Search, Hot (icons + hidden labels consistent with existing)
- [x] `PageView` with 3 pages, `AppAnimations.medium` + `AppAnimations.standard` transitions
- [x] MiniPlayer above `NavigationBar`
- [x] Library tab shows `HomeContent` (online work browse) as pre–Milestone F placeholder
- [x] Search tab embeds search UI (not a push route)
- [x] Hot tab shows original `PopularContent`
- [x] AppBar search button removed (search is already a tab); Library/Hot retain filter
- [x] `fvm flutter analyze` passes (main_screen + new files)

## 4. Steps

- [x] **Step 1**: Create TODO doc (this file)
  - Verify: file at `docs/todos/active/`
- [x] **Step 2**: Add `library_tab_content.dart`, `search_tab_content.dart`, `hot_tab_content.dart`
  - Files: `lib/screens/contents/*_tab_content.dart`
- [x] **Step 3**: Update `app_*.arb` + `strings.dart` (`tabLibrary` / `tabSearch` / `tabHot`)
  - Verify: `fvm flutter gen-l10n` succeeds
- [x] **Step 4**: Refactor `main_screen.dart` (3 tabs, remove Favorites/Recommend VMs, update AppBar)
  - Files: `lib/screens/main_screen.dart`
- [x] **Step 5**: Commit and push `cursor/eara-nav-library-search-hot-1e9b`
  - Related commit: `1b2a4a2`

## 5. Risks

- **Risk**: Search tab nests `SearchScreenContent`'s `Scaffold` inside outer `Scaffold` (double layer); Search tab has no outer AppBar drawer button (drawer still opens via edge swipe)
- **Rollback**: revert this branch commit

## 6. Notes

- **Library placeholder**: Before Milestone F, use `HomeContent` (asmr.one online list + filter); AppBar title uses `Strings.tabLibrary`; replace `LibraryTabContent` implementation once local scan lands.
- **Recommend**: Users can still discover via other entry points; this task does not add a drawer item (scope forbids sidebar changes).

---

## ✅ Done

> Fill after all steps are checked.
