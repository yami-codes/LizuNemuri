# Internal metadata translation (Google + LLM Lite/Main)

- **Created**: 2026-07-06
- **Owner**: cursor-agent
- **Status**: active
- **Related Issue / PR**: metadata translation feature

---

## 1. Goal

Add internal translation for work list titles, search results, and track names using free Google Translate (no API key) or LLM bulk (one page = one request), with Main/Lite model split and auto/manual settings.

## 2. Scope

**In scope:**
- Google Translate client (`translate.googleapis.com`, client=gtx)
- Settings: provider (google/llm), mode (auto/manual), Main model (subtitles), Lite model (metadata)
- Bulk list title translation in paginated/search/favorites/recommend VMs
- Track name translation in work detail (auto + manual)
- Settings UI + l10n strings
- Unit tests for Google response parsing and bulk LLM JSON parsing

**Out of scope:**
- Tag label translation (TagDisplayName already handles English)
- Subtitle pipeline changes beyond Main model routing
- Multiple LLM endpoints (shared endpoint, different models only)

## 3. Acceptance

- [ ] Work grids show translated titles when metadata translation enabled + auto
- [ ] Manual translate action available for lists and track names when mode=manual
- [ ] Google provider works without API key; LLM Lite used when provider=llm
- [ ] Subtitle translation uses Main model; metadata uses Lite model
- [ ] Settings expose provider, mode, Main/Lite models
- [ ] `flutter analyze` passes; relevant tests pass

## 4. Steps

- [x] **Step 1**: Settings enums + AppSettingsService fields
- [x] **Step 2**: GoogleTranslateClient + MetadataTranslationService + cache
- [x] **Step 3**: LlmClient Main/Lite model routing
- [x] **Step 4**: WorkListTranslationMixin + VM hooks
- [x] **Step 5**: UI wiring (grid, detail tracks, settings)
- [x] **Step 6**: Tests + analyze + commit

## 5. Risks

- **Risk**: Unofficial Google endpoint rate limits or breakage
- **Rollback**: Switch provider to LLM or disable metadata translation toggle
