# Playback State Slim-Down + Throttled Persistence — Reduce Main-Isolate JSON Encode Overhead

- **Created**: 2026-05-15
- **Owner**: WuMe-sicx
- **Status**: done
- **Related Issue / PR**: Local persistence optimization checklist item 1 (Codex SESSION 019e2c0c…2962 analysis B1/C6)

---

## 1. Goal

`last_playback_state` currently JSON-encodes full `Work + Files + currentFile + playlist + currentIndex` on main isolate to SharedPreferences, and every `playerStateStream` event resets 5s debounce. Large file trees cause jank. This task removes redundant fields restore never uses, lengthens throttle interval, adds lifecycle flush and stop cleanup, directly reducing frame drops during play/track change **without changing restore semantics**.

## 2. Scope

**In scope:**
- `PlaybackState` model remove `playlist`, `currentIndex` (restore path does not consume them, only redundant copies of `files` nodes).
- Save debounce interval 5s → 20s.
- `pause()` immediate flush once; keep existing immediate save on playback completion.
- `PlaybackStateManager.dispose()` best-effort flush before canceling timer.
- `stop()` clear persisted `last_playback_state` (new `clearState()`).
- Fix `restorePlaybackState()` references to `state.playlist`/`state.currentIndex` (use rebuilt `context.playlist` for null check and logging).

**Out of scope:**
- Do not replace `work`/`files` with `workId` + API refetch on launch (network-dependent architectural change, restore semantics change, offline restore affected) — deferred independent task; keep offline-restorable this round.
- No new `WidgetsBindingObserver`: background/detached flush covered by `pause()` flush + completion save + 20s interval + dispose best-effort flush on realistic paths.
- Do not touch `audio_player_handler.dart` same-named `PlaybackState` from `audio_service` package (different type, unrelated).

## 3. Acceptance

- [x] `PlaybackState` keeps only `work/files/currentFile/playMode/position/timestamp`; old JSON with `playlist`/`currentIndex` still loads via `fromJson` (Codex verified `.g.dart` ignores unknown keys).
- [x] Track change/play/pause no longer triggers full-tree JSON encode every 5s; interval 20s, `pause()` immediate persist.
- [x] After `stop()`, `last_playback_state` cleared, next launch does not restore stopped session (including write race fix).
- [x] Restore behavior unchanged: still rebuilds playback context from `work/files/currentFile/playMode/position` (playlist/index derived by `PlaybackContext` factory from `files`).
- [x] `flutter analyze` passes, no new warnings (only 2 pre-existing: `playback_controller.dart:9`, `playback_context.dart:196`).
- [x] Ran `dart run build_runner build --delete-conflicting-outputs`, `playback_state.freezed.dart`/`.g.dart` regenerated.
- [x] Related unit / widget tests pass (31 pass; `test/widget_test.dart` counter template fails on clean tree too, pre-existing stale, unrelated).
- [x] Codex review ✅ PASS (SESSION 019e2c0c…2962, race fix then round 2 PASS).

## 4. Steps

- [x] **Step 1**: `PlaybackState` remove `playlist`/`currentIndex` fields (`playback_state.dart`, build_runner regenerated)
- [x] **Step 2**: `PlaybackStateManager` — `saveState()` drop two fields, `_saveInterval` 20s, `dispose()` best-effort flush (`playback_state_manager.dart`)
- [x] **Step 3**: Interface and repository add `clearState()` + manager `clearSavedState()` passthrough (`i_playback_state_repository.dart` / `playback_state_repository.dart`)
- [x] **Step 4**: `audio_player_service.dart` — `pause()` flush, `stop()` calls `clearSavedState()`, `restorePlaybackState()` uses `context.playlist`
- [x] **Step 5**: `flutter analyze` (no new warnings) + `flutter test` (31 pass, 1 pre-existing stale unrelated) full regression
- [x] **Step 6**: Codex review — round 1 ❌ save/clear write race → fixed (persistence serialization `_persistChain` + `_persistSuppressed` tombstone) → round 2 ✅ PASS

## 5. Risks

- **Risk**: hard kill (no pause) may lose up to ~20s progress; acceptable (completion/pause/dispose have flush). If trimmed fields had hidden consumers restore would fail — grep confirmed only restore logging and manager construction reference them.
- **Rollback**: revert commit; model field rollback requires re-run build_runner.

## 6. Notes / Decision Log

- Key basis: `PlaybackContext` factory `playback_context.dart:51-68` derives playlist/currentIndex from `files`+`currentFile`; `restorePlaybackState` `audio_player_service.dart:174-179` uses that factory, so persisted playlist/currentIndex are dead data for restore.
- Backward compatible, no migration: json_serializable default ignores unknown keys, old JSON extra keys discarded.
- **Codex round 1 race (fixed)**: original `saveState()` fire-and-forget; in-flight save `setString` completing after `stop()` `remove` could write stopped session back. Fix: all save/clear serialized in single `_persistChain` (remove must follow in-flight save), plus `_persistSuppressed` tombstone (`clearSavedState()` sets synchronously, saves after stop and before new non-null `updateContext` no-op; snapshot `context`/`positionMs` at call time prevents chain executing after `_currentContext` cleared). Round 2 Codex ✅ PASS.

---

## ✅ Done

- Completed at: 2026-05-15 16:20
- Command run: `/init`
- CLAUDE.md update summary: refreshed audio subsystem persistence — `PlaybackState` slimmed (removed playlist/currentIndex), 20s throttle + pause/completion/dispose flush, `stop()` clears persistence, save/clear via `_persistChain` serialization + `_persistSuppressed` tombstone eliminates write-back race.
- Related commit: not committed (user did not request commit; pending unified commit timing)
