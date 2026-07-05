import 'package:flutter/material.dart';
import 'package:lizunemu/core/theme/player_hue_derivation.dart';
import 'package:lizunemu/widgets/player/cover_artwork_backdrop_style.dart';
import 'package:lizunemu/widgets/player/player_cover_palette_loader.dart';

/// Lyric / chrome colors for immersive player backdrop.
class PlayerImmersiveColors {
  const PlayerImmersiveColors({
    required this.activeLyric,
    required this.inactiveLyric,
    required this.accentStrong,
    required this.backdropTint,
    required this.enabled,
  });

  final Color activeLyric;
  final Color inactiveLyric;
  final Color accentStrong;
  final Color backdropTint;
  final bool enabled;

  static PlayerImmersiveColors resolve({
    required BuildContext context,
    required PlayerHuePalette palette,
    required bool coverBackgroundEnabled,
    double clarity = kPlayerCoverBackdropClarity,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!coverBackgroundEnabled) {
      return PlayerImmersiveColors(
        activeLyric: cs.primary,
        inactiveLyric: cs.onSurface.withValues(alpha: 0.7),
        accentStrong: cs.primary,
        backdropTint: cs.surface,
        enabled: false,
      );
    }

    final backdropEstimate = estimateLyricBackdropColor(
      backdropTintColor: palette.backdropTint,
      backgroundColor: cs.surface,
      coverBackgroundEnabled: true,
      coverBackgroundClarity: clarity,
      isDark: isDark,
    );
    final activeText = pickReadableLyricTextColor(
      backdrop: backdropEstimate,
      fallback: cs.onSurface,
    );
    final inactiveText = inactiveLyricTextColor(
      activeText: activeText,
      fallback: cs.onSurfaceVariant,
    );

    return PlayerImmersiveColors(
      activeLyric: activeText,
      inactiveLyric: inactiveText,
      accentStrong: palette.primaryStrong,
      backdropTint: palette.backdropTint,
      enabled: true,
    );
  }
}

class PlayerImmersiveScope extends InheritedWidget {
  const PlayerImmersiveScope({
    super.key,
    required this.colors,
    required super.child,
  });

  final PlayerImmersiveColors colors;

  static PlayerImmersiveColors? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PlayerImmersiveScope>()
        ?.colors;
  }

  @override
  bool updateShouldNotify(PlayerImmersiveScope oldWidget) {
    return colors != oldWidget.colors;
  }
}
