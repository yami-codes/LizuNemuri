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
    Widget host({required PlayerViewMode mode}) => MaterialApp(
          home: Scaffold(
            body: PlayerSurfaceSwitcher(
              mode: mode,
              coverChild: const Text('cover', key: ValueKey('cover-text')),
              lyricsChild: const Text('lyrics', key: ValueKey('lyrics-text')),
              loreChild: const Text('lore', key: ValueKey('lore-text')),
            ),
          ),
        );

    testWidgets('shows cover surface by default', (tester) async {
      await tester.pumpWidget(host(mode: PlayerViewMode.cover));
      expect(find.text('cover'), findsOneWidget);
      expect(find.text('lyrics'), findsNothing);
    });

    testWidgets('cross-fades to lyrics surface', (tester) async {
      await tester.pumpWidget(host(mode: PlayerViewMode.cover));
      await tester.pumpWidget(host(mode: PlayerViewMode.lyrics));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('lyrics'), findsOneWidget);
    });

    testWidgets('cross-fades to lore surface', (tester) async {
      await tester.pumpWidget(host(mode: PlayerViewMode.cover));
      await tester.pumpWidget(host(mode: PlayerViewMode.lore));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('lore'), findsOneWidget);
    });
  });

  group('playerSurfaceTransitionBuilder', () {
    testWidgets('builds without throwing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: playerSurfaceTransitionBuilder(
              const KeyedSubtree(
                key: kPlayerLyricsSurfaceKey,
                child: Text('x'),
              ),
              const AlwaysStoppedAnimation(1),
            ),
          ),
        ),
      );
      expect(find.text('x'), findsOneWidget);
      expect(AppAnimations.long.inMilliseconds, greaterThan(0));
    });
  });
}
