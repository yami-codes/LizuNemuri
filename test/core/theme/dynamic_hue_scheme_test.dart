import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xuro/core/settings/app_settings_service.dart';
import 'package:xuro/core/theme/app_colors.dart';
import 'package:xuro/core/theme/player_hue_derivation.dart';

void main() {
  test('schemeFromPlayerPalette rotates primary from cover palette', () {
    const seed = Color(0xFFE91E63);
    final palette = derivePlayerHuePalette(
      seed: seed,
      fallbackPrimary: const Color(0xFF0066FF),
      background: Colors.white,
      isDark: false,
    );
    final scheme = AppColors.schemeFromPlayerPalette(
      palette,
      Brightness.light,
    );
    final base = AppColors.lightSchemeFor(ColorVariant.blue);
    expect(scheme.primary, palette.primary);
    expect(scheme.primary, isNot(base.primary));
    expect(scheme.surface, base.surface);
  });
}
