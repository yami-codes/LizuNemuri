# Fix Windows playback (SQLite + URL refresher)

- **Created**: 2026-07-06
- **Status**: active

## Goal

Restore online playback on Windows when SQLite native library is missing and stop URL refresh from failing on immutable Freezed file trees.

## Root cause (from user logs)

1. `DownloadService.localPathIfDownloaded` opens SQLite → `sqlite3.dll` not found → every playlist item skipped.
2. `WorkMediaUrlRefresher` patch into Freezed `children` throws `Cannot modify an unmodifiable list`, aborting refresh.

## Plan

- [x] Bundle/load SQLite on Windows (`sqlite3_flutter_libs`, `winsqlite3.dll` fallback)
- [x] Playlist builder: download lookup failure falls back to streaming
- [x] URL refresher: patch failure must not discard fresh URL
- [ ] Tests + rc.15 bump
