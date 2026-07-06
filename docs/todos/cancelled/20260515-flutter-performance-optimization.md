# Flutter Performance Optimization: Startup, List Scrolling, Player Page Jank

- **Created**: 2026-05-15
- **Owner**: codex
- **Status**: cancelled
- **Related Issue / PR**: N/A (user feedback: app speed and jank)

---

## 1. Goal

Systematically reduce Xuro jank in startup, home/recommend/popular list scrolling, detail open, player and lyrics interaction. Establish profile baselines first, then optimize hot paths in phases with measurable, regression-verifiable improvements.

## 2. Scope

**In scope:**
- Performance baseline and regression records: profile-mode cold start, home first screen, work list scroll, tab switch, detail open, play start, player cover page, lyrics page, background resume, etc.
- List rendering optimization: focus on `lib/widgets/work_grid.dart`, `lib/widgets/work_row.dart`, `lib/widgets/work_card/`, `lib/widgets/work_grid/` — reduce build/layout/raster cost.
- Player refresh optimization: focus on `lib/presentation/viewmodels/player_viewmodel.dart`, `lib/widgets/mini_player/`, `lib/widgets/player/`, `lib/widgets/lyrics/` — split high-frequency progress refresh from low-frequency metadata refresh.
- Startup path optimization: focus on `lib/main.dart`, `lib/core/di/service_locator.dart`, cache cleanup, floating lyrics init, playback state restore — first-frame vs post-first-frame task boundaries.
- Detail page and file tree optimization: focus on `lib/screens/detail_screen.dart`, `lib/presentation/viewmodels/detail_viewmodel.dart`, `lib/widgets/detail/work_files_list.dart`, `lib/widgets/detail/work_folder_item.dart`.
- Audio time-to-first-sound and playlist prep: focus on `lib/core/audio/controllers/playback_controller.dart`, `lib/core/audio/utils/playlist_builder.dart`, `lib/core/audio/cache/audio_cache_manager.dart`.
- Image cache and decode strategy: focus on `lib/core/image/cache/image_cache_manager.dart` and `CachedNetworkImage` usage — reduce decode/memory pressure during list scroll.
- Logging strategy: evaluate `lib/utils/logger.dart` and high-frequency debug logs — avoid profile/release log overhead.

**Out of scope:**
- Full UI redesign or visual reskin.
- Replace Provider/GetIt state management.
- Rewrite audio architecture; only notification granularity, playlist prep, cache policy within existing event-driven architecture.
- Upgrade Flutter, Dart, Gradle, CocoaPods, or third-party deps unless proven root cause in a separate TODO.
- Change ASMR.ONE API protocol or request semantics.
- Change data model fields; if `lib/data/models/` Freezed/json_serializable must change, add steps here and run build_runner.

## 3. Acceptance

- [ ] Android device profile baseline recorded in Notes or separate perf doc: device, Flutter version, steps, metrics, screenshot/log refs.
- [ ] Cold start to home first interactive frame measurably improved, or first-frame tasks classified necessary vs deferred with non-critical work moved post-first-frame.
- [ ] Home/recommend/popular list continuous scroll: jank frame count down vs baseline; UI/Raster frame p95 must not regress.
- [ ] Mini player on home during playback: progress ticks no longer rebuild cover/title/buttons each tick.
- [ ] Player seek drag does not fire continuous seeks; release seeks accurately; play/pause/prev/next unchanged.
- [ ] Lyrics auto-scroll, manual scroll, tap-to-seek work; sync without obvious jitter or dropped frames.
- [ ] Large file-tree detail pages open without long main-thread blocks; load/play/back flows unchanged.
- [ ] Multi-file work play start time not worse; queue prep covers current/prev/next/order/restore if optimized.
- [ ] Image/audio/subtitle cache cleanup does not delete in-use files; cache manager UI unchanged.
- [ ] `fvm flutter analyze` passes; existing withOpacity deprecation warnings OK; no new warnings from this task.
- [ ] `fvm flutter test` passes; any new/adjusted tests pass.
- [ ] On completion: fill Done block, run `/init`, move file to `docs/todos/done/`.

## 4. Steps

- [ ] **Phase 0: Performance baseline and triage**
  - Files: `docs/todos/active/20260515-flutter-performance-optimization.md`, optionally new `docs/performance/` doc.
  - Work: profile cold start, list scroll, tab switch, detail, play start, player cover, lyrics, background resume; tag UI thread, raster, image decode, network, logs, file IO bottlenecks.
  - Verify: device, OS, Flutter SDK, build commands, repro steps, baseline metrics, comparison method.

- [ ] **Phase 1: Player high-frequency refresh noise reduction**
  - Files: `lib/presentation/viewmodels/player_viewmodel.dart`, `lib/widgets/mini_player/mini_player.dart`, `lib/widgets/mini_player/mini_player_progress.dart`, `lib/widgets/mini_player/mini_player_controls.dart`, `lib/widgets/player/player_progress.dart`, `lib/widgets/player/player_controls.dart`, `lib/screens/player_screen.dart`.
  - Work: split progress, play state, track metadata, subtitle UI subscriptions; prevent progress tick rebuilding cover/title/buttons; seek bar local preview + seek on release.
  - Verify: profile shows smaller rebuild scope on home/player; no seek storm on drag; controls unchanged.

- [ ] **Phase 2: Work list rendering optimization**
  - Files: `lib/widgets/work_grid.dart`, `lib/widgets/work_row.dart`, `lib/widgets/work_grid_view.dart`, `lib/widgets/work_grid/enhanced_work_grid_view.dart`, `lib/widgets/work_grid/components/grid_content.dart`, `lib/widgets/work_card/`, `lib/presentation/layouts/work_layout_strategy.dart`.
  - Work: evaluate/replace manual row grouping `SliverList + Row` with true lazy grid; cap tag count and dynamic height in cards; cache repeated build computations.
  - Verify: home/recommend/popular scroll metrics improve vs baseline; 2/3/4 column layouts correct; tap detail, refresh, pagination, filter panel unchanged.

- [ ] **Phase 3: Startup path and deferred background tasks**
  - Files: `lib/main.dart`, `lib/core/di/service_locator.dart`, `lib/core/cache/cache_lifecycle_manager.dart`, `lib/core/audio/audio_player_service.dart`, `lib/core/audio/storage/playback_state_repository.dart`, `lib/core/platform/lyric_overlay_manager.dart`.
  - Work: classify must-await-before-first-frame vs deferrable; evaluate floating lyrics init, cache cleanup, legacy migration, playback restore post-first-frame or idle; avoid cache cleanup IO fighting first paint.
  - Verify: cold start first interactive time same or better; login, theme, playback restore, floating lyrics permission unchanged.

- [ ] **Phase 4: Detail page and file tree lazy build**
  - Files: `lib/screens/detail_screen.dart`, `lib/presentation/viewmodels/detail_viewmodel.dart`, `lib/widgets/detail/work_files_list.dart`, `lib/widgets/detail/work_folder_item.dart`, `lib/widgets/detail/work_file_item.dart`, `lib/core/audio/models/file_path.dart`.
  - Work: avoid mapping entire large file tree to widgets at once; build children on folder expand; move/cache smart path search out of hot build path; predictable default expand.
  - Verify: large file-count detail open/scroll smooth; first audio folder still expands by default; tap audio play unchanged.

- [ ] **Phase 5: Play time-to-first-sound and queue prep**
  - Files: `lib/core/audio/controllers/playback_controller.dart`, `lib/core/audio/utils/playlist_builder.dart`, `lib/core/audio/cache/audio_cache_manager.dart`, `lib/core/audio/models/playback_context.dart`, `lib/core/audio/state/playback_state_manager.dart`.
  - Work: evaluate cost of creating AudioSource for full same-dir playlist; prioritize current track first sound, defer non-current if needed; preserve prev/next/restore semantics.
  - Verify: time-to-first-sound not worse; multi-file skip, completion, restore, cache hit/miss paths OK.

- [ ] **Phase 6: Image and cache policy refinement**
  - Files: `lib/core/image/cache/image_cache_manager.dart`, `lib/widgets/work_card/components/work_cover_image.dart`, `lib/widgets/detail/work_cover.dart`, `lib/widgets/player/player_cover.dart`, `lib/widgets/mini_player/mini_player_cover.dart`, `lib/core/cache/cache_coordinator.dart`.
  - Work: evaluate fixed decode sizes for list thumbnails; confirm object count, expiry, memory pressure; schedule cleanup away from first frame and playback.
  - Verify: list scroll decode jitter reduced; Hero cover, detail large cover, mini player cover OK; cache manager unchanged.

- [ ] **Phase 7: Logging and verification wrap-up**
  - Files: `lib/utils/logger.dart` and high-frequency files touched.
  - Work: reduce profile/release debug log cost; add unit/widget tests or manual records; run analyze/test; document before/after metrics.
  - Verify: `fvm flutter analyze`, `fvm flutter test` pass; perf record has before/after; all acceptance criteria met.

## 5. Risks

- **Risk**: List layout replacement may affect tablet/desktop columns, card height, hit targets, Hero animation.
- **Rollback**: Independent list rendering commits; revert to old `WorkGrid` path on layout regression.
- **Risk**: Player refresh split may miss updates (play/pause, title, subtitle import state).
- **Rollback**: Clear state boundaries and manual test matrix; revert subscription split and redo smaller grain.
- **Risk**: Deferred startup tasks may shift playback restore, floating lyrics, cache cleanup timing.
- **Rollback**: Post-first-frame migrations individually revertible; correctness over timing.
- **Risk**: Deferred audio queue prep may delay prev/next availability.
- **Rollback**: If `just_audio` dynamic queue prep costly/unreliable, keep full queue prep, optimize cache check and logs only.
- **Risk**: Performance work scope creep into architecture rewrite.
- **Rollback**: Each phase separate commit and verify; no profile-unsupported refactors.

## 6. Notes / Decision Log

- Initial static analysis top hotspots: manual row list rendering, player high-frequency `notifyListeners()` wide rebuilds, non-critical startup tasks competing with first frame, detail file tree built all at once.
- Performance judgments must use profile data; debug jank is clues only, not acceptance basis.
- Recommended order: baseline → player refresh and seek → list grid → startup → detail file tree → play start and cache.

---

## ⛔ Cancelled

- Cancelled: 2026-05-15
- Reason: This TODO was drafted by codex from **stale `ui-design-spec.md §7.1` audit**. Same-day static re-check showed **7 of 9 P0/P1 hotspots already fixed** in prior commits (PlayerViewModel 60Hz throttle, PlaybackEventHub `==`/`hashCode`, SubtitleList binary search, Shimmer removal, WorkRow no IntrinsicHeight, WorkFilesList side effects out of build, PlayerLyricView side effects out of build), **1 fixed by another TODO this session** (sidebar BackdropFilter jank, see below), remaining 1-2 either too small for a 7-phase task or need profile data to confirm real issues. Continuing this 7-phase push = blind edits to fixed code; regression risk > benefit.
- Superseded related work:
  - [`done/20260515-sidebar-first-open-jank.md`](../done/20260515-sidebar-first-open-jank.md) — PerfDog real-device data found 256ms sidebar first-open jank; fixed by removing redundant `BackdropFilter`, equivalent to one vertical slice of this TODO Phase 0+2.
  - [`done/20260515-disable-impeller-android.md`](../done/20260515-disable-impeller-android.md) — Adreno + Vulkan + Impeller long-session `ErrorDeviceLost` crash; outside original TODO scope but part of perf/stability goals.
  - [`done/20260515-color-palette-simplification.md`](../done/20260515-color-palette-simplification.md) — Neutralized surface tokens, removed hardcoded color sets, indirectly reduced first-frame draw cost.
- Follow-up: For future perf issues, use **real-device profile + Flutter DevTools Timeline flame graph** to pinpoint widget/method, then open a **separate TODO** (granularity like this session's three vertical slices), not another 7-phase big-bang optimization.
- **No `/init`** — cancellation is TODO archive only; no code/architecture change.
