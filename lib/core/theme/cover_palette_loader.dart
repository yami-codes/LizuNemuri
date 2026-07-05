import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:xuro/core/image/cache/image_cache_manager.dart';
import 'package:xuro/core/theme/player_hue_derivation.dart';

/// Loads a [PlayerHuePalette] from a network [coverUrl].
Future<PlayerHuePalette> loadCoverPalette({
  required String? coverUrl,
  required Color fallbackPrimary,
  required Color background,
  required bool isDark,
}) async {
  if (coverUrl == null || coverUrl.isEmpty) {
    return derivePlayerHuePalette(
      seed: const Color(0x00000000),
      fallbackPrimary: fallbackPrimary,
      background: background,
      isDark: isDark,
    );
  }

  try {
    final provider = CachedNetworkImageProvider(
      coverUrl,
      cacheManager: ImageCacheManager.instance,
    );
    final generator = await PaletteGenerator.fromImageProvider(
      provider,
      maximumColorCount: 12,
      timeout: const Duration(seconds: 8),
    );
    final seed = generator.dominantColor?.color ??
        generator.vibrantColor?.color ??
        generator.mutedColor?.color ??
        fallbackPrimary;
    return derivePlayerHuePalette(
      seed: seed,
      fallbackPrimary: fallbackPrimary,
      background: background,
      isDark: isDark,
    );
  } catch (_) {
    return derivePlayerHuePalette(
      seed: const Color(0x00000000),
      fallbackPrimary: fallbackPrimary,
      background: background,
      isDark: isDark,
    );
  }
}
