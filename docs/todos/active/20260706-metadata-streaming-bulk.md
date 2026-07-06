# Metadata bulk translate + LLM streaming

- **Created**: 2026-07-06
- **Status**: active

## Goal

Progressive bulk title/track translation on list/search/detail with Google or LLM (settings), and LLM streaming partial updates like subtitles.

## Plan

- [x] StreamingMetadataParser + MetadataTranslationService onPartial/stream
- [x] WorkListTranslationMixin + DetailViewModel incremental UI
- [x] Gate detail manual track translate by settings
- [x] Tests + analyze
