# LLM streaming translation, split modes, cost history, README i18n

- **创建时间**：2026-07-05
- **负责人**：cursor-agent
- **状态**：active

## 1. 目标

Stream-parse subtitle translations line-by-line, fix mobile player translation layout, add configurable batch split modes, track OpenRouter token/cost usage with history, and make English the primary README with zh/th sub-pages.

## 2. 范围

**包含：**
- NDJSON streaming format + incremental subtitle updates during translation
- Split mode: none / provider context / manual batch size
- `LlmUsageRepository` + settings UI for cost/token history (OpenRouter)
- Mobile player translation status banner layout fix
- README.md (EN) + README_zh.md + README_th.md

**不包含：**
- Subtitle preview screen streaming translate
- Server-side proxy for LLM

## 3. 验收标准

- [ ] Mobile player shows translation progress without AppBar overflow
- [ ] Subtitles update incrementally while LLM streams NDJSON lines
- [ ] Split mode none/provider/manual respected in batch planner
- [ ] Usage records prompt/completion tokens + cost; history screen lists entries
- [ ] README.md is English; zh/th linked as subs
- [ ] `fvm flutter test` + analyze on touched files pass

## 4. 步骤

- [ ] Core: streaming client, parser, batch planner, usage repo
- [ ] Service + ViewModel partial translation callbacks
- [ ] Settings UI: split mode, usage history screen
- [ ] Player mobile layout fix
- [ ] L10n + README + tests + PR

## 5. 风险与回滚

- **风险**：Streaming parse errors may show partial subs; provider model lookup may fail offline
- **回滚方案**：Revert branch; non-streaming path kept as fallback when stream disabled
