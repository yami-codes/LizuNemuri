import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lizunemu/common/constants/log_strings.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/audio/cache/audio_cache_manager.dart';
import 'package:lizunemu/core/cache/cache_lifecycle_manager.dart';
import 'package:lizunemu/core/platform/background_play_controller.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/presentation/viewmodels/auth_viewmodel.dart';
import 'package:lizunemu/utils/platform_capabilities.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'core/di/service_locator.dart';
import 'package:provider/provider.dart';
import 'screens/main_screen.dart';
import 'package:lizunemu/core/theme/app_theme.dart';
import 'package:lizunemu/core/audio/effects/audio_effects_controller.dart';
import 'package:lizunemu/core/theme/dynamic_hue_controller.dart';
import 'package:lizunemu/core/theme/theme_controller.dart';
import 'package:lizunemu/core/database/database_bootstrap.dart';
import 'screens/search_screen.dart';

void main() async {
  final startupStopwatch = kDebugMode ? (Stopwatch()..start()) : null;
  WidgetsFlutterBinding.ensureInitialized();

  if (PlatformCapabilities.isLinux) {
    JustAudioMediaKit.ensureInitialized(
      linux: true,
      windows: false,
    );
  }

  await bootstrapDatabaseFactory();

  // In-memory image cache budget cap
  PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20; // 100 MiB

  // Initialize service locator with first-frame essentials only: prefs + saved auth —
  // MainScreen ViewModels fire tokenized requests in their constructors; deferring auth
  // would send the first batch without a token and misreport login state.
  await setupServiceLocator();

  runApp(const MyApp());

  // Cache lifecycle / legacy cleanup already runs after runApp; CacheLifecycleManager
  // defers its first scan via addPostFrameCallback with a 6h throttle; cleanLegacyCache is
  // fire-and-forget. Call directly — no extra post-frame wrapper or startup cleanup slips later.
  CacheLifecycleManager().initialize();
  AudioCacheManager.cleanLegacyCache();

  // Background-play switch: register lifecycle observer (default on preserves behavior).
  getIt<BackgroundPlayController>().initialize();

  // Lyric overlay init does platform I/O; defer until after first frame to avoid jank.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (kDebugMode) {
      startupStopwatch!.stop();
      debugPrint(
        LogStrings.logStartupFirstFrame(
          startupStopwatch.elapsedMilliseconds.toString(),
        ),
      );
    }
    initDeferredStartupServices();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => getIt<AuthViewModel>(),
        ),
        ChangeNotifierProvider(
          create: (_) => getIt<ThemeController>(),
        ),
        ChangeNotifierProvider.value(
          value: getIt<AppSettingsService>(),
        ),
        ChangeNotifierProvider.value(
          value: getIt<DynamicHueController>(),
        ),
        ChangeNotifierProvider.value(
          value: getIt<AudioEffectsController>(),
        ),
      ],
      child: Consumer2<ThemeController, DynamicHueController>(
        builder: (context, themeController, hueController, child) {
          return MaterialApp(
            key: ValueKey(getIt<AppSettingsService>().appLanguage),
            title: Strings.appName,
            locale: getIt<AppSettingsService>().materialLocale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.fromColorScheme(hueController.lightScheme),
            darkTheme: AppTheme.fromColorScheme(hueController.darkScheme),
            themeMode: themeController.themeMode,
            home: const MainScreen(),
            routes: {
              // '/player': (context) => const PlayerScreen(),
              '/search': (context) {
                final keyword =
                    ModalRoute.of(context)?.settings.arguments as String?;
                return SearchScreen(initialKeyword: keyword);
              },
            },
          );
        },
      ),
    );
  }
}
