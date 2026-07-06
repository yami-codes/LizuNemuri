# Floating Lyrics: Pass-Through + Vertical-Only Drag + Text Stroke (Issue #1)

- **Created**: 2026-05-15
- **Owner**: WuMe-sicx
- **Status**: done
- **Related Issue / PR**: https://github.com/WuMe-sicx/Xuro/issues/1

---

## 1. Goal

Per Issue #1 feedback, reshape Android floating lyric interaction and visuals: default full pass-through (do not intercept underlying app touches), lock to vertical movement only, replace semi-transparent black background with text stroke, keep "edit mode" for position adjustment anytime.

## 2. Scope

**In scope:**
- Android native overlay: remove horizontal drag, add `FLAG_NOT_TOUCHABLE` for default pass-through, expose `setEditable` to toggle draggable state.
- Layout: dual stacked `TextView` for text stroke, remove black semi-transparent background.
- Dart `ILyricOverlayController` / impl / Dummy sync `setEditable`.
- `LyricOverlayManager` expose `toggleEditable`, force exit edit mode on `hide()`.
- `PlayerScreen` toolbar: long-press lyric icon to enter/exit edit mode with SnackBar feedback.

**Out of scope:**
- iOS / desktop (keep Dummy stub).
- Custom font size / color / stroke width settings (deferred TODO).
- Overlay background blur, animation, scroll sync advanced effects.

## 3. Acceptance

- [x] Default state: while floating lyrics visible, underlying app (including home screen, video, text input) receives touches normally; overlay intercepts nothing.
- [x] Long-press PlayerScreen top lyric icon enters edit mode: drag overlay vertically only; horizontal position fixed (always centered).
- [x] Long-press again / hide overlay: auto exit edit mode, restore pass-through.
- [x] Floating lyric text has stroke (black outline white fill), no semi-transparent background box.
- [x] `flutter analyze` passes with no new warnings.
- [ ] Device (Android) smoke test: 1) overlay on video, can tap pause 2) edit mode vertical drag smooth 3) lock screen / background resume, position correct. **Left for maintainer device verification.**

## 4. Steps

- [x] **Step 1**: Change `android/app/src/main/res/layout/lyric_overlay.xml`
  - `FrameLayout` + two `TextView`s: bottom stroke layer (id `lyric_stroke`), top fill (id `lyric_fill`).
  - Remove `android:background`.
  - Verify: local build passes (`fvm flutter build apk --debug`).
- [x] **Step 2**: Change `LyricOverlayService.kt`
  - flags add `FLAG_NOT_TOUCHABLE`, `gravity` → `TOP or CENTER_HORIZONTAL`, `x=0`.
  - After inflate set `lyric_stroke.paint.style = STROKE`, `strokeWidth=...`.
  - `setText` writes both TextViews.
  - `OnTouchListener` only updates `params.y`; persist only `KEY_Y`.
  - New `setEditable(boolean)`: edit mode removes `FLAG_NOT_TOUCHABLE`, reuse windowManager.updateViewLayout.
  - Verify: default pass-through on device, edit mode drags Y.
- [x] **Step 3**: Change `LyricOverlayPlugin.kt`
  - Add `setEditable` method route.
  - Verify: Plugin does not throw `notImplemented`.
- [x] **Step 4**: Change Dart interface/impl
  - Interface add `Future<void> setEditable(bool)`; real impl forwards to channel; Dummy no-op.
  - Verify: `flutter analyze` no missing method errors.
- [x] **Step 5**: Change `LyricOverlayManager`
  - Maintain `_isEditable`; reset on `hide`; provide `toggleEditable`.
  - Verify: unit/manual toggle behavior correct.
- [x] **Step 6**: Change `lib/screens/player_screen.dart`
  - Lyric `IconButton` → `InkResponse(onTap, onLongPress, ...)`; long-press triggers `toggleEditable`, SnackBar feedback.
  - Verify: tap still show/hide; long-press shows "adjust mode" hint.
- [x] **Step 7**: `fvm flutter analyze`, fix any new warnings; prepare git diff for Codex review.
  - Verify: analyze pass + Codex ✅ PASS.

## 5. Risks

- **Risk**: Some OEM ROMs may behave oddly with `FLAG_NOT_TOUCHABLE + TYPE_APPLICATION_OVERLAY` (not shown / force dismiss).
  - **Rollback**: if ROM abnormal in `setEditable(false)`, keep flag but remove X-axis drag as minimum; or revert to default touchable.
- **Risk**: dual TextView stack mixed CJK/Latin line breaks may desync stroke offset.
  - **Mitigation**: both TextViews identical width, padding, textSize, fontFamily, letterSpacing; `match_parent` for layout-driven wraps.
- **Risk**: old users have `KEY_X` in SharedPreferences.
  - **Mitigation**: ignore `KEY_X` read, no migration needed.

## 6. Notes / Decision Log

- User wants both ① "lock vertical movement" and ③ "pass-through". Technically exclusive in default state — chose **option b**: default pass-through, long-press PlayerScreen lyric icon for edit mode.
- Stroke approach: **dual TextView stack** (true stroke) not `setShadowLayer` (glow shadow) — matches Issue "text stroke" visual.
- Codex round 1: Android 12+ security policy: `TYPE_APPLICATION_OVERLAY + FLAG_NOT_TOUCHABLE` requires `LayoutParams.alpha ≤ getMaximumObscuringOpacityForTouch()` (default 0.8) for underlying app to receive touches. Added `PASS_THROUGH_ALPHA=0.8f` / `EDIT_MODE_ALPHA=1.0f`, `createLyricView` and `setEditable` sync alpha.
- Codex round 2: ✅ PASS (SESSION_ID `019e28db-bf47-7da3-83a0-fef3847e8c85`).
- Copy centralized in `lib/common/constants/strings.dart` `// Floating lyric overlay` section, 6 constants.

---

## ✅ Done

- Completed at: 2026-05-15
- Command run: `/init` (executed, CLAUDE.md refreshed)
- CLAUDE.md update summary: `lib/core/platform/` paragraph adds floating lyric invariants (default pass-through = FLAG_NOT_TOUCHABLE + alpha 0.8 for Android 12+ security policy, Y-axis lock, dual TextView stroke, edit mode long-press entry, setEditable wired through stack).
- Related commit: `3071d8e` (code) + CLAUDE.md/archive commit

---
