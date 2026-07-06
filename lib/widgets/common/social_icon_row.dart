import 'package:flutter/material.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';

/// One social link entry.
class SocialAction {
  const SocialAction({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;
}

/// Circular social icon row (about page). Spec §2.2.
///
/// Neutral `surfaceContainerHighest` circle, `onSurfaceVariant` icon — no accent.
class SocialIconRow extends StatelessWidget {
  const SocialIconRow({super.key, required this.actions});

  final List<SocialAction> actions;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final a in actions)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.space8),
            child: Semantics(
              button: true,
              label: a.semanticLabel,
              child: Material(
                color: cs.surfaceContainerHighest,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: a.onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.space12),
                    child: Icon(a.icon,
                        size: 20, color: cs.onSurfaceVariant),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
