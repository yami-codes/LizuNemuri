# Fix: In-App Player Cannot Pause (`_isToggling` Stuck by Long `play()` Future)

- **Created**: 2026-05-15
- **Owner**: WuMe-sicx
- **Status**: done <!-- active | done | cancelled -->
- **Related Issue / PR**: User verbal feedback; Codex SESSION_ID `019e2be0-4cce-7f82-aa9f-e8d2b2e9f783` confirmed not introduced this cycle

---

## 1. Goal

Fix existing bug: after resuming via in-app player play button, pause button does nothing. Root cause: `PlayerViewModel.playPause()` `await _audioService.resume()`, and just_audio `play()` Future **completes only on pause/stop/completion** (just_audio 0.9.42 docs), leaving `_isToggling` permanently `true`; subsequent pause clicks hit `if (_isToggling) return;`.

## 2. Scope

**In scope:**
- Only `lib/presentation/viewmodels/player_viewmodel.dart` `playPause()`: resume path must not `await` the never-completing `play()` Future.

**Out of scope:**
- No changes to `PlaybackController.play()` / `AudioPlayerService.resume()` / `playWithContext` (their `await resume()` long-hang is pre-existing; callers don't lock UI — separate task if needed).
- No changes to pause path (`pause()` Future completes promptly).

## 3. Acceptance

- [x] Device: play → pause → resume via in-app button → pause again works (repeatable). (Code fix done; **pending user device tap test**)
- [x] MiniPlayer and PlayerScreen both work (shared `playPause`). (Same code path)
- [x] `flutter analyze` passes, no new warnings (file: No issues found).
- [x] No data models; no build_runner.

## 4. Steps

- [x] **Step 1**: Resume branch in `playPause()` changed from `await _audioService.resume()` to `unawaited(_audioService.resume().catchError(...→ emit PlaybackErrorEvent('resume', e, st)))` with WHY comment.
  - File: `lib/presentation/viewmodels/player_viewmodel.dart`
  - Verify: analyze; `_isToggling` released in finally; errors via existing `_eventHub.errors` subscription.
- [x] **Step 2**: `flutter analyze lib/presentation/viewmodels/player_viewmodel.dart` → No issues found.
- [x] **Step 3**: Codex review (SESSION_ID `019e2be0-4cce-7f82-aa9f-e8d2b2e9f783`): round 1 ❌ CHANGE (fire-and-forget missing error handling) → fixed → ✅ PASS.
- [x] **Wrap-up**: Done block filled; no structural change, **no /init** (CLAUDE.md does not describe `playPause` internals); moved to done/.

## 5. Risks

- **Risk (corrected)**: Codex noted `resume()`→`PlaybackController.play()=>_player.play()` has **no** internal error wrapping (unlike `next/previous/setPlaybackContext`). Fire-and-forget must `catchError` and `emit(PlaybackErrorEvent('resume', e, st))` via existing `_eventHub.errors` (`_errorMessage` + `AppLogger.error`). Implemented.
- **Secondary**: Rapid double-tap window (resume sent, `_isPlaying` not yet true) may send second resume not pause; just_audio `play()` sets `playing=true` early so mostly idempotent — acceptable vs permanent lock.
- **Rollback**: Single-line revert.

## 6. Notes / Decision Log

- Local fire-and-forget in `playPause()` vs changing `PlaybackController.play()`: minimal blast radius; don't touch `playWithContext` semantics. Evidence: just_audio-0.9.42 `just_audio.dart` lines 918-920 docs + line 971 `await playCompleter.future`.

---

## ✅ Done

- Completed at: 2026-05-15
- Command run: None (pure behavior fix; no structural change; CLAUDE.md does not describe `playPause` internals)
- CLAUDE.md update summary: No change
- Related commit: (pending user commit; not auto-committed)
- Codex: SESSION_ID `019e2be0-4cce-7f82-aa9f-e8d2b2e9f783`, final ✅ PASS
- Remaining: Device tap test "resume then pause repeatedly" pending user acceptance
