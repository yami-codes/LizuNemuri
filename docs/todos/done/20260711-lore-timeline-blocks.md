# Lore timeline blocks + per-track editor UI

- **Created**: 2026-07-11
- **Owner**: mirai
- **Status**: done
- **Related Issue / PR**:

---

## 1. Goal

> Make lore param changes span/interpolate like video-editor clips on a per-track timeline, with discrete-change effects, and stop the broken mixed all-tracks event dump.

## 2. Scope

**In scope:**
- `endMs` on events + projector span interpolation (numeric) / hold-then-snap (status)
- Primary-track ordering (ignore remaster duplicates in prior carry)
- Player Lore tab: per-track block timeline + playhead + pulse on status change
- Detail lore timeline grouped by track (not flat mixed list)
- LLM prompt hint for `endMs`; tests

**Out of scope:**
- Regenerating existing packs
- Multi-character lane editing tools

## 3. Acceptance

- [x] Mid-span gauge values lerp between from→to
- [x] Discrete/status deltas snap with a visible pulse
- [x] Player timeline shows only the current track’s blocks
- [x] Detail timeline grouped per track
- [x] Prior-track carry ignores no-SFX remaster duplicates
- [x] Tests + analyze clean

## 4. Steps

- [x] **Step 1**: Model `endMs` + projector interpolation + primary keys
- [x] **Step 2**: Player block timeline UI + param pulse
- [x] **Step 3**: Detail panel group-by-track + LLM prompt
- [x] **Step 4**: Tests / analyze / CLAUDE.md / done

## 5. Risks

- **Risk**: Old packs without `endMs` use a short default ramp — values mid-event differ from old snap-at-atMs
- **Rollback**: Revert projector + panel widgets

## 6. Notes / Decision Log

> Default ramp = min(2500ms, nextEvent.atMs - atMs) when `endMs`/`evidenceEndMs` absent. Existing packs still get smooth ramps via evidenceEndMs or default.

---

## ✅ Done

- Completed at: 2026-07-11 12:20
- Command run: `/init` (manual CLAUDE.md span/timeline note)
- CLAUDE.md update summary: Documented span lerp, status pulses, primaryTrackKeys, per-track timeline UI.
- Related commit: (pending user commit)
