# Fix WorkMediaUrlRefresher unmodifiable list patch

- **Created**: 2026-07-06
- **Status**: active

## Goal

Stop `Cannot modify an unmodifiable list` when refreshing presigned URLs on Freezed file trees.

## Plan

- [x] Immutable `patchInFiles` in `WorkMediaUtils`
- [x] `onTreePatched` callback in `WorkMediaUrlRefresher.refreshFile`
- [x] Wire `DetailViewModel._freshFile` to replace `_files`
- [x] Unit tests for immutable patch path

## ✅ Done

- Moved during 2026-07-09 system audit (shipped or superseded by M3 player).
- /init: skipped (batch housekeeping)
- Timestamp: 2026-07-09
