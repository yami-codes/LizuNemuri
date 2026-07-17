# Queue UI Tachiyomi-style refactor

- **Created**: 2026-07-17
- **Owner**: mirai
- **Status**: done

## 1. Goal

> Rebuild lore + translation queues as TachiyomiSY-style work header + item rows — no fullGenerate dumps, no status soup.

## 2. Scope

**In scope:**
- Shared queue header + item row widgets
- Lore + Translation screen rewrites
- Kind l10n for header

**Out of scope:**
- Pause/reorder, FGS/retry logic, mini-indicator chrome

## 3. Acceptance

- [x] Prep shows human stage row — zero `fullGenerate`
- [x] Episodes/tracks are primary rows under work header
- [x] Both queues share hierarchy
- [x] `flutter analyze` clean on touched files

## 4. Steps

- [x] Shared widgets — `lib/widgets/queue/`
- [x] Lore screen — `lore_generate_queue_screen.dart`
- [x] Translation screen — `translation_queue_screen.dart`
- [x] l10n + analyze + archive

## ✅ Done

`/init` — 2026-07-17 (queue UI Tachiyomi hierarchy)
