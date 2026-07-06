# Xuro Development Workflow (Mandatory)

> This document is the **mandatory workflow** for all new features, refactors, and bug fixes in the Xuro project.
> It complements [`guidelines_zh.md`](guidelines_zh.md) (architecture / code style): this document governs **the order of work**; guidelines govern **how to work**.

---

## Core Rules (Non-Negotiable)

Any project-level, feature-level, or module-level development task must satisfy:

1. **Before starting**: Create (or update) a **TODO document** under `docs/todos/`, fixing the goal, scope, acceptance criteria, and breakdown steps.
2. **During development**: As each sub-item completes, immediately check it off in the TODO document and add references to actual deliverables (file paths, commit hashes, etc.).
3. **On completion**: Append the completion marker `/init` at the bottom of the TODO document and actually run `/init` to refresh the root `CLAUDE.md`, keeping codebase documentation aligned with the latest state.

> ❌ Skipping the TODO document and writing code directly = violation.
> ❌ Completing a feature without marking and running `/init` = task not closed.

---

## 1. When a TODO Document Is Required

| Scenario | TODO document required? |
| :--- | :--- |
| New feature / page / module | ✅ Required |
| Cross-file refactor, architecture change | ✅ Required |
| Bug fix affecting public interfaces | ✅ Required |
| Data model change (freezed) | ✅ Required |
| Performance / cache strategy change | ✅ Required |
| Dependency upgrade (pubspec / Gradle / Pod) | ✅ Required by default |
| Single-file typo, format, or comment fix | ❌ May omit |
| Pure documentation polish (no runtime / build impact) | ❌ May omit |

Decision rule: **the change spans more than one file _or_ has any observable impact on runtime behavior / build artifacts / externally visible behavior → TODO required**.
Dependency upgrades default to "required": version changes affect generated code, builds, runtime, and security surface. Exempt only when you can confirm the change is pure formatting, comments, or doc polish with zero runtime or build impact.

---

## 2. TODO Document Conventions

### 2.1 Location

```
docs/
└── todos/
    ├── README.md            # Template and index
    ├── _template.md         # Copy this template for new tasks
    ├── active/              # In progress
    │   └── YYYYMMDD-<slug>.md
    ├── done/                # Completed (after /init)
    │   └── YYYYMMDD-<slug>.md
    └── cancelled/           # Cancelled mid-flight (no /init)
        └── YYYYMMDD-<slug>.md
```

### 2.2 Naming

`YYYYMMDD-<kebab-case-slug>.md`

- Example: `20260515-floating-lyric-color-picker.md`
- Slug must use lowercase English hyphenation; no spaces or Chinese characters.

### 2.3 Required Fields (see `docs/todos/_template.md`)

Each TODO document must include at minimum:

1. **Goal**: One sentence on what and why.
2. **Scope**: What is in / out of scope.
3. **Acceptance**: Verifiable success conditions (tests, UI behavior, API behavior).
4. **Steps**: Ordered checklist with verification method per step.
5. **Risks**: Possible impact on existing features; rollback plan.
6. **Done Marker**: `/init` line + execution timestamp.

### 2.4 Lifecycle

```
Draft → move to active/ → develop + check off → all checked + /init → move to done/
                                              └─ cancelled mid-flight → move to cancelled/
```

- **In progress (active)**: File lives in `docs/todos/active/`.
- **Done (done)**: All steps checked; fill the "✅ Done" block; **actually run `/init`** to refresh root `CLAUDE.md`; move the file to `docs/todos/done/`. `done/` means "completed and /init executed" — do not mix other states.
- **Cancelled (cancelled)**: Task cancelled mid-flight; **do not run `/init`; no completion block required**. Change template `Status: active` to `Status: cancelled`, append a "cancellation reason" section at the end, then move the file to `docs/todos/cancelled/` (kept for traceability).

---

## 3. `/init` Completion Marker

`/init` is a Claude Code slash command that scans the codebase and updates the root `CLAUDE.md`.

### 3.1 When to Run

**Feature complete = all acceptance criteria pass ⇒ run `/init` immediately**.

Rationale:
- `CLAUDE.md` is the AI collaboration entry document; stale content causes later sessions to reason from outdated information.
- TODO documents capture "what we did this time"; `CLAUDE.md` captures "what the whole project looks like now" — keep them in sync.

### 3.2 How to Mark in the TODO

Append at the bottom of the TODO document:

```markdown
---
## ✅ Done

- Completed at: 2026-05-15 14:30
- Command run: `/init`
- CLAUDE.md update summary: <one or two sentences on what changed in CLAUDE.md>
- Related commit: <commit hash>
```

### 3.3 Post-Run Checklist

- [ ] Directory tree and module descriptions in `CLAUDE.md` match reality.
- [ ] New / renamed services, ViewModels, and Screens are reflected.
- [ ] Stale content (deleted files, outdated commands) is removed.

---

## 4. Relationship to Other Specs

| Document | What it governs |
| :--- | :--- |
| **dev_workflow.md (this doc)** | Task flow: TODO → develop → /init |
| [`guidelines_zh.md`](guidelines_zh.md) | Architecture, code style, naming, string management |
| [`ui-design-spec.md`](ui-design-spec.md) | Visual design tokens, animation, component standards |
| [`audio_architecture.md`](audio_architecture.md) | Event-driven audio subsystem architecture |
| [`architecture.md`](architecture.md) | Early architecture sketch (historical reference) |

On conflict, priority is: **dev_workflow > subsystem docs > general guidelines**.

### 4.1 Integration with CCG / Coder Workflow

If global CCG rules are enabled (`[coder].enabled = true` in `~/.ccg-mcp/config.toml`, or `CCG_CODER_ENABLED=true`):

- **Same change-set principle**: The TODO document, code changes for this task, and the `CLAUDE.md` diff from `/init` belong to **one change set** and must pass Codex review together before the task is closed.
- **Who implements**: When Coder is enabled and the task should use Coder, implementation steps in the TODO and `CLAUDE.md` updates from `/init` are done by Coder; Claude plans and does quick verification; Codex review must return ✅ PASS before merge.
- **Who runs /init**: `/init` is a Claude Code slash command triggered by whichever role holds the session; if Coder is enabled, `CLAUDE.md` edits still require Codex review.
- If Coder is not enabled: follow this document's default flow; Coder/Codex is not mandatory.

---

## 5. Checklists

Use in two phases: **"in-development commit"** for interim commits/PRs; **"feature complete"** when closing the task.

### 5.1 In-Development Commit (each interim commit / PR)

- [ ] A TODO document exists for this work and lives in `docs/todos/active/`.
- [ ] Completed steps in the TODO are checked off with file paths or commit hashes.
- [ ] `flutter analyze` has been run; if models changed, `dart run build_runner build --delete-conflicting-outputs` has been run.
- [ ] Relevant unit / widget tests pass.
- [ ] Commit message references the TODO path (e.g. `feat(player): xxx (refs docs/todos/active/20260515-...)`).

### 5.2 Feature Complete (final commit before closing)

- [ ] All TODO steps are checked; all acceptance criteria pass.
- [ ] `/init` was actually run and root `CLAUDE.md` was manually verified (see §3.3).
- [ ] The "✅ Done" block at the bottom of the TODO is complete.
- [ ] The TODO file was moved from `docs/todos/active/` to `docs/todos/done/`.
- [ ] Commit message references the archived path (e.g. `feat(player): xxx (closes docs/todos/done/20260515-...)`).

> If any item is unchecked → the task is not closed; do not declare it done.
