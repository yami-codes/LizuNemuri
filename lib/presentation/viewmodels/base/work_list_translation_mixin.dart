import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/core/settings/metadata_translation_mode.dart';
import 'package:lizunemu/core/translation/metadata_translation_service.dart';
import 'package:lizunemu/data/models/works/work.dart';

/// Shared state + hooks for translating work titles in list ViewModels.
mixin WorkListTranslationMixin on ChangeNotifier {
  final Map<String, String> _translatedWorkTitles = {};
  bool _isTranslatingWorkTitles = false;

  Map<String, String> get translatedWorkTitles =>
      Map.unmodifiable(_translatedWorkTitles);

  bool get isTranslatingWorkTitles => _isTranslatingWorkTitles;

  String displayWorkTitle(Work work) {
    final id = work.id?.toString();
    if (id != null) {
      final translated = _translatedWorkTitles[id];
      if (translated != null && translated.isNotEmpty) {
        return translated;
      }
    }
    return work.title ?? '';
  }

  MetadataTranslationService get _metadataTranslation =>
      GetIt.I<MetadataTranslationService>();

  AppSettingsService get _translationSettings =>
      GetIt.I<AppSettingsService>();

  void clearTranslatedWorkTitles() {
    _translatedWorkTitles.clear();
  }

  Future<void> maybeAutoTranslateWorks(List<Work> works) async {
    final settings = _translationSettings;
    if (!settings.metadataTranslationEnabled) return;
    if (settings.metadataTranslationMode != MetadataTranslationMode.auto) {
      return;
    }
    await translateWorksManual(works);
  }

  Future<void> translateWorksManual(List<Work> works) async {
    if (works.isEmpty || _isTranslatingWorkTitles) return;
    if (!_translationSettings.metadataTranslationEnabled) return;

    _isTranslatingWorkTitles = true;
    notifyListeners();
    try {
      final map = await _metadataTranslation.translateWorkTitles(works);
      _translatedWorkTitles.addAll(map);
    } catch (_) {
      // Best-effort — list still shows originals on failure.
    } finally {
      _isTranslatingWorkTitles = false;
      notifyListeners();
    }
  }
}
