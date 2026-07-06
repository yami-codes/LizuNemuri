# ASMR.one Search Command Syntax

This document describes the **search command language** used by asmr.one and implemented in Lizunemu's advanced search field. Commands are typed in the search bar as `$key:value$` tokens (space-separated). Multiple tokens combine with AND semantics.

---

## 1. Token format

```
$<command>:<value>$
```

| Part | Rule |
|------|------|
| `$` | Opening delimiter — triggers autocomplete in Lizunemu |
| `<command>` | Filter key (see §2). Prefix `-` means **exclude / reverse** |
| `<value>` | Filter-specific value (tag name, age key, duration, price, …) |
| Closing `$` | Required — marks end of token |

**Examples**

```
$tag:Binaural$ $age:r15$ sleep
$-tag:AI$ $duration:1h$
```

Free text outside tokens is treated as a **keyword** search and appended after filter tokens in the composed `/search/{keyword}` path segment.

---

## 2. Commands reference

### Include filters

| Command | Description | Example |
|---------|-------------|---------|
| `$tag:` | Include works with tag | `$tag:ASMR$` |
| `$tagw:` | Include low-vote tags | `$tagw:RareTag$` |
| `$circle:` | Filter by circle (brand) | `$circle:Whisp$` |
| `$va:` | Filter by voice actor | `$va:Name$` |
| `$duration:` | Duration **greater than** value | `$duration:20m$`, `$duration:1.2h$` |
| `$rate:` | Rating **greater than** value | `$rate:4.5$` |
| `$price:` | Price **greater than** (JPY) | `$price:100$` |
| `$sell:` | Sales count **greater than** | `$sell:1000$` |
| `$age:` | Age rating only | `$age:general$`, `$age:r15$`, `$age:adult$` |
| `$lang:` | Language filter | `$lang:ja$` |

### Exclude filters (reverse)

Prefix the command with `-` inside the token:

| Command | Description | Example |
|---------|-------------|---------|
| `$-tag:` | Exclude tag | `$-tag:AI$` |
| `$-tagw:` | Exclude low-vote tag | `$-tagw:Foo$` |
| `$-circle:` | Exclude circle | `$-circle:Bar$` |
| `$-va:` | Exclude voice actor | `$-va:Baz$` |
| `$-duration:` | Duration **less than** value | `$-duration:1h$` |
| `$-age:` | Exclude age rating | `$-age:adult$` |
| `$-lang:` | Exclude language | `$-lang:en$` |

---

## 3. Value formats

### Age (`$age:` / `$-age:`)

| Value | Meaning |
|-------|---------|
| `general` | All-ages (一般) |
| `r15` | R-15 |
| `adult` | R-18 / adult |

### Duration (`$duration:` / `$-duration:`)

| Unit | Example |
|------|---------|
| Minutes | `20m`, `30m`, `40m`, `50m` |
| Hours | `1h`, `1.2h` |

Include = works **longer than** threshold. Exclude = works **shorter than** threshold.

### Price (`$price:`)

Common presets (JPY): `100`, `300`, `500`, `700`, `1000`, `2000`.

Include = price **greater than** value. `$-price:` reverses (exclude / less than).

---

## 4. Lizunemu UI behavior

### 4.1 Advanced search field

- Complete tokens render as **removable chips** inside the search bar (see reference mockups).
- Typing `$` opens the **command list** autocomplete.
- After `$tag:` (etc.), autocomplete shows **value suggestions** (tags from `/tags/`, age presets, duration/price presets).
- **Advanced search** entry opens the full Search screen from Home.
- Clear (×) removes all tokens and draft text.

### 4.2 Tag chips on work cards

| Gesture | Action |
|---------|--------|
| **Tap tag** | Add tag to **include** filter (`$tag:name$`) |
| **Long-press tag** | Sheet: **Include filter** or **Exclude filter** (`$-tag:name$`) |

**Display language:** When app language is **Chinese**, tag labels use zh-CN from API `i18n`. For **English, Thai, or system non-Chinese**, labels prefer **English** (`en-us`). The API filter key is always the canonical `name` field, never the localized label.

### 4.3 Filter bar (Home / Hot / Search)

- Include tags → green/neutral chips + `$tag:` tokens
- Exclude tags → red-outline chips + `$-tag:` tokens
- Tag / age / sort / subtitle combine into one `/search/{keyword}` request when any command filter is active.

---

## 5. API transport

All tokens are sent as a **single path segment**:

```
GET /api/search/{keyword}?page=1&order=…&sort=…&subtitle=0|1&includeTranslationWorks=true
```

`keyword` = space-joined tokens + optional free text.

**Encoding:** Tag names may contain `/` (e.g. `巨乳/爆乳`). Lizunemu builds the URI via `ApiService.buildSearchUri` (path segments), never string-concatenated paths.

---

## 6. Implementation map

| Concern | Location |
|---------|----------|
| Parse / compose tokens | `lib/presentation/models/search_command_parser.dart` |
| Autocomplete logic | `lib/presentation/models/search_command_suggestions.dart` |
| Chip search field UI | `lib/widgets/search/search_command_field.dart` |
| Filter state (include/exclude tags) | `lib/presentation/models/filter_state.dart` |
| Keyword builder | `lib/presentation/models/work_list_query_builder.dart` |
| Tag display locale | `lib/utils/tag_display_name.dart` |
| URL builder | `lib/data/services/api_service.dart` |

---

## 7. Out of scope (current)

- Embedded MKV subtitles / video-only filters
- Circle / VA inline autocomplete from live lists (deep links use `$circle:` / `$va:` strings)
- Recommend / Similar list command syntax (subtitle-only API)

---

## 8. References

- `docs/schema/api_contracts.md` — locked endpoint notes
- `docs/todos/active/20260706-search-command-autocomplete.md` — implementation task
- asmr.one web client — reference UX for `$` autocomplete and chip rendering
