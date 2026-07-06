# Fix floating lyric service background-start crash (BackgroundServiceStartNotAllowedException)

- **Created**: 2026-05-15
- **Owner**: WuMe-sicx
- **Status**: active
- **Related Issue / PR**: none (startup log error)

---

## 1. Goal

Fix cold-start `LyricOverlayService` crash on Android 12+ background-start restrictions (`BackgroundServiceStartNotAllowedException`), which caused floating lyric bind failure and silent feature loss.

## 2. Scope

**In scope:**
- `android/.../lyric/LyricOverlayPlugin.kt`: remove redundant `context.startService(serviceIntent)` from `initialize`, and paired `context.stopService(serviceIntent)` from `dispose`; keep only `bindService(BIND_AUTO_CREATE)`.
- Codex review follow-ups (direct consequences of bind-only lifecycle, same file, each complete):
  - Add `isBound` flag for `bindService` return value; `dispose` calls `unbindService` only when `isBound`, avoiding `IllegalArgumentException` on failed bind / double dispose.
  - `MainActivity`: `LyricOverlayPlugin(this)` → `LyricOverlayPlugin(applicationContext)` so overlay service lifecycle decouples from Activity rebuild.

**Out of scope:**
- No Dart init timing changes (`service_locator` / `LyricOverlayManager`).
- **Cold-start state restore (`KEY_SHOWING`) not in this fix**: Codex noted `bindService` is async; after `initialize` returns, Dart immediately calls `isShowing()`/`show()` while `service` is still `null`. Prefs-only fallback for `isShowing` cannot make subsequent `show()` work (service not connected → no-op) — half solution. Correct approach needs plugin "replay pending actions after connect" or `initialize` waiting for `onServiceConnected` — separate task. Note: restore was already broken before this fix (old code threw on `startService`, `bindService` never ran); this fix is not a regression. Follow-up: `docs/todos/active/20260515-lyric-overlay-startup-restore.md`.
- Do not convert service to foreground service (overlay does not need it; over-engineering).

## 3. Acceptance

- [ ] Cold-start logs no longer show `SERVICE_START_ERROR` / `BackgroundServiceStartNotAllowedException`.
- [ ] Enter player, long-press lyrics icon: floating lyrics show/drag (bind succeeds).
- [ ] Last shown state (`KEY_SHOWING`) still restores after restart.
- [ ] `flutter analyze` passes with no new warnings (Kotlin-only change).
- [ ] Codex review PASS.

## 4. Steps

- [ ] **Step 1**: Remove `context.startService(serviceIntent)` from `LyricOverlayPlugin.onMethodCall` `"initialize"` branch; keep `bindService(... BIND_AUTO_CREATE)`.
  - Files: `android/app/src/main/kotlin/com/xuro/lyric/LyricOverlayPlugin.kt`
  - Verify: no background-start exception on cold start.
- [ ] **Step 2**: Remove paired `context.stopService(serviceIntent)` from `"dispose"` branch (cleanup orphan call after this change; bind-only service destroyed via `unbindService`).
  - Verify: overlay dismiss releases service, no leak.
- [ ] **Step 3**: Codex review diff.
  - Verify: PASS.

## 5. Risks

- **Risk**: On some devices `bindService(BIND_AUTO_CREATE)` from background may delay service creation; binding own service is not subject to Android 12 background-start ban — low risk.
- **Rollback**: `git revert` commit restores `startService`/`stopService`.

## 6. Notes

> `LyricOverlayService` is bind-only (no `startForeground`/notification, only `WindowManager` overlay). `startService()` is the only call subject to Android 12 background-start limits and is fully redundant. `bindService(BIND_AUTO_CREATE)` lazily creates, lives with binding, dies on `unbindService` — equivalent behavior without losing state-restore capability.
