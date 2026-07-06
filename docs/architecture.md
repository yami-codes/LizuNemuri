# ASMR Music App Architecture

## Directory Structure

<pre>
lib/
├── main.dart              # Application entry
├── screens/              # Screens
│   ├── home_screen.dart   # Home (music list)
│   ├── player_screen.dart # Player screen
│   └── detail_screen.dart # Detail screen
├── widgets/              # Reusable widgets
│   └── drawer_menu.dart   # Side drawer menu
└── models/              # Data models (TBD)
    └── music.dart        # Music model (TBD)
</pre>

## Main Feature Modules

1. Home (HomeScreen)
   - Music list
   - Search
   - Side drawer access

2. Player (PlayerScreen)
   - Playback controls
   - Progress bar
   - Volume control

3. Detail (DetailScreen)
   - Track/work details
   - Comments (TBD)
   - Favorites (TBD)

4. Side Drawer (DrawerMenu)
   - Home navigation
   - Favorites list
   - Settings

## Tech Stack

- Flutter SDK
- Material Design 3
- Routing: Flutter built-in navigation
- State management: TBD

## Development Plan

1. Phase 1: Foundation
   - [x] Basic page structure
   - [x] Page navigation
   - [x] Side drawer

2. Phase 2: UI
   - [ ] Music list UI
   - [ ] Player UI
   - [ ] Detail UI

3. Phase 3: Features
   - [ ] Playback
   - [ ] Search
   - [ ] Favorites

4. Phase 4: Polish
   - [ ] Performance
   - [ ] UI/UX improvements
   - [ ] Refactoring

## Notes

1. Code style
   - Use const constructors
   - Follow official Flutter style
   - Add comments where needed

2. Performance
   - Use StatelessWidget and StatefulWidget appropriately
   - Avoid unnecessary rebuilds
   - Optimize image assets

3. User experience
   - Loading indicators
   - Error handling and messaging
   - Sensible transition animations
