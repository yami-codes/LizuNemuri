# Accept-Language header for asmr.one API bypass

- **Created**: 2026-07-11
- **Status**: active

## Goal

Inject locale-aware `Accept-Language` on asmr API/media clients. **English is banned** on mirrors — English UI (or EN system locale) sends Thai header; Chinese UI sends zh; never includes `en` in the chain.

## Plan

- [x] `AsmrApiHeaders` + `AcceptLanguageInterceptor`
- [x] Wire ApiService, AuthService, SubtitleLoader, DownloadService, media fetch headers
- [x] Unit test interceptor
