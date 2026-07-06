import 'package:flutter/material.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/core/theme/app_text_styles.dart';

/// Copyright footer (about). Spec §2.2. Copy from caller via Strings.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space24),
      child: Center(
        child: Text(
          text,
          style:
              AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
