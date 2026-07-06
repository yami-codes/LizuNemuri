import 'package:flutter/material.dart';
import 'package:lizunemu/core/theme/app_radius.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/core/theme/app_text_styles.dart';

class SettingsGroup extends StatelessWidget {
  final String? header;
  final String? footer;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  // Divider indent = left padding (16) + leading slot (40) + text gap (12).
  static const double _dividerIndent = 68;

  const SettingsGroup({
    super.key,
    this.header,
    this.footer,
    required this.children,
    this.margin =
        const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.space16,
                bottom: AppSpacing.space8,
              ),
              child: Text(
                header!,
                style: AppTextStyles.labelMedium
                    .copyWith(color: colorScheme.primary),
              ),
            ),
          ClipRRect(
            borderRadius: AppRadius.mdAll,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: AppRadius.mdAll,
              ),
              child: Column(
                children: _buildChildrenWithSeparators(context),
              ),
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.space16,
                top: AppSpacing.space8,
              ),
              child: Text(
                footer!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildChildrenWithSeparators(BuildContext context) {
    if (children.isEmpty) return [];
    final list = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      list.add(children[i]);
      if (i < children.length - 1) {
        list.add(Divider(
          height: 0.5,
          thickness: 0.5,
          indent: _dividerIndent,
          color: Theme.of(context).colorScheme.outlineVariant,
        ));
      }
    }
    return list;
  }
}
