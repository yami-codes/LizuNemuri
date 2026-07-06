# [Task title — one clear sentence]

- **Created**: YYYY-MM-DD
- **Owner**: <github username>
- **Status**: active <!-- active | done | cancelled -->
- **Related Issue / PR**: <link or number, may be empty>

---

## 1. Goal

> One sentence: what + why.
> Example: "Add a color picker to the floating lyric window so users can stay readable on different wallpapers."

## 2. Scope

**In scope:**
- ...

**Out of scope:**
- ... (explicitly mark what this task does *not* do, to prevent scope creep)

## 3. Acceptance

Verifiable success conditions. Each must be falsifiable via UI, tests, or logs.

- [ ] ...
- [ ] ...
- [ ] `flutter analyze` passes with no new warnings.
- [ ] If `lib/data/models/` Freezed/json_serializable types changed, `dart run build_runner build --delete-conflicting-outputs` was run and generated artifacts are committed.
- [ ] Relevant unit / widget tests pass.

## 4. Steps

Ordered by dependency. Each step notes how to verify.

- [ ] **Step 1**: <what to do>
  - Files: `lib/...`
  - Verify: <how you know this step is correct>
- [ ] **Step 2**: <what to do>
  - Files: `lib/...`
  - Verify: ...
- [ ] **Step 3**: ...

## 5. Risks

- **Risk**: <possible impact on existing features / performance / compatibility>
- **Rollback**: <how to undo, e.g. revert commit or keep a feature flag>

## 6. Notes / Decision Log

> Key decisions and pitfalls discovered during development — for future reference.

---

## ✅ Done

> After all steps are checked, fill this block, actually run `/init` to refresh root `CLAUDE.md`, then move this file to `docs/todos/done/`.

- Completed at: YYYY-MM-DD HH:mm
- Command run: `/init`
- CLAUDE.md update summary: <one or two sentences on what changed in CLAUDE.md>
- Related commit: <commit hash>

---

## ⛔ Cancelled

> Fill this block only for cancelled tasks (mutually exclusive with Done above). **Do not run `/init`**. Move the file to `docs/todos/cancelled/`.

- Cancelled at: YYYY-MM-DD HH:mm
- Reason: <e.g. replaced by approach XYZ / deprioritized / upstream API removed>
- Follow-up: <successor TODO path if any; otherwise leave empty>
