# Changelog

All user-visible and developer-visible changes in Xuro since v1.1.11. Version numbers follow [SemVer](https://semver.org/) and [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) style.

---

## Unreleased

---

## v2.0.0-rc.10 — 2026-07-06

### Added
- **Metadata translation**: Google Translate (free, no key) or LLM Lite bulk for work list titles, search results, and track names; auto or manual per page.
- **Main vs Lite LLM models**: Main for subtitles, Lite for titles/tracks/tags.
- **LLM provider presets**: OpenRouter, Gemini (AI Studio), OpenAI, and custom OpenAI-compatible endpoints.
- **Model autocomplete** from provider `/models` APIs (OpenRouter, Gemini, OpenAI, custom).
- **OpenRouter balance** tile in LLM settings via `/auth/key`.

### Changed
- **Default OpenRouter models**: Main `google/gemma-4-31b-it:free`, Lite `google/gemma-4-26b-a4b-it:free`.

---

## v2.0.0-rc.9 — 2026-07-06

### Fixed
- **PC playback (all formats)**: desktop now streams presigned URLs directly instead of the byte-stream cache proxy that broke Windows/Linux playback for mp3, m4a, wav, and every other online track.
- **PC subtitle preview**: removed auth header from presigned CDN fetches; plain-text response decoding for `.txt`/`.vtt`/`.lrc`/`.srt`.
- **Linux audio**: register `just_audio_media_kit` backend.
- **Android silent playback**: wait for audio pipeline ready before volume fade-in on resume.

---

## v2.0.0-rc.8 — 2026-07-06

### Added
- **Apple Music twist backdrop**: four-layer GLSL shader on the player background (twist UV rotation, saturation/brightness), animates while playing with reduced-motion fallback.
- **Player gestures**: vertical swipe up/down toggles cover ↔ lyrics on narrow layout.

### Changed
- **Player surface transition**: 12% slide, 0.94→1.0 scale, 450ms crossfade between cover and lyrics.
- **Album art**: crossfade on track change; subtle play/pause breathe scale.
- **Kinetic lyrics**: fixed 22px typography — emphasis via opacity/blur/scale only (no font-size wobble); active line follows scroll center.

---

## v2.0.0-rc.7 — 2026-07-06

### Added
- **Advanced list filters** (Eara-style): horizontal sort chips on Home, Hot, and Search — Latest, New releases, Best sellers, Top price, Top rated, Random, plus a "More filters" sheet.
- **Tag picker**: multi-select tags from `/tags/` API; composes asmr.one `$tag:name$` search syntax on Home, Hot, and Search.
- **Age rating filter**: Any / All ages (`$age:general$`) / R18 (`$age:adult$`) chips; switches to `/search` when tag or age filters are active.

### Changed
- **Docs**: project markdown translated to English; localized logs (`LogStrings`) and `README_zh` / `README_th` / `guidelines_zh` unchanged.
- **Code comments**: `lib/` comments translated from Chinese to English.

### Fixed
- **Player**: Android silent playback regression; Apple Music–style player UI refresh.
- **CI**: reject truncated `KEYSTORE_BASE64` early before decode.

---

### Fixed
- **Android CI signing**: PKCS12 keystores fail GNU `base64 -d` — CI now decodes via `openssl base64 -d -A` and sets `storeType=pkcs12` for Gradle.
- **Signing passwords with special chars**: `key.properties` is written via env vars (safe for `!@` etc.).

---

## v2.0.0-rc.5 — 2026-07-05

### Internal
- Re-trigger release CI after `KEYSTORE_BASE64` and signing secrets were updated in GitHub Actions.

---

## v2.0.0-rc.4 — 2026-07-05

### Fixed
- **CI keystore decode**: strip whitespace from `KEYSTORE_BASE64`, validate JKS magic bytes, and emit actionable errors when the secret is empty or malformed.

### Internal
- CI: `concurrency.cancel-in-progress: false` so Web/iOS/Windows jobs finish even if Android signing fails.
- CI: `workflow_dispatch` platform toggles for manual verification without a tag.

---

### Fixed
- **Web CI compile**: rc.2 `database_bootstrap` imported `dart:ffi` / `dart:io` unconditionally — split into `database_bootstrap_stub.dart` (web) vs `database_bootstrap_io.dart` (mobile/desktop).
- **Web `dart:io`**: migrated file/cache/download/subtitle imports to `universal_io` so `flutter build web` can compile the app graph.
- **Android release**: ProGuard keep rules for `moe.lizu.nemu.**` lyric overlay after package rename.

### Internal
- CI: explicit `flutter gen-l10n` before all platform builds.
- Task doc: [`active/20260705-fix-android-web-ci.md`](docs/todos/active/20260705-fix-android-web-ci.md).

---

## v2.0.0-rc.2 — 2026-07-05

### Fixed
- **Library tab gray-screen crash**: `LibraryTabContent` read `LocalLibraryViewModel` outside `MultiProvider`, causing `ProviderNotFoundException`; AppBar title now reads the Provider from a `Builder` child context.
- **Linux desktop SQLite won't open**: distros like Ubuntu ship only `libsqlite3.so.0` (no `libsqlite3.so` symlink); `database_bootstrap` adds soname fallback via `createDatabaseFactoryFfi` + `open.overrideFor`, fixing local downloads / local library init.
- **Linux window title still Xuro**: `linux/my_application.cc` updated to **Lizunemu**.

### Internal
- Added `test/screens/contents/library_tab_content_test.dart` regression test (185 tests total).
- Task doc: [`done/20260705-fix-broken-app-tabs.md`](docs/todos/done/20260705-fix-broken-app-tabs.md).

---

## v2.0.0-rc.1 — 2026-07-05

First Lizunemu 2.0 RC: Xuro → Lizunemu rename (`moe.lizu.nemu`), Eara milestones A–H, app icon and CI artifact rename. See [`done/20260705-lizunemu-2.0-rebrand.md`](docs/todos/done/20260705-lizunemu-2.0-rebrand.md).

### Added
- **User registration** (`POST /api/auth/reg`): drawer login dialog adds "No account? Register"; new dialog with username / password / confirm password; submit enabled by client-side validation. Auto-login on success; if the server returns no token, falls back to `login`; `RegisteredButNotLoggedInException` for account-created-but-login-failed. Task doc: [`done/20260515-user-registration.md`](docs/todos/done/20260515-user-registration.md).
- **3 accent color variants** (blue / mono / green, default blue): Settings "Appearance" followed by "Accent color" group, persisted to `AppSettingsService.colorVariant`. `AppColors` refactored to `lightSchemeFor(variant)` / `darkSchemeFor(variant)` factories, 6 hand-rolled ColorSchemes without `fromSeed`. Task doc: [`done/20260515-color-palette-simplification.md`](docs/todos/done/20260515-color-palette-simplification.md).
- **Side drawer visual** (dark glassmorphism): dark blue-purple gradient + soft glow + semi-transparent grouped cards + circular profile card. Added "Recently played", "Rankings", "Dark mode", "About" entries. Width follows `ui-design-spec §5` mobile/tablet breakpoints. Task doc: [`done/20260515-sidebar-glassmorphism-redesign.md`](docs/todos/done/20260515-sidebar-glassmorphism-redesign.md).

### Changed
- **`AuthService` node-aware**: was hardcoded `https://api.asmr.one/api`; now injects `AppSettingsService`, listens and syncs Dio baseUrl — login and register follow the user's selected node (main / 100 / 200 / 300).
- **Neutral surface tokens**: `AppColors.lightSurfaceL1/L2` and `darkSurfaceL1/L2` were slightly purple (`#F7F2FA` etc.); now hue-neutral grays to avoid clashing with mono/green accents.
- **Side drawer "two-color" simplification**: 9 menu icon backgrounds unified to neutral gray `_kIconBgGray = #8E8E93`; only accent affordances (avatar / circular arrow / footer dots / gradient glow / card shadow) use `Theme.of(context).colorScheme.primary`, switching with the user's accent.

### Fixed
- **Side drawer first-open 256ms jank**: PerfDog on-device data showed `BackdropFilter(blur 18)` on top of `Stack` — visually a no-op over opaque gradient but first paint triggers Impeller offscreen layer + shader compile. Removed `BackdropFilter`; original 18% black overlay baked into gradient RGB and glow RGB via `0.82` factor (alpha unchanged, mathematically equivalent compositing). Task doc: [`done/20260515-sidebar-first-open-jank.md`](docs/todos/done/20260515-sidebar-first-open-jank.md).
- **Xiaomi HyperOS 3 + Adreno + Vulkan long-session crash** (`ErrorDeviceLost` → `SIGSEGV in libvulkan.so::CmdEndRenderPass+4`): Impeller disabled on Android, Skia renderer (`AndroidManifest.xml` `io.flutter.embedding.android.EnableImpeller=false`). iOS keeps Impeller. Task doc: [`done/20260515-disable-impeller-android.md`](docs/todos/done/20260515-disable-impeller-android.md); SDK upgrade tracking: [`active/20260515-upgrade-flutter-sdk.md`](docs/todos/active/20260515-upgrade-flutter-sdk.md).
- **Login/register dialog stale errors**: added `AuthViewModel.clearError()`; called when switching `LoginDialog` ⇄ `RegisterDialog`.
- **Logout dialog sometimes missing / intermittent crash**: `SidebarHeader` → `StatefulWidget` + `_dialogScheduled` guard; `Navigator.maybePop(drawer)` + `addPostFrameCallback` defers dialog open to next frame, avoiding same-frame pop+push race. Logout button restores `dialogContext.mounted` guard. Task doc: [`done/20260515-auth-flow-bugfix.md`](docs/todos/done/20260515-auth-flow-bugfix.md).
- **Drawer dialogs inherited dark Theme**: login/logout dialogs use `rootNavigator`, decoupled from drawer's local dark Theme.

### Removed
- **Register form "referrer UUID" field**: UI input removed; optional service parameter kept for future deep-link parsing.

### Internal
- **Task doc archive**: 5 new `done/` docs today (registration / auth bugfix / drawer first-open jank / Impeller disable / palette simplification) + 1 `cancelled/` ([`flutter-performance-optimization.md`](docs/todos/cancelled/20260515-flutter-performance-optimization.md) — audit baseline stale, 7/9 P0 fixed, remainder needs profile data) + 1 `active/` placeholder (Flutter SDK upgrade, start after Skia stable for a week).
- **Codex review**: all 6 independent TODOs this session reviewed under SESSION_ID `019e2873-2990-72e2-bc68-ba47328971b7`, all ⚠️/❌ → ✅ PASS.
- **CLAUDE.md anti-pitfall patches**: sidebar Theme override must use `darkSchemeFor(variant)` not brightness-only; no fullscreen `BackdropFilter`; Android Impeller disabled; dual-axis theme ThemeMode × ColorVariant.
- **Static analysis**: `fvm flutter analyze` zero new warnings on changed files (33 pre-existing `withOpacity` deprecations unchanged).

---

## Before v1.1.11

See git log and GitHub Releases ([releases](https://github.com/WuMe-sicx/Xuro/releases)).
