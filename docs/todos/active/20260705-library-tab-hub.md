# Library tab hub — Downloads + Browse segments

- **创建时间**：2026-07-05
- **负责人**：cursor-agent
- **状态**：active
- **关联 Issue / PR**：PR #11

---

## 1. 目标（Goal）

Interim Library tab toward Milestone F: segment control **Downloads | Browse** with self-contained AppBar (Eara library-first mental model).

## 2. 范围（Scope）

**包含：**
- `LibraryTabContent` scaffold + `SegmentedButton`
- Downloads segment → `DownloadsHubContent`
- Browse segment → `HomeContent` + filter action
- `MainScreen` hides outer AppBar on Library tab

**不包含：**
- Local folder scan (Milestone F)
- Full Eara reskin (Milestone E)

## 3. 验收标准（Acceptance）

- [x] Library tab shows Downloads / Browse toggle; default Downloads
- [x] Filter icon only on Browse segment
- [x] `fvm flutter test` passes
- [x] `fvm flutter analyze` no new warnings

## 4. 拆解步骤（Steps）

- [x] **Step 1**：Rewrite `library_tab_content.dart`
- [x] **Step 2**：Update `main_screen.dart` AppBar guard
- [x] **Step 3**：Add `librarySegmentBrowse` l10n
- [x] **Step 4**：Run tests + analyze

## 5. 风险与回滚（Risks）

- **风险**：Duplicate `DownloadsViewModel` vs sidebar `DownloadsScreen` (acceptable — separate routes)
- **回滚方案**： Revert `library_tab_content.dart` to `HomeContent` only
