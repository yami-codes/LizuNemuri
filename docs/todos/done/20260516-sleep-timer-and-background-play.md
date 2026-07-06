# Sleep Timer + Background Play Toggle (Real Features, Not Placeholders)

- **Created**: 2026-05-16
- **Owner**: WuMe-sicx
- **Status**: done
- **Related Issue / PR**: User explicitly requested after `docs/todos/active/20260516-five-screen-layout-token-polish.md`: "add sleep timer and background play toggle in settings" — previously audited as "no backend in reference mock", now user explicitly wants **real implementation** (not invented placeholders), per [[feedback-reference-reskin-discipline]] (user explicit request = implement, must be actually usable).

## 1. Goal

> Add two **real, usable** features to Settings → Playback: ① Sleep timer — auto-pause playback after selected duration; ② Background play toggle — when off, app pauses when backgrounded (default on = preserve existing "always background play" behavior). Both reuse existing `WakeLockController` / `CacheLifecycleManager` patterns without inventing behavior or breaking audio subsystem invariants.

## 2. Scope

**In scope:**
- New `lib/core/platform/sleep_timer_controller.dart`: `ChangeNotifier`, holds `Timer` + selected minutes; on expiry call `IAudioPlayerService.pause()`; `setMinutes(null|0)` cancels; `dispose()` cancels Timer.
- New `lib/screens/settings/sleep_timer_dialog.dart`: single-select duration dialog (Off/15/30/45/60/90 min), mirrors `AudioFormatOrderDialog` structure.
- New `lib/core/platform/background_play_controller.dart`: `WidgetsBindingObserver`, `AppLifecycleState.paused` && `!backgroundPlayEnabled` && playing → `pause()`; idempotent `initialize()` (mirrors `CacheLifecycleManager`).
- `app_settings_service.dart`: persist `backgroundPlayEnabled` (default `true`, mirrors existing setter pattern).
- `service_locator.dart`: register both controllers (SleepTimer depends on `IAudioPlayerService`; BackgroundPlay depends on `AppSettingsService` + `IAudioPlayerService`).
- `main.dart`: `BackgroundPlayController().initialize()` (right after `CacheLifecycleManager().initialize()`).
- `settings_screen.dart` `_playbackSection`: + sleep timer `SettingsTile.navigation` (value=current selection, onTap opens dialog); + background play `SettingsTile.toggle`.
- `strings.dart`: new copy constants (sleep timer / off / N minutes function / background play / description).
- Unit test `test/core/platform/sleep_timer_controller_test.dart` (pure state logic, network/timing-free).

**Out of scope (strict boundary):**
- Sleep timer **not persisted** (session-only; silent re-arm on launch = bad UX, avoids `playback_state` persistence invariants).
- Expiry action uses **`pause()` not `stop()`**: `stop()` clears `last_playback_state` (CLAUDE.md invariant); sleep scenario should be resumable; `pause()` is standard podcast/music sleep behavior.
- When background play off: **pause only, no auto-resume** on foreground return — minimal, predictable.
- No refactor of `audio_service` / `AudioPlayerHandler` / foreground service; no lock-screen notification or playback persistence chain changes.
- Do not invent other reference-mock items without backend (volume/effects/EQ/language etc. still out of scope).

## 3. Acceptance

- [ ] Settings → Playback: sleep timer row shows current selection (Off / X min), dialog on tap; after selection, playback auto-pauses at expiry, manually resumable.
- [ ] Selecting "Off" or re-selecting another duration correctly cancels/resets old Timer (no double-Timer leak).
- [ ] Background play toggle default **ON** (upgraded user behavior unchanged); when off, backgrounding auto-pauses, foreground does not auto-resume; when on, background play continues (current behavior).
- [ ] `backgroundPlayEnabled` persisted (survives restart); sleep timer not persisted (restart = off).
- [ ] `flutter analyze` no new warnings; **full `flutter test` zero regression** + new SleepTimer unit tests pass.
- [ ] Codex review ✅ PASS (Coder not enabled, Claude edited directly).
- [ ] User device verification of both features → `/init` wrap-up.

## 4. Steps

- [x] **Step 1** This TODO doc ✅ 2026-05-16.
- [x] **Step 2** ✅ 2026-05-16: `sleep_timer_controller.dart` (ChangeNotifier, Timer→`pause()`, not persisted) + `sleep_timer_dialog.dart` (Off/15/30/45/60/90 single-select) + `service_locator` registration + `settings_screen._playbackSection` navigation row.
- [x] **Step 3** ✅ 2026-05-16: `AppSettingsService.backgroundPlayEnabled` (persisted default true) + `background_play_controller.dart` (`WidgetsBindingObserver`, `paused` & `!enabled` → `pause()`, no auto-resume, idempotent initialize) + `service_locator` registration + `main.dart` initialize + `settings_screen` toggle row.
- [x] **Step 4** ✅ 2026-05-16: `strings.dart` +5 strings (sleepTimer/Off/Minutes(n)/backgroundPlay/Desc).
- [x] **Step 5** ✅ 2026-05-16: `test/core/platform/sleep_timer_controller_test.dart` 8 cases (fakeAsync); `pubspec` explicit `fake_async ^1.3.1` (eliminates depend_on_referenced_packages info); `flutter analyze` 7 files No issues; full `flutter test` **103/103 zero regression**.
- [x] **Step 6** ✅ 2026-05-16: Codex review (SESSION_ID `019e2dfd-621a-7652-a5a0-eb75b483bbd8`) → **✅ PASS** (Timer lifecycle / background pause gating / DI timing / Listenable.merge / persistence boundary / no fiction all verified).
- [x] **Step 7** ✅ 2026-05-16: user confirmed, agreed to formal wrap-up → completion block + `/init` + move to done.

## 5. Risks

- **Risk**: Sleep Timer not cancelled correctly in `setMinutes` / `dispose` → double Timer / post-dispose callback.
  - **Mitigation**: `_timer?.cancel()` before every `setMinutes`; cancel in `dispose()`; unit tests cover cancel/reset.
- **Risk**: Background pause false positive — `paused` may fire on brief overlays on some devices.
  - **Mitigation**: `pause()` only when `!backgroundPlayEnabled` and currently playing; default on = zero behavior change; no auto-resume avoids overriding user intent.
- **Risk**: touching audio subsystem invariants.
  - **Mitigation**: only call existing `IAudioPlayerService.pause()` (public API); no handler/notification/persistence changes; sleep not persisted avoids `playback_state` invariant.
- **Rollback**: new files independent; `settings_screen` / `app_settings` / `service_locator` / `main` changes small and focused, revert per file.

## 6. Notes / Decision Log

- 2026-05-16: user explicitly requested sleep timer and background play toggle. Design "reasonable defaults": duration options Off/15/30/45/60/90; expiry `pause()` not `stop()`; sleep not persisted, background toggle persisted default ON; background pause only no auto-resume. Continuation: Coder not enabled, Claude direct edit + Codex review ([[feedback-codex-review-loop]]); player/settings minimal ([[feedback-player-ui-minimal]]) — reuse existing tile factories, no clutter.

---

## ✅ Done

- Completed at: 2026-05-16 17:40
- Command run: `/init`
- CLAUDE.md update summary: added `SleepTimerController` (session-only, expiry `pause()`, not persisted) + `BackgroundPlayController` (lifecycle observer, `paused` & `!enabled` pauses, no auto-resume); `AppSettingsService.backgroundPlayEnabled` persisted default true; Settings Playback section wires both controls + player AppBar sleep timer shortcut.
- Related commit: not committed (user did not request commit; pending user decision)

---

## ⛔ Cancelled

> Fill only for cancelled tasks (mutually exclusive with Done above). **Do not run `/init`**. Move file to `docs/todos/cancelled/`.

- Cancelled at: YYYY-MM-DD HH:mm
- Reason: <...>
- Follow-up: <...>
