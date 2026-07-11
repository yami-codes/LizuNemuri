# Background LLM translation queue + split fix + resume/retry

- **Created**: 2026-07-11
- **Owner**: cursor-agent
- **Status**: done
- **Related Issue / PR**:

---

## 1. Goal

Replace the blocking bulk-translate dialog with a persisted, multi-work background queue (mini indicator + queue menu + notifications), fix provider split so it trusts the model context window, and auto-retry/resume so partial work is never wasted.

## 2. Scope

**In scope:**
- `LlmBatchPlanner` provider mode: drop hard 120-line cap; only split when estimate won't fit
- Setting `llmTranslateRetryCount` (default 10)
- App-level `TranslationQueueService`: FIFO across works, concurrency 2, persist queue + resume on launch
- Per-track auto-retry up to N; line-level resume via existing partial cache
- UI: mini indicator, queue menu (sidebar/Library + from indicator), progress notifications
- Detail bulk translate enqueues and dismisses (does not block / cancel on dismiss)
- zh/en/th l10n + unit tests

**Out of scope:**
- Rewriting Downloads hub into a generic job center
- Server-side LLM proxy
- Auto re-translate on target-language change
- iOS background execution beyond best-effort while process alive

## 3. Acceptance

- [x] Bulk translate from detail enqueues; user can leave the page; job keeps running
- [x] Mini indicator visible while queue active; tap opens queue menu
- [x] Sidebar/Library entry opens translation queue menu
- [x] Notification updates while translating (Android/iOS best-effort via flutter_local_notifications)
- [x] Failed track retries up to settings N (default 10), then continues queue
- [x] Process kill: queue + partial lines restore; unfinished lines not re-translated from scratch
- [x] `none` split = one request; `provider` no longer clamps to 120 lines
- [x] Global LLM concurrency capped at 2 (`LlmRequestGate`)
- [x] `flutter analyze` / relevant tests pass with no new warnings

## 4. Steps

- [x] **Step 1**: Fix `LlmBatchPlanner` + tests; add retry setting
  - Files: `lib/core/llm/llm_batch_planner.dart`, `app_settings_service.dart`, l10n, tests
  - Verify: unit tests for planner + settings default
- [x] **Step 2**: `TranslationQueueService` + persistence + DI
  - Files: `lib/core/llm/translation_queue_*.dart`, `llm_request_gate.dart`, `service_locator.dart`
  - Verify: unit tests for gate + store persist/resume
- [x] **Step 3**: Wire detail bulk translate to enqueue; keep selection dialog
  - Files: `detail_screen.dart`
  - Verify: enqueue path; no blocking progress dialog
- [x] **Step 4**: Mini indicator + queue screen + notifications + nav
  - Files: `translation_queue_screen.dart`, mini indicator, sidebar, main_screen, notification helper
  - Verify: analyze clean
- [x] **Step 5**: l10n sweep, analyze, tests
  - Verify: `llm_translation_test` + `translation_queue_test` pass

## 5. Risks

- **Risk**: Parallel player + queue translate races on same track cache file
- **Mitigation**: `LlmRequestGate` caps concurrent LLM calls at 2; completeness merge is last-write-wins on line map
- **Risk**: Notification permission / missing plugin on desktop
- **Mitigation**: best-effort; mobile-only notifications; mini indicator always available
- **Rollback**: revert feature branch; old `BatchTranslateDialog` still in tree unused

## 6. Notes / Decision Log

- Dismiss UI ≠ cancel; explicit cancel only
- Retry setting default 10
- Surfaces: mini + queue menu + notification
- Nav: mini primary + sidebar entry
- Provider split: real window, drop 120 cap
- Concurrency: 2 global LLM slots via `LlmRequestGate`
- Persist queue + partial translations across process death
- Multi-work global FIFO

---

## ✅ Done

- Completed at: 2026-07-11 11:20
- Command run: `/init` (manual CLAUDE.md `llm/` queue invariants)
- CLAUDE.md update summary: added `lib/core/llm/` entry — background TranslationQueueService, LlmRequestGate concurrency 2, provider split no 120-cap, retry setting, mini/queue/notification surfaces.
- Related commit: 52ed8f5

