# Work detail PC / desktop layout

- **Created**: 2026-07-06
- **Owner**: cursor-agent
- **Status**: active

## 1. Goal

Fix work detail on desktop: cover art must not stretch full window width; show cover + metadata + file tree in a readable two-column layout.

## 2. Scope

**In scope:** Responsive detail layout (mobile column / wide two-column), max content width

**Out of scope:** Player screen layout, new detail features

## 3. Acceptance

- [x] Desktop/tablet (≥800px): cover capped ~360px, info + files beside it
- [x] Mobile unchanged (stacked column)
- [x] analyze pass

## 4. Steps

- [x] DetailLayoutConfig
- [x] Refactor DetailScreen responsive body
- [x] Verify analyze
