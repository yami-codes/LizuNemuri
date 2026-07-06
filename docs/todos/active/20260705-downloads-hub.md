# Downloads hub (Eara DownloadsScreen pattern)

- **Created**: 2026-07-05
- **Owner**: cursor-agent
- **Status**: active
- **Related Issue / PR**:

---

## 1. Goal

Provide a "Downloads" entry in the sidebar showing completed local downloads grouped by work; navigate to work detail or play audio offline.

## 2. Scope

**In scope:**
- `DownloadsViewModel` + grouping pure function + unit test
- `DownloadsHubContent` / `DownloadsScreen` full-page wrapper
- Sidebar nav item
- l10n + `Strings` copy
- `DownloadService.localPathIfDownloaded` title fallback (offline playback)

**Out of scope:**
- `main_screen.dart` bottom navigation (another agent)
- DB schema changes / in-progress download queue UI

## 3. Acceptance

- [x] Sidebar "Downloads" opens Downloads page
- [x] List grouped by workId, shows RJ/title, file count, total size
- [x] Tap entry opens work detail; plays audio when available
- [x] Empty state when no downloads
- [x] `flutter analyze` no new warnings
- [x] Grouping logic unit test passes

## 4. Steps

- [x] **Step 1**: Grouping util + ViewModel
  - Files: `lib/core/download/utils/download_grouping.dart`, `lib/presentation/viewmodels/downloads_viewmodel.dart`
  - Verify: unit test
- [x] **Step 2**: UI content + full-page Screen
  - Files: `lib/screens/contents/downloads_hub_content.dart`, `lib/screens/downloads_screen.dart`
  - Verify: analyze
- [x] **Step 3**: Sidebar + l10n
  - Files: `sidebar_menu.dart`, `app_*.arb`, `strings.dart`
  - Verify: analyze
- [x] **Step 4**: Offline playback fallback + tests + analyze
  - Verify: `fvm flutter test`, `fvm flutter analyze`

## 5. Risks

- **Risk**: Wrong title fallback match for same-named files (rare)
- **Rollback**: Revert commit

## 6. Notes

- Reuses `IDownloadRepository.listAllOldestFirst()`; VM filters stale files and groups
- ViewModel uses local `ChangeNotifierProvider`, not registered in GetIt
