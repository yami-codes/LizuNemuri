import 'package:flutter/material.dart';
import 'package:lizunemu/core/theme/app_colors.dart';
import 'package:lizunemu/core/theme/app_radius.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';

/// Rounded search field (home / browse). Spec §2.2.
///
/// Full radius + neutral Surface L2 background, no border.
/// Superset of `BrowseSearchBar` for Phase D migration.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  /// Read-only + [onTap]: navigates to search page; used on home (reference design).
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      readOnly: readOnly,
      onTap: onTap,
      textInputAction: TextInputAction.search,
      style: TextStyle(color: cs.onSurface),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.surfaceL2(brightness),
        hintText: hintText,
        hintStyle: TextStyle(color: cs.onSurfaceVariant),
        prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space12,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.fullAll,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.fullAll,
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.fullAll,
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
