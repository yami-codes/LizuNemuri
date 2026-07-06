# Xuro TODO Document Index

This directory holds **TODO documents** for all features, refactors, and bug fixes in the Xuro project.
See [`../dev_workflow.md`](../dev_workflow.md) for the full workflow.

---

## Directory Layout

```
docs/todos/
├── README.md        # This index
├── _template.md     # Copy when creating a new TODO
├── active/          # In progress (one file = one open task)
├── done/            # Completed (archived after /init)
└── cancelled/       # Cancelled mid-flight (no /init; traceability only)
```

## Workflow Summary

1. **Before starting**: Copy `_template.md` → `active/YYYYMMDD-<slug>.md`; fill goal, scope, acceptance, and steps.
2. **During development**: Check off `[ ]` → `[x]` immediately after each step; attach file paths or commit hashes.
3. **On completion**:
   - All steps checked.
   - Fill the "✅ Done" block with `/init` and timestamp.
   - Actually run `/init` to refresh root `CLAUDE.md`.
   - Move the file from `active/` to `done/`.

> Any cross-file change or externally visible behavior change must have a TODO document first. See [`../dev_workflow.md` §1](../dev_workflow.md#1-when-a-todo-document-is-required).

## Naming Convention

`YYYYMMDD-<kebab-case-slug>.md`

- Date: day work starts.
- Slug: lowercase English hyphenation; no spaces or Chinese.
- Examples:
  - `20260515-floating-lyric-color-picker.md`
  - `20260520-fix-vtt-parser-utf16-bom.md`
  - `20260601-refactor-paginated-viewmodel.md`

## Index (Optional)

If multiple tasks run in parallel, list `active/` files here for a quick overview. Leaving this empty is fine — browse the directory directly.

| Date | File | Status | Owner |
| :--- | :--- | :--- | :--- |
| 2026-05-16 | `active/20260516-startup-loading-performance.md` | active | WuMe-sicx |
| 2026-05-16 | `active/20260516-local-media-download-and-video.md` | active | WuMe-sicx |
