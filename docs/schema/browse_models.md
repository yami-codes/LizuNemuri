# Browse List Model Schema (Locked)

## TagItem — Tag list entry
- Endpoint: `GET /api/tags/`
- Response: `List<TagItem>`

| Field | Type | Description |
|------|------|------|
| id | int | Tag ID |
| name | String | Tag name |
| count | int | Related work count |
| i18n | I18n? | i18n translations; reuses existing I18n |

## CircleItem — Circle list entry
- Endpoint: `GET /api/circles/`
- Response: `List<CircleItem>`

| Field | Type | Description |
|------|------|------|
| id | int | Circle ID |
| name | String | Circle name |
| count | int | Work count |
| i18n | I18n? | i18n (API currently returns `{}`, mapped to null) |

## VoiceActor — Voice actor list entry
- Endpoint: `GET /api/vas/`
- Response: `List<VoiceActor>`

| Field | Type | Description |
|------|------|------|
| id | String | UUID format |
| name | String | Voice actor name |
| count | int | Work count |
| i18n | I18n? | i18n (API currently returns `{}`, mapped to null) |
