# ASMR.one-style bottom nav + sidebar extras

- **Created**: 2026-07-06
- **Owner**: cursor-agent
- **Status**: active

## 1. Goal

Restore ASMR.one-like primary navigation: bottom tabs for Favorites, Home, Recommended, Popular while keeping the sidebar drawer for Library, Search, DLsite, and other secondary destinations.

## 2. Scope

**In scope:**
- 4-tab bottom bar (Favorites | Home | Recommended | Popular)
- Drawer retained with Library, Search, DLsite, browse, settings
- Remove duplicate Favorites/Recommend from drawer

**Out of scope:** New screens, ranking/recent implementation, removing LibraryTabContent

## 3. Acceptance

- [x] Bottom nav shows Favorites, Home, Recommended, Popular
- [x] Sidebar drawer still opens from hamburger on all main tabs
- [x] Library + Search accessible from drawer; DLsite stays under Discover
- [x] `flutter analyze` + tests pass

## 4. Steps

- [x] l10n tabHome / tabRecommend / tabPopular
- [x] MainScreen 4 tabs + ViewModels
- [x] Thin tab shell widgets
- [x] Sidebar: Library + Search; drop Favorites/Recommend duplicates
- [x] Verify analyze + tests
