import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// Monet-style player palette derived from cover art dominant color.
class PlayerHuePalette {
  const PlayerHuePalette({
    required this.primary,
    required this.primarySoft,
    required this.primaryStrong,
    required this.backdropTint,
  });

  final Color primary;
  final Color primarySoft;
  final Color primaryStrong;
  final Color backdropTint;
}

/// Builds player accent + backdrop tint from a cover-sampled [seed] color.
PlayerHuePalette derivePlayerHuePalette({
  required Color seed,
  required Color fallbackPrimary,
  required Color background,
  required bool isDark,
}) {
  final hsl = _rgbToHsl(seed);
  _clampPrimaryHslForMode(hsl, isDark);
  final primary = _hslToRgb(hsl);

  final softHsl = List<double>.from(hsl)
    ..[1] = (hsl[1] * 0.68).clamp(0.0, 0.76)
    ..[2] = isDark
        ? (hsl[2] + 0.08).clamp(0.42, 0.74)
        : (hsl[2] - 0.06).clamp(0.66, 0.78);
  final primarySoft = _hslToRgb(softHsl);

  final strongHsl = List<double>.from(hsl)
    ..[1] = (hsl[1] * 0.82).clamp(0.0, 0.78);
  final primaryStrong = _hslToRgb(strongHsl);

  final backdropTint = derivePlayerBackdropTint(
    primary: primary,
    primarySoft: primarySoft,
    background: background,
    isDark: isDark,
  );

  if (seed.a == 0) {
    return PlayerHuePalette(
      primary: fallbackPrimary,
      primarySoft: fallbackPrimary.withValues(alpha: 0.35),
      primaryStrong: fallbackPrimary,
      backdropTint: background,
    );
  }

  return PlayerHuePalette(
    primary: primary,
    primarySoft: primarySoft,
    primaryStrong: primaryStrong,
    backdropTint: backdropTint,
  );
}

Color derivePlayerBackdropTint({
  required Color primary,
  required Color primarySoft,
  required Color background,
  required bool isDark,
}) {
  final seedMixed = _blendSrgb(
    primarySoft,
    primary,
    isDark ? 0.72 : 0.52,
  );
  final mixed = _blendSrgb(
    background,
    seedMixed,
    isDark ? 0.88 : 0.86,
  );
  final hsl = _rgbToHsl(mixed);
  if (isDark) {
    hsl[1] = hsl[1].clamp(0.24, 0.58);
    hsl[2] = hsl[2].clamp(0.42, 0.56);
  } else {
    hsl[1] = hsl[1].clamp(0.22, 0.56);
    hsl[2] = hsl[2].clamp(0.66, 0.78);
  }
  return _hslToRgb(hsl);
}

/// Picks light or dark lyric text for WCAG-ish contrast on [backdrop].
Color pickReadableLyricTextColor({
  required Color backdrop,
  required Color fallback,
}) {
  const lightCandidate = Color(0xFFF7FAFC);
  const darkCandidate = Color(0xFF111418);
  final lightContrast = _contrastRatio(lightCandidate, backdrop);
  final darkContrast = _contrastRatio(darkCandidate, backdrop);
  final best = lightContrast >= darkContrast ? lightCandidate : darkCandidate;
  final bestContrast = math.max(lightContrast, darkContrast);
  return bestContrast >= 4.5 ? best : fallback;
}

Color inactiveLyricTextColor({
  required Color activeText,
  required Color fallback,
}) {
  const lightGray = Color(0xFFD7DCE4);
  const darkGray = Color(0xFF3E4651);
  final lum = activeText.computeLuminance();
  if (lum > 0.5) return lightGray;
  if (lum < 0.2) return darkGray;
  return fallback;
}

void _clampPrimaryHslForMode(List<double> hsl, bool isDark) {
  var hue = hsl[0] % 360;
  if (hue < 0) hue += 360;
  hsl[0] = hue;
  hsl[1] = hsl[1].clamp(0.0, isDark ? 0.78 : 0.76);

  if (isDark) {
    final minL = switch (hue) {
      >= 38 && < 85 => 0.58,
      >= 85 && < 170 => 0.54,
      >= 170 && < 260 => 0.48,
      _ => 0.52,
    };
    final maxL = switch (hue) {
      >= 38 && < 85 => 0.74,
      >= 85 && < 170 => 0.70,
      >= 170 && < 260 => 0.66,
      _ => 0.68,
    };
    hsl[2] = hsl[2].clamp(minL, maxL);
  } else {
    const minL = 0.18;
    final maxL = switch (hue) {
      >= 38 && < 85 => hsl[1] >= 0.45 ? 0.38 : 0.42,
      >= 85 && < 170 => hsl[1] >= 0.45 ? 0.40 : 0.44,
      >= 170 && < 260 => hsl[1] >= 0.45 ? 0.46 : 0.50,
      _ => hsl[1] >= 0.45 ? 0.42 : 0.46,
    };
    hsl[2] = hsl[2].clamp(minL, maxL);
  }
}

Color _blendSrgb(Color start, Color end, double fraction) {
  final t = fraction.clamp(0.0, 1.0);
  return Color.fromARGB(
    255,
    _lerpInt((start.r * 255).round(), (end.r * 255).round(), t),
    _lerpInt((start.g * 255).round(), (end.g * 255).round(), t),
    _lerpInt((start.b * 255).round(), (end.b * 255).round(), t),
  );
}

int _lerpInt(int start, int end, double t) =>
    (start + (end - start) * t).round().clamp(0, 255);

List<double> _rgbToHsl(Color color) {
  final r = color.r;
  final g = color.g;
  final b = color.b;
  final maxC = math.max(r, math.max(g, b));
  final minC = math.min(r, math.min(g, b));
  final l = (maxC + minC) / 2;
  if ((maxC - minC).abs() < 0.00001) {
    return [0, 0, l];
  }
  final d = maxC - minC;
  final s = l > 0.5 ? d / (2 - maxC - minC) : d / (maxC + minC);
  double h;
  if (maxC == r) {
    h = ((g - b) / d + (g < b ? 6 : 0)) * 60;
  } else if (maxC == g) {
    h = ((b - r) / d + 2) * 60;
  } else {
    h = ((r - g) / d + 4) * 60;
  }
  return [h, s, l];
}

Color _hslToRgb(List<double> hsl) {
  final h = ((hsl[0] % 360) + 360) % 360;
  final s = hsl[1].clamp(0.0, 1.0);
  final l = hsl[2].clamp(0.0, 1.0);
  if (s <= 0) {
    final v = (l * 255).round();
    return Color.fromARGB(255, v, v, v);
  }
  final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
  final p = 2 * l - q;
  final hk = h / 360;
  return Color.fromARGB(
    255,
    (_hueToRgb(p, q, hk + 1 / 3) * 255).round(),
    (_hueToRgb(p, q, hk) * 255).round(),
    (_hueToRgb(p, q, hk - 1 / 3) * 255).round(),
  );
}

double _hueToRgb(double p, double q, double t) {
  var tt = t;
  if (tt < 0) tt += 1;
  if (tt > 1) tt -= 1;
  if (tt < 1 / 6) return p + (q - p) * 6 * tt;
  if (tt < 1 / 2) return q;
  if (tt < 2 / 3) return p + (q - p) * (2 / 3 - tt) * 6;
  return p;
}

double _contrastRatio(Color fg, Color bg) {
  final l1 = fg.computeLuminance() + 0.05;
  final l2 = bg.computeLuminance() + 0.05;
  return l1 > l2 ? l1 / l2 : l2 / l1;
}
