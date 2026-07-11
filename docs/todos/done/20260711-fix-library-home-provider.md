# Fix LibraryTabContent missing HomeViewModel provider

- **Created**: 2026-07-11
- **Owner**: mirai
- **Status**: done

## 1. Goal

> Fix ProviderNotFoundError for HomeViewModel when opening Library from the sidebar (Browse segment / HomeContent).

## 2. Scope

**In scope:** `library_tab_content.dart` — own + provide HomeViewModel  
**Out of scope:** Merging with MainScreen's HomeViewModel instance

## 3. Acceptance

- [x] Opening Library from drawer does not throw ProviderNotFound
- [x] Browse segment shows HomeContent with working counts/title
- [x] analyze clean

## 4. Steps

- [x] Provide + dispose HomeViewModel in LibraryTabContent

## 5. Notes

> Sidebar `_navigate` pushes Library outside MainScreen MultiProvider. IndexedStack still builds HomeContent immediately, so missing HomeViewModel threw even before switching to Browse.

---

## ✅ Done

- Completed at: 2026-07-11 17:05
- Command run: `/init` (skipped CLAUDE — tiny provider scope fix)
- CLAUDE.md update summary: n/a (local route provider ownership, no new invariant beyond existing Provider scoping)
- Related commit: (pending user commit)
