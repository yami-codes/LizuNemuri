# Xuro UI Design Spec v4.0 (Reference Mockups · Code-Aligned)

> Visual baseline: user-provided reference mockups (blue-white / black-white / green-white × sidebar / home / player / settings / about — five screens).
> **Reference mockups = this spec = code** must stay aligned. When they conflict, **code wins** — update this spec; do not let the spec drift from reality.
> Design core: as an ASMR audio app, optimize for **calm, immersion, and smoothness**; follow Material 3, but **colors use a custom two-axis system (not `ColorScheme.fromSeed`)**.
>
> v4.0 summary: ① color chapter rewritten from purple `fromSeed` to real `ColorVariant × Brightness` two-axis system; ② components refactored to atom library + 5-screen reuse matrix + three-variant invariant; ③ §7 performance audit table updated to real status (most P0/P1 closed); ④ animation/a11y/responsive/workflow sections kept where still accurate.

---

## Table of Contents

1. [Design Tokens](#1-design-tokens)
2. [Component Standards (Reference Mockups)](#2-component-standards-reference-mockups)
3. [Animation & Micro-interactions](#3-animation--micro-interactions)
4. [Accessibility](#4-accessibility)
5. [Responsive Layout](#5-responsive-layout)
6. [Component Development Rules](#6-component-development-rules)
7. [Performance Guidelines](#7-performance-guidelines)
8. [Development Workflow](#8-development-workflow)

---

## 1. Design Tokens

### 1.1 Color System: Two-Axis (source of truth `lib/core/theme/app_colors.dart`)

Color is determined by **two orthogonal axes**, producing 6 hand-rolled `ColorScheme`s:

```
ThemeMode (light / dark / system)   ×   ColorVariant (blue / mono / green)
        ↑ ThemeController                       ↑ AppSettingsService
```

> ⚠️ **Do not use `ColorScheme.fromSeed`**: it derives secondary/tertiary by hue and breaks the "two-color simplification" intent. Use `AppColors.lightSchemeFor(variant)` / `darkSchemeFor(variant)` instead.

#### Three-variant invariant (reference mockup "three palettes")

> **Same components; only accent pixels differ across the three variants.** Surfaces stay white (light) / near-black (dark); icon/card backgrounds stay neutral gray.
> Only these three tokens rotate with `ColorVariant`; everything else is neutral: `primary`, `onPrimary`, `primaryContainer`.
> Components **must not hardcode colors** — always use `Theme.of(context).colorScheme.*` or §1.2–1.6 tokens.

| Variant | Label (Strings) | Reference subtitle | Light `primary` | Dark `primary` |
| :--- | :--- | :--- | :--- | :--- |
| `blue` | Blue | Fresh · soothing · relaxed | `#0066FF` | `#4D9AFF` |
| `mono` | Mono | Minimal · focused · immersive | `#000000` | `#FFFFFF` |
| `green` | Green | Natural · healing · fresh | `#00A86B` | `#4DD7A1` |

`onPrimary`: all variants — light=white / dark=black.
`primaryContainer` (chip/selected background): blue `#E3EEFF`/`#1A2A4A`, mono `#EEEEEE`/`#2A2A2A`, green `#D8F4E7`/`#1A3A2A`.
Default variant `ColorVariant.blue`; light/dark mode persisted independently.

#### Neutral surfaces & semantic colors (variant-independent)

| Role | Light | Dark | Usage |
| :--- | :--- | :--- | :--- |
| `surface` | `#FFFFFF` | `#1C1B1F` | Base background |
| `onSurface` | `black87` | `#FFFFFF` | Primary text |
| `surfaceContainerHighest` | `#E6E6E6` | `#2B2B2B` | Highest contrast layer / dark card bg |
| Surface L1 (custom token) | `#F7F7F7` | `#1F1F1F` | Containers, mini-player background |
| Surface L2 (custom token) | `#F2F2F2` | `#252525` | Sidebar, search field, dialog background |
| `onSurfaceVariant` | `#49454F` | `#CAC4D0` | Secondary text/icons |
| `outlineVariant` | `#CAC4D0` | `#49454F` | Dividers/strokes |
| `error` | `#B3261E` | `#F2B8B5` | Error state |

> Surface L1/L2 were **implemented and neutralized** in the palette-simplification task (removed old purple tint). Use `AppColors.surfaceL1/L2(brightness)`. Old "not yet implemented" notes are obsolete.

#### Interaction state overlays

| State | Overlay |
| :--- | :--- |
| Hover | Primary 8% |
| Pressed | Primary 12% |
| Focused | Primary 12% + 2px outline |
| Disabled | 38% opacity (uniform; no custom disabled color) |

> Use `.withValues(alpha:)` for opacity (**do not add new `.withOpacity()`**; legacy 25 call sites cleaned in Phase E).

### 1.2 Typography

> Status: `AppTextStyles` is a Phase B token class; until then use `Theme.of(context).textTheme.*` — **no hardcoded `fontSize:` overrides** (violations in `work_info_section.dart` etc. cleaned in Phase C).

| Style | Weight | sp | Line height | Usage |
| :--- | :--- | :--- | :--- | :--- |
| Headline Medium | Medium | 28 | 1.2 | Large titles |
| Title Large | Medium | 22 | 1.3 | AppBar title, player track name |
| Title Medium | Medium | 16 | 1.5 | List titles, card titles, section headers |
| Body Large | Regular | 16 | 1.5 | Primary body |
| Body Medium | Regular | 14 | 1.5 | Secondary description, subtitles |
| Label Medium | Medium | 12 | 1.3 | Labels, buttons, captions |
| Caption | Regular | 10 | 1.2 | Timestamps (e.g. `30:45`), copyright |

### 1.3 Spacing

> Status: `AppSpacing` is a Phase B token class. 4px base grid.

- Tokens: 4 / 8 / 12 / 16 / 20 / 24 / 32 / 40 / 48 / 64
- Page margins: mobile 16, tablet/desktop 24

### 1.4 Border Radius

> Status: `AppRadius` is a Phase B token class. Current `app_theme.dart` card radius hardcoded to 12 (Phase B wires tokens).

| Token | Value | Usage |
| :--- | :--- | :--- |
| Small | 8 | Chips, tooltips |
| Medium | 12 | Work cards, list items |
| Large | 16 | Player sheet, bottom panels, dialogs |
| Full | 999 | Pill buttons, search field, avatar, `AccentPill` |
| Circle | — | Player round cover `CircularCover` (reference mockup) |

### 1.5 Icon System

| Token | dp | Usage |
| :--- | :--- | :--- |
| Inline | 16 | In-body icons |
| List Leading | 20–24 | List leading icons (outlined) |
| Standard | 24 | Standard actions |
| Emphasis | 32 | Play/pause |
| Feature | 48 | Empty states / feature highlights |

- Opacity: active 87% / inactive 60% / disabled 38%. Icons default neutral; **accent only when active**.
- Hit targets: 24px icon → 48×48; 20px → 40×40 (mobile minimum 48×48).

### 1.6 Elevation

- Current `cardTheme.elevation = 0`; light cards may use 1dp separation; **no shadows in dark mode** — depth via surface levels (L1/L2/Highest).
- AppBar: `elevation:0` + `scrolledUnderElevation:0` + `centerTitle:true` (`app_theme.dart`).

---

## 2. Component Standards (Reference Mockups)

### 2.0 Three-Layer Architecture

```
Layer 0  Design tokens   AppColors(two-axis) + AppSpacing/AppRadius/AppTextStyles/AppAnimations
Layer 1  Atoms            Reused across 5 screens × 3 variants; no hardcoded colors; Theme/tokens only
Layer 2  Screen compose   Sidebar/Home/Player/Settings/About layout only
```

### 2.1 Atom × Screen Reuse Matrix

| Atom | Sidebar | Home | Player | Settings | About | Location |
| :--- | :-: | :-: | :-: | :-: | :-: | :--- |
| `BrandWordmark` | ● | | | | ● | `lib/widgets/common/` |
| `AccentPill` | ● | | ● | | | `lib/widgets/common/` |
| `SectionHeader` | | ● | | ● | ● | `lib/widgets/common/` |
| `AppSearchField` | | ● | | | | Extract from `browse_search_bar.dart` |
| `AppListTile` | ● | | | ● | ● | Generalize `settings/widgets/settings_tile.dart` |
| `AppListGroup` | | | | ● | ● | Promote `settings/widgets/settings_group.dart` |
| `CategoryChip` | | ● | | | | Evolve `widgets/common/tag_chip.dart` |
| `WorkCoverCard` | | ● | | | | `widgets/work_card/*` + duration badge |
| `CircularCover` | | | ● | | | `widgets/player/player_cover.dart` |
| `WaveformProgress` | | | ● | | | Replace visual layer of `player_progress.dart` |
| `NowPlayingRow` | | ● | | | | Reuse `widgets/mini_player/*` controls |
| `SidebarDecoration` | ● | | | | | `lib/widgets/sidebar/` |
| `SocialIconRow` | | | | | ● | `lib/widgets/common/` |
| `AppFooter` | | | | | ● | `lib/widgets/common/` |

Reuse rate: Settings/About ≈80% from existing `SettingsGroup`/`SettingsTile` (`.navigation/.toggle/.selection` factories); Home is the largest new composition but built from atoms; Player changes focus on `CircularCover` + `WaveformProgress`.

### 2.2 Five-Screen Layout (reference mockups)

**Sidebar**: top `BrandWordmark`; nav list — selected = `AccentPill` (solid accent + `onPrimary` text + full radius), unselected = text + outlined icon; bottom `SidebarDecoration` (blue/green leaves, mono moon+hills). Mobile width `min(screen×72%, 360px)`, right edge radius 28px; follows existing glassmorphism dark strategy (`lib/widgets/sidebar/`, do not regress).

**Home**: AppBar title + notification bell; `AppSearchField` (full radius, Surface L2); `SectionHeader("Recommended", more>)` + horizontal `WorkCoverCard` strip (medium radius cover + bottom-left duration caption + title); `SectionHeader("Popular categories")` + two-column `CategoryChip` grid (`primaryContainer` soft bg); `SectionHeader("Latest uploads", more>)` + `NowPlayingRow` (small square cover + title + "Now playing" + mini controls).

**Player**: AppBar back + "Player" + favorite + more; track Title Large + subtitle Body Medium + `AccentPill("Follow")`; `CircularCover` (large round cover + thin ring, keep `Hero(tag:'mini-player-cover')`); `WaveformProgress` (waveform + time caption `12:34 / 30:45`, seek logic from `PlayerProgress`); main row `[repeat][prev][large accent play][next][list]`; bottom actions: sleep timer / speed / sound / favorite (icon + label).
> Controls follow **player minimalism**: extend the single control row; no duplicate/ambiguous icons; bottom actions without backend (speed/EQ/timer) are placeholders only — do not invent features to match UI.

**Settings**: AppBar "Settings"; `AppListGroup` sections (accent `SectionHeader`): playback / sound / general; each `AppListTile` = outlined leading + title + trailing (value+`>` / switch / slider). Keep `SettingsTheme.pageBackground` + `noSplashTheme`.

**About**: AppBar back + "About"; centered `BrandWordmark` + "Version Vx.y.z" (`package_info_plus`, not hardcoded); product blurb; `AppListGroup` (terms/privacy/feedback `>` items, reuse 7 `SettingsTile.navigation`); contact + email; `SocialIconRow`; `AppFooter` copyright.

### 2.3 Shared Component Rules

- **Work card**: 1:1 cover; press scale 0.95 (`MicroInteractions.buttonScaleDown`, `WorkCard` TBD Phase E); hover 8% primary overlay.
- **Buttons**: Filled h40 / horizontal 24 / full radius / primary bg; Outlined 1px border transparent bg; Text no bg primary text; IconButton 48×48 target.
- **Mini player**: content 48 + safe area; top 2px `LinearProgressIndicator`(primary); Surface L1 bg; tap/swipe-up Hero expand.
- **List item**: single 56 / double 72 / triple 88; leading 40 (icon) or 56 (thumb); divider 1px `outlineVariant` inset 16; section header Label Medium + accent.
- **Dialog**: width 280–560, padding 24, Surface L2, large radius; title `headlineSmall`, actions right-aligned 8 gap.
- **Chip**: h32 h-pad 12; read-only Surface L2; selected interactive Primary + checkmark; Wrap gap 8.
- **Feedback**: empty centered (280w) icon 64 → title → description → action; errors inline/full-screen/Snackbar(4s+retry)/offline banner. Copy via `NetworkException.userMessage` (connection=VPN hint, 401/403=login), never `e.toString()`.

---

## 3. Animation & Micro-interactions

> Status: `AppAnimations` / `MicroInteractions` live in `lib/core/theme/app_animations.dart` and **match this section**. No hardcoded Duration/Curve in business code.

### 3.1 Curves & Durations (`AppAnimations`)

| Constant | Value | Usage |
| :--- | :--- | :--- |
| `enter` | `easeOutCubic` | Enter: decelerate to stop |
| `exit` | `easeInCubic` | Exit: accelerate away |
| `standard` | `easeInOutCubic` | State changes |
| `emphasis` | `elasticOut` | Emphasis bounce |
| `smoothScroll` | `easeOutQuart` | Lyric scroll / long lists |
| `micro` | 100ms | Ripple, color, opacity |
| `short` | 200ms | Tabs, menus, chips |
| `medium` | 300ms | List enter, card expand, lyric sync |
| `long` | 450ms | Player fullscreen, page routes |

No single animation may exceed 500ms.

### 3.2 Micro-interactions (`MicroInteractions`)

Button press scale 0.95 / opacity 0.8 / 100ms; card elevation +2 (light only) / 150ms; favorite scale→1.3 / 300ms / elasticOut; play icon morph 200ms; pull-to-refresh indicator 40 / trigger 100; slider thumb drag 8 / idle 0 / 150ms.

### 3.3 Page-Level Animation (no custom transitions)

| Scene | Approach | Duration | Curve |
| :--- | :--- | :--- | :--- |
| Main grid enter | Staggered fade-in, first 6 items only, max delay 250ms | 300ms | easeOutCubic |
| Player fullscreen | Hero(cover) + Slide(controls) | 450ms | easeOutCubic |
| Tab switch | Crossfade (no horizontal slide) | 200ms | easeInOut |
| Lyric highlight | Scale 1.0→1.05 + Opacity 0.5→1.0 | 300ms | easeOutCubic |
| Filter panel | AnimatedSlide + AnimatedOpacity | 200ms | easeInOut |
| Skeleton | Opacity pulse 0.3↔0.7 (`SkeletonPulse`, no Shimmer) | 1500ms loop | easeInOut |

### 3.4 Animation Performance

Prefer implicit animations; wrap hot repaints in `RepaintBoundary` (§7.4); never animate width/height/margin (use `Transform`); respect `MediaQuery.disableAnimations` (zero Duration when true); ≤3 non-looping animations per screen; `const` Tween/Duration/Offset; `TickerProviderStateMixin` on multi-animation screens.

---

## 4. Accessibility

- Contrast: body text ≥4.5:1, large text (18pt+) ≥3:1.
- Touch targets: mobile minimum 48×48.
- Reduced motion: `MediaQuery.disableAnimations` → all Duration zero.
- Screen readers: all `IconButton` / images need `semanticLabel`.
- Focus: 2px primary outline, 2px offset.

---

## 5. Responsive Layout

| Breakpoint | Layout | Grid columns | Gap |
| :--- | :--- | :--- | :--- |
| < 800 (Mobile) | Bottom nav | 2 | 8 |
| 800–1200 (Tablet) | Bottom nav / sidebar | 3 | 12 |
| ≥ 1200 (Desktop) | Fixed side nav | 4 | 16 |

---

## 6. Component Development Rules

### 6.1 Splitting

- `build()` >80 lines → extract child widgets; prefer `StatelessWidget`; ≤3 public widgets per file.

### 6.2 Naming

Screen→`XxxScreen`; ViewModel→`XxxViewModel`; reusable→`XxxWidget`/`XxxView`; interface→`IXxxService`; impl→`XxxService`; Freezed→`Xxx`/`XxxModel`.

### 6.3 Provider

Precise listen via `context.select<T,R>()`; methods via `context.read`; **never wrap large trees in `context.watch`**.

### 6.4 Strings

All user-visible copy in `lib/common/constants/strings.dart` — **no hardcoded UI Chinese** (logs/debug exempt). ~60–90 legacy UI violations closed in Phase E.

---

## 7. Performance Guidelines

### 7.1 Audit Status (measured 2026-05-16; old table largely stale)

| Item | File | Status |
| :--- | :--- | :--- |
| PlayerViewModel 60Hz progress rebuild (was P0) | `player_viewmodel.dart` | ✅ **Closed**: UI `.throttleTime(200ms)` + subtitle full precision without notify (:78-98) |
| `work_row.dart` IntrinsicHeight (was P1) | `work_row.dart` | ✅ **Closed**: zero `IntrinsicHeight` in repo; `Row+Expanded` |
| Shimmer frame cost (was P1) | multiple | ⚠️ **Mostly closed** (`SkeletonPulse` + `RepaintBoundary`); residual `shimmer` dep + `work_files_skeleton.dart` → Phase E |
| `groupWorksIntoRows` per-build (was P1) | `work_layout_strategy.dart:35` | ❌ **Open**: no memo, called from `work_grid.dart:21` build → Phase E |
| `PlaybackEventHub` throttle (was P0) | `playback_event_hub.dart` | ◐ `playbackProgress` custom `.distinct(position)`; `playbackState.distinct()` relies on `PlaybackStateEvent` `==/hashCode` — verify at runtime |

### 7.2 State Management Performance

notifyListeners: UI ≤30/s; progress throttle 200ms; subtitles notify only on line change. Fine-grained Provider + `context.select`. No `addPostFrameCallback`/`Timer`/heavy work inside `build()`.

### 7.3 Lists & Scrolling

Mandatory `*.builder`; no Column/Row spread for long lists; avoid `IntrinsicHeight` (fixed height/AspectRatio/LayoutBuilder); memoize grid grouping; images via `CachedNetworkImage` with explicit w/h to prevent CLS.

### 7.4 RepaintBoundary

Wrap: MiniPlayer, PlayerProgress, active lyric line, custom `AnimationController` widgets. Do not wrap static widgets or whole pages. Add only after Repaint Rainbow confirms hotspots.

### 7.5 Memory

Subscribe streams in initState / cancel in dispose; central `List<StreamSubscription>` + try-catch; cancel all Timers in dispose; prefer RxDart throttle/debounce; Controller lifecycle aligned with initState/dispose + `@mustCallSuper`.

### 7.6 Pre-Release Performance Check (Profile mode, not debug)

Main list scroll ≥55fps; player animation ≥55fps; cold start first frame <2s (release); tab switch <300ms; cold start memory <150MB; 30min playback no leaks.

---

## 8. Development Workflow

> Authoritative doc: [`dev_workflow.md`](dev_workflow.md) (mandatory: TODO → develop → `/init`). This section is a summary; on conflict, `dev_workflow.md` wins.

- After Freezed changes under `lib/data/models/`: run `dart run build_runner build --delete-conflicting-outputs`, commit generated files, never hand-edit.
- Before commit: `flutter analyze` (no new warnings) → `flutter test` (all pass) → `dart format lib/`.
- Profile performance in Profile/Release — **not debug FPS**.
- Doc priority: `dev_workflow > subsystem docs > this spec > guidelines`. Visual judgment defers to reference mockups.
