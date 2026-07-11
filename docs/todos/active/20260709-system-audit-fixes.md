# System audit — correctness fixes

- **Created**: 2026-07-09
- **Status**: active

## Goal

Fix out-of-place / broken behavior found in a full-app audit after Material You + URL refresher landings.

## Plan

- [x] Align `PlayerLayoutConfig` tests with current cover sizing
- [x] Search: cancel debounce + generation guard against stale responses
- [x] Remove dead player backdrop clarity setting (M3 player has no backdrop)
- [x] Refresh subtitle URL in player load path; refresh file tree on playback restore
- [x] Don't show "translation done" when LLM translate was cancelled/stale
- [x] Clean obvious analyze warnings (unused imports / dead immersive branch / dead playlist pop)
