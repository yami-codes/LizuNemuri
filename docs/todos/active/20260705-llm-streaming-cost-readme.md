# LLM streaming translation, split modes, cost history, README i18n

- **Created**: 2026-07-05
- **Owner**: cursor-agent
- **Status**: active
- **Related Issue / PR**:

---

## 1. Goal

Stream-parse subtitle translations line-by-line, fix mobile player translation layout, add configurable batch split modes, track OpenRouter token/cost usage with history, and make English the primary README with zh/th sub-pages.

## 2. Scope

**In scope:**
- NDJSON streaming format + incremental subtitle updates during translation
- Split mode: none / provider context / manual batch size
- `LlmUsageRepository` + settings UI for cost/token history (OpenRouter)
- Mobile player translation status banner layout fix
- README.md (EN) + README_zh.md + README_th.md

**Out of scope:**
- Subtitle preview screen streaming translate
- Server-side proxy for LLM

## 3. Acceptance

- [x] Mobile player shows translation progress without AppBar overflow
- [x] Subtitles update incrementally while LLM streams NDJSON lines
- [x] Split mode none/provider/manual respected in batch planner
- [x] Usage records prompt/completion tokens + cost; history screen lists entries
- [x] README.md is English; zh/th linked as subs
- [x] `fvm flutter test` + analyze on touched files pass

## 4. Steps

- [x] Core: streaming client, parser, batch planner, usage repo
- [x] Service + ViewModel partial translation callbacks
- [x] Settings UI: split mode, usage history screen
- [x] Player mobile layout fix
- [x] L10n + README + tests + PR (#10, commit 8f0ff7d)

## 5. Risks

- **Risk**: Streaming parse errors may show partial subs; provider model lookup may fail offline
- **Rollback**: Revert branch; non-streaming path kept as fallback when stream disabled
