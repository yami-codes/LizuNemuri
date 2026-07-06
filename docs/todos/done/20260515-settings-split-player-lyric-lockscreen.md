# Settings/About Split + Player Seek + Lyric Lock Switch + Lock-Screen Playback Info

- **Created**: 2026-05-15
- **Owner**: WuMe-sicx
- **Status**: done <!-- active | done | cancelled -->
- **Related Issue / PR**: (none)

---

## 1. Goal

Deliver four UX improvements in one pass: ① Split Settings and About into separate pages; ② Add fast-forward/rewind controls to player; ③ Add Settings toggle to lock/unlock floating lyric position; ④ Adapt lock-screen playback progress and lyric display.

## 2. Scope

**In scope:**
- A. New `AboutScreen`, migrate all `_aboutSection` items from Settings + top product intro; remove about content from Settings; sidebar "关于我们" routes to `AboutScreen`.
- B. Wire existing but unused `PlayerSeekControls` (±5s / ±30s and prev/next lyric line) into player UI for seek capability.
- C. `AppSettingsService` persistent floating-lyric lock preference; Settings toggle; `LyricOverlayManager` applies preference on show.
- D. `AudioNotificationService` / `AudioPlayerHandler` lock-screen: complete MediaItem duration → visible moving lock-screen seekbar; inject current lyric line into media notification subtitle.

**Out of scope:**
- Vendor-private lock-screen scrolling lyric APIs (StatusBarManager / ROM SDKs) — not portable; lock-screen lyrics via "current line in media notification subtitle" only.
- Player UI visual redesign, lyric style changes.
- Separate iOS lock-screen verification (audio_service shares MediaItem, logic common).

## 3. Acceptance

- [x] Settings no longer shows About group; sidebar "关于我们" opens standalone `AboutScreen` with intro + version + check update + licenses + feedback/source/original repo/TG. (Code done, pending device tap test)
- [x] Player shows rewind/fast-forward/lyric-jump buttons between progress and play controls; taps change position correctly. (Code done, pending device tap test)
- [x] Settings has "悬浮歌词" toggle; when shown, floating lyrics draggable / pass-through restored per toggle; preference survives restart. (Code done, pending device tap test)
- [x] Lock-screen media notification shows moving progress bar; when subtitles play, notification subtitle shows current lyric line. (Code done, pending device tap test)
- [x] `flutter analyze` passes, no new warnings (full 36→33, fixed 3 introduced by this task).
- [x] No `lib/data/models/` Freezed changes (no build_runner).
- [x] Related unit/widget tests pass (analyze + manual verification primary; no new pure-logic unit test points).

> ⚠️ Runtime/device verification (lock-screen progress/lyrics, overlay drag, UI tap tests) requires Android device; cannot complete in this environment — explicitly marked pending user acceptance.

## 4. Steps

- [x] **A1**: Add `Strings.aboutAppName` / `Strings.aboutAppDescription`. File: `lib/common/constants/strings.dart`. Verify: analyze.
- [x] **A2**: New `lib/screens/about_screen.dart`, migrate about items + top intro + `_openUrl`. Verify: manual page entry.
- [x] **A3**: `settings_screen.dart` remove `_aboutSection` / `_packageInfoFuture` / stale imports. Verify: analyze no unused imports.
- [x] **A4**: `sidebar_menu.dart` "关于我们" → `AboutScreen`. Verify: sidebar opens about page.
- [x] **B1**: `player_screen.dart` insert `PlayerSeekControls` between `PlayerProgress` and `PlayerControls`. Verify: buttons appear and seek works.
- [x] **C1**: `AppSettingsService` add `lyricOverlayUnlocked` persisted field + setter. Verify: analyze.
- [x] **C2**: `LyricOverlayManager` inject `AppSettingsService`, `show()` applies preference via `setEditable`; add `setUnlockedPreference`. `service_locator` passes settings. Verify: analyze.
- [x] **C3**: `settings_screen.dart` new "悬浮歌词" group toggle + `Strings`. Verify: manual toggle + restart persistence.
- [x] **D1**: `AudioNotificationService` inject `ISubtitleService`, cache track/duration/lyric, listen `playbackState` (real duration) and subtitle stream, unified `_pushMediaItem()`. Verify: lock-screen seekbar + subtitle line updates.
- [x] **D2**: `AudioPlayerHandler` add `playbackProgress` throttle (1s) pushing `PlaybackState` position. Verify: lock-screen seekbar moves.
- [x] **D3**: `AudioPlayerService._init` inject notification with `getIt<ISubtitleService>()`. Verify: analyze + no DI error at runtime.
- [x] **Wrap-up**: `flutter analyze`; Done block + `/init`; move to `done/`.

## 5. Risks

- **Risk**: Lock-screen lyrics replace `artist` row when playing lyrics — artist hidden while lyric active (tradeoff: lyric priority). Frequent MediaItem re-push may refetch artwork — mitigated by audio_service same `artUri` cache and re-push only on lyric text change (distinct).
- **Risk**: `LyricOverlayManager` new settings dependency; registration order must have `AppSettingsService` before `setupSubtitleServices()` (already satisfied, line 88 < 128).
- **Rollback**: Four features independent; revert per commit; no data model changes.

## 6. Notes / Decision Log

- B: Reuse existing unused `PlayerSeekControls` instead of single new button in `PlayerControls` — zero new code, adds rewind/forward/lyric jump, fits "simple first + reuse".
- C: Settings toggle is persistent default; player long-press remains session-only temporary toggle (`hide()` resets); `show()` always applies persisted preference last.
- D: True lock-screen scrolling lyrics need vendor APIs, not portable → media notification subtitle = current line; lock-screen seekbar root cause was MediaItem missing duration (often null at trackChange), fixed with real duration then system extrapolates via updateTime+speed.

### Post-close supplement (user feedback + Codex review, 2026-05-15)

- B adjustment: User said unused `PlayerSeekControls` row overcomplicated player (duplicate prev/next icons). **Changed to** rewrite `player_controls.dart` as single row `[rewind 10s][prev][play/pause][next][forward 10s]`, removed `PlayerSeekControls` from player_screen (back to unused). Overrides B decision above.
- "Cannot pause": Claude static analysis + Codex read-only review (SESSION_ID `019e2be0-4cce-7f82-aa9f-e8d2b2e9f783`) independently confirmed **not introduced by this change** (rxdart `throttleTime` leading-only no trailing; `copyWith` keeps `playing:false`; `mediaItem.add` doesn't trigger play/pause; lazy singleton no DI timing risk). Treated as pre-existing/environment issue; needs user repro scene (in-app button / lock screen / after lock) to locate.
- Codex ⚠️ OPTIMIZE (mergeable), adopted: ① trackChange uses `event.track.duration ?? _player.duration` fallback, fixes "lock-screen seekbar missing when restoring paused track"; ② `AudioPlayerHandler` add `cancelSubscriptions()` called from `AudioNotificationService.dispose()`, fixes progress subscription leak (and unused_field warning).

---

## ✅ Done

- Completed at: 2026-05-15
- Command run: `/init`
- CLAUDE.md update summary: New `AboutScreen` (about split from settings); player wired `PlayerSeekControls`; `AppSettingsService` adds `lyricOverlayUnlocked` with `LyricOverlayManager` injecting `AppSettingsService`; `AudioNotificationService` injects `ISubtitleService`, re-pushes MediaItem on playbackState real duration and subtitle stream, `AudioPlayerHandler` throttled progress push for lock-screen seekbar.
- Related commit: (pending user commit; not auto-committed)
