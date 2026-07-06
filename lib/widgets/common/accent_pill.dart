import 'package:flutter/material.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/core/theme/app_text_styles.dart';

/// Solid accent pill: sidebar selection / follow / primary CTA. Spec §2.2.
///
/// Background `primary`, foreground `onPrimary` — accent-only variant change.
class AccentPill extends StatelessWidget {
  const AccentPill({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  /// Compact size (e.g. small follow pill).
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hPad = dense ? AppSpacing.space12 : AppSpacing.space16;
    final vPad = dense ? AppSpacing.space4 : AppSpacing.space8;
    return Material(
      color: cs.primary,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: dense ? 14 : 18, color: cs.onPrimary),
                const SizedBox(width: AppSpacing.space8),
              ],
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(color: cs.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
