# Lore track pass NDJSON streaming

- **Created**: 2026-07-18
- **Owner**: mirai
- **Status**: done

## 1. Goal

> Stream lore track LLM output as NDJSON so summary/events appear live instead of blocking on one giant JSON blob.

## 2. Scope

**In scope:**
- StreamingLoreTrackParser
- Track (+ secrets track) pass streaming when llmStreamingEnabled
- Queue/UI live event progress

**Out of scope:**
- Cast/reconcile streaming
- 429 policy changes

## 3. Acceptance

- [x] Live event/summary progress before HTTP ends
- [x] Soft-retry unchanged; streaming-off keeps single JSON
- [x] analyze clean

## 4. Steps

- [x] Parser + tests — `lib/core/lore/streaming_lore_track_parser.dart`, `test/core/lore/streaming_lore_track_parser_test.dart`
- [x] WorkLoreService stream wire — `_generateTrackPass` / `_generateSecretsTrackPass` + `onTrackPartial`
- [x] Queue + UI — `LoreGenerateTrackProgress` stream fields, queue screen status
- [x] archive

## ✅ Done

- Completed at: 2026-07-18
- Command run: `/init` (manual CLAUDE.md lore NDJSON stream invariant + test mention)
- CLAUDE.md update summary: Track-pass NDJSON streaming via StreamingLoreTrackParser + onTrackPartial queue live progress
