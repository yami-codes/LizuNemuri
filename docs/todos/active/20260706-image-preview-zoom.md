# Image preview with pinch zoom in file tree

- **Created**: 2026-07-06
- **Owner**: cursor-agent
- **Status**: active

## 1. Goal

Tap image files (jpg/png/webp/gif/bmp/avif) in the work file tree to open a full-screen zoomable preview.

## 2. Scope

**In scope:**
- Extension + API `type==image` detection
- `ImagePreviewScreen` with `InteractiveViewer` pinch/pan zoom
- Local-download-first, then presigned URL (same as subtitle preview)
- Tappable rows + image icon in file list

**Out of scope:** SVG viewer, in-app image editor, batch gallery

## 3. Acceptance

- [x] JPG/PNG/WebP/GIF/BMP/AVIF open zoomable preview from detail file tree
- [x] Downloaded local copy preferred over network
- [x] Tests for `isImageFile`; analyze clean

## 4. Steps

- [x] DetailViewModel.isImageFile + WorkFileItem tappable/icon
- [x] ImagePreviewScreen + detail_screen routing
- [x] l10n strings (en/zh/th)
- [x] Tests + analyze
