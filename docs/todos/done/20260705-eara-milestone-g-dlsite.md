# Milestone G — DLsite Play library

- **Created**: 2026-07-05
- **Owner**: cursor-agent
- **Status**: done
- **Related Issue / PR**: #11

---

## 1. Goal

DLsite Play purchased-library integration (cookie auth + library list + stream play).

## 2. Scope

**In scope:**
- Cookie-based auth (secure storage) + login screen with legal disclaimer
- `DlsitePlayLibraryService` (sales + works API, Eara port)
- `DlsitePlayWorkService` (sign + ziptree + audio URLs)
- Library screen + drawer entry
- Enrich RJ → asmr.one detail when available

**Out of scope:**
- WebView cookie capture (v1: cookie paste only)
- Full asmr.one RJ enrichment (deferred)

## 3. Acceptance

- [x] User can save play.dlsite.com cookie and load library
- [x] Tap album plays DLsite optimized audio stream
- [x] Disclaimer shown before login

## 4. Steps

- (see related commit)

## 5. Risks

- (none recorded)

## 6. Notes

- v1: cookie paste only (no WebView); asmr.one RJ enrichment deferred
- Search field wired on library screen (`AppSearchField` + `setQuery`)

---

## ✅ Done

- Completed at: 2026-07-05 10:00 UTC
- Command run: `/init`
- CLAUDE.md update summary: Added `dlsite/` invariants + `dlsite_json_utils_test` in Tests.
- Related commit: `2829586`
