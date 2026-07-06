import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';

enum _TileType { navigation, toggle, selection }

class SettingsTile extends StatelessWidget {
  // spec §2.3: 56dp row; not on AppSpacing grid — named constant like SettingsGroup._dividerIndent.
  static const double _kRowMinHeight = 56;

  final _TileType _type;
  final String title;
  final String? subtitle;
  final IconData leading;
  final VoidCallback? onTap;
  final String? value;
  final bool? toggled;
  final ValueChanged<bool>? onChanged;
  final bool? selected;

  /// Optional leading icon color; null keeps neutral `onSurfaceVariant`.
  /// For "content is the color" cases (e.g. variant picker swatches).
  final Color? leadingColor;

  const SettingsTile._({
    super.key,
    required _TileType type,
    required this.title,
    this.subtitle,
    required this.leading,
    this.onTap,
    this.value,
    this.toggled,
    this.onChanged,
    this.selected,
    this.leadingColor,
  }) : _type = type;

  /// Navigation tile with trailing chevron
  const SettingsTile.navigation({
    Key? key,
    required String title,
    String? subtitle,
    required IconData leading,
    VoidCallback? onTap,
    String? value,
  }) : this._(
          key: key,
          type: _TileType.navigation,
          title: title,
          subtitle: subtitle,
          leading: leading,
          onTap: onTap,
          value: value,
        );

  /// Toggle tile with CupertinoSwitch
  const SettingsTile.toggle({
    Key? key,
    required String title,
    String? subtitle,
    required IconData leading,
    required bool value,
    ValueChanged<bool>? onChanged,
  }) : this._(
          key: key,
          type: _TileType.toggle,
          title: title,
          subtitle: subtitle,
          leading: leading,
          toggled: value,
          onChanged: onChanged,
        );

  /// Selection tile with checkmark
  const SettingsTile.selection({
    Key? key,
    required String title,
    String? subtitle,
    required IconData leading,
    required bool selected,
    VoidCallback? onTap,
    Color? leadingColor,
  }) : this._(
          key: key,
          type: _TileType.selection,
          title: title,
          subtitle: subtitle,
          leading: leading,
          selected: selected,
          onTap: onTap,
          leadingColor: leadingColor,
        );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget trailing = _buildTrailing(context, colorScheme);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _kRowMinHeight),
      child: InkWell(
        onTap: _type == _TileType.toggle ? null : (onTap != null ? _handleTap : null),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space12,
          ),
          child: Row(
            children: [
              _buildLeadingIcon(colorScheme),
              const SizedBox(width: AppSpacing.space12),
              Expanded(child: _buildText(context, colorScheme)),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  // Reference design: neutral leading icons; accent only on headers/toggles/selection.
  Widget _buildLeadingIcon(ColorScheme colorScheme) {
    return SizedBox(
      width: AppSpacing.space40,
      height: AppSpacing.space40,
      child: Icon(
        leading,
        size: 20,
        color: leadingColor ?? colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildText(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildTrailing(BuildContext context, ColorScheme colorScheme) {
    switch (_type) {
      case _TileType.navigation:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.space4),
                child: Text(
                  value!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
          ],
        );

      case _TileType.toggle:
        return CupertinoSwitch(
          value: toggled ?? false,
          activeTrackColor: colorScheme.primary,
          onChanged: (v) {
            HapticFeedback.lightImpact();
            onChanged?.call(v);
          },
        );

      case _TileType.selection:
        return selected == true
            ? Icon(Icons.check, color: colorScheme.primary)
            : const SizedBox(width: 24);
    }
  }

  void _handleTap() {
    if (_type == _TileType.selection) {
      HapticFeedback.selectionClick();
    }
    onTap?.call();
  }
}
