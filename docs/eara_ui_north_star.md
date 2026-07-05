# Eara UI North Star (locked)

> **Source:** `/grill-me` answers — 2026-07-05  
> **Reference app:** [EaraAsmrPlayer](https://github.com/moyucc/EaraAsmrPlayer)  
> **Status:** product direction — supersedes older “asmr.one-only / skip DLsite / keep 3 color variants” assumptions **where this doc conflicts**.

---

## Your choices (verbatim mapping)

| # | Question | Your pick | Meaning |
|---|----------|-----------|---------|
| 1 | Scope of Eara visual port | **D** | **Full app reskin** — all main tabs at Eara density |
| 2 | Color philosophy | **D** | **Always Monet-from-cover** — drop blue/mono/green variant picker |
| 3 | Navigation | **B** | **Eara bottom bar** (Library / Search / Hot) + drawer for the rest |
| 4 | Player layout | **D** | Full-screen **player ↔ lyrics** toggle with **shared backdrop** |
| 5 | Mini → full motion | **D** | **Eara-level motion** — polish over speed |
| 6 | Lyrics | **B** | **Apple-style kinetic** centered scroll |
| 7 | UI stack | **A** | Stay **Flutter Material 3** (no Compose platform views) |
| 8 | Audio stack | **C** | **Evaluate Flutter audio plugins** if they unlock EQ/spectrum |
| 9 | Library home | **C** | **Full local scan library** like Eara |
| 10 | Search sources | **C** | **DLsite integration** (eventually) |
| 11 | Tradeoffs | **A+B+C** | Slower roadmap; **Eara wins over old reference spec**; **Android may look better** than iOS |
| 12 | First milestone | **A** | **Player motion + shared backdrop + lyrics page toggle** |

---

## What this means in plain language

You want Xuro to **feel like Eara**, not “Xuro with a blurred cover.” That implies:

1. **Visual system change** — accent color comes from **now-playing / dominant cover art** (Monet), not a user-picked blue/mono/green theme.
2. **Information architecture change** — home becomes **local library–centric** (scan + tags), discovery moves to **Search + Hot**, with a drawer for playlists, settings, downloads, etc.
3. **Player as a stage** — one continuous immersive surface; lyrics are a **mode** of the same scene, not a separate flat screen.
4. **Product scope expansion** — **DLsite** and **folder library** join asmr.one (long-horizon; legal/ToS review required).
5. **Audio** — stay Flutter-first, but **research plugins** (or Android-first native modules) for ear-FX; Media3 itself is **not** an option (Android-only, no UI).

---

## Media3 vs Flutter (decision record)

| | Media3 (Eara) | Xuro path (locked) |
|---|---------------|-------------------|
| Cross-platform | ❌ Android only | ✅ Flutter UI everywhere |
| UI | ❌ None | Flutter Material 3 |
| Deep EQ / spectrum / balance | ✅ PCM processors | 🔍 **Evaluate plugins** (8C); fallback Android-first |
| asmr.one API | Secondary | ✅ Primary + mirrors |
| LLM subtitles | ❌ | ✅ Keep |

**Do not rewrite Xuro in Kotlin for Media3.** Port **patterns**; replicate **audio graph** only where Flutter ecosystem allows.

---

## Conflicts with current Xuro (must plan migrations)

| Current | North star | Migration |
|---------|------------|-----------|
| `ColorVariant` × `ThemeMode` (`docs/ui-design-spec.md` v4) | Monet-only dynamic accent | Deprecate variant picker; global `DynamicHueController` from cover; update/remove `atom_three_variant_test` |
| Bottom tabs: Favorites / Home / Recommend / Popular | Library / Search / Hot | `MainScreen` destinations + drawer map |
| Online-first home | Local scan library first | New `LibraryViewModel`, scan roots, SQLite album model |
| `PlayerScreen` cover/lyrics toggle in-column | Shared backdrop + motion between surfaces | Milestone A |
| `docs/inspiration_eara.md` “out of scope” DLsite/local | **In scope** | This doc supersedes |

---

## Phased roadmap (order matters)

### Milestone A — **Player shell** (your 12A — do first)

**Goal:** Eara-grade player ↔ lyrics on one backdrop with real motion.

- Shared cover backdrop: mini player → full player (hero / fade-slide per Eara `NowPlayingMotion`)
- Player surface ↔ lyrics surface: same `CoverArtworkBackground` + palette, animated transition
- Backdrop clarity control (settings slider; today hardcoded)
- **Not in A:** kinetic lyrics (that's 6B — milestone B)

**Eara refs:** `NowPlayingScreen.kt`, `NowPlayingMotion.kt`, `PlayerSharedBackdrop.kt`, `LyricsPage.kt`

**Xuro touch:** `player_screen.dart`, `cover_artwork_background.dart`, `mini_player`, new `player_surface_transition.dart`

---

### Milestone B — **Kinetic lyrics** (6B)

- Center-active line, smooth follow, readable colors on backdrop
- **Eara ref:** `AppleLyricsView.kt`, `LyricReadableColors.kt`

---

### Milestone C — **Global Monet theme** (2D)

- App-wide accent/surfaces derived from **current or last cover** (or neutral idle seed)
- Remove `ColorVariant` settings UI; migration for prefs
- Update `ui-design-spec.md` §1 (major version bump)

---

### Milestone D — **Navigation** (3B)

- Bottom: **Library | Search | Hot**
- Drawer: Favorites, Playlists, Downloads, Settings, About, …
- Mini player stays above `NavigationBar` (Eara `BottomChrome` pattern)

---

### Milestone E — **Full reskin** (1D)

- Search chips, settings grouping, cards, typography density on **all** main tabs
- Screen-by-screen parity pass vs Eara screenshots

---

### Milestone F — **Local library** (9C)

- Scan roots, album grid/list, tags, FTS, ingest downloaded folders
- **Eara refs:** `LibraryScreen.kt`, `libraryviewmodel.kt`, `ScanRootsStore.kt`

---

### Milestone G — **DLsite** (10C) ✅

- Cookie auth + Play library list + stream play (`lib/core/dlsite/`, drawer entry)
- **Deferred:** WebView login, scraper path, asmr.one RJ enrichment
- **Eara refs:** `DlsiteLoginScreen.kt`, `DLSiteScraper.kt`, `DlsitePlayLibraryClient.kt`

---

### Milestone H — **Audio plugin evaluation** (8C) ✅

- **Decision:** `just_audio` `AndroidEqualizer` v1 — see `docs/audio_plugin_evaluation.md`
- Shipped: `AudioEffectsController` + equalizer sheet (Android-gated)
- **Deferred:** balance, spectrum, reverb (phase 2 Media3 spike)

---

## How to get “native Material god-tier” in Flutter (7A)

You **cannot** use Compose Material 3 directly. You **can** match Eara by copying **tokens and motion**, not widgets:

| Eara (Compose M3) | Flutter equivalent |
|-------------------|-------------------|
| `MaterialTheme` + dynamic color | `ThemeData` + `ColorScheme` from `palette_generator` / `player_hue_derivation.dart` |
| `NavigationBar` + tonal icons | `NavigationBar` (already in `MainScreen`) |
| `FilterChip` / `SuggestionChip` | `FilterChip`, `ChoiceChip` |
| `Surface` tonal elevation 0 | `Card` + `colorScheme.surfaceContainer*` |
| Shared element transition | `Hero` + custom `PageRouteBuilder` / `animations` package |
| `AppleLyricsView` physics | `ScrollablePositionedList` + custom snap + `AppAnimations` |

**Rule:** When Eara and old Xuro reference images disagree, **Eara wins** (your 11B).

---

## Success criteria (milestones A–E)

- [ ] Mini → full player feels like **one object** expanding, not a new route
- [ ] Lyrics toggle does **not** flash a flat `surface` background
- [ ] Readable lyrics on any cover (contrast guard from `pickReadableLyricTextColor`)
- [ ] Monet accent updates when track/cover changes (global after milestone C)
- [ ] Bottom nav matches Eara **three-tab** mental model (after milestone D)

---

## Non-goals (still)

- Rewriting UI in Jetpack Compose
- Media3 as cross-platform playback core
- Listen-together social backend (unless explicitly requested later)

---

## Related docs

- [`docs/inspiration_eara.md`](inspiration_eara.md) — feature inventory + Kotlin map
- [`docs/ui-design-spec.md`](ui-design-spec.md) — **will need v5** after milestone C (Monet-only)
- Active implementation: [`docs/todos/active/20260705-eara-player-motion-milestone.md`](todos/active/20260705-eara-player-motion-milestone.md)
