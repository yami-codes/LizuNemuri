# Library tab hub — Downloads + Browse segments

- **Created**: 2026-07-05
- **Owner**: cursor-agent
- **Status**: active
- **Related Issue / PR**: PR #11

---

## 1. Goal

Interim Library tab toward Milestone F: segment control **Downloads | Browse** with self-contained AppBar (Eara library-first mental model).

## 2. Scope

**In scope:**
- `LibraryTabContent` scaffold + `SegmentedButton`
- Downloads segment → `DownloadsHubContent`
- Browse segment → `HomeContent` + filter action
- `MainScreen` hides outer AppBar on Library tab

**Out of scope:**
- Local folder scan (Milestone F)
- Full Eara reskin (Milestone E)

## 3. Acceptance

- [x] Library tab shows Downloads / Browse toggle; default Downloads
- [x] Filter icon only on Browse segment
- [x] `fvm flutter test` passes
- [x] `fvm flutter analyze` no new warnings

## 4. Steps

- [x] **Step 1**: Rewrite `library_tab_content.dart`
- [x] **Step 2**: Update `main_screen.dart` AppBar guard
- [x] **Step 3**: Add `librarySegmentBrowse` l10n
- [x] **Step 4**: Run tests + analyze

## 5. Risks

- **Risk**: Duplicate `DownloadsViewModel` vs sidebar `DownloadsScreen` (acceptable — separate routes)
- **Rollback**: Revert `library_tab_content.dart` to `HomeContent` only
