import 'package:flutter/material.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'app_colors.dart';
import 'app_radius.dart';

/// 应用主题配置
class AppTheme {
  const AppTheme._();

  // 暗色主题
  static ThemeData dark(ColorVariant variant) => fromColorScheme(
        AppColors.darkSchemeFor(variant),
      );

  /// Theme from a pre-built [ColorScheme] (Monet dynamic hue).
  static ThemeData fromColorScheme(ColorScheme scheme) => ThemeData(
        useMaterial3: true,
        brightness: scheme.brightness,
        colorScheme: scheme,
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mdAll,
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      );

  // 亮色主题
  static ThemeData light(ColorVariant variant) => fromColorScheme(
        AppColors.lightSchemeFor(variant),
      );
}
