import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xuro/core/settings/app_language.dart';
import 'package:xuro/core/settings/llm_batch_split_mode.dart';
import 'package:xuro/core/llm/llm_batch_planner.dart';
import 'package:xuro/core/settings/llm_subtitle_target_language.dart';

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
  // 跨多个列表 ViewModel 共享的「仅看带字幕作品」筛选。收敛到此单点，
  // 取代各 VM 自行 SharedPreferences.getInstance() + dispose 回写陈旧值。
  static const String _subtitleFilterKey = 'subtitle_filter';
  static const String _appLanguageKey = 'app_language';
  static const String _llmTranslationEnabledKey = 'llm_translation_enabled';
  static const String _llmApiEndpointKey = 'llm_api_endpoint';
  static const String _llmModelKey = 'llm_model';
  static const String _llmTargetLanguageKey = 'llm_target_language';
  static const String _llmSystemPromptKey = 'llm_system_prompt';
  static const String _llmJailbreakPromptKey = 'llm_jailbreak_prompt';
  static const String _llmJailbreakAutoKey = 'llm_jailbreak_auto';
  static const String _llmBatchSplitModeKey = 'llm_batch_split_mode';
  static const String _llmManualBatchSizeKey = 'llm_manual_batch_size';
  static const String _llmStreamingEnabledKey = 'llm_streaming_enabled';
  static const String _playbackVolumeKey = 'playback_volume';

  static const String defaultServerUrl = 'https://api.asmr.one/api';
  static const String defaultLlmApiEndpoint = 'https://api.openai.com/v1';
  static const String defaultLlmModel = 'gpt-4o-mini';
  static const String defaultOpenRouterEndpoint = 'https://openrouter.ai/api/v1';
  static const ColorVariant defaultColorVariant = ColorVariant.blue;
  static const AppLanguage defaultAppLanguage = AppLanguage.system;
  static const List<String> defaultAudioFormatOrder = [
    'mp3', 'flac', 'wav', 'opus', 'm4a', 'aac'
  ];

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
  late LlmSubtitleTargetLanguage _llmTargetLanguage;
  late String _llmSystemPromptOverride;
  late String _llmJailbreakPrompt;
  late bool _llmJailbreakAuto;
  late LlmBatchSplitMode _llmBatchSplitMode;
  late int _llmManualBatchSize;
  late bool _llmStreamingEnabled;
  late double _playbackVolume;

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
        _prefs.getString(_llmApiEndpointKey) ?? defaultLlmApiEndpoint;
    _llmModel = _prefs.getString(_llmModelKey) ?? defaultLlmModel;
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
    _playbackVolume = _prefs.getDouble(_playbackVolumeKey) ?? 1.0;
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
  /// `true` → 悬浮歌词可拖动调整位置；`false` → 锁定（点穿，默认）。
  bool get lyricOverlayUnlocked => _lyricOverlayUnlocked;

  Future<void> setLyricOverlayUnlocked(bool unlocked) async {
    if (_lyricOverlayUnlocked == unlocked) return;
    _lyricOverlayUnlocked = unlocked;
    notifyListeners();
    await _prefs.setBool(_lyricOverlayUnlockedKey, unlocked);
  }

  // === Background Play ===
  /// `true`（默认）→ 切后台继续播放（现有行为）；`false` → 切后台自动暂停。
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

  Future<void> setLlmModel(String model) async {
    final trimmed = model.trim();
    if (_llmModel == trimmed) return;
    _llmModel = trimmed;
    notifyListeners();
    await _prefs.setString(_llmModelKey, trimmed);
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

  // === Playback volume (0.0–1.0) ===
  double get playbackVolume => _playbackVolume;

  Future<void> setPlaybackVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    if (_playbackVolume == clamped) return;
    _playbackVolume = clamped;
    notifyListeners();
    await _prefs.setDouble(_playbackVolumeKey, clamped);
  }
}
