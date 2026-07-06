# Startup & Loading Performance — Faster Cold Start + Smoother Image/List Loading

- **Created**: 2026-05-16
- **Owner**: WuMe-sicx
- **Status**: active <!-- active | done | cancelled -->
- **Related Issue / PR**: PR #4 (code optimizations merged with branch)
- **2026-05-16 progress note (Codex pre-merge MEDIUM resolution)**: Startup critical-path **code changes merged with PR #4**; acceptance item "device Profile/Release cold-start first frame + list scroll before/after measurements" **not yet collected** — deliberately **no fabricated numbers**. Task **stays active** as explicit follow-up (device measurement only); close per workflow when real-device metrics meet bar.

---

## 1. Goal

> Shorten cold start to first interactive frame, make list/image loading *feel* fast: trim synchronous path before `runApp`, optimize cover request/decode/cache strategy and lazy loading, improve loading feedback, avoid white screen and startup jank.

## 2. Scope

**In scope:**
- Audit and minimize sync init `await`ed before `runApp`: move non-first-frame init (`LyricOverlayManager.initialize()` etc.) post-first-frame; before first frame only what `MaterialApp` truly needs (`SharedPreferences` + auth gate).
- Lightweight first screen (branded/skeleton) for instant paint, eliminate cold-start white flash; skeleton/error states for `MainScreen` tab async content (reuse `SkeletonPulse` / `GridError`).
- Image perf: set `memCacheWidth` / `maxWidthDiskCache` on four cover components to display box size (downsample decode); modest `fadeInDuration`; calibrate `PaintingBinding.imageCache` budget and `ImageCacheManager` if needed.
- Lazy-load audit: confirm all paginated lists/grids use builder delegates (`work_grid.dart` already `SliverChildBuilderDelegate`); check pagination prefetch threshold.
- Assert cache cleanup scan does not block first frame (`CacheLifecycleManager` already `addPostFrameCallback` + 6h throttle — verify/guard only).

**Out of scope:**
- Audio/subtitle download, offline playback (see `20260516-local-media-download-and-video.md`).
- Video format compatibility (same, local media TODO).
- Replace image cache backend or image library.
- Server / API response structure changes.

## 3. Acceptance

- [ ] Cold start to first interactive frame measurably improved: startup instrumentation (`main()` start → first-frame `addPostFrameCallback` timestamp) before/after on real device, recorded in Notes. **(Code ready: `main.dart` `[startup]` debugPrint; before/after values pending real device; AI has no device access)**
- [ ] First frame shows branded screen or skeleton — no blank flash; startup no >16ms drops attributable to file scan (cleanup deferred). **(Confirmed: native `LaunchTheme`→Flutter first frame `Scaffold`+`AppBar`, grid uses `GridLoading`/`SkeletonPulse`; visual no-flash pending device recording)**
- [ ] Smooth list scroll: covers decoded at ≤ display resolution (DevTools memory: image cache down vs baseline), not blurry at display size. **(Code ready: 4 cover components `memCacheWidth`; DevTools comparison pending device)**
- [x] Every async list/grid/cover has skeleton/placeholder on load; errors actionable (reuse `GridError`). — Already satisfied (`EnhancedWorkGridView`→`GridLoading`/`GridError`, cover `SkeletonPulse`).
- [x] `flutter analyze` passes, no new warnings. — Changed files analyze clean; `withOpacity` info on `work_cover.dart`/`player_cover.dart`/`work_cover_image.dart` pre-existing, not introduced here.
- [x] Related unit/widget tests pass. — 31 pass; only failure `test/widget_test.dart` (`flutter create` counter boilerplate) also fails on clean HEAD (`+0 -1`), not regression.

## 4. Steps

- [x] **Step 1**: Startup instrumentation (`kDebugMode`-guarded `[startup]` debugPrint: `main()` → first frame ms, zero release overhead).
  - Files: `lib/main.dart` (`Stopwatch` + `addPostFrameCallback` + `kDebugMode`, new `import 'package:flutter/foundation.dart'`)
  - Verify: `flutter analyze` clean; device console prints `[startup] main() → first frame: N ms` (value pending user device).
- [x] **Step 2**: Split `setupSubtitleServices()` — registration only (sync `void`); new `initDeferredStartupServices()` for `LyricOverlayManager.initialize()`; `main.dart` post-`runApp` `addPostFrameCallback` runs that init + `CacheLifecycleManager().initialize()` + `AudioCacheManager.cleanLegacyCache()`. `prefs` + `AuthViewModel.loadSavedAuth()` **stay** on critical path (MainScreen VMs fire token requests on construct; deferring causes false login errors). DI order (`AppSettingsService` before `setupSubtitleServices`) unchanged.
  - Files: `lib/main.dart`, `lib/core/di/service_locator.dart`
  - Verify: `flutter analyze` clean; deferred init within 1 frame after start; floating lyrics still work (restore delayed ≤1 frame, noted in Risks).
- [x] **Step 3**: Decision — **no** redundant Flutter splash. Native `LaunchTheme`/`NormalTheme` already cover process launch window; Flutter first frame is `MainScreen` `Scaffold`+`AppBar` (not blank); tabs use `EnhancedWorkGridView`→`GridLoading`/`SkeletonPulse`. Extra Flutter splash over-engineering per guidelines — no change.
  - Files: none (decision record)
  - Verify: code path confirms non-blank first frame + skeleton wired (visual confirm pending device recording).
- [x] **Step 4**: Four cover components add `memCacheWidth` (`LayoutBuilder`/known size × `MediaQuery.devicePixelRatio` rounded) + `fadeInDuration: 150ms`. **Only** `memCacheWidth`, **not** `maxWidthDiskCache` — disk cache shared app-wide; downsampling disk file would blur large consumers reusing same cover URL (e.g. `PlayerCover`) (decision in Notes).
  - Files: `lib/widgets/work_card/components/work_cover_image.dart`, `lib/widgets/detail/work_cover.dart`, `lib/widgets/player/player_cover.dart`, `lib/widgets/mini_player/mini_player_cover.dart`
  - Verify: `flutter analyze` clean; DevTools image cache memory down pending device.
- [x] **Step 5**: `main.dart` set `PaintingBinding.instance.imageCache.maximumSizeBytes = 100<<20`. `ImageCacheManager` config (`stalePeriod 30d` / `maxNrOfCacheObjects 500`) verified reasonable, unchanged.
  - File: `lib/main.dart`
  - Verify: `flutter analyze` clean.
- [x] **Step 6**: Audit — `GridContent`→`WorkGrid` uses `SliverList`+`SliverChildBuilderDelegate(childCount:)`, **fully lazy**; pagination explicit page numbers (`PaginationControls`) not infinite scroll, no prefetch threshold to tune; infinite scroll would be feature change, out of scope. **No change needed**.
  - Files: audit `lib/widgets/work_grid.dart`, `lib/widgets/work_grid/components/grid_content.dart`, `enhanced_work_grid_view.dart`
  - Verify: read confirms lazy delegate in place.
- [ ] **Step 7**: Re-test startup + scroll, record before/after in Notes. Instrumentation `kDebugMode`-guarded (zero release overhead, no removal needed). **Pending user real-device measurement** — AI has no device/DevTools access; code and collection mechanism ready.
  - Verify: Notes contain before/after values (TBD).

## 5. Risks

- **Risk**: Deferred `LyricOverlayManager.initialize()` may delay first floating-lyrics availability — mitigate: init immediately after first frame (not lazy on first use), keep `AppSettingsService` registration order.
- **Risk**: `memCacheWidth` too small blurs covers on high DPI — use `devicePixelRatio × layout width`.
- **Rollback**: Each step independently revertible; additive changes, one commit per step, no feature flag.

## 6. Notes / Decision Log

> - Verified current state (file:line): `main.dart:14-26` sync `await setupServiceLocator()`; `service_locator.dart` `SharedPreferences`(38)/`AuthViewModel.loadSavedAuth()`(121)/`LyricOverlayManager.initialize()`(158) all awaited before first frame; `CacheLifecycleManager` already `addPostFrameCallback`+6h throttle (low risk, verify only); images use `CachedNetworkImage`+`SkeletonPulse`, **no fade-in, no downsample**; `work_grid.dart` already `SliverChildBuilderDelegate` (lazy OK).
> - **Decision (Step 3)**: No Flutter splash — native LaunchTheme + first-frame Scaffold + existing grid skeleton covers non-blank first frame + loading feedback; extra layer over-engineering.
> - **Decision (Step 4)**: `memCacheWidth` only, not `maxWidthDiskCache`. `ImageCacheManager.instance` disk cache shared; grid shrinking disk files would blur `PlayerCover` (large) reading same URL from disk. `memCacheWidth` affects per-widget memory decode only, correct fix.
> - **Decision (Step 2)**: `loadSavedAuth()` not deferred — MainScreen 4 VMs fire token requests on construct; deferring causes first requests without token, false login errors (conflicts CLAUDE.md error-prompt UX). Deferred only: floating lyrics init + cache lifecycle/legacy migration.
> - **Device dependency**: Startup ms, DevTools image cache memory, scroll timeline before/after need real device + DevTools; AI has no access; `[startup]` debugPrint and downsample code ready, pending user backfill below.
> - Startup before/after values: <pending user device backfill>
> - Scroll timeline / image cache memory before/after: <pending user device backfill>
>
> **Codex review (SESSION_ID `019e2c83-d6d9-7583-928e-2f3a589037e5`)**:
> - Round 1 ⚠️ OPTIMIZE, 3 lows → fixed:
>   1. `CacheLifecycleManager().initialize()`/`cleanLegacyCache()` moved out of outer post-frame, called directly after `runApp()` (internal post-frame+6h throttle; outer wrapper delayed cleanup further and `addPostFrameCallback` doesn't request next frame).
>   2. Four cover `memCacheWidth` add `isFinite && >0` guard + `<1?1` fallback else `null` (avoid `double.infinity.round()` `UnsupportedError`).
>   3. `Stopwatch` gated by `kDebugMode` ternary, true zero allocation in release.
> - Round 2 (re-review, same SESSION_ID) ✅ PASS — ship as-is.
> - Changelog: `lib/main.dart`, `lib/core/di/service_locator.dart`, `lib/widgets/{work_card/components/work_cover_image,detail/work_cover,player/player_cover,mini_player/mini_player_cover}.dart`; `flutter analyze` only pre-existing `withOpacity` info; tests 31 pass, `widget_test.dart` boilerplate fail pre-existing non-regression.

---

## ✅ Done

> After all steps checked, fill this block, run `/init` to refresh root `CLAUDE.md`, then move to `docs/todos/done/`.

- Completed: YYYY-MM-DD HH:mm
- Command: `/init`
- CLAUDE.md summary: <one or two sentences>
- Related commit: <commit hash>

---

## ⛔ Cancelled (cancelled tasks only; mutually exclusive with Done above)

- Cancelled: YYYY-MM-DD HH:mm
- Reason: <...>
- Follow-up: <...>
