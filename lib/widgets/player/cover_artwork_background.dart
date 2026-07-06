import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lizunemu/core/di/service_locator.dart';
import 'package:lizunemu/core/image/cache/image_cache_manager.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/widgets/common/skeleton_pulse.dart';
import 'package:lizunemu/widgets/player/cover_artwork_backdrop_style.dart';
import 'package:lizunemu/widgets/player/twist_backdrop_shader.dart';

/// Full-bleed Apple Music–style twist backdrop with Monet tint layers.
///
/// When [animating] and cover art is available, renders the four-layer twist
/// shader (decompiled Apple Music web pipeline). Falls back to static blur
/// when the shader or image is unavailable.
class CoverArtworkBackground extends StatelessWidget {
  const CoverArtworkBackground({
    super.key,
    required this.coverUrl,
    required this.enabled,
    required this.clarity,
    required this.overlayBaseColor,
    required this.tintBaseColor,
    required this.isDark,
    this.animating = true,
  });

  final String? coverUrl;
  final bool enabled;
  final double clarity;
  final Color overlayBaseColor;
  final Color tintBaseColor;
  final bool isDark;
  final bool animating;

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
          animating: animating,
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
    required this.animating,
  });

  final String? coverUrl;
  final bool enabled;
  final double clarity;
  final Color overlayBaseColor;
  final Color tintBaseColor;
  final bool isDark;
  final bool animating;

  Widget _staticBlurredArtwork(CoverArtworkBackdropStyle style) {
    if (coverUrl == null || style.artworkAlpha <= 0) {
      return const SizedBox.shrink();
    }
    return Opacity(
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
    );
  }

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

    final useTwist = coverUrl != null && style.artworkAlpha > 0.15;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: overlayBaseColor),
        if (style.baseTintAlpha > 0) ColoredBox(color: baseBackdrop),
        if (useTwist)
          ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: style.blurSigma > 0 ? style.blurSigma * 0.85 : 28,
              sigmaY: style.blurSigma > 0 ? style.blurSigma * 0.85 : 28,
              tileMode: TileMode.clamp,
            ),
            child: Opacity(
              opacity: style.artworkAlpha.clamp(0.0, 1.0),
              child: TwistBackdropView(
                coverUrl: coverUrl,
                animating: animating,
                fallback: _staticBlurredArtwork(style),
              ),
            ),
          )
        else
          _staticBlurredArtwork(style),
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
