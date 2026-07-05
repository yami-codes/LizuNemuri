import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Visual parameters for [CoverArtworkBackground], ported from Eara's
/// `coverArtworkBackdropStyle` (clarity-driven blur / veil).
class CoverArtworkBackdropStyle {
  const CoverArtworkBackdropStyle({
    required this.blurSigma,
    required this.baseTintAlpha,
    required this.artworkAlpha,
    required this.overlayAlpha,
    required this.tintAlpha,
    required this.scrimAlpha,
  });

  final double blurSigma;
  final double baseTintAlpha;
  final double artworkAlpha;
  final double overlayAlpha;
  final double tintAlpha;
  final double scrimAlpha;
}

CoverArtworkBackdropStyle coverArtworkBackdropStyle({
  required double clarity,
  required bool isDark,
}) {
  final normalized = clarity.clamp(0.0, 1.0);
  // Lower clarity = heavier veil; higher opens up faster (Eara uses ^2.15).
  final reveal = math.pow(normalized, 2.15).toDouble();

  return CoverArtworkBackdropStyle(
    blurSigma: _lerp(isDark ? 30.0 : 28.0, 0.0, reveal),
    baseTintAlpha: _lerp(isDark ? 0.90 : 0.82, isDark ? 0.40 : 0.26, reveal),
    artworkAlpha: normalized > 0
        ? _lerp(isDark ? 0.10 : 0.08, isDark ? 0.98 : 0.99, reveal)
        : 0,
    overlayAlpha: _lerp(isDark ? 0.04 : 0.02, 0.0, reveal),
    tintAlpha: _lerp(isDark ? 0.26 : 0.18, isDark ? 0.08 : 0.05, reveal),
    scrimAlpha: _lerp(isDark ? 0.01 : 0.0, 0.0, reveal),
  );
}

double _lerp(double start, double end, double fraction) {
  final t = fraction.clamp(0.0, 1.0);
  return start + (end - start) * t;
}

/// Estimates the flat color behind lyrics for contrast picking.
Color estimateLyricBackdropColor({
  required Color backdropTintColor,
  required Color backgroundColor,
  required bool coverBackgroundEnabled,
  required double coverBackgroundClarity,
  required bool isDark,
}) {
  if (!coverBackgroundEnabled) return backgroundColor;

  final style = coverArtworkBackdropStyle(
    clarity: coverBackgroundClarity,
    isDark: isDark,
  );
  var estimated = backdropTintColor;
  estimated = Color.alphaBlend(
    backgroundColor.withValues(alpha: style.overlayAlpha),
    estimated,
  );
  estimated = Color.alphaBlend(
    backdropTintColor.withValues(alpha: style.tintAlpha),
    estimated,
  );
  if (style.scrimAlpha > 0) {
    estimated = Color.alphaBlend(
      Colors.black.withValues(alpha: style.scrimAlpha),
      estimated,
    );
  }
  return estimated;
}
