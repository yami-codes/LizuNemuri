import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:xuro/core/di/service_locator.dart';
import 'package:xuro/core/image/cache/image_cache_manager.dart';
import 'package:xuro/core/settings/app_settings_service.dart';
import 'package:xuro/widgets/common/skeleton_pulse.dart';
import 'package:xuro/widgets/player/cover_artwork_backdrop_style.dart';

/// Full-bleed blurred cover backdrop with Monet tint layers (Eara-style).
///
/// [clarity] is kept for call-site compatibility; live value comes from
/// [AppSettingsService.playerBackdropClarity].
class CoverArtworkBackground extends StatelessWidget {
  const CoverArtworkBackground({
    super.key,
    required this.coverUrl,
    required this.enabled,
    required this.clarity,
    required this.overlayBaseColor,
    required this.tintBaseColor,
    required this.isDark,
  });

  final String? coverUrl;
  final bool enabled;
  final double clarity;
  final Color overlayBaseColor;
  final Color tintBaseColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final settings = getIt<AppSettingsService>();
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return _CoverArtworkBackgroundBody(
          coverUrl: coverUrl,
          enabled: enabled,
          clarity: settings.playerBackdropClarity,
          overlayBaseColor: overlayBaseColor,
          tintBaseColor: tintBaseColor,
          isDark: isDark,
        );
      },
    );
  }
}

class _CoverArtworkBackgroundBody extends StatelessWidget {
  const _CoverArtworkBackgroundBody({
    required this.coverUrl,
    required this.enabled,
    required this.clarity,
    required this.overlayBaseColor,
    required this.tintBaseColor,
    required this.isDark,
  });

  final String? coverUrl;
  final bool enabled;
  final double clarity;
  final Color overlayBaseColor;
  final Color tintBaseColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return ColoredBox(color: overlayBaseColor);
    }

    final style = coverArtworkBackdropStyle(
      clarity: clarity,
      isDark: isDark,
    );

    final baseBackdrop = Color.alphaBlend(
      tintBaseColor.withValues(alpha: style.baseTintAlpha),
      overlayBaseColor,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: overlayBaseColor),
        if (style.baseTintAlpha > 0) ColoredBox(color: baseBackdrop),
        if (coverUrl != null && style.artworkAlpha > 0)
          Opacity(
            opacity: style.artworkAlpha,
            child: ImageFiltered(
              imageFilter: style.blurSigma > 0
                  ? ImageFilter.blur(
                      sigmaX: style.blurSigma,
                      sigmaY: style.blurSigma,
                      tileMode: TileMode.clamp,
                    )
                  : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: CachedNetworkImage(
                imageUrl: coverUrl!,
                fit: BoxFit.cover,
                cacheManager: ImageCacheManager.instance,
                placeholder: (_, __) => SkeletonPulse(
                  child: ColoredBox(color: overlayBaseColor),
                ),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        if (style.overlayAlpha > 0)
          ColoredBox(
            color: overlayBaseColor.withValues(alpha: style.overlayAlpha),
          ),
        if (style.tintAlpha > 0)
          ColoredBox(
            color: tintBaseColor.withValues(alpha: style.tintAlpha),
          ),
        if (style.scrimAlpha > 0)
          ColoredBox(
            color: Colors.black.withValues(alpha: style.scrimAlpha),
          ),
      ],
    );
  }
}
