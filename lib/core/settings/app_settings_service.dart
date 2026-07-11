import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lizunemu/core/settings/app_language.dart';
import 'package:lizunemu/core/settings/llm_batch_split_mode.dart';
import 'package:lizunemu/core/llm/llm_batch_planner.dart';
import 'package:lizunemu/core/settings/llm_subtitle_display_mode.dart';
import 'package:lizunemu/core/settings/playback_speed_presets.dart';
import 'package:lizunemu/core/settings/llm_subtitle_target_language.dart';
import 'package:lizunemu/core/logging/app_log_level.dart';
import 'package:lizunemu/core/settings/metadata_translation_mode.dart';
import 'package:lizunemu/core/settings/metadata_translation_provider.dart';

/// Top-level accent color variants. Surfaces stay neutral (white/black) across
/// all variants — only the `primary` token rotates. Persisted by
/// [AppSettingsService.colorVariant].
enum ColorVariant {
  blue,
  mono,
  green,
}

class AppSettingsService extends ChangeNotifier {
  static const String _serverUrlKey = 'server_url';
  static const String _smartPathKey = 'smart_path_enabled';
  static const String _audioFormatOrderKey = 'audio_format_order';
  static const String _colorVariantKey = 'color_variant';
  static const String _lyricOverlayUnlockedKey = 'lyric_overlay_unlocked';
  static const String _backgroundPlayKey = 'background_play_enabled';
  // Shared "subtitle works only" filter across list ViewModels. Single source of truth
  // instead of each VM calling SharedPreferences.getInstance() and writing stale values on dispose.
  static const String _subtitleFilterKey = 'subtitle_filter';
  static const String _appLanguageKey = 'app_language';
  static const String _llmTranslationEnabledKey = 'llm_translation_enabled';
  static const String _llmApiEndpointKey = 'llm_api_endpoint';
  static const String _llmModelKey = 'llm_model';
  static const String _llmLiteModelKey = 'llm_lite_model';
  static const String _metadataTranslationEnabledKey =
      'metadata_translation_enabled';
  static const String _metadataTranslationProviderKey =
      'metadata_translation_provider';
  static const String _metadataTranslationModeKey =
      'metadata_translation_mode';
  static const String _llmTargetLanguageKey = 'llm_target_language';
  static const String _llmSystemPromptKey = 'llm_system_prompt';
  static const String _llmJailbreakPromptKey = 'llm_jailbreak_prompt';
  static const String _llmJailbreakAutoKey = 'llm_jailbreak_auto';
  static const String _llmBatchSplitModeKey = 'llm_batch_split_mode';
  static const String _llmManualBatchSizeKey = 'llm_manual_batch_size';
  static const String _llmStreamingEnabledKey = 'llm_streaming_enabled';
  static const String _llmSubtitleDisplayModeKey = 'llm_subtitle_display_mode';
  static const String _playbackVolumeKey = 'playback_volume';
  static const String _playbackSpeedKey = 'playback_speed';
  static const String _sleepTimerFadeOutKey = 'sleep_timer_fade_out';
  static const String _sleepTimerDimScreenKey = 'sleep_timer_dim_screen';
  static const String _playbackFadeEnabledKey = 'playback_fade_enabled';
  static const String _playbackFadeMsKey = 'playback_fade_ms';
  static const String _lyricAutoScrollResumeSecKey = 'lyric_auto_scroll_resume_sec';
  static const String _playerBackdropClarityKey = 'player_backdrop_clarity';
  static const String _logCaptureMinLevelKey = 'log_capture_min_level';

  static const String defaultServerUrl = 'https://api.asmr.one/api';
  static const String defaultLlmApiEndpoint = 'https://api.openai.com/v1';
  static const String defaultOpenRouterEndpoint = 'https://openrouter.ai/api/v1';
  static const String defaultGeminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/openai';

  static const String defaultOpenAiMainModel = 'gpt-4o-mini';
  static const String defaultOpenAiLiteModel = 'gpt-4o-mini';
  static const String defaultOpenRouterMainModel = 'google/gemma-4-31b-it:free';
  static const String defaultOpenRouterLiteModel =
      'google/gemma-4-26b-a4b-it:free';
  static const String defaultGeminiMainModel = 'gemini-2.5-flash';
  static const String defaultGeminiLiteModel = 'gemini-2.5-flash-lite';

  /// Default LLM endpoint + models for new installs (OpenRouter free Gemma).
  static const String defaultLlmEndpoint = defaultOpenRouterEndpoint;
  static const String defaultLlmModel = defaultOpenRouterMainModel;
  static const String defaultLlmLiteModel = defaultOpenRouterLiteModel;
  static const ColorVariant defaultColorVariant = ColorVariant.blue;
  static const AppLanguage defaultAppLanguage = AppLanguage.system;
  static const List<String> defaultAudioFormatOrder = [
    'mp3', 'flac', 'wav', 'opus', 'm4a', 'aac'
  ];
  static const double defaultPlayerBackdropClarity = 0.35;
  static const AppLogLevel defaultLogCaptureMinLevel = AppLogLevel.debug;
  static const bool defaultPlaybackFadeEnabled = true;
  static const int defaultPlaybackFadeMs = 300;
  static const int minPlaybackFadeMs = 100;
  static const int maxPlaybackFadeMs = 1000;
  static const int defaultLyricAutoScrollResumeSec = 3;
  static const int minLyricAutoScrollResumeSec = 1;
  static const int maxLyricAutoScrollResumeSec = 30;

  /// Available API nodes (labels via [Strings.serverMain] etc. at UI layer).
  static const List<String> serverUrls = [
    defaultServerUrl,
    'https://api.asmr-100.com/api',
    'https://api.asmr-200.com/api',
    'https://api.asmr-300.com/api',
  ];

  final SharedPreferences _prefs;

  late String _serverUrl;
  late bool _smartPathEnabled;
  late List<String> _audioFormatOrder;
  late ColorVariant _colorVariant;
  late bool _lyricOverlayUnlocked;
  late bool _backgroundPlayEnabled;
  late bool _hasSubtitleFilter;
  late AppLanguage _appLanguage;
  late bool _llmTranslationEnabled;
  late String _llmApiEndpoint;
  late String _llmModel;
  late String _llmLiteModel;
  late bool _metadataTranslationEnabled;
  late MetadataTranslationProvider _metadataTranslationProvider;
  late MetadataTranslationMode _metadataTranslationMode;
  late LlmSubtitleTargetLanguage _llmTargetLanguage;
  late String _llmSystemPromptOverride;
  late String _llmJailbreakPrompt;
  late bool _llmJailbreakAuto;
  late LlmBatchSplitMode _llmBatchSplitMode;
  late int _llmManualBatchSize;
  late bool _llmStreamingEnabled;
  late LlmSubtitleDisplayMode _llmSubtitleDisplayMode;
  late double _playbackVolume;
  late double _playbackSpeed;
  late bool _sleepTimerFadeOutEnabled;
  late bool _sleepTimerDimScreenEnabled;
  late bool _playbackFadeEnabled;
  late int _playbackFadeMs;
  late int _lyricAutoScrollResumeSec;
  late double _playerBackdropClarity;
  late AppLogLevel _logCaptureMinLevel;

  AppSettingsService(this._prefs) {
    _serverUrl = _prefs.getString(_serverUrlKey) ?? defaultServerUrl;
    _smartPathEnabled = _prefs.getBool(_smartPathKey) ?? true;
    final savedOrder = _prefs.getStringList(_audioFormatOrderKey);
    _audioFormatOrder = savedOrder ?? List.from(defaultAudioFormatOrder);
    final savedVariant = _prefs.getString(_colorVariantKey);
    _colorVariant = ColorVariant.values.firstWhere(
      (v) => v.name == savedVariant,
      orElse: () => defaultColorVariant,
    );
    _lyricOverlayUnlocked = _prefs.getBool(_lyricOverlayUnlockedKey) ?? false;
    _backgroundPlayEnabled = _prefs.getBool(_backgroundPlayKey) ?? true;
    _hasSubtitleFilter = _prefs.getBool(_subtitleFilterKey) ?? false;
    final savedLang = _prefs.getString(_appLanguageKey);
    _appLanguage = AppLanguage.values.firstWhere(
      (v) => v.name == savedLang,
      orElse: () => defaultAppLanguage,
    );
    _llmTranslationEnabled =
        _prefs.getBool(_llmTranslationEnabledKey) ?? false;
    _llmApiEndpoint =
        _prefs.getString(_llmApiEndpointKey) ?? defaultLlmEndpoint;
    _llmModel = _prefs.getString(_llmModelKey) ?? defaultLlmModel;
    _llmLiteModel =
        _prefs.getString(_llmLiteModelKey) ?? defaultLlmLiteModel;
    _metadataTranslationEnabled =
        _prefs.getBool(_metadataTranslationEnabledKey) ?? false;
    final savedProvider = _prefs.getString(_metadataTranslationProviderKey);
    _metadataTranslationProvider =
        MetadataTranslationProvider.values.firstWhere(
      (v) => v.name == savedProvider,
      orElse: () => MetadataTranslationProvider.google,
    );
    final savedMetadataMode = _prefs.getString(_metadataTranslationModeKey);
    _metadataTranslationMode = MetadataTranslationMode.values.firstWhere(
      (v) => v.name == savedMetadataMode,
      orElse: () => MetadataTranslationMode.auto,
    );
    final savedTarget = _prefs.getString(_llmTargetLanguageKey);
    _llmTargetLanguage = LlmSubtitleTargetLanguage.values.firstWhere(
      (v) => v.name == savedTarget,
      orElse: () => LlmSubtitleTargetLanguage.system,
    );
    _llmSystemPromptOverride = _prefs.getString(_llmSystemPromptKey) ?? '';
    _llmJailbreakPrompt = _prefs.getString(_llmJailbreakPromptKey) ?? '';
    _llmJailbreakAuto = _prefs.getBool(_llmJailbreakAutoKey) ?? true;
    final savedSplit = _prefs.getString(_llmBatchSplitModeKey);
    _llmBatchSplitMode = LlmBatchSplitMode.values.firstWhere(
      (v) => v.name == savedSplit,
      orElse: () => LlmBatchSplitMode.provider,
    );
    _llmManualBatchSize =
        _prefs.getInt(_llmManualBatchSizeKey) ??
            LlmBatchPlanner.defaultManualBatchSize;
    _llmStreamingEnabled = _prefs.getBool(_llmStreamingEnabledKey) ?? true;
    final savedDisplayMode = _prefs.getString(_llmSubtitleDisplayModeKey);
    _llmSubtitleDisplayMode = LlmSubtitleDisplayMode.values.firstWhere(
      (v) => v.name == savedDisplayMode,
      orElse: () => LlmSubtitleDisplayMode.translationOnly,
    );
    _playbackVolume = _prefs.getDouble(_playbackVolumeKey) ?? 1.0;
    _playbackSpeed = PlaybackSpeedPresets.clamp(
      _prefs.getDouble(_playbackSpeedKey) ?? PlaybackSpeedPresets.defaultSpeed,
    );
    _sleepTimerFadeOutEnabled =
        _prefs.getBool(_sleepTimerFadeOutKey) ?? true;
    _sleepTimerDimScreenEnabled =
        _prefs.getBool(_sleepTimerDimScreenKey) ?? true;
    _playbackFadeEnabled =
        _prefs.getBool(_playbackFadeEnabledKey) ?? defaultPlaybackFadeEnabled;
    _playbackFadeMs = (_prefs.getInt(_playbackFadeMsKey) ??
            defaultPlaybackFadeMs)
        .clamp(minPlaybackFadeMs, maxPlaybackFadeMs);
    _lyricAutoScrollResumeSec = (_prefs.getInt(_lyricAutoScrollResumeSecKey) ??
            defaultLyricAutoScrollResumeSec)
        .clamp(minLyricAutoScrollResumeSec, maxLyricAutoScrollResumeSec);
    _playerBackdropClarity = (_prefs.getDouble(_playerBackdropClarityKey) ??
            defaultPlayerBackdropClarity)
        .clamp(0.0, 1.0);
    _logCaptureMinLevel = AppLogLevelX.fromName(
      _prefs.getString(_logCaptureMinLevelKey),
      fallback: defaultLogCaptureMinLevel,
    );
  }

  // === UI Language ===
  AppLanguage get appLanguage => _appLanguage;

  /// `null` → follow the OS locale in [MaterialApp].
  Locale? get materialLocale {
    switch (_appLanguage) {
      case AppLanguage.system:
        return null;
      case AppLanguage.zh:
        return const Locale('zh');
      case AppLanguage.en:
        return const Locale('en');
      case AppLanguage.th:
        return const Locale('th');
    }
  }

  /// Concrete locale for [Strings] / API i18n when no [BuildContext] exists.
  Locale get stringsLocale {
    final forced = materialLocale;
    if (forced != null) return forced;
    return _normalizePlatformLocale(
      PlatformDispatcher.instance.locale,
    );
  }

  static Locale _normalizePlatformLocale(Locale locale) {
    final code = locale.languageCode;
    if (code == 'en' || code == 'th') return Locale(code);
    if (code.startsWith('zh')) return const Locale('zh');
    return const Locale('zh');
  }

  Future<void> setAppLanguage(AppLanguage language) async {
    if (_appLanguage == language) return;
    _appLanguage = language;
    notifyListeners();
    await _prefs.setString(_appLanguageKey, language.name);
  }

  // === Server URL ===
  String get serverUrl => _serverUrl;

  Future<void> setServerUrl(String url) async {
    if (_serverUrl == url) return;
    _serverUrl = url;
    notifyListeners();
    await _prefs.setString(_serverUrlKey, url);
  }

  // === Smart Path ===
  bool get smartPathEnabled => _smartPathEnabled;

  Future<void> setSmartPathEnabled(bool enabled) async {
    if (_smartPathEnabled == enabled) return;
    _smartPathEnabled = enabled;
    notifyListeners();
    await _prefs.setBool(_smartPathKey, enabled);
  }

  // === Subtitle Filter (shared across list ViewModels) ===
  bool get hasSubtitleFilter => _hasSubtitleFilter;

  Future<void> setHasSubtitleFilter(bool value) async {
    if (_hasSubtitleFilter == value) return;
    _hasSubtitleFilter = value;
    notifyListeners();
    await _prefs.setBool(_subtitleFilterKey, value);
  }

  // === Audio Format Order ===
  List<String> get audioFormatOrder => List.unmodifiable(_audioFormatOrder);

  /// Get supported audio file extensions with dot prefix, ordered by preference
  List<String> get audioExtensions =>
      _audioFormatOrder.map((f) => '.$f').toList();

  Future<void> setAudioFormatOrder(List<String> order) async {
    _audioFormatOrder = List.from(order);
    notifyListeners();
    await _prefs.setStringList(_audioFormatOrderKey, _audioFormatOrder);
  }

  Future<void> resetAudioFormatOrder() async {
    await setAudioFormatOrder(List.from(defaultAudioFormatOrder));
  }

  // === Lyric Overlay Lock ===
  /// `true` → floating lyrics draggable; `false` → locked pass-through (default).
  bool get lyricOverlayUnlocked => _lyricOverlayUnlocked;

  Future<void> setLyricOverlayUnlocked(bool unlocked) async {
    if (_lyricOverlayUnlocked == unlocked) return;
    _lyricOverlayUnlocked = unlocked;
    notifyListeners();
    await _prefs.setBool(_lyricOverlayUnlockedKey, unlocked);
  }

  // === Background Play ===
  /// `true` (default) → keep playing in background; `false` → pause when backgrounded.
  bool get backgroundPlayEnabled => _backgroundPlayEnabled;

  Future<void> setBackgroundPlayEnabled(bool enabled) async {
    if (_backgroundPlayEnabled == enabled) return;
    _backgroundPlayEnabled = enabled;
    notifyListeners();
    await _prefs.setBool(_backgroundPlayKey, enabled);
  }

  // === Color Variant ===
  ColorVariant get colorVariant => _colorVariant;

  Future<void> setColorVariant(ColorVariant variant) async {
    if (_colorVariant == variant) return;
    _colorVariant = variant;
    notifyListeners();
    await _prefs.setString(_colorVariantKey, variant.name);
  }

  // === LLM subtitle translation ===
  bool get llmTranslationEnabled => _llmTranslationEnabled;

  Future<void> setLlmTranslationEnabled(bool enabled) async {
    if (_llmTranslationEnabled == enabled) return;
    _llmTranslationEnabled = enabled;
    notifyListeners();
    await _prefs.setBool(_llmTranslationEnabledKey, enabled);
  }

  String get llmApiEndpoint => _llmApiEndpoint;

  Future<void> setLlmApiEndpoint(String endpoint) async {
    final trimmed = endpoint.trim();
    if (_llmApiEndpoint == trimmed) return;
    _llmApiEndpoint = trimmed;
    notifyListeners();
    await _prefs.setString(_llmApiEndpointKey, trimmed);
  }

  String get llmModel => _llmModel;

  /// Main model — subtitles and other high-quality translation.
  String get llmMainModel => _llmModel;

  Future<void> setLlmModel(String model) async {
    final trimmed = model.trim();
    if (_llmModel == trimmed) return;
    _llmModel = trimmed;
    notifyListeners();
    await _prefs.setString(_llmModelKey, trimmed);
  }

  Future<void> setLlmMainModel(String model) => setLlmModel(model);

  String get llmLiteModel => _llmLiteModel;

  Future<void> setLlmLiteModel(String model) async {
    final trimmed = model.trim();
    if (_llmLiteModel == trimmed) return;
    _llmLiteModel = trimmed;
    notifyListeners();
    await _prefs.setString(_llmLiteModelKey, trimmed);
  }

  bool get metadataTranslationEnabled => _metadataTranslationEnabled;

  Future<void> setMetadataTranslationEnabled(bool enabled) async {
    if (_metadataTranslationEnabled == enabled) return;
    _metadataTranslationEnabled = enabled;
    notifyListeners();
    await _prefs.setBool(_metadataTranslationEnabledKey, enabled);
  }

  MetadataTranslationProvider get metadataTranslationProvider =>
      _metadataTranslationProvider;

  Future<void> setMetadataTranslationProvider(
    MetadataTranslationProvider provider,
  ) async {
    if (_metadataTranslationProvider == provider) return;
    _metadataTranslationProvider = provider;
    notifyListeners();
    await _prefs.setString(_metadataTranslationProviderKey, provider.name);
  }

  MetadataTranslationMode get metadataTranslationMode =>
      _metadataTranslationMode;

  Future<void> setMetadataTranslationMode(MetadataTranslationMode mode) async {
    if (_metadataTranslationMode == mode) return;
    _metadataTranslationMode = mode;
    notifyListeners();
    await _prefs.setString(_metadataTranslationModeKey, mode.name);
  }

  LlmSubtitleTargetLanguage get llmTargetLanguage => _llmTargetLanguage;

  Future<void> setLlmTargetLanguage(LlmSubtitleTargetLanguage language) async {
    if (_llmTargetLanguage == language) return;
    _llmTargetLanguage = language;
    notifyListeners();
    await _prefs.setString(_llmTargetLanguageKey, language.name);
  }

  String get llmSystemPromptOverride => _llmSystemPromptOverride;

  Future<void> setLlmSystemPromptOverride(String prompt) async {
    if (_llmSystemPromptOverride == prompt) return;
    _llmSystemPromptOverride = prompt;
    notifyListeners();
    await _prefs.setString(_llmSystemPromptKey, prompt);
  }

  String get llmJailbreakPrompt => _llmJailbreakPrompt;

  Future<void> setLlmJailbreakPrompt(String prompt) async {
    if (_llmJailbreakPrompt == prompt) return;
    _llmJailbreakPrompt = prompt;
    notifyListeners();
    await _prefs.setString(_llmJailbreakPromptKey, prompt);
  }

  bool get llmJailbreakAuto => _llmJailbreakAuto;

  Future<void> setLlmJailbreakAuto(bool enabled) async {
    if (_llmJailbreakAuto == enabled) return;
    _llmJailbreakAuto = enabled;
    notifyListeners();
    await _prefs.setBool(_llmJailbreakAutoKey, enabled);
  }

  LlmBatchSplitMode get llmBatchSplitMode => _llmBatchSplitMode;

  Future<void> setLlmBatchSplitMode(LlmBatchSplitMode mode) async {
    if (_llmBatchSplitMode == mode) return;
    _llmBatchSplitMode = mode;
    notifyListeners();
    await _prefs.setString(_llmBatchSplitModeKey, mode.name);
  }

  int get llmManualBatchSize => _llmManualBatchSize;

  Future<void> setLlmManualBatchSize(int size) async {
    final clamped = size.clamp(1, 500);
    if (_llmManualBatchSize == clamped) return;
    _llmManualBatchSize = clamped;
    notifyListeners();
    await _prefs.setInt(_llmManualBatchSizeKey, clamped);
  }

  bool get llmStreamingEnabled => _llmStreamingEnabled;

  Future<void> setLlmStreamingEnabled(bool enabled) async {
    if (_llmStreamingEnabled == enabled) return;
    _llmStreamingEnabled = enabled;
    notifyListeners();
    await _prefs.setBool(_llmStreamingEnabledKey, enabled);
  }

  LlmSubtitleDisplayMode get llmSubtitleDisplayMode => _llmSubtitleDisplayMode;

  Future<void> setLlmSubtitleDisplayMode(LlmSubtitleDisplayMode mode) async {
    if (_llmSubtitleDisplayMode == mode) return;
    _llmSubtitleDisplayMode = mode;
    notifyListeners();
    await _prefs.setString(_llmSubtitleDisplayModeKey, mode.name);
  }

  // === Playback volume (0.0–1.0) ===
  double get playbackVolume => _playbackVolume;

  Future<void> setPlaybackVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    if (_playbackVolume == clamped) return;
    _playbackVolume = clamped;
    notifyListeners();
    await _prefs.setDouble(_playbackVolumeKey, clamped);
  }

  double get playbackSpeed => _playbackSpeed;

  Future<void> setPlaybackSpeed(double speed) async {
    final clamped = PlaybackSpeedPresets.clamp(speed);
    if (_playbackSpeed == clamped) return;
    _playbackSpeed = clamped;
    notifyListeners();
    await _prefs.setDouble(_playbackSpeedKey, clamped);
  }

  bool get sleepTimerFadeOutEnabled => _sleepTimerFadeOutEnabled;

  Future<void> setSleepTimerFadeOutEnabled(bool enabled) async {
    if (_sleepTimerFadeOutEnabled == enabled) return;
    _sleepTimerFadeOutEnabled = enabled;
    notifyListeners();
    await _prefs.setBool(_sleepTimerFadeOutKey, enabled);
  }

  bool get sleepTimerDimScreenEnabled => _sleepTimerDimScreenEnabled;

  Future<void> setSleepTimerDimScreenEnabled(bool enabled) async {
    if (_sleepTimerDimScreenEnabled == enabled) return;
    _sleepTimerDimScreenEnabled = enabled;
    notifyListeners();
    await _prefs.setBool(_sleepTimerDimScreenKey, enabled);
  }

  bool get playbackFadeEnabled => _playbackFadeEnabled;

  Future<void> setPlaybackFadeEnabled(bool enabled) async {
    if (_playbackFadeEnabled == enabled) return;
    _playbackFadeEnabled = enabled;
    notifyListeners();
    await _prefs.setBool(_playbackFadeEnabledKey, enabled);
  }

  int get playbackFadeMs => _playbackFadeMs;

  Future<void> setPlaybackFadeMs(int ms) async {
    final clamped = ms.clamp(minPlaybackFadeMs, maxPlaybackFadeMs);
    if (_playbackFadeMs == clamped) return;
    _playbackFadeMs = clamped;
    notifyListeners();
    await _prefs.setInt(_playbackFadeMsKey, clamped);
  }

  int get lyricAutoScrollResumeSec => _lyricAutoScrollResumeSec;

  Future<void> setLyricAutoScrollResumeSec(int seconds) async {
    final clamped = seconds.clamp(
      minLyricAutoScrollResumeSec,
      maxLyricAutoScrollResumeSec,
    );
    if (_lyricAutoScrollResumeSec == clamped) return;
    _lyricAutoScrollResumeSec = clamped;
    notifyListeners();
    await _prefs.setInt(_lyricAutoScrollResumeSecKey, clamped);
  }

  // === Player cover backdrop clarity (0.0–1.0) ===
  double get playerBackdropClarity => _playerBackdropClarity;

  Future<void> setPlayerBackdropClarity(double clarity) async {
    final clamped = clarity.clamp(0.0, 1.0);
    if (_playerBackdropClarity == clamped) return;
    _playerBackdropClarity = clamped;
    notifyListeners();
    await _prefs.setDouble(_playerBackdropClarityKey, clamped);
  }

  // === Diagnostic log capture ===
  AppLogLevel get logCaptureMinLevel => _logCaptureMinLevel;

  Future<void> setLogCaptureMinLevel(AppLogLevel level) async {
    if (_logCaptureMinLevel == level) return;
    _logCaptureMinLevel = level;
    notifyListeners();
    await _prefs.setString(_logCaptureMinLevelKey, level.name);
  }
}
