# Fix streaming translation lyric active-line flicker

- **Created**: 2026-07-11
- **Owner**: cursor-agent
- **Status**: active

---

## 1. Goal

> Stop the current lyric line flickering active/inactive while LLM subtitle translation streams partial updates.

## 2. Scope

**In scope:** `SubtitleStateManager`, `SubtitleService.loadSubtitleFromContent`, `PlayerLyricView` active/scroll guards.

**Out of scope:** Translation model/prompt changes.

## 3. Acceptance

- [x] Partial `loadSubtitleFromContent` does not call `clearSubtitle()` first
- [x] Current subtitle tracked by **index**, not object identity
- [x] Streaming partial updates do not emit null current-subtitle between chunks
- [x] Unit test covers replace-without-clear behavior
- [x] `flutter analyze` + relevant tests pass

## 4. Steps

- [ ] Fix `SubtitleStateManager` position/index sync
- [ ] Remove clear-before-replace in `loadSubtitleFromContent`
- [ ] Index-based `isActive` + scroll guard in `PlayerLyricView`
- [ ] Add unit test
