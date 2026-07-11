# Work Lore: per-track story, characters, state timeline, CCv2 export

- **Created**: 2026-07-11
- **Owner**: Miri
- **Status**: done
- **Related Issue / PR**:

---

## 1. Goal

> Add an LLM-generated Work Lore system: per-work/track story summaries, detailed characters (maximal NSFW modular ontology + kinks), timestamped state-change timeline with playback-synced HUD reveal, local persistence/export, and Character Card V2 export via LLM rewrite for other platforms.

## 2. Scope

**In scope (shipped):**
- LLM generate from metadata + subtitles + seed notes (work / character / keyed lorebook-style)
- Manual Generate trigger; sectioned regenerate; full character editor
- Work-local characters → optional global promote (field-level merge)
- Maximal NSFW ontology as versioned modules; sparse values; `contentLevel` UI filter; reveal + opt-in Generate secrets (`speculative`)
- Track summaries (prose) separate from structured timeline events; optional subtitle evidence quotes
- Precompute events + playback reveal + local gauge projection; bidirectional seek projection
- Detail tab = authoring; Player = HUD gauges (user pins) + expandable timeline scrubber; hide player lore until pack exists
- Local SQLite + Lizunemu lore pack export/import (`schema_version`)
- Character Card V2 export: LLM rewrite, cache, invalidate on lore change; single + batch zip; speculative opt-in; `extensions.lizunemu`
- Lore language setting (default = app language); max-tracks-per-generate setting
- VA↔character links: LLM proposes, user confirms

**Out of scope (deliberate):**
- Live LLM mid-playback generation
- Cloud sync
- Auto-generate on open/play
- Silent global character auto-merge
- PNG-embedded CCv2 (JSON first)

## 3. Acceptance

- [x] Manual "Generate lore" on Work Detail produces work synopsis + local cast + per-track summary + timestamped events when subs exist
- [x] Partial tracks without subs still allow work-level lore; track events stubbed/thin
- [x] Player shows lore HUD only after lore exists; reveals events + projects gauges with playback position; seek recomputes state bidirectionally
- [x] User can select focus character; LLM suggests default focus + initial HUD pins; pin config UI
- [x] Lore persisted in local SQLite for the work (DB v4)
- [x] Versioned ontology modules + contentLevel + Generate secrets
- [x] Full editor + sectioned regen
- [x] Lizunemu pack export/import
- [x] Global character library + field-level merge
- [x] CCv2 LLM-rewrite export with cache + batch zip
- [x] Seed notes: work + character + keyed lorebook entries
- [x] Evidence quotes on events; VA link confirm UI
- [x] Unit tests for projection / parse / pack round-trip (network-free)
- [x] `flutter analyze` on lore surface: no errors (1 pre-existing info elsewhere in detail_screen)

## 4. Steps

- [x] **Step 1**: Domain models + SQLite schema (migration v4) + repositories
- [x] **Step 2**: Lore generation service (cast → per-track carry-over → reconcile)
- [x] **Step 3**: Detail Lore tab + editor + regen + secrets + export
- [x] **Step 4**: Playback sync HUD + timeline sheet
- [x] **Step 5**: Settings (lore language, max tracks) + global library entry
- [x] **Step 6–11**: HUD pins, ontology/secrets, pack IO, global merge, CCv2 (shipped together)

## 5. Risks

- Token cost / long albums — mitigated with max-tracks setting + per-track chunking
- Hallucinated NSFW on SFW — contentLevel + opt-in secrets + speculative flag
- Global merge false positives — field-level confirm only
- Player HUD vs immersive — hide-until-lore + compact pins

## 6. Notes / Decision Log

See grilling lock in prior revision. User override 2026-07-11: **full production, no deferred phases**.

### Key files
- `lib/core/lore/` — models, projector, services, storage, pack IO, CCv2
- `lib/presentation/viewmodels/work_lore_viewmodel.dart`
- `lib/widgets/lore/` — Detail panel, HUD, editor/pins/merge sheets
- `lib/screens/lore/global_character_library_screen.dart`
- `test/core/lore/lore_core_test.dart`

## ✅ Done

- Completed: 2026-07-11
- `/init` refresh: lore invariants appended to CLAUDE.md / AGENTS.md
- Moved to `docs/todos/done/`
