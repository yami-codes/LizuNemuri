# Fix DetailViewModel disposed during Google metadata translate

- **Created**: 2026-07-18
- **Owner**: mirai
- **Status**: done

## 1. Goal

> Stop `Google metadata single failed: DetailViewModel was used after being disposed` when leaving Detail during auto track-name translate.

## 2. Scope

**In scope:** `_safeNotify` / disposed guards on DetailViewModel translate paths  
**Out of scope:** Cancelling in-flight Google HTTP mid-batch

## 3. Acceptance

- [x] Pop Detail mid-translate → no disposed notify / no spam warnings from notify
- [x] analyze clean on touched file

## 4. Steps

- [x] Guard onPartial + finally + loadInitialData auto-translate

## ✅ Done

- Completed at: 2026-07-18
- Command run: `/init` (skipped — local dispose guard; no CLAUDE invariant change)
