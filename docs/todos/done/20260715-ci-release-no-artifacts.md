# CI: attach release assets without Actions artifacts

- **Created**: 2026-07-15
- **Owner**: mirai
- **Status**: done

## 1. Goal

> Stop using `actions/upload-artifact` in release CI (quota exhausted); attach built packages directly to the GitHub Release.

## 3. Acceptance

- [x] No `upload-artifact` / `download-artifact` in release workflow
- [x] Tag builds still publish APK/AAB/IPA/web/windows onto the GH Release
- [x] workflow_dispatch still builds without requiring artifact storage

## ✅ Done

- Completed at: 2026-07-15
- Command run: `/init` (not needed — CI-only; CLAUDE.md unchanged)
- Related commit: (see v2.0.0-rc.25)
