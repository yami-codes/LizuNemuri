# Milestone G — DLsite Play library

- **创建时间**：2026-07-05
- **状态**：done
- **关联 PR**：#11

## Goal
DLsite Play purchased-library integration (cookie auth + library list + stream play).

## Scope
- Cookie-based auth (secure storage) + login screen with legal disclaimer
- `DlsitePlayLibraryService` (sales + works API, Eara port)
- `DlsitePlayWorkService` (sign + ziptree + audio URLs)
- Library screen + drawer entry
- Enrich RJ → asmr.one detail when available

## Acceptance
- [x] User can save play.dlsite.com cookie and load library
- [x] Tap album plays DLsite optimized audio stream
- [x] Disclaimer shown before login

## Notes
- v1: cookie paste only (no WebView); asmr.one RJ enrichment deferred
- Search field wired on library screen (`AppSearchField` + `setQuery`)

---

## ✅ 完成标记

- 完成时间：2026-07-05 10:00 UTC
- 执行命令：`/init`
- CLAUDE.md 更新摘要：Added `dlsite/` invariants + `dlsite_json_utils_test` in Tests.
- 关联 commit：`d26ffee`
