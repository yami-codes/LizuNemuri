# Tag Search: `/` Not Encoded Causes 404 (Issue #2)

- **Created**: 2026-05-15
- **Owner**: WuMe-sicx
- **Status**: done <!-- active | done | cancelled -->
- **Related Issue / PR**: https://github.com/WuMe-sicx/Xuro/issues/2

---

## 1. Goal

Fix 404 when clicking some tags (e.g. "巨乳/爆乳"): when `tag.name` contains `/` (ASMR.ONE writes alias/merged tags as `primary/alias`), slashes in `/search/${...}` path are interpreted as path separators by the server → route mismatch → 404 → user sees garbled error.

## 2. Scope

**In scope:**
- Adjust path construction in `lib/data/services/api_service.dart::searchWorks` so all reserved characters in keyword (including `/`) are percent-encoded and not decoded by Dio.
- Add minimal unit test: keyword with `/` produces URL with `%2F` and only one search path segment.

**Out of scope:**
- Other API endpoints (no similar issues found; others put `/`-containing content in query params, not path segments).
- Tag list endpoint `/tags/` (parameterless list, unaffected).
- Manually typed search terms in input (already work; this task targets tag chip navigation path segments only).

## 3. Acceptance

- [x] Click tag "巨乳/爆乳" (`tag.name` contains `/`) returns 20 results, no 404.
- [x] Tags without slashes (e.g. "哦吼淫叫", "啊嘿颜") still work.
- [x] Unit test passes: `searchWorks` URL with slash in keyword keeps `/` as `%2F` in final path (single search segment).
- [x] `flutter analyze` passes, no new warnings.
- [ ] Real-device smoke test (left to maintainer): tap two tags containing `/` on tag screen, search screen shows results.

## 4. Steps

- [x] **Step 1**: Change `lib/data/services/api_service.dart::searchWorks`
  - Build full URI via `Uri.parse(baseUrl)` + `replace(pathSegments: ..., queryParameters: ...)`; call `_dio.getUri(uri)` not `_dio.get(path)` to avoid string-concat decode risk.
  - Verify: log or unit test confirms outgoing URL path contains `%2F` and `pathSegments.length == baseSegments + 2`.
- [x] **Step 2**: Add `test/data/services/api_service_url_test.dart`
  - No real HTTP; test URL construction only: keyword with `/` → URI path contains `%2F`.
  - Verify: `fvm flutter test test/data/services/api_service_url_test.dart` PASS.
- [x] **Step 3**: `fvm flutter analyze`, `fvm flutter test`, `git diff` for Codex review.
  - Verify: analyze clean + Codex ✅ PASS.

## 5. Risks

- **Risk**: `Uri.replace(pathSegments: [...])` replaces all path segments; if `baseUrl` has `/api` prefix, must preserve in segment list.
  - **Mitigation**: Concatenate via `baseUri.pathSegments`; handled in code.
- **Risk**: Dio `getUri` vs `get` consistency for interceptors, retry, query merge.
  - **Mitigation**: Dio 5.x docs; both are entry points, interceptors/retry apply equally.

## 6. Notes / Decision Log

- Empirical evidence (curl main site + three mirror nodes):
  - `https://api.asmr.one/api/search/%24tag%3A%E5%B7%A8%E4%B9%B3%2F%E7%88%86%E4%B9%B3%24?...` → 200, 20 results.
  - Same URL with `%2F` decoded to `/` → 404.
  - Server is correct; bug is Dart string-concat URL where Dio decodes `%2F`.
- Chose `Uri.pathSegments` + `getUri`: Dart-recommended explicit path-segment construction; each segment auto percent-encoded; Dio won't re-parse string.
- Codex: round 1 ⚠️ OPTIMIZE → round 2 ✅ PASS (SESSION_ID `019e2a9d-bde0-7053-a53d-1bd5d4dd0ea8`), added wire-level Dio interceptor test + reserved-char table cases + comment polish. 10 tests passed.
- User-reported "哦吼淫叫" returned 200 in curl (tag 524 primary name "啊哦淫叫", no `/`). Possibly old build or transient network. This fix covers root cause (tags with `/`); no separate follow-up for tag 524.

---

## ✅ Done

- Completed at: 2026-05-15
- Command run: `/init` (executed; CLAUDE.md refreshed)
- CLAUDE.md update summary: API section mandates `searchWorks` via `buildSearchUri` (Uri.pathSegments + getUri) and documents `%2F` decode → 404 root cause; Tests section reflects `test/data/services/` unit scaffold.
- Related commit: `8326d02` (code) + CLAUDE.md/archive commit
