# Milestone F — Local folder scan library

- **创建时间**：2026-07-05
- **状态**：active
- **关联 PR**：#11

## Goal
Eara-style local library: scan roots, album list, offline play.

## Scope
- DB v3: `local_scan_roots`, `local_albums`, `local_tracks`
- `LocalLibraryScanner`, `LocalLibraryRepository`, `ScanRootsStore`
- `LocalLibraryViewModel` + `LocalLibraryContent`
- Library tab: **Local | Downloads | Browse** (default Local)
- Settings: manage scan folders
- `PlaylistBuilder` `file://` support

## Acceptance
- [ ] User can add folder + scan
- [ ] Albums listed grouped by folder
- [ ] Tap album plays local files
- [ ] Unit test for scanner grouping
