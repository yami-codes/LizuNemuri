# Work title LLM translation + Windows back navigation

- **Created**: 2026-07-05
- **Owner**: cursor-agent
- **Status**: active
- **Related Issue / PR**:

---

## 1. Goal

Translate work/project title via LLM on detail page (cached per work), and fix missing back navigation on Windows for Search and other pushed screens.

## 2. Scope

**In scope:**
- `WorkTitleTranslationService` + disk cache
- Detail `WorkInfoHeader` translate title UI
- Optional title in bulk translate selection
- `BackLeading` widget; Search AppBar; Favorites drawer/back fix

**Out of scope:**
- Work card grid title translation
- Mini player title line

## 3. Acceptance

- [x] Detail page: translate title button, cached reuse, show original option
- [x] Search screen has visible back on Windows
- [x] Favorites / browse pushed screens pop correctly
- [x] Tests + analyze pass

## 4. Steps

- [x] Title translation service + DI
- [x] DetailViewModel + WorkInfoHeader UI
- [x] Back navigation fixes
- [x] L10n + tests + PR
