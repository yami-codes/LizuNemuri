# LLM resume, track-change fix, player view toggle polish

- **Created**: 2026-07-05
- **Owner**: cursor-agent
- **Status**: active
- **Related Issue / PR**:

---

## 1. Goal

Harden streaming translation edge cases with resume-from-partial, fix stale subtitles on track change, polish mobile cover/subtitle toggle.

## 2. Scope

**In scope:**
- Completeness gate + partial cache + resume untranslated lines only
- Keep partial UI on failure; SSE error/content_filter handling
- PlayerViewModel epoch cancel + immediate clear on track change
- Player view toggle redesign

**Out of scope:**
- In-player cancel button
- Subtitle preview screen

## 3. Acceptance

- [x] Partial progress saved; resume skips already-translated lines
- [x] Incomplete stream never marked complete in cache
- [x] Track change clears stale translation immediately
- [x] Player cover/subtitle switch looks polished on mobile
- [x] Tests pass
