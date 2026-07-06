# Material You player + search/tag fixes

- **Created**: 2026-07-06
- **Status**: active

## Goal

Replace Apple Music player chrome with Material 3, fix subtitle dual-line/kinetic bugs, readable tags, debounced persistent search, English `$tag:` suggestions.

## Plan

- [x] Player M3 surface (no glass/blur backdrop) — `lib/screens/player_screen.dart`
- [x] Lyrics: single active line, M3 pill, translation-only default — `lyric_line.dart`, `player_lyric_view.dart`, `app_settings_service.dart`
- [x] Search debounce + keyword persist + restore — `search_viewmodel.dart`, `search_screen.dart`
- [x] Tag chip contrast + EN `$tag:` autocomplete — `search_command_field.dart`, `search_command_suggestions.dart`, `advanced_filter_bar.dart`, `work_tags_panel.dart` (already readable)
- [x] Translation partial success — `detail_viewmodel.dart`
- [x] Tests — lyric + search suggestion tests updated/added
