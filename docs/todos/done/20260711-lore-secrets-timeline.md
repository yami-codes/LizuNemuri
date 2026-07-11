# Secrets as per-track timeline events

- **Created**: 2026-07-11
- **Owner**: mirai
- **Status**: done

## 1. Goal

> Refactor Generate Secrets so speculative params are seeded as baselines then driven by per-track timestamped events (like normal lore), not a static character-only dump.

## ✅ Done

- Completed at: 2026-07-11 15:25
- `generateSecrets` → seed baselines + per-track speculative events with atMs/endMs
- VM passes subtitle tracks; progress stage `secrets:*`
- CLAUDE.md updated
