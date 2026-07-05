# Work title LLM translation + Windows back navigation

- **创建时间**：2026-07-05
- **负责人**：cursor-agent
- **状态**：active

## 1. 目标

Translate work/project title via LLM on detail page (cached per work), and fix missing back navigation on Windows for Search and other pushed screens.

## 2. 范围

**包含：**
- `WorkTitleTranslationService` + disk cache
- Detail `WorkInfoHeader` translate title UI
- Optional title in bulk translate selection
- `BackLeading` widget; Search AppBar; Favorites drawer/back fix

**不包含：**
- Work card grid title translation
- Mini player title line

## 3. 验收标准

- [x] Detail page: translate title button, cached reuse, show original option
- [x] Search screen has visible back on Windows
- [x] Favorites / browse pushed screens pop correctly
- [x] Tests + analyze pass

## 4. 步骤

- [x] Title translation service + DI
- [x] DetailViewModel + WorkInfoHeader UI
- [x] Back navigation fixes
- [x] L10n + tests + PR
