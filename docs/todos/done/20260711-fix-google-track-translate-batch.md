# Fix Google gtx multi-q track-name translation failure

- **Created**: 2026-07-11
- **Owner**: cursor-agent
- **Status**: done
- **Related Issue / PR**: user report (แปลชื่อแทร็กไม่สำเร็จ)

---

## 1. Goal

Fix manual track-name translation failing with `metadataTrackTranslationFailed` because `client=gtx` does not honor multi-`q` batches and `parseBatchResponse(expectedCount > 1)` yields empty strings with no sequential fallback.

## 2. Scope

**In scope:**
- `GoogleTranslateClient.translateBatch` → one `q` per request
- `_translateBatchGoogle` empty/partial-result sequential fallback
- Network-free regression tests

**Out of scope:**
- Folder-name translation in the work tree
- Google RPC `batchexecute` endpoint
- LLM prompt/model changes

## 3. Acceptance

- [x] `translateBatch` with 2+ texts issues one GET per text and returns non-empty translations (mocked Dio)
- [x] `_translateBatchGoogle` retries missing ids when a chunk returns empty/partial results
- [x] `flutter analyze` passes with no new warnings on touched files
- [x] `fvm flutter test test/core/translation/metadata_translation_test.dart` passes

## 4. Steps

- [x] **Step 1**: TODO doc (this file)
- [x] **Step 2**: Fix `GoogleTranslateClient.translateBatch` to one-q-per-request
  - Files: `lib/data/services/google_translate_client.dart`
- [x] **Step 3**: Empty/partial fallback in `_translateBatchGoogle`
  - Files: `lib/core/translation/metadata_translation_service.dart`
- [x] **Step 4**: Regression tests + analyze
  - Files: `test/core/translation/metadata_translation_test.dart`

## 5. Risks

- **Risk**: More HTTP round-trips for large track lists (rate limit)
- **Rollback**: Revert the Google client + service commits

## 6. Notes / Decision Log

- Live probe: multi-`q` gtx returns a single-text JSON blob; single-`q` works (ja→th).
- Parser with `expectedCount > 1` on that shape called `_joinSegment` on flat rows → empty strings; DioException fallback never ran.

---

## ✅ Done

- Completed at: 2026-07-11 10:10
- Command run: `/init` (manual CLAUDE.md update)
- CLAUDE.md update summary: Added `core/translation/` Google gtx one-`q`-per-request invariant + metadata translation test mention
- Related commit: (pending user commit)
