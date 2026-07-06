# LLM subtitle translation (OpenAI / OpenRouter)

- **Created**: 2026-07-05
- **Owner**: cursor-agent
- **Status**: active
- **Related Issue / PR**:

---

## 1. Goal

Playback subtitles auto-translate via OpenAI-compatible or OpenRouter APIs, with rich work/playlist context, configurable target language, system prompt override, and optional jailbreak prompt for stable adult-content translation.

## 2. Scope

**In scope:**
- `LlmClient` + `SubtitleTranslationService` + disk cache
- Secure API key storage
- `AppSettingsService` LLM prefs + settings screen
- Hook in `PlayerViewModel` after subtitle parse
- zh/en/th UI strings

**Out of scope:**
- Real-time per-cue streaming translation UI
- Subtitle preview screen translation
- Server-side proxy

## 3. Acceptance

- [ ] Toggle enables/disables LLM translation during playback
- [ ] Endpoint/model/key configurable; OpenRouter preset works
- [ ] Target language + system/jailbreak prompts configurable
- [ ] Context includes work, track, playlist in LLM prompt
- [ ] Translated cache reused on replay
- [ ] `flutter analyze` + unit tests pass

## 4. Steps

- [ ] Core services + repository
- [ ] Settings + UI
- [ ] PlayerViewModel integration
- [ ] L10n + DI + tests
