import 'package:flutter/material.dart';
import 'package:lizunemu/core/theme/app_radius.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/core/theme/app_text_styles.dart';

/// Icon + label category chip (home hot categories). Spec §2.1.
///
/// Soft `primaryContainer` background, `primary` icon; text stays neutral `onSurface`.
/// Different semantic from [TagChip] on detail — not shared.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.primaryContainer,
      borderRadius: AppRadius.smAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space12,
            vertical: AppSpacing.space8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: cs.primary),
              const SizedBox(width: AppSpacing.space8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium
                      .copyWith(color: cs.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
