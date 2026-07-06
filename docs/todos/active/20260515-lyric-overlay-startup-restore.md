# Floating lyric cold-start state restore (async bind race redesign)

- **Created**: 2026-05-15
- **Owner**: WuMe-sicx
- **Status**: active
- **Related Issue / PR**: derived from `docs/todos/active/20260515-fix-lyric-overlay-bg-start.md`

---

## 1. Goal

When floating lyrics were enabled in the last session, automatically restore display after app cold start.

## 2. Scope

**In scope:**
- `LyricOverlayPlugin.kt`: fix `bindService` async race — after `initialize` returns, Dart immediately calls `isShowing()` / `show()` while `service` is still `null`.
- Choose one approach:
  - A. `initialize` waits until `onServiceConnected` before `result.success`; or
  - B. Plugin maintains pending actions (pendingShow / pendingText), replays on `onServiceConnected`; `isShowing` falls back to `LyricOverlayService` SharedPrefs when `service==null` (`PREFS_NAME` / `KEY_SHOWING` exposed as shared constants — single source of truth, no duplicate literals across files).

**Out of scope:**
- Background-start crash fix (completed in `20260515-fix-lyric-overlay-bg-start.md`).

## 3. Acceptance

- [ ] Floating lyrics enabled → kill process → cold start → overlay reappears and is draggable.
- [ ] `isShowing()` returns value consistent with persistence when `service` not connected.
- [ ] No new background-start exceptions; `flutter analyze` passes.
- [ ] Codex review PASS.

## 4. Steps

- [ ] **Step 1**: Choose approach A or B (B more robust, A simpler); record decision.
- [ ] **Step 2**: Implement plugin changes.
- [ ] **Step 3**: Real-device cold-start restore verification.
- [ ] **Step 4**: Codex review.

## 5. Risks

- **Risk**: Approach A blocking `initialize` may slow startup; Approach B adds plugin state-machine complexity.
- **Rollback**: `git revert`; does not affect landed crash fix.

## 6. Notes

> Split from crash-fix task: prefs-only fallback for `isShowing` cannot make subsequent `show()` work (service not connected → no-op) — half solution, hence separate redesign task.
