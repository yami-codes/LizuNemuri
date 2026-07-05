import 'package:flutter/material.dart';
import 'package:xuro/core/theme/app_animations.dart';
import 'package:xuro/screens/player_screen.dart';

/// Hero tag shared by mini player cover and full-screen [CircularCover].
const String kMiniPlayerCoverHeroTag = 'mini-player-cover';

/// Hero tag for track title mini → full.
const String kPlayerTitleHeroTag = 'player-title';

/// Keys for [PlayerSurfaceSwitcher] children.
const ValueKey<String> kPlayerCoverSurfaceKey = ValueKey('cover');
const ValueKey<String> kPlayerLyricsSurfaceKey = ValueKey('lyrics');

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

/// Cross-fade + slide between player cover and lyrics on the shared backdrop.
class PlayerSurfaceSwitcher extends StatelessWidget {
  const PlayerSurfaceSwitcher({
    super.key,
    required this.showLyrics,
    required this.coverChild,
    required this.lyricsChild,
  });

  final bool showLyrics;
  final Widget coverChild;
  final Widget lyricsChild;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppAnimations.medium,
      switchInCurve: AppAnimations.smoothScroll,
      switchOutCurve: AppAnimations.exit,
      transitionBuilder: playerSurfaceTransitionBuilder,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: showLyrics
          ? KeyedSubtree(key: kPlayerLyricsSurfaceKey, child: lyricsChild)
          : KeyedSubtree(key: kPlayerCoverSurfaceKey, child: coverChild),
    );
  }
}

Widget playerSurfaceTransitionBuilder(
  Widget child,
  Animation<double> animation,
) {
  final isLyrics = child.key == kPlayerLyricsSurfaceKey;
  return FadeTransition(
    opacity: animation,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, isLyrics ? 0.08 : -0.08),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: AppAnimations.smoothScroll,
        reverseCurve: AppAnimations.exit,
      )),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1.0).animate(CurvedAnimation(
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
