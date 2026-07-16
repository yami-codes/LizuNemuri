# Realtime lore generate progress UI

- **Created**: 2026-07-16
- **Owner**: mirai
- **Status**: done

## 1. Goal

> Make lore generate progress update live during subtitle prep and while waiting on each LLM call, instead of sitting dead for minutes between stage jumps.

## 2. Scope

**In scope:**
- LoreTrackInputBuilder progress callbacks
- LoreGenerateQueueService live heartbeat + prep progress
- Detail generating card + mini indicator UX (indeterminate while waiting, elapsed, clearer stage)

**Out of scope:**
- Streaming full lore JSON mid-parse (LLM still needs complete JSON)

## 3. Acceptance

- [x] Subtitle resolve/translate reports progress before first LLM call
- [x] While an LLM call is in flight, UI pulses (indeterminate) and shows elapsed seconds
- [x] Stage label updates immediately on phase change (cast / track i/N / reconcile)
- [x] analyze clean on touched files

## 4. Steps

- [x] Builder + queue live progress
  - Files: `lib/core/lore/lore_track_input_builder.dart`, `lore_generate_queue_service.dart`, `lore_generate_queue_models.dart`, `work_lore_service.dart` (`onWaiting`)
- [x] UI card / mini indicator
  - Files: `work_lore_panel.dart`, `lore_generate_queue_mini_indicator.dart`, `lore_progress_labels.dart`, `lore_generate_queue_screen.dart`
- [x] l10n + tests/analyze + archive
  - Files: `app_en/zh/th.arb`, `strings.dart`; `fvm flutter analyze` clean on touched files

---
## ✅ Done

- Completed at: 2026-07-16 22:30 (UTC+7)
- Command run: `/init` (manual CLAUDE.md lore live-progress invariant)
- CLAUDE.md update summary: documented `subs:*` prep progress, `onWaiting` / `waitingOnLlm` / heartbeat for indeterminate+elapsed UI
- Related commit: (uncommitted)
