import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xuro/core/theme/player_hue_derivation.dart';
import 'package:xuro/widgets/player/cover_artwork_backdrop_style.dart';

void main() {
  group('coverArtworkBackdropStyle', () {
    test('low clarity keeps heavy blur in dark mode', () {
      final style = coverArtworkBackdropStyle(clarity: 0.0, isDark: true);
      expect(style.blurSigma, greaterThan(20));
      expect(style.artworkAlpha, 0);
    });

    test('high clarity opens artwork in light mode', () {
      final style = coverArtworkBackdropStyle(clarity: 1.0, isDark: false);
      expect(style.blurSigma, 0);
      expect(style.artworkAlpha, closeTo(0.99, 0.01));
    });
  });

  group('derivePlayerHuePalette', () {
    test('transparent seed falls back to theme primary', () {
      const fallback = Color(0xFF0066FF);
      const background = Colors.white;
      final palette = derivePlayerHuePalette(
        seed: const Color(0x00000000),
        fallbackPrimary: fallback,
        background: background,
        isDark: false,
      );
      expect(palette.primary, fallback);
      expect(palette.backdropTint, background);
    });

    test('vivid seed produces backdrop tint distinct from background', () {
      final palette = derivePlayerHuePalette(
        seed: const Color(0xFFE91E63),
        fallbackPrimary: Colors.blue,
        background: const Color(0xFFF4F6F8),
        isDark: false,
      );
      expect(palette.backdropTint, isNot(equals(const Color(0xFFF4F6F8))));
      expect(palette.primaryStrong, isNot(equals(Colors.blue)));
    });
  });

  group('pickReadableLyricTextColor', () {
    test('picks light text on dark backdrop', () {
      final color = pickReadableLyricTextColor(
        backdrop: const Color(0xFF1A1D22),
        fallback: Colors.black,
      );
      expect(color.computeLuminance(), greaterThan(0.5));
    });
  });
}
