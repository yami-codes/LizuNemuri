# Lore intelligent resume (checkpoint + skip done)

- **Created**: 2026-07-18
- **Owner**: mirai
- **Status**: done

## 1. Goal

> Checkpoint lore pack after cast + each finished track; resume skips already-complete work so mid-run failure does not redo the whole generate.

## 2. Scope

**In scope:**
- `loreTrackSummaryIsComplete` helper
- `generate(resumeFrom:)` checkpoint + skip
- Queue hydrate / retryFailed / cold-start

**Out of scope:**
- Mid-stream NDJSON resume
- Cast/reconcile streaming

## 3. Acceptance

- [x] Kill after track N → pack has cast + 0..N; retry only LLMs remaining
- [x] retryFailed leaves complete episodes alone
- [x] Soft-empty stubs still retried
- [x] analyze + unit tests pass

## 4. Steps

- [x] Helper + generate checkpoint/resume — `lib/core/lore/lore_resume.dart`, `work_lore_service.dart`
- [x] Queue hydrate + retryFailed + cold start — `lore_generate_queue_service.dart`
- [x] Tests + CLAUDE.md + archive — `test/core/lore/lore_resume_test.dart`

## ✅ Done

- Completed at: 2026-07-18
- Command run: `/init` (manual CLAUDE.md intelligent-resume invariant)
- CLAUDE.md update summary: Checkpoint after cast/track; resumeFrom skip complete summaries; hydrate + retryFailed keep done EPs
