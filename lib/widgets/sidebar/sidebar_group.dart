import 'package:flutter/material.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/core/theme/app_text_styles.dart';

/// Sidebar section: flat, no glass card. Header is muted `onSurfaceVariant` label.
class SidebarGroup extends StatelessWidget {
  const SidebarGroup({super.key, required this.children, this.header});

  final List<Widget> children;
  final String? header;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space12,
                AppSpacing.space8,
                0,
                AppSpacing.space4,
              ),
              child: Text(
                header!,
                style: AppTextStyles.labelMedium.copyWith(
                  color: cs.onSurfaceVariant,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ...children,
        ],
      ),
    );
  }
}
