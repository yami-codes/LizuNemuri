# asmr.one tag + age rating filters

- **Created**: 2026-07-06
- **Owner**: cursor-agent
- **Status**: active
- **Related Issue / PR**: extends PR #18 (Eara advanced filter)

---

## 1. Goal

Add asmr.one-style **tag picker** ("tags I want") and **age rating** (general / R18) to browse, hot, and search lists — not only sort chips.

## 2. Scope

**In scope:**
- `FilterState.includeTags` + `AgeRatingFilter` persisted per screen (home / popular / search)
- `WorkListQueryBuilder` composes `$tag:name$` / `$age:general$` / `$age:adult$` search keywords
- Home / Hot / Search switch to `/search` when tag or age filter active
- Tag picker bottom sheet (multi-select from `/tags/`)
- Age chips on `AdvancedFilterBar`
- L10n (en/zh/th) + unit tests

**Out of scope:**
- Exclude tags ("tags I don't want") — not documented in API contract
- Circle / VA pickers in filter bar (already routed from browse screens)
- Recommend / Similar sort (subtitle-only API)

## 3. Acceptance

- [x] User can pick multiple tags; grid refreshes via search syntax
- [x] User can filter general-only or R18-only via age chips
- [x] Tag + age + sort + subtitle combine correctly
- [x] `flutter analyze` passes
- [x] `WorkListQueryBuilder` unit tests pass

## 4. Steps

- [x] **Step 1**: `AgeRatingFilter`, extend `FilterState`, `WorkListQueryBuilder`
- [x] **Step 2**: `TagPickerSheet` + `AdvancedFilterBar` age/tag chips
- [x] **Step 3**: Wire `HomeViewModel` / `PopularViewModel` / `SearchViewModel`
- [x] **Step 4**: L10n, tests, analyze, commit

## 5. Risks

- **Risk**: `/works` has no tag params — must use `/search` (slower, different pagination)
- **Rollback**: Revert branch; sort-only filters remain

## 6. Notes

- API probe: `$tag:A$ $tag:B$` (space-separated); `$age:general$` / `$age:adult$` (not `r18`)
- Tag key must be API `name`, not localized display name
