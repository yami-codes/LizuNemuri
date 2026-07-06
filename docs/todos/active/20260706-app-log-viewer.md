# In-app diagnostic log viewer

- **Created**: 2026-07-06
- **Status**: active

## Goal

Capture app logs by level, view/copy/clear them in Settings, so playback/translation failures are debuggable without adb.

## Plan

- [x] AppLogStore + AppLogLevel + AppLogger integration
- [x] Settings capture level + AppLogViewerScreen (filter, copy, clear)
- [x] Global Flutter error hooks
- [x] Tagged detail logs for playback/subtitle/translation
- [x] Tests + l10n
