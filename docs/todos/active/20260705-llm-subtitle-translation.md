# LLM subtitle translation (OpenAI / OpenRouter)

- **创建时间**：2026-07-05
- **负责人**：cursor-agent
- **状态**：active

## 1. 目标

Playback subtitles auto-translate via OpenAI-compatible or OpenRouter APIs, with rich work/playlist context, configurable target language, system prompt override, and optional jailbreak prompt for stable adult-content translation.

## 2. 范围

**包含：**
- `LlmClient` + `SubtitleTranslationService` + disk cache
- Secure API key storage
- `AppSettingsService` LLM prefs + settings screen
- Hook in `PlayerViewModel` after subtitle parse
- zh/en/th UI strings

**不包含：**
- Real-time per-cue streaming translation UI
- Subtitle preview screen translation
- Server-side proxy

## 3. 验收标准

- [ ] Toggle enables/disables LLM translation during playback
- [ ] Endpoint/model/key configurable; OpenRouter preset works
- [ ] Target language + system/jailbreak prompts configurable
- [ ] Context includes work, track, playlist in LLM prompt
- [ ] Translated cache reused on replay
- [ ] `flutter analyze` + unit tests pass

## 4. 步骤

- [ ] Core services + repository
- [ ] Settings + UI
- [ ] PlayerViewModel integration
- [ ] L10n + DI + tests
