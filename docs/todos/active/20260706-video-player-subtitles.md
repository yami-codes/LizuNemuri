# In-app video player with subtitle overlay

- **Created**: 2026-07-06
- **Owner**: cursor-agent
- **Status**: active

## 1. Goal

Play work video files in-app (stream or local) with matched sibling subtitle overlay (VTT/LRC).

## 2. Scope

**In scope:**
- media_kit video player screen
- Tap video in file tree → player (not external OpenFilex)
- Auto-match sibling `.vtt`/`.lrc`, overlay synced to position
- Network URL + downloaded local path

**Out of scope:** Embedded MKV subs, SRT parser, PiP

## 3. Acceptance

- [x] Video files open in-app player on Android/Windows/Linux
- [x] Matched subtitle displays over video when available
- [x] Tests + analyze pass

## 4. Steps

- [x] media_kit_video deps + MediaKit.ensureInitialized
- [x] VideoPlayerScreen + subtitle overlay
- [x] detail_screen routing + VM subtitle match helper
- [x] l10n + tests
