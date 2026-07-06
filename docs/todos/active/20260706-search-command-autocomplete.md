# ASMR.one search command syntax + autocomplete

- **Created**: 2026-07-06
- **Owner**: cursor-agent
- **Status**: active

## 1. Goal

Support ASMR.one-style `$tag:`, `$age:`, `$duration:`, `$price:`, `$-tag:` search filters with autocomplete dropdown in the search field.

## 2. Scope

**In scope:** Parser, suggestor, SearchCommandField, SearchViewModel tag loading, tests, l10n hints

**Out of scope:** Home/Hot inline syntax (chip bar remains); circle/va live autocomplete from API

## 3. Acceptance

- [x] Typing `$` shows command list; `$tag:` shows tag suggestions; `$age:` / `$price:` / `$duration:` show presets
- [x] Parsed tokens compose correct `/search/{keyword}` string
- [x] Tests + analyze pass

## 4. Steps

- [x] SearchCommandParser + SearchCommandSuggestor
- [x] SearchCommandField widget
- [x] Wire SearchScreen + SearchViewModel
- [x] Extend WorkListQueryBuilder merge logic
- [x] l10n + tests
- [x] docs/search_command_syntax.md
- [x] Work card tag tap/long-press include/exclude
