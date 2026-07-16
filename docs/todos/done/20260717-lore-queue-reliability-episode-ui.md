# Lore queue reliability + episode UI + full-tree metadata

- **Created**: 2026-07-17
- **Owner**: mirai
- **Status**: done

## 1. Goal

> Survive screen-off lore/translate work on Android 14+, stop blank EPs via soft-fail retries, show lore queue as work→episode list with partial-success UX, and translate folder + all tree labels.

## 2. Scope

**In scope:**
- Soft vs hard fail track retries with backoff/jitter
- API 34+ dataSync FGS (legacy ongoing notification below 14)
- Lore queue episode list + retry failed tracks
- Metadata translate folders + all leaves

**Out of scope:**
- WorkManager for mid-LLM HTTP
- Untyped FGS on API < 34
- Subtitle-content translate of non-audio files

## 3. Acceptance

- [x] Soft fail retries same track before blank stub
- [x] Android 14+ uses dataSync FGS during lore/translate; <14 falls back to ongoing show
- [x] Lore queue lists episodes with status/attempts; partial success summary; retry failed
- [x] Folder names + non-audio leaves get metadata translation
- [x] `flutter analyze` clean on touched files

## 4. Steps

- [x] Soft-fail retry in WorkLoreService — `lib/core/lore/work_lore_service.dart`, `test/core/lore/lore_soft_retry_test.dart`
- [x] Episode progress model + LoreGenerateQueueScreen UI — `lore_generate_queue_models.dart`, `lore_generate_queue_service.dart`, `lore_generate_queue_screen.dart`
- [x] PlatformCapabilities SDK + LlmBackgroundKeeper + manifest — `llm_background_keeper.dart`, DI wire into lore + translation queues
- [x] Full-tree metadata translate — `detail_viewmodel.dart`, `work_folder_item.dart`, `work_files_list.dart`, arb copy
- [x] CLAUDE.md + analyze + archive

## 5. Risks

- **Risk**: FGS policy / Android 15 6h dataSync budget
- **Rollback**: revert keeper wiring; keep decorative notification

## ✅ Done

`/init` executed (manual CLAUDE.md refresh) — 2026-07-17
