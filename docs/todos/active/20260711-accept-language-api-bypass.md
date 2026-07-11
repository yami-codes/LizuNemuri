# Accept-Language header for asmr.one API bypass

- **Created**: 2026-07-11
- **Status**: active

## Goal

asmr.one mirrors gate traffic on browser `Accept-Language` only. Send zh-heavy header on all asmr API/media clients so Thai/EN UI users reach the API without VPN.

## Plan

- [x] `AsmrApiHeaders` + `AcceptLanguageInterceptor`
- [x] Wire ApiService, AuthService, SubtitleLoader, DownloadService, media fetch headers
- [x] Unit test interceptor
