# Drawer — Recommend + Playlists routes

- **Created**: 2026-07-05
- **Owner**: cursor-agent
- **Status**: active
- **Related Issue / PR**: PR #11

---

## 1. Goal

Restore Recommend and Playlists after 3-tab nav shrink — accessible from drawer (Eara Milestone D follow-up).

## 2. Scope

**In scope:**
- `RecommendScreen`, `PlaylistsScreen` wrapper pages
- Sidebar tiles + login gate (Recommend, Playlists)
- `playlistsTitle` l10n

**Out of scope:**
- Playlists as bottom tab

## 3. Acceptance

- [x] Drawer shows Recommend + Playlists under Content section
- [x] Recommend requires login; navigates to grid
- [x] Playlists lists user playlists when logged in
- [x] Tests pass

## 4. Steps

- [x] **Step 1**: Add screens
- [x] **Step 2**: Wire `sidebar_menu.dart`
- [x] **Step 3**: l10n + `Strings` getters
- [x] **Step 4**: Analyze + test
