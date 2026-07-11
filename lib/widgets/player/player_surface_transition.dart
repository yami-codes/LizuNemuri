import 'package:flutter/material.dart';
import 'package:lizunemu/core/theme/app_animations.dart';
import 'package:lizunemu/screens/player_screen.dart';

/// Hero tag shared by mini player cover and full-screen [CircularCover].
const String kMiniPlayerCoverHeroTag = 'mini-player-cover';

/// Hero tag for track title mini → full.
const String kPlayerTitleHeroTag = 'player-title';

/// Keys for [PlayerSurfaceSwitcher] children.
const ValueKey<String> kPlayerCoverSurfaceKey = ValueKey('cover');
const ValueKey<String> kPlayerLyricsSurfaceKey = ValueKey('lyrics');
const ValueKey<String> kPlayerLoreSurfaceKey = ValueKey('lore');

/// Narrow player center surface: cover art, lyrics, or lore detail.
enum PlayerViewMode { cover, lyrics, lore }

/// Transparent [Material] wrapper so Hero flights do not clip or flash white.
Widget playerHeroFlightShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final target = direction == HeroFlightDirection.push
      ? toHeroContext.widget
      : fromHeroContext.widget;
  return Material(
    color: Colors.transparent,
    child: target,
  );
}

/// Cross-fade + slide between player cover / lyrics / lore on the shared backdrop.
class PlayerSurfaceSwitcher extends StatelessWidget {
  const PlayerSurfaceSwitcher({
    super.key,
    required this.mode,
    required this.coverChild,
    required this.lyricsChild,
    this.loreChild,
  });

  final PlayerViewMode mode;
  final Widget coverChild;
  final Widget lyricsChild;
  final Widget? loreChild;

  @override
  Widget build(BuildContext context) {
    final Widget child;
    switch (mode) {
      case PlayerViewMode.lyrics:
        child = KeyedSubtree(key: kPlayerLyricsSurfaceKey, child: lyricsChild);
      case PlayerViewMode.lore:
        child = KeyedSubtree(
          key: kPlayerLoreSurfaceKey,
          child: loreChild ?? lyricsChild,
        );
      case PlayerViewMode.cover:
        child = KeyedSubtree(key: kPlayerCoverSurfaceKey, child: coverChild);
    }

    return AnimatedSwitcher(
      duration: AppAnimations.long,
      switchInCurve: AppAnimations.smoothScroll,
      switchOutCurve: AppAnimations.exit,
      transitionBuilder: playerSurfaceTransitionBuilder,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      // Tight height so lore/lyrics Column+Expanded can claim the player area.
      child: SizedBox.expand(key: child.key, child: child),
    );
  }
}

Widget playerSurfaceTransitionBuilder(
  Widget child,
  Animation<double> animation,
) {
  final key = child.key;
  final slideDown =
      key == kPlayerLyricsSurfaceKey || key == kPlayerLoreSurfaceKey;
  return FadeTransition(
    opacity: animation,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, slideDown ? 0.12 : -0.12),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: AppAnimations.smoothScroll,
        reverseCurve: AppAnimations.exit,
      )),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1.0).animate(CurvedAnimation(
          parent: animation,
          curve: AppAnimations.smoothScroll,
          reverseCurve: AppAnimations.exit,
        )),
        child: child,
      ),
    ),
  );
}

/// Mini player → full player route: Hero cover continuity, no scaffold flash.
Route<void> createPlayerScreenRoute() {
  return PageRouteBuilder<void>(
    opaque: false,
    barrierColor: Colors.transparent,
    pageBuilder: (context, animation, secondaryAnimation) {
      return const PlayerScreen();
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppAnimations.smoothScroll,
        reverseCurve: AppAnimations.exit,
      );
      return FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
    transitionDuration: AppAnimations.long,
    reverseTransitionDuration: AppAnimations.medium,
  );
}
