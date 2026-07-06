import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/core/settings/metadata_translation_mode.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';

/// Manual "translate this page" action for work list screens.
class MetadataTranslatePageBar extends StatelessWidget {
  final bool isTranslating;
  final VoidCallback? onTranslate;

  const MetadataTranslatePageBar({
    super.key,
    required this.isTranslating,
    required this.onTranslate,
  });

  @override
  Widget build(BuildContext context) {
    final settings = GetIt.I<AppSettingsService>();
    if (!settings.metadataTranslationEnabled) {
      return const SizedBox.shrink();
    }
    if (settings.metadataTranslationMode != MetadataTranslationMode.manual) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        0,
        AppSpacing.space16,
        AppSpacing.space8,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: isTranslating ? null : onTranslate,
          icon: isTranslating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.translate, size: 18),
          label: Text(Strings.metadataTranslatePage),
        ),
      ),
    );
  }
}
