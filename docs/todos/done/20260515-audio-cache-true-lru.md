# Audio Cache True LRU + Deferred Startup Cleanup — Eliminate statSync Jank and Wrong Eviction

- **Created**: 2026-05-15
- **Owner**: WuMe-sicx
- **Status**: done
- **Related Issue / PR**: Local persistence optimization checklist item 3 (Codex SESSION 019e2c0c…2962 analysis B2/C1)

---

## 1. Goal

`AudioCacheManager.cleanCache()` currently calls synchronous `statSync()` inside `files.sort` comparator (O(N log N) blocking FS calls, janks main isolate); eviction logic is wrong — accumulates `totalSize` by modified ascending, when over limit deletes **current (newer)** files, does not decrement `totalSize` after delete, keeping old files and wrongly deleting new ones plus deleting all subsequent files. Plus startup triggers cleanup during first frame. This task changes to **true LRU + one-shot async stat collection**, and defers startup cleanup **until after first frame**.

## 2. Scope

**In scope:**
- Rewrite `AudioCacheManager.cleanCache()`: one-shot async `await file.stat()` collect `(file, stat)`; delete expired first; then by modified ascending delete **oldest** until `totalSize ≤ _maxCacheSize`, **decrement totalSize per delete**; single file delete failure (in use) skip not abort whole sweep.
- `CacheLifecycleManager.initialize()`: startup cleanup from sync `_triggerCleanup()` to `WidgetsBinding.instance.addPostFrameCallback` deferred after first frame; resume path stays immediate (unchanged).

**Out of scope:**
- No capacity scan before `createAudioSource` (every play): full dir scan per track slows playback (conflicts with fluency goal). Periodic correct LRU + 30d expiry + 6h throttle sufficient. Deferred optional.
- Do not touch `getCacheSize()` / `clearAllCache()` / `_isCacheValid()` (not hot path or already correct).
- No change to cache limit (1024MB), expiry (30 days), directory (app support `audio_cache/`).
- No image/subtitle cache changes (flutter_cache_manager built-in strategy, checklist follow-up).

## 3. Acceptance

- [x] No `statSync()` inside `cleanCache()`; stat collected once via `await` then sort (Codex verified :52/:79).
- [x] True LRU eviction: delete oldest until total ≤ limit, `totalSize` decrements after delete; no longer wrongly deletes newer files.
- [x] Expired files deleted first; expired delete failure (in use) **added back to live** (counted in capacity + LRU queue head retry), does not abort whole cleanup.
- [x] Startup cleanup deferred after first frame (`addPostFrameCallback`); resume immediate cleanup unchanged.
- [x] `flutter analyze lib/core/audio/cache/` = No issues found (pre-existing unrelated warning in unchanged `recommendation_cache_manager.dart:1`).
- [x] Related unit / widget tests pass (31 pass; `test/widget_test.dart` pre-existing stale unrelated).
- [x] Codex review ✅ PASS (SESSION 019e2c0c…2962, round 1 ❌ capacity underestimate → fixed → round 2 PASS).

## 4. Steps

- [x] **Step 1**: Rewrite `cleanCache()` (async stat collection + expired first + true LRU + skip in-use; expired delete failure add back to live)
- [x] **Step 2**: `CacheLifecycleManager.initialize()` defer startup cleanup to after first frame (`addPostFrameCallback`)
- [x] **Step 3**: `flutter analyze` (changed files no warnings) + `flutter test` (31 pass, 1 pre-existing stale) full regression
- [x] **Step 4**: Codex review — round 1 ❌ (expired delete failure dropped from capacity accounting causing underestimate) → fixed (failed entry add back to live) → round 2 ✅ PASS

## 5. Risks

- **Risk**: LRU uses `modified` as "recently used" proxy (`LockCachingAudioSource` writes while downloading, modified ≈ last cache time) — not strict atime, but platform atime unreliable, modified is acceptable proxy. Delete failure skip may not reach limit if many files in use (better than aborting whole sweep). Deferred first frame means first cleanup slightly later — acceptable (6h throttle + 30d expiry backstop).
- **Rollback**: revert commit (pure logic, no model/generated artifacts).

## 6. Notes / Decision Log

- Trigger chain: `main.dart:21 CacheLifecycleManager().initialize()` → (was) sync `_triggerCleanup()` → `CacheCoordinator().cleanAll()` → `AudioCacheManager.cleanCache()`. `cleanAll` is fire-and-forget (`.then`), does not block `main()` to `runApp()`, but internal stat-heavy scan async continuation contends with main isolate during first frame — hence defer after first frame.
- Codex round 1 boundary fix: expired file `delete()` failure if dropped directly, file still on disk but not counted in `live.fold` capacity — extreme case (large expired in use + unexpired files / all expired undeletable) actual usage far over 1GB. Fix: failed entry add back to `live`: counted in capacity, oldest modified sorts to LRU queue head for retry delete.

---

## ✅ Done

- Completed at: 2026-05-15 18:00
- Command run: `/init`
- CLAUDE.md update summary: added audio cache cleanup invariants — `cleanCache()` one-shot async stat collection (no sync statSync in sort comparator), true LRU delete oldest to ≤1GB with totalSize decrement, expired first and failed expired deletes must rejoin capacity set; startup cleanup deferred after first frame via `CacheLifecycleManager`.
- Related commit: not committed (user did not request commit; pending unified commit timing)
