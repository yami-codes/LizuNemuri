# Lore speedup + translate cache dedupe + lore generate queue

- **Created**: 2026-07-15
- **Owner**: mirai
- **Status**: done

## 1. Goal

> Finish remaining phases: cut wasted lore LLM calls (merge secrets, skip reconcile, rolling brief, reactive pacer), make subtitle translate cache/queue hash-centric with remaster dedupe, and add a background lore generate queue mirroring translation queue.

## 2. Scope

**In scope:**
- WorkLoreService pipeline speedup
- SubtitleTranslationCache hash-primary + queue LogicalTrackDedupe
- LoreGenerateQueue (models/store/service/UI/DI)
- Tests + CLAUDE.md refresh

**Out of scope:**
- Parallel track LLM concurrency
- OpenRouter is_free_tier auto-detect
- Lore job mid-pipeline checkpoint resume

## 3. Acceptance

- [x] Full generate with secrets ≈ `1+N` (+ optional reconcile), not `2+2N`
- [x] Same subtitle hash → one cache file regardless of audio title
- [x] Bulk translate enqueue collapses remaster twins
- [x] Detail lore Generate enqueues background job; survive navigation
- [x] Unit tests for pacer/brief/reconcile/queue store
- [x] analyze clean on touched paths

## 4. Steps

- [x] **S1** LoreLlmPacer, LoreTrackContextBrief, reconcile heuristic
- [x] **S2** Merge secrets + slim prompts + generate() pipeline
- [x] **S3** Settings loreLlmPaceMs + secrets-only pacer/brief
- [x] **B1** Hash-primary SubtitleTranslationCache + mem key
- [x] **B2** Queue/selection LogicalTrackDedupe
- [x] **C1** LoreTrackInputBuilder + LoreGenerateQueue stack
- [x] **C2** Panel/main/sidebar + DI init
- [x] **V** Tests + CLAUDE + archive TODO

---

## ✅ Done

- Completed at: 2026-07-15
- Command run: `/init` (manual CLAUDE.md lore + llm invariants refresh)
- CLAUDE.md update summary: merged track+secrets, conditional reconcile, pacer gap 0, hash-primary translate cache, lore generate queue
- Related commit: (uncommitted)
