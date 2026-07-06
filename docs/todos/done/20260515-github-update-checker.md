# In-App Update Check + Download Redirect (GitHub Releases)

- **Created**: 2026-05-15
- **Owner**: WuMe-sicx
- **Status**: done <!-- active | done | cancelled -->
- **Related Issue / PR**: (TBD)

---

## 1. Goal

> One line: Add "检查更新" entry under Settings → About, read this repo's GitHub Releases, compare with current version; when newer, show version + release notes and guide user to download — upgrade without manually browsing GitHub.

**Context**:

- Repo: `https://github.com/WuMe-sicx/Xuro`, current version `pubspec.yaml` = `1.1.11`.
- CI (`.github/workflows/build.yml`) on `v*` tag push uses `softprops/action-gh-release@v2` with **`prerelease: true`**, artifacts: Android `app-release.apk` / `app-release.aab`, iOS `app-release.ipa`.
- **Key constraint**: All releases are prerelease, so GitHub `GET /releases/latest` **skips prerelease** (may 404). Must use `GET /repos/WuMe-sicx/Xuro/releases?per_page=10`, **filter tags matching `^v?\d+\.\d+\.\d+$`, pick semver max** (not list `[0]`: GitHub does not guarantee first item is max semver; republished old tags can mislead).
- **Error semantics must not reuse `NetworkException`**: `NetworkException.userMessage` is asmr.one-specific — 403/401 → 「请先登录」, connection/timeout → 「请先连接 VPN 服务」 (asmr.one geo-blocked). GitHub is **not geo-blocked**, and 403/429 are **rate limit** not auth failure. This feature needs **GitHub-specific error mapping**; must not expose asmr login/VPN copy on update check.
- Existing deps sufficient, no new pub packages: `dio`, `package_info_plus`, `url_launcher`, `permission_handler`, `path_provider`.

## 2. Scope

**In scope (Phase 1):**

- New `UpdateService`: independent Dio to `https://api.github.com`, GitHub headers `Accept: application/vnd.github+json` + `X-GitHub-Api-Version: 2022-11-28`, read releases list, filter valid tags, pick semver max, parse release and APK asset URL.
- New **GitHub-specific** `UpdateException` + `UpdateErrorType` enum (separate from `NetworkException`): `network` (connection/timeout — generic network failure, **no** VPN mention), `rateLimited` (403/429 + rate-limit headers/body — 「GitHub 请求过于频繁，请稍后再试」), `notFound` (404), `noRelease` (empty list / no valid tag — 「暂无可用发布」), `invalidPayload` (JSON parse fail — 「发布信息解析失败」), `unknown`. Each type has own `userMessage`.
- Version compare: pure `compareSemver(String a, String b)` (strip `v`, pad digits, safe on invalid input), compare with `package_info_plus` current version; use to pick max among valid releases.
- New `UpdateInfo` Freezed model (`lib/data/models/`, **`.freezed.dart` only, no json_serializable**: derived mapping, custom `factory UpdateInfo.fromReleaseJson(Map)`, no generated `fromJson`). `apkDownloadUrl` nullable.
- New `UpdateViewModel` (`ChangeNotifier`, mirrors `AuthViewModel`).
- New `UpdateDialog`: checking / up-to-date / new version (version + notes + 「立即下载」「稍后」) / error (`UpdateException.userMessage` + retry) four states.
- Settings → About `_aboutSection()` new `SettingsTile.navigation()` entry, copy via `Strings`.
- Download action: `url_launcher` external open — Android prefer `.apk` asset `browser_download_url`; **Android no `.apk` asset falls back to Release `html_url`** (button still works, no dead link); iOS/other always Release `html_url`.
- DI register `UpdateService` (lazy singleton, after `ApiService`).
- Strings centralized in `lib/common/constants/strings.dart`.
- Pure logic tests: `compareSemver` + GitHub Release JSON parse (network-free, mirrors `test/data/services/api_service_url_test.dart`).

**Out of scope (explicit boundary):**

- ❌ In-app APK downloader with progress bar.
- ❌ Android silent install Intent, `REQUEST_INSTALL_PACKAGES`, FileProvider, Manifest changes (conservative on native; Phase 2 separate TODO).
- ❌ iOS sideload (GitHub IPA not sideloadable; iOS opens Release page only).
- ❌ Auto check on launch / background poll / auto-check setting (needs `AppSettingsService`, later).
- ❌ Force update / staged rollout / delta updates.

## 3. Acceptance

- [x] Settings → About shows "检查更新" entry; tap opens `UpdateDialog`.
- [x] Remote latest > current: dialog shows remote version, release notes, 「立即下载」 (Android `.apk` link, iOS Release page) and 「稍后」.
- [x] Remote ≤ current: dialog shows up-to-date message.
- [x] Network failure (offline/timeout/GitHub unreachable): **generic network prompt** (not VPN, not 「请先登录」), retry offered, no crash, no swallowed exception.
- [x] **GitHub rate limit (403/429)**: show 「GitHub 请求过于频繁，请稍后再试」, **not** 「请先登录」; unit test covers mapping.
- [x] All prerelease releases still resolve latest (use `/releases?per_page=10` filter max semver, not `/releases/latest`; unit or manual test).
- [x] **Empty releases / all invalid tags**: show 「暂无可用发布」, no crash.
- [x] **Multiple valid releases**: picks semver max (not list first); unit test includes "first item old tag, max later" case.
- [x] **Android release has no `.apk` asset**: 「立即下载」 falls back to Release `html_url`, no dead link (code + device verified).
- [x] `tag_name` like `v1.1.12` strips `v` and compares with `1.1.11`; invalid/missing tag hits error branch not crash (unit tests).
- [x] `compareSemver` tests: equal / major/minor/patch greater-less / uneven digits (`1.2` vs `1.2.0`) / `v` prefix / invalid input / multi-version max pick.
- [x] `UpdateInfo.fromReleaseJson` tests: normal `tag_name`/`body`/`html_url`/first `.apk` `browser_download_url`; boundaries `[]`, no `assets`, assets no `.apk`, missing `tag_name`, missing `html_url`.
- [x] `flutter analyze` (8 changed files) passes, no new warnings.
- [x] Ran `dart run build_runner build --delete-conflicting-outputs`; `UpdateInfo` generated (**`.freezed.dart` only, no `.g.dart`**) committed.
- [x] Related unit tests `fvm flutter test` (21 cases) all pass.
- [x] Settings→About→check update four UI states — user verified on real device (2026-05-15).

## 4. Steps

- [x] **Step 1**: Add `UpdateInfo` Freezed model
  - Files: `lib/data/models/update_info.dart` (+ generated `.freezed.dart`, **no `.g.dart`**)
  - Fields: `tagName`, `version`(strip v), `releaseNotes`, `htmlUrl`, `apkDownloadUrl`(nullable), `publishedAt`
  - `factory UpdateInfo.fromReleaseJson(Map<String,dynamic>)`: custom mapping (derive `version`, pick first `.apk` asset), **no** json_serializable `fromJson`; illegal/missing → `UpdateException(invalidPayload)`
  - Verify: `build_runner` OK, `flutter analyze` clean
- [x] **Step 2**: GitHub-specific errors + `UpdateService`
  - Files: `lib/data/services/exceptions/update_exception.dart`, `lib/data/services/update_service.dart`
  - Independent `Dio(BaseOptions(baseUrl: 'https://api.github.com', headers: {...}, timeouts like ApiService))`, **no** `AuthInterceptor`, **no** `AppSettingsService` listener
  - `Future<UpdateInfo> fetchLatest()`: `GET /repos/WuMe-sicx/Xuro/releases?per_page=10` → filter `^v?\d+\.\d+\.\d+$` → `compareSemver` max → `UpdateInfo.fromReleaseJson`; empty/invalid → `UpdateException(noRelease)`; `DioException` mapped by status + rate-limit headers (403/429→`rateLimited`, 404→`notFound`, connection/timeout→`network`, else→`unknown`); `AppLogger`, no swallow
  - `static int compareSemver(String a, String b)`: pure, unit-tested
  - owner/repo constants from `Strings.repoUrl`
  - Verify: unit tests for compare, error mapping, parse boundaries
- [x] **Step 3**: DI registration
  - File: `lib/core/di/service_locator.dart` (`registerLazySingleton<UpdateService>` after `ApiService`)
  - Verify: `getIt<UpdateService>()` resolves; app starts
- [x] **Step 4**: `UpdateViewModel` (`lib/presentation/viewmodels/update_viewmodel.dart`)
  - State: `isChecking`, `error`, `UpdateInfo? latest`, `bool hasUpdate`, `String currentVersion`
  - `Future<void> check()` (double-trigger guard + `notifyListeners`; `catch UpdateException` → `error = e.userMessage`, **no `NetworkException` in ViewModel**), `Future<void> openDownload()` (`url_launcher`, platform branch, `context.mounted` on UI side)
  - Verify: mirrors `AuthViewModel`; analyze clean
- [x] **Step 5**: `UpdateDialog` (`lib/presentation/widgets/update/update_dialog.dart`)
  - `AlertDialog` + local `ChangeNotifierProvider`/`Consumer`, four states; root navigator like `LoginDialog`
  - Verify: manual four states (mock high/low version, offline)
- [x] **Step 6**: Settings wiring + strings
  - Files: `lib/screens/settings/settings_screen.dart` (`_aboutSection()` after version tile), `lib/common/constants/strings.dart`
  - Verify: visible, tappable, no hardcoded copy
- [x] **Step 7**: Unit tests (network-free)
  - Files: `test/data/services/update_version_compare_test.dart`, `test/data/services/update_release_parse_test.dart`
  - Verify: `fvm flutter test` on both files passes

## 5. Risks

- **Risk: GitHub API rate limit** — unauthenticated 60/hour/IP, 403 or 429 on exceed. Manual trigger, low risk; map to `rateLimited`, no retry storm.
- **Risk: `prerelease: true` breaks `/releases/latest`** — mitigated: `/releases?per_page=10` filter max semver (not first item).
- **Risk: `tag_name` format / empty releases / missing assets** — regex filter + `noRelease`/`invalidPayload`; Android no `.apk` → Release page; no crash, no swallow.
- **Risk: Wrong error semantics** — mitigated: no `NetworkException` reuse (403→login, connection→VPN wrong for GitHub); dedicated `UpdateException`.
- **Risk: iOS no sideload artifact** — iOS/other open `html_url` only.
- **Rollback**: Self-contained (mostly new files, incremental wiring in `settings_screen.dart`/`strings.dart`/`service_locator.dart`); single `git revert` removes all; no migration or persisted state.

## 6. Notes / Decision Log

- **Why `/releases` not `/releases/latest`**: CI publishes `prerelease: true`; `latest` skips prerelease per GitHub docs.
- **Why Phase 1 browser download not in-app install**: In-app APK install needs Android Intent + `REQUEST_INSTALL_PACKAGES` + FileProvider + Manifest; project conservative on native (Impeller disabled for GPU issues). Browser/system downloader is standard for GitHub APK, zero new permissions. Phase 2 separate TODO.
- **Why `UpdateInfo` Freezed-only**: `lib/data/models/` convention is Freezed; fields derived from GitHub JSON (`version` strip v, `apkDownloadUrl` pick asset), so generated `fromJson` not ideal — Freezed + custom `fromReleaseJson`, no json_serializable.
- **Why `UpdateService` doesn't listen `AppSettingsService`**: asmr node switching unrelated to GitHub host; deliberate decoupling.
- **Why not reuse `NetworkException`**: `userMessage` bound to asmr.one — 403→「请先登录」, connection→「请先连接 VPN 服务」. GitHub not blocked; 403/429 is rate limit. Misleading copy → dedicated `UpdateException`.
- **Why max semver not `[0]` on `/releases`**: List order not guaranteed max; republished old tags can mislead. Filter + `compareSemver` max is safer.
- **Codex review (SESSION_ID `019e2b49-3a33-7303-a401-33b6ff2a8a14`)**:
  - Planning: R1 ❌ (error semantics / empty releases / version pick / headers·factory) → absorbed; R2 ❌ (Step4 still NetworkException / acceptance vs Freezed-only / regex missing `$`) → fixed; R3 ✅ PASS.
  - Implementation: R-impl1 ❌ (`UpdateViewModel` no disposed guard after await, dialog closed mid-check → "used after disposed") → `_disposed` + `dispose()` + `_safeNotify()`; R-impl2 ✅ PASS (ship as-is).
- **`openDownload` uses `dart:io` `Platform.isAndroid`**: consistent with `service_locator.dart` (Android/iOS only).
- **Dialog `_download` captures `Navigator`/`ScaffoldMessenger` before await**: safe after await; Codex confirmed.

---

## ✅ Done

- Completed at: 2026-05-15
- Command run: `/init`
- CLAUDE.md update summary: Added update-check subsystem in `lib/data/`/`lib/presentation/`/API/Tests — `UpdateService` (independent GitHub Dio, no node switch, `/releases?per_page=10` semver max), `UpdateException` (not NetworkException), `UpdateInfo` (Freezed-only custom factory), `UpdateDialog`+`UpdateViewModel` (disposed guard invariant), two new test files.
- Related commit: `f872229` (implementation) + `eda9d7f` (/init CLAUDE.md + archive) + acceptance wrap-up commit
- Note: **All acceptance criteria met** — real-device four-state UI verified by user (2026-05-15); logic layer Codex planning 3 rounds + implementation 2 rounds to ✅ PASS, 21 unit tests pass, analyze clean. Fully closed.
