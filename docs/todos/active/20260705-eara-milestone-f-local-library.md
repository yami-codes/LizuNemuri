# Milestone F — Local folder scan library

- **Created**: 2026-07-05
- **Owner**: cursor-agent
- **Status**: active
- **Related Issue / PR**: #11

---

## 1. Goal

Eara-style local library: scan roots, album list, offline play.

## 2. Scope

**In scope:**
- DB v3: `local_scan_roots`, `local_albums`, `local_tracks`
- `LocalLibraryScanner`, `LocalLibraryRepository`, `ScanRootsStore`
- `LocalLibraryViewModel` + `LocalLibraryContent`
- Library tab: **Local | Downloads | Browse** (default Local)
- Settings: manage scan folders
- `PlaylistBuilder` `file://` support

**Out of scope:**
- (none listed)

## 3. Acceptance

- [ ] User can add folder + scan
- [ ] Albums listed grouped by folder
- [ ] Tap album plays local files
- [ ] Unit test for scanner grouping
