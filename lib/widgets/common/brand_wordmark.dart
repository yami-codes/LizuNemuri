import 'package:flutter/material.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';

/// Brand lockup: waveform icon + text. Spec §2.1 (sidebar top / about center).
///
/// Icon uses accent; text uses onSurface. No external assets.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    this.text = 'ASMR',
    this.iconSize = 28,
    this.fontSize = 22,
  });

  final String text;
  final double iconSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.graphic_eq, size: iconSize, color: cs.primary),
        const SizedBox(width: AppSpacing.space8),
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
