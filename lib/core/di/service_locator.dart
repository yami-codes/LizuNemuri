import 'package:lizunemu/core/lore/ccv2_export_service.dart';
import 'package:lizunemu/core/lore/global_character_service.dart';
import 'package:lizunemu/core/lore/storage/ccv2_card_cache_repository.dart';
import 'package:lizunemu/core/lore/storage/global_character_repository.dart';
import 'package:lizunemu/core/lore/storage/work_lore_repository.dart';
import 'package:lizunemu/core/lore/work_lore_service.dart';
import 'package:lizunemu/utils/platform_capabilities.dart';
import 'package:dio/dio.dart';
import 'package:lizunemu/data/services/interceptors/retry_interceptor.dart';
import 'package:lizunemu/data/services/interceptors/accept_language_interceptor.dart';
import 'package:lizunemu/core/platform/dummy_lyric_overlay_controller.dart';
import 'package:get_it/get_it.dart';
import '../audio/i_audio_player_service.dart';
import '../audio/audio_player_service.dart';
import '../../data/services/api_service.dart';
import '../../data/services/update_service.dart';
import '../../presentation/viewmodels/player_viewmodel.dart';
import '../../data/services/auth_service.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/auth_repository.dart';
import '../subtitle/i_subtitle_service.dart';
import '../subtitle/subtitle_service.dart';
import '../subtitle/subtitle_loader.dart';
import '../../core/audio/storage/i_playback_state_repository.dart';
import '../../core/audio/storage/playback_state_repository.dart';
import '../audio/events/playback_event_hub.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/platform/i_lyric_overlay_controller.dart';
import '../../core/platform/lyric_overlay_controller.dart';
import '../../core/platform/lyric_overlay_manager.dart';
import '../../core/platform/wakelock_controller.dart';
import '../../core/platform/sleep_timer_controller.dart';
import '../../core/platform/background_play_controller.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/core/database/database_service.dart';
import 'package:lizunemu/core/subtitle/storage/i_user_subtitle_repository.dart';
import 'package:lizunemu/core/subtitle/storage/user_subtitle_repository.dart';
import 'package:lizunemu/core/subtitle/import/i_file_picker_service.dart';
import 'package:lizunemu/core/subtitle/import/file_picker_service.dart';
import 'package:lizunemu/core/subtitle/subtitle_import_service.dart';
import 'package:lizunemu/core/download/storage/i_download_repository.dart';
import 'package:lizunemu/core/download/storage/download_repository.dart';
import 'package:lizunemu/data/repositories/llm_api_key_repository.dart';
import 'package:lizunemu/data/repositories/llm_usage_repository.dart';
import 'package:lizunemu/data/services/llm_client.dart';
import 'package:lizunemu/data/services/llm_model_catalog_service.dart';
import 'package:lizunemu/core/llm/subtitle_translation_service.dart';
import 'package:lizunemu/core/llm/llm_request_gate.dart';
import 'package:lizunemu/core/llm/translation_queue_service.dart';
import 'package:lizunemu/core/llm/translation_queue_store.dart';
import 'package:lizunemu/core/llm/work_title_translation_service.dart';
import 'package:lizunemu/core/translation/metadata_translation_service.dart';
import 'package:lizunemu/data/services/google_translate_client.dart';
import 'package:lizunemu/core/media/work_media_url_refresher.dart';
import 'package:lizunemu/core/download/download_service.dart';
import 'package:lizunemu/core/library/scan_roots_store.dart';
import 'package:lizunemu/core/library/storage/local_library_repository.dart';
import 'package:lizunemu/core/dlsite/auth/dlsite_auth_repository.dart';
import 'package:lizunemu/core/dlsite/dlsite_play_library_service.dart';
import 'package:lizunemu/core/dlsite/dlsite_play_work_service.dart';
import 'package:lizunemu/core/theme/dynamic_hue_controller.dart';
import 'package:lizunemu/core/audio/effects/audio_effects_controller.dart';
import 'package:lizunemu/core/logging/app_log_store.dart';
import 'package:lizunemu/utils/logger.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  final prefs = await SharedPreferences.getInstance();

  // Register EventHub
  getIt.registerLazySingleton(() => PlaybackEventHub());

  // Register SharedPreferences instance
  getIt.registerSingleton<SharedPreferences>(prefs);

  // Database service
  getIt.registerLazySingleton<DatabaseService>(() => DatabaseService());

  // User subtitle storage
  getIt.registerLazySingleton<IUserSubtitleRepository>(
    () => UserSubtitleRepository(getIt<DatabaseService>()),
  );

  // File picker
  getIt.registerLazySingleton<IFilePickerService>(() => FilePickerService());

  // Subtitle import service
  getIt.registerLazySingleton<SubtitleImportService>(
    () => SubtitleImportService(
      picker: getIt<IFilePickerService>(),
      repository: getIt<IUserSubtitleRepository>(),
    ),
  );

  // Download storage + service (depends on DatabaseService registered above)
  getIt.registerLazySingleton<IDownloadRepository>(
    () => DownloadRepository(getIt<DatabaseService>()),
  );
  getIt.registerLazySingleton<DownloadService>(() {
    final dio = Dio();
    dio.interceptors.add(const AcceptLanguageInterceptor());
    return DownloadService(repository: getIt<IDownloadRepository>(), dio: dio);
  });

  // Register PlaybackStateRepository
  getIt.registerLazySingleton<IPlaybackStateRepository>(
    () => PlaybackStateRepository(getIt()),
  );

  // Core services
  getIt.registerLazySingleton<IAudioPlayerService>(
    () => AudioPlayerService(
      eventHub: getIt(),
      stateRepository: getIt(),
    ),
  );

  // Register PlayerViewModel
  getIt.registerLazySingleton<PlayerViewModel>(
    () => PlayerViewModel(
      audioService: getIt(),
      eventHub: getIt(),
      subtitleService: getIt(),
    ),
  );

  getIt.registerLazySingleton<DynamicHueController>(
    () => DynamicHueController(playerViewModel: getIt<PlayerViewModel>()),
  );

  getIt.registerLazySingleton<AudioEffectsController>(
    () => AudioEffectsController(),
  );

  getIt.registerLazySingleton<ScanRootsStore>(
    () => ScanRootsStore(prefs),
  );

  getIt.registerLazySingleton<LocalLibraryRepository>(
    () => LocalLibraryRepository(getIt<DatabaseService>()),
  );

  getIt.registerLazySingleton<DlsiteAuthRepository>(
    () => DlsiteAuthRepository(),
  );
  getIt.registerLazySingleton<DlsitePlayLibraryService>(
    () => DlsitePlayLibraryService(getIt<DlsiteAuthRepository>()),
  );
  getIt.registerLazySingleton<DlsitePlayWorkService>(
    () => DlsitePlayWorkService(getIt<DlsiteAuthRepository>()),
  );

  // Register AppSettingsService
  getIt.registerSingleton<AppSettingsService>(
    AppSettingsService(prefs),
  );

  getIt.registerLazySingleton<AppLogStore>(() => AppLogStore());

  AppLogger.configure(
    store: getIt<AppLogStore>(),
    captureMinLevel: getIt<AppSettingsService>().logCaptureMinLevel,
    consoleEnabled: true,
  );

  getIt.registerLazySingleton<LlmApiKeyRepository>(
    () => LlmApiKeyRepository(prefs),
  );

  getIt.registerLazySingleton<LlmUsageRepository>(
    () => LlmUsageRepository(prefs),
  );

  getIt.registerLazySingleton<LlmModelCatalogService>(
    () => LlmModelCatalogService(),
  );

  getIt.registerLazySingleton<LlmClient>(
    () => LlmClient(getIt<AppSettingsService>(), getIt<LlmApiKeyRepository>()),
  );

  getIt.registerLazySingleton<WorkLoreRepository>(
    () => WorkLoreRepository(getIt<DatabaseService>()),
  );
  getIt.registerLazySingleton<GlobalCharacterRepository>(
    () => GlobalCharacterRepository(getIt<DatabaseService>()),
  );
  getIt.registerLazySingleton<Ccv2CardCacheRepository>(
    () => Ccv2CardCacheRepository(getIt<DatabaseService>()),
  );
  getIt.registerLazySingleton<WorkLoreService>(
    () => WorkLoreService(
      llm: getIt<LlmClient>(),
      settings: getIt<AppSettingsService>(),
      repo: getIt<WorkLoreRepository>(),
      ccv2Cache: getIt<Ccv2CardCacheRepository>(),
    ),
  );
  getIt.registerLazySingleton<Ccv2ExportService>(
    () => Ccv2ExportService(
      llm: getIt<LlmClient>(),
      cache: getIt<Ccv2CardCacheRepository>(),
    ),
  );
  getIt.registerLazySingleton<GlobalCharacterService>(
    () => GlobalCharacterService(
      repo: getIt<GlobalCharacterRepository>(),
      loreService: getIt<WorkLoreService>(),
    ),
  );

  getIt.registerLazySingleton<LlmRequestGate>(
    () => LlmRequestGate(maxConcurrent: 2),
  );

  getIt.registerLazySingleton<SubtitleTranslationService>(
    () => SubtitleTranslationService(
      settings: getIt<AppSettingsService>(),
      client: getIt<LlmClient>(),
      apiKeyRepo: getIt<LlmApiKeyRepository>(),
      usageRepo: getIt<LlmUsageRepository>(),
      gate: getIt<LlmRequestGate>(),
    ),
  );

  getIt.registerLazySingleton<GoogleTranslateClient>(
    () => GoogleTranslateClient(),
  );

  getIt.registerLazySingleton<MetadataTranslationService>(
    () => MetadataTranslationService(
      settings: getIt<AppSettingsService>(),
      google: getIt<GoogleTranslateClient>(),
      llm: getIt<LlmClient>(),
      apiKeyRepo: getIt<LlmApiKeyRepository>(),
      usageRepo: getIt<LlmUsageRepository>(),
    ),
  );

  getIt.registerLazySingleton<WorkTitleTranslationService>(
    () => WorkTitleTranslationService(
      metadata: getIt<MetadataTranslationService>(),
    ),
  );

  // API services
  getIt.registerLazySingleton<ApiService>(
    () => ApiService(settings: getIt<AppSettingsService>()),
  );

  getIt.registerLazySingleton<WorkMediaUrlRefresher>(
    () => WorkMediaUrlRefresher(getIt<ApiService>()),
  );

  // Update check service (standalone GitHub Dio, decoupled from asmr nodes)
  getIt.registerLazySingleton<UpdateService>(
    () => UpdateService(),
  );

  // Register AuthService
  getIt.registerLazySingleton<AuthService>(
    () => AuthService(settings: getIt<AppSettingsService>()),
  );

  // Register AuthRepository
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(prefs),
  );

  // Register AuthViewModel
  getIt.registerSingleton<AuthViewModel>(
    AuthViewModel(
      authService: getIt<AuthService>(),
      authRepository: getIt<AuthRepository>(),
    ),
  );

  // Wait for AuthViewModel initialization
  await getIt<AuthViewModel>().loadSavedAuth();

  // Register subtitle services
  getIt.registerLazySingleton<ISubtitleService>(
    () => SubtitleService(),
  );

  setupSubtitleServices();

  getIt.registerLazySingleton<TranslationQueueStore>(
    () => TranslationQueueStore(prefs),
  );
  getIt.registerLazySingleton<TranslationQueueService>(
    () => TranslationQueueService(
      settings: getIt<AppSettingsService>(),
      translation: getIt<SubtitleTranslationService>(),
      download: getIt<DownloadService>(),
      subtitleLoader: getIt<SubtitleLoader>(),
      importService: getIt<SubtitleImportService>(),
      store: getIt<TranslationQueueStore>(),
    ),
  );

  // Register theme controller
  getIt.registerLazySingleton<ThemeController>(
    () => ThemeController(prefs),
  );

  // Register WakeLockController
  getIt.registerLazySingleton(() => WakeLockController(prefs));

  // Register SleepTimerController (session-only; expires to pause(), not persisted)
  getIt.registerLazySingleton(
    () => SleepTimerController(
      getIt<IAudioPlayerService>(),
      getIt<AppSettingsService>(),
    ),
  );

  // Register BackgroundPlayController (background-play switch; initialize in main)
  getIt.registerLazySingleton(
    () => BackgroundPlayController(
      settings: getIt<AppSettingsService>(),
      audioService: getIt<IAudioPlayerService>(),
    ),
  );
}

void setupSubtitleServices() {
  getIt.registerLazySingleton<SubtitleLoader>(() {
    // Presigned mediaDownloadUrl must not carry AuthInterceptor — CDN rejects
    // extra Authorization headers (403) while Android streaming stays tokenless.
    final dio = Dio();
    dio.interceptors.add(const AcceptLanguageInterceptor());
    dio.interceptors.add(RetryInterceptor(dio: dio));
    return SubtitleLoader(dio: dio);
  });
  if (PlatformCapabilities.isAndroid) {
    getIt.registerLazySingleton<ILyricOverlayController>(() => LyricOverlayController());
  } else {
    getIt.registerLazySingleton<ILyricOverlayController>(() => DummyLyricOverlayController());
  }
  getIt.registerLazySingleton(() => LyricOverlayManager(
    controller: getIt(),
    subtitleService: getIt(),
    settings: getIt<AppSettingsService>(),
    playerViewModel: getIt<PlayerViewModel>(),
  ));
}

/// Non-critical startup work deferred until after the first frame.
///
/// `LyricOverlayManager.initialize()` does platform-channel round-trips (controller.initialize /
/// isShowing). Running that on the cold-start critical path (before runApp) delays the first
/// interactive frame; floating lyrics are not needed until playback and user opt-in — defer until after first paint.
Future<void> initDeferredStartupServices() async {
  await getIt<LyricOverlayManager>().initialize();
  await getIt<TranslationQueueService>().initialize();
}
