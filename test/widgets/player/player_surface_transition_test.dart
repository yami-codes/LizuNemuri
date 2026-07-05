import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/theme/app_animations.dart';
import 'package:lizunemu/widgets/mini_player/mini_player_cover.dart';
import 'package:lizunemu/widgets/player/player_art_panel.dart';
import 'package:lizunemu/widgets/player/player_surface_transition.dart';

void main() {
  group('player hero tag contract', () {
    test('cover hero tag is stable', () {
      expect(kMiniPlayerCoverHeroTag, 'mini-player-cover');
    });

    test('title hero tag is stable', () {
      expect(kPlayerTitleHeroTag, 'player-title');
    });

    test('mini and full player widgets exist for hero endpoints', () {
      expect(MiniPlayerCover.new, isNotNull);
      expect(PlayerArtPanel.new, isNotNull);
    });
  });

  group('PlayerSurfaceSwitcher', () {
    Widget host({required bool showLyrics}) => MaterialApp(
          home: Scaffold(
            body: PlayerSurfaceSwitcher(
              showLyrics: showLyrics,
              coverChild: const Text('cover', key: ValueKey('cover-text')),
              lyricsChild: const Text('lyrics', key: ValueKey('lyrics-text')),
            ),
          ),
        );

    testWidgets('shows cover surface by default', (tester) async {
      await tester.pumpWidget(host(showLyrics: false));
      expect(find.text('cover'), findsOneWidget);
      expect(find.text('lyrics'), findsNothing);
    });

    testWidgets('cross-fades to lyrics surface', (tester) async {
      await tester.pumpWidget(host(showLyrics: false));
      await tester.pumpWidget(host(showLyrics: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('lyrics'), findsOneWidget);
    });
  });

  group('createPlayerScreenRoute', () {
    test('route is non-opaque for backdrop continuity', () {
      final route = createPlayerScreenRoute();
      expect(route, isA<PageRoute<void>>());
      expect((route as PageRoute<void>).opaque, isFalse);
      expect(route.transitionDuration, AppAnimations.long);
    });
  });
}
