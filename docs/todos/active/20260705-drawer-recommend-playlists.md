# Drawer — Recommend + Playlists routes

- **创建时间**：2026-07-05
- **负责人**：cursor-agent
- **状态**：active
- **关联 Issue / PR**：PR #11

---

## 1. 目标（Goal）

Restore Recommend and Playlists after 3-tab nav shrink — accessible from drawer (Eara Milestone D follow-up).

## 2. 范围（Scope）

**包含：**
- `RecommendScreen`, `PlaylistsScreen` wrapper pages
- Sidebar tiles + login gate (Recommend, Playlists)
- `playlistsTitle` l10n

**不包含：**
- Playlists as bottom tab

## 3. 验收标准（Acceptance）

- [x] Drawer shows Recommend + Playlists under Content section
- [x] Recommend requires login; navigates to grid
- [x] Playlists lists user playlists when logged in
- [x] Tests pass

## 4. 拆解步骤（Steps）

- [x] **Step 1**：Add screens
- [x] **Step 2**：Wire `sidebar_menu.dart`
- [x] **Step 3**：l10n + `Strings` getters
- [x] **Step 4**：Analyze + test
