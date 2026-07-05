# Milestone D — Eara 3-tab bottom navigation (Library / Search / Hot)

- **创建时间**：2026-07-05
- **负责人**：cursor-agent
- **状态**：active
- **关联 Issue / PR**：（Milestone D, `docs/eara_ui_north_star.md` §3B）

---

## 1. 目标（Goal）

将 `MainScreen` 底部导航从 4 tab（收藏 / 首页 / 推荐 / 热门）替换为 Eara 风格 **3 tab：Library | Search | Hot**；收藏与推荐仅保留在侧栏入口；MiniPlayer 仍在 `NavigationBar` 上方。

## 2. 范围（Scope）

**包含：**
- `lib/screens/main_screen.dart` — 3-page `PageView`、新 destinations、AppBar 逻辑
- `lib/screens/contents/library_tab_content.dart` — 薄壳，临时嵌入 `HomeContent`
- `lib/screens/contents/search_tab_content.dart` — 嵌入 `SearchScreenContent`
- `lib/screens/contents/hot_tab_content.dart` — 包装 `PopularContent`
- `lib/l10n/app_*.arb` + `strings.dart` — tab 文案
- 本 TODO 文档

**不包含：**
- `sidebar_menu.dart` 改动（Favorites/Recommend 已在 drawer，本任务不改侧栏）
- 下载、音频、播放器文件
- Milestone F 本地扫描库（Library 暂用在线 `HomeContent` 占位）

## 3. 验收标准（Acceptance）

- [x] 底部仅 3 tab：Library、Search、Hot（图标 + 隐藏 label 与现有一致）
- [x] `PageView` 3 页，`AppAnimations.medium` + `AppAnimations.standard` 切换
- [x] MiniPlayer 在 `NavigationBar` 上方
- [x] Library tab 显示 `HomeContent`（在线作品浏览）作为 Milestone F 前占位
- [x] Search tab 内嵌搜索 UI（非 push 路由）
- [x] Hot tab 显示原 `PopularContent`
- [x] AppBar 搜索按钮移除（搜索已是 tab）；Library/Hot 保留筛选
- [x] `fvm flutter analyze` 通过（main_screen + 新文件）

## 4. 拆解步骤（Steps）

- [x] **Step 1**：创建 TODO 文档（本文件）
  - 验证：文件位于 `docs/todos/active/`
- [x] **Step 2**：新增 `library_tab_content.dart`、`search_tab_content.dart`、`hot_tab_content.dart`
  - 涉及文件：`lib/screens/contents/*_tab_content.dart`
- [x] **Step 3**：更新 `app_*.arb` + `strings.dart`（`tabLibrary` / `tabSearch` / `tabHot`）
  - 验证：`fvm flutter gen-l10n` 成功
- [x] **Step 4**：重构 `main_screen.dart`（3 tab、移除 Favorites/Recommend VM、更新 AppBar）
  - 涉及文件：`lib/screens/main_screen.dart`
- [x] **Step 5**：提交并 push `cursor/eara-nav-library-search-hot-1e9b`
  - 关联 commit：`1b2a4a2`

## 5. 风险与回滚（Risks）

- **风险**：Search tab 嵌套 `SearchScreenContent` 的 `Scaffold` 与外层 `Scaffold` 双层；Search tab 无外层 AppBar drawer 按钮（仍可通过边缘滑动打开 drawer）
- **回滚**：revert 本分支 commit

## 6. 备注 / 决策记录

- **Library 占位**：Milestone F 之前使用 `HomeContent`（asmr.one 在线列表 + 筛选），AppBar 标题用 `Strings.tabLibrary`；本地扫描落地后替换 `LibraryTabContent` 实现。
- **Recommend**：无独立侧栏项时用户仍可通过其他入口发现；本任务不增 drawer 项（scope 禁止改 sidebar）。

---

## ✅ 完成标记

> 全部步骤勾选完毕后填写。
