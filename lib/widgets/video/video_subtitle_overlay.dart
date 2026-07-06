import 'package:flutter/material.dart';
import 'package:lizunemu/core/theme/app_radius.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/core/theme/app_text_styles.dart';

/// Bottom subtitle line for [VideoPlayerScreen].
class VideoSubtitleOverlay extends StatelessWidget {
  const VideoSubtitleOverlay({
    super.key,
    required this.text,
    required this.visible,
  });

  final String? text;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible || text == null || text!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space16,
          0,
          AppSpacing.space16,
          AppSpacing.space48,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.62),
            borderRadius: AppRadius.smAll,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space12,
              vertical: AppSpacing.space8,
            ),
            child: Text(
              text!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: cs.onPrimary,
                height: 1.35,
                shadows: const [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
