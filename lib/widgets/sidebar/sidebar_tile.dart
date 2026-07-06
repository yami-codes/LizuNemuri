import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lizunemu/core/theme/app_radius.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/core/theme/app_text_styles.dart';

/// Sidebar row: neutral icon + themed text; selected = solid accent pill.
class SidebarTile extends StatelessWidget {
  // spec §2.3: 56dp row height, aligned with SettingsTile._kRowMinHeight.
  static const double _kRowMinHeight = 56;

  const SidebarTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool selected;

  /// Custom trailing; default faint chevron when null and unselected.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = selected ? cs.onPrimary : cs.onSurface;
    final iconColor = selected ? cs.onPrimary : cs.onSurfaceVariant;

    return Semantics(
      button: true,
      label: title,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
        child: Material(
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: AppRadius.lgAll,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(minHeight: _kRowMinHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space12,
                  vertical: AppSpacing.space12,
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 22, color: iconColor),
                    const SizedBox(width: AppSpacing.space12),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: fg,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (trailing != null)
                      trailing!
                    else if (!selected)
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 14,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
