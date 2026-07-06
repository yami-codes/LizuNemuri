# API Contracts (Locked)

## New Endpoints

| Endpoint | Method | Auth | Response Model |
|------|------|------|----------|
| /api/tags/ | GET | No | List&lt;TagItem&gt; |
| /api/circles/ | GET | No | List&lt;CircleItem&gt; |
| /api/vas/ | GET | No | List&lt;VoiceActor&gt; |
| /api/workInfo/{id} | GET | No | WorkInfo |

## Parameter Upgrades

| Endpoint | Change |
|------|------|
| GET /api/tracks/{id} | v=1 → v=2 |
| GET /api/search/{keyword} | Added includeTranslationWorks (already implemented in code) |
| GET /api/playlist/get-playlists | Added filterBy, pageSize |

## Search Syntax Extensions
- `$tag:tag-name$` — filter by tag
- `$-tag:tag-name$` — exclude tag
- `$circle:circle-name$` — filter by circle
- `$va:voice-actor-name$` — filter by voice actor
- `$age:general$` / `$age:r15$` / `$age:adult$` — age rating
- `$duration:20m$` / `$price:100$` — numeric filters (see `docs/search_command_syntax.md`)
