# Fix cover images failing on asmr CDN (missing Accept-Language)

- **Created**: 2026-07-11
- **Owner**: cursor-agent
- **Status**: active
- **Related Issue / PR**: user report — home grid red error placeholders; only Chinese UI loads metadata

---

## 1. Goal

> Cover art and other CDN image fetches must send browser-like `Accept-Language` (zh-CN) headers so asmr.one mirrors do not block them; API requests already have headers but `ImageCacheManager` did not.

## 2. Scope

**In scope:**
- Custom `FileService` for `ImageCacheManager` injecting CDN headers
- Shared `AsmrApiHeaders.cdnFetchHeaders` used by image cache + media CDN fetches
- Unit test for header injection

**Out of scope:**
- Changing UI language / translation behavior
- DLsite cover URLs (different host)

## 3. Acceptance

- [x] `ImageCacheManager` uses header-aware file service with `zh-CN` Accept-Language
- [x] `WorkMediaUtils.mediaFetchHeaders` reuses shared CDN header map
- [x] Unit test passes
- [x] `fvm flutter analyze` passes with no new warnings
- [x] Relevant unit tests pass

## 4. Steps

- [x] **Step 1**: Add `cdnFetchHeaders` to `AsmrApiHeaders`
- [x] **Step 2**: Implement `AsmrHttpFileService` wrapping `HttpFileService`
- [x] **Step 3**: Wire into `ImageCacheManager` + `WorkMediaUtils`
- [x] **Step 4**: Add unit test

## 5. Risks

- **Risk**: Stale cached 403/error responses in image cache after fix
- **Rollback**: Revert branch; users can clear image cache in Settings

## 6. Notes / Decision Log

- CDN/image traffic always sends `zhAcceptLanguage` — mirrors require Chinese regardless of UI language; API Dio clients now use the same fixed header (no locale-aware mapping).
