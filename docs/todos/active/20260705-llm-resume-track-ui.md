# LLM resume, track-change fix, player view toggle polish

- **创建时间**：2026-07-05
- **负责人**：cursor-agent
- **状态**：active

## 1. 目标

Harden streaming translation edge cases with resume-from-partial, fix stale subtitles on track change, polish mobile cover/subtitle toggle.

## 2. 范围

**包含：**
- Completeness gate + partial cache + resume untranslated lines only
- Keep partial UI on failure; SSE error/content_filter handling
- PlayerViewModel epoch cancel + immediate clear on track change
- Player view toggle redesign

**不包含：**
- In-player cancel button
- Subtitle preview screen

## 3. 验收标准

- [x] Partial progress saved; resume skips already-translated lines
- [x] Incomplete stream never marked complete in cache
- [x] Track change clears stale translation immediately
- [x] Player cover/subtitle switch looks polished on mobile
- [x] Tests pass
