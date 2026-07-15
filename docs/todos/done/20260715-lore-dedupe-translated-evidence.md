# Track dedupe + translated lore evidence

- **Created**: 2026-07-15
- **Owner**: mirai
- **Status**: done

## 1. Goal

> Collapse remaster twins (no-SFX / mp3-wav) before lore LLM calls, and feed lore only subtitles already translated to the lore language so evidenceQuote is never raw JP/CN.

## 2. Scope

**In scope:**
- Shared logical-track dedupe helper
- WorkLoreViewModel generate/regen/secrets input pipeline
- Translate-ensure via SubtitleTranslationService (lore language)
- Prompt rule against original-language quotes
- Remove blind 1.5s lore inter-track delay

**Out of scope (follow-up):**
- Full translation-queue subtitle-centric cache migration
- Lore background queue UI
- Merge secrets into track pass / rolling brief (speedup plan)

## 3. Acceptance

- [x] Remaster twins → one LoreTrackInput per logical episode
- [x] LoreTrackInput.subtitleText is in resolved lore language when translation succeeds
- [x] Prompt forbids original JP/CN evidence quotes
- [x] No hardcoded 1.5s delay between lore track LLM calls
- [x] Unit tests + analyze clean on touched files

## 4. Steps

- [x] Dedupe helper + tests (`lib/core/media/logical_track_dedupe.dart`)
- [x] Lore subtitle language pipeline + translate override
- [x] Wire ViewModel + prompts + drop 1.5s delay + pack key align
- [x] Analyze / close

## 6. Notes / Decision Log

- Regen/secrets reuses pack `trackKey` via normalized title so remaster collapse doesn't orphan regen lookups.
- Cross-folder twins merge only when subtitle content ≥80 chars and MD5 matches.

---

## ✅ Done

- Completed at: 2026-07-15
- Command run: `/init` (manual CLAUDE.md lore invariants refresh)
- CLAUDE.md update summary: lore dedupe + translated evidence; removed blind 1.5s delay; regen key align
- Related commit: (uncommitted)
