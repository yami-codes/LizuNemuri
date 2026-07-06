import 'package:flutter/widgets.dart';

/// Typography tokens (spec §1.2).
///
/// Size / weight / line height only — **no color** (from `colorScheme` at use site
/// for three-variant invariant). `height` is a multiple of fontSize.
class AppTextStyles {
  AppTextStyles._();

  /// Display / hero title
  static const TextStyle headlineMedium =
      TextStyle(fontSize: 28, fontWeight: FontWeight.w500, height: 1.2);

  /// AppBar title / player track name
  static const TextStyle titleLarge =
      TextStyle(fontSize: 22, fontWeight: FontWeight.w500, height: 1.3);

  /// List title / card title / section header
  static const TextStyle titleMedium =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5);

  /// Body text
  static const TextStyle bodyLarge =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);

  /// Secondary description / subtitle
  static const TextStyle bodyMedium =
      TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);

  /// Label / button / caption
  static const TextStyle labelMedium =
      TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.3);

  /// Timestamp (e.g. 30:45) / copyright
  static const TextStyle caption =
      TextStyle(fontSize: 10, fontWeight: FontWeight.w400, height: 1.2);
}
