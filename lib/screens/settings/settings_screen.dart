import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/theme/theme_controller.dart';
import 'package:lizunemu/core/platform/wakelock_controller.dart';
import 'package:lizunemu/core/platform/sleep_timer_controller.dart';
import 'package:lizunemu/core/platform/lyric_overlay_manager.dart';
import 'package:lizunemu/screens/settings/sleep_timer_dialog.dart';
import 'package:lizunemu/core/settings/app_language.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/core/library/scan_roots_store.dart';
import 'package:lizunemu/screens/settings/cache_manager_screen.dart';
import 'package:lizunemu/screens/settings/audio_format_order_dialog.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/screens/settings/widgets/settings_group.dart';
import 'package:lizunemu/screens/settings/widgets/settings_tile.dart';
import 'package:lizunemu/screens/settings/widgets/settings_theme.dart';
import 'package:lizunemu/screens/settings/llm_translation_settings_screen.dart';
import 'package:lizunemu/utils/platform_capabilities.dart';
import 'package:lizunemu/widgets/player/player_equalizer_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final bgColor = SettingsTheme.pageBackground(context);

    return Scaffold(
      appBar: AppBar(title: Text(Strings.settings)),
      backgroundColor: bgColor,
      body: SettingsTheme.noSplashTheme(
        context: context,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space16),
          children: [
            _appearanceSection(),
            const SizedBox(height: AppSpacing.space24),
            _languageSection(),
            const SizedBox(height: AppSpacing.space24),
            _networkSection(),
            const SizedBox(height: AppSpacing.space24),
            _contentSection(context),
            const SizedBox(height: AppSpacing.space24),
            _localLibrarySection(),
            const SizedBox(height: AppSpacing.space24),
            _playbackSection(),
            const SizedBox(height: AppSpacing.space24),
            _llmTranslationSection(context),
            const SizedBox(height: AppSpacing.space24),
            if (PlatformCapabilities.supportsFloatingLyrics) ...[
              _lyricOverlaySection(),
              const SizedBox(height: AppSpacing.space24),
            ],
            _storageSection(context),
          ],
        ),
      ),
    );
  }

  Widget _appearanceSection() {
    return Consumer<ThemeController>(
      builder: (context, tc, _) => SettingsGroup(
        header: Strings.appearance,
        footer: Strings.themeAutoDesc,
        children: [
          SettingsTile.selection(
            title: Strings.followSystem,
            leading: Icons.brightness_auto_outlined,
            selected: tc.themeMode == ThemeMode.system,
            onTap: () => tc.setThemeMode(ThemeMode.system),
          ),
          SettingsTile.selection(
            title: Strings.lightMode,
            leading: Icons.light_mode_outlined,
            selected: tc.themeMode == ThemeMode.light,
            onTap: () => tc.setThemeMode(ThemeMode.light),
          ),
          SettingsTile.selection(
            title: Strings.darkMode,
            leading: Icons.dark_mode_outlined,
            selected: tc.themeMode == ThemeMode.dark,
            onTap: () => tc.setThemeMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }

  Widget _languageSection() {
    return Builder(builder: (context) {
      final settings = GetIt.I<AppSettingsService>();
      return ListenableBuilder(
        listenable: settings,
        builder: (context, _) => SettingsGroup(
          header: Strings.languageTitle,
          children: [
            SettingsTile.selection(
              title: Strings.languageSystem,
              leading: Icons.translate_outlined,
              selected: settings.appLanguage == AppLanguage.system,
              onTap: () => settings.setAppLanguage(AppLanguage.system),
            ),
            SettingsTile.selection(
              title: Strings.languageChinese,
              leading: Icons.language_outlined,
              selected: settings.appLanguage == AppLanguage.zh,
              onTap: () => settings.setAppLanguage(AppLanguage.zh),
            ),
            SettingsTile.selection(
              title: Strings.languageEnglish,
              leading: Icons.language_outlined,
              selected: settings.appLanguage == AppLanguage.en,
              onTap: () => settings.setAppLanguage(AppLanguage.en),
            ),
            SettingsTile.selection(
              title: Strings.languageThai,
              leading: Icons.language_outlined,
              selected: settings.appLanguage == AppLanguage.th,
              onTap: () => settings.setAppLanguage(AppLanguage.th),
            ),
          ],
        ),
      );
    });
  }

  String _serverLabel(String url) {
    switch (url) {
      case AppSettingsService.defaultServerUrl:
        return Strings.serverMain;
      case 'https://api.asmr-100.com/api':
        return Strings.serverNode1;
      case 'https://api.asmr-200.com/api':
        return Strings.serverNode2;
      case 'https://api.asmr-300.com/api':
        return Strings.serverNode3;
      default:
        return url;
    }
  }

  Widget _networkSection() {
    return Builder(builder: (context) {
      final settings = GetIt.I<AppSettingsService>();
      return ListenableBuilder(
        listenable: settings,
        builder: (context, _) => SettingsGroup(
          header: Strings.network,
          children: AppSettingsService.serverUrls.map((url) {
            return SettingsTile.selection(
              title: _serverLabel(url),
              subtitle: url,
              leading: Icons.lan_outlined,
              selected: settings.serverUrl == url,
              onTap: () => settings.setServerUrl(url),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _contentSection(BuildContext context) {
    return Builder(builder: (context) {
      final settings = GetIt.I<AppSettingsService>();
      return ListenableBuilder(
        listenable: settings,
        builder: (context, _) => SettingsGroup(
          header: Strings.content,
          children: [
            SettingsTile.toggle(
              title: Strings.smartPath,
              subtitle: Strings.smartPathDesc,
              leading: Icons.folder_open_outlined,
              value: settings.smartPathEnabled,
              onChanged: (v) => settings.setSmartPathEnabled(v),
            ),
            SettingsTile.navigation(
              title: Strings.audioFormatPreference,
              leading: Icons.audio_file_outlined,
              value: settings.audioFormatOrder.join(' > '),
              onTap: () => showDialog(
                context: context,
                builder: (_) => AudioFormatOrderDialog(settings: settings),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _localLibrarySection() {
    final store = GetIt.I<ScanRootsStore>();
    final roots = store.roots;
    return SettingsGroup(
      header: Strings.localLibraryScanFolders,
      children: [
        SettingsTile.navigation(
          title: Strings.localLibraryAddFolder,
          leading: Icons.folder_outlined,
          value: roots.isEmpty ? Strings.localLibraryEmpty : '${roots.length}',
          onTap: () async {
            final path = await FilePicker.platform.getDirectoryPath();
            if (path == null || path.isEmpty) return;
            await store.addRoot(path);
            if (mounted) setState(() {});
          },
        ),
        ...roots.map(
          (path) => SettingsTile.navigation(
            title: path,
            leading: Icons.music_note_outlined,
            value: '',
            onTap: () async {
              await store.removeRoot(path);
              if (mounted) setState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget _playbackSection() {
    return Builder(builder: (context) {
      final wakeLock = GetIt.I<WakeLockController>();
      final sleepTimer = GetIt.I<SleepTimerController>();
      final settings = GetIt.I<AppSettingsService>();
      return ListenableBuilder(
        listenable: Listenable.merge([wakeLock, sleepTimer, settings]),
        builder: (context, _) => SettingsGroup(
          header: Strings.playback,
          children: [
            SettingsTile.navigation(
              title: Strings.sleepTimer,
              leading: Icons.bedtime_outlined,
              value: sleepTimer.isActive
                  ? Strings.sleepTimerActiveSummary(
                      sleepTimer.minutes!,
                      sleepTimer.remaining ?? Duration.zero,
                    )
                  : Strings.sleepTimerOff,
              onTap: () => showDialog(
                context: context,
                builder: (_) => SleepTimerDialog(controller: sleepTimer),
              ),
            ),
            SettingsTile.toggle(
              title: Strings.sleepTimerFadeOut,
              subtitle: Strings.sleepTimerFadeOutDesc,
              leading: Icons.volume_down_outlined,
              value: settings.sleepTimerFadeOutEnabled,
              onChanged: settings.setSleepTimerFadeOutEnabled,
            ),
            SettingsTile.toggle(
              title: Strings.sleepTimerDimScreen,
              subtitle: Strings.sleepTimerDimScreenDesc,
              leading: Icons.brightness_4_outlined,
              value: settings.sleepTimerDimScreenEnabled,
              onChanged: settings.setSleepTimerDimScreenEnabled,
            ),
            SettingsTile.toggle(
              title: Strings.playbackFade,
              subtitle: Strings.playbackFadeDesc,
              leading: Icons.graphic_eq_outlined,
              value: settings.playbackFadeEnabled,
              onChanged: settings.setPlaybackFadeEnabled,
            ),
            if (settings.playbackFadeEnabled)
              _PlaybackFadeDurationSlider(settings: settings),
            if (PlatformCapabilities.supportsAndroidEqualizer)
              SettingsTile.navigation(
                title: Strings.equalizerTitle,
                subtitle: Strings.equalizerDesc,
                leading: Icons.equalizer,
                value: '',
                onTap: () => PlayerEqualizerSheet.show(context),
              ),
            SettingsTile.toggle(
              title: Strings.backgroundPlay,
              subtitle: Strings.backgroundPlayDesc,
              leading: Icons.play_circle_outline,
              value: settings.backgroundPlayEnabled,
              onChanged: (v) => settings.setBackgroundPlayEnabled(v),
            ),
            _PlayerBackdropClaritySlider(settings: settings),
            SettingsTile.toggle(
              title: Strings.screenKeepAwake,
              subtitle: Strings.screenKeepAwakeDesc,
              leading: Icons.wb_sunny_outlined,
              value: wakeLock.enabled,
              onChanged: (_) => wakeLock.toggle(),
            ),
          ],
        ),
      );
    });
  }

  Widget _llmTranslationSection(BuildContext context) {
    final settings = GetIt.I<AppSettingsService>();
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => SettingsGroup(
        header: Strings.llmTranslationTitle,
        footer: Strings.llmTranslationDesc,
        children: [
          SettingsTile.toggle(
            title: Strings.llmTranslationEnabled,
            leading: Icons.translate_outlined,
            value: settings.llmTranslationEnabled,
            onChanged: settings.setLlmTranslationEnabled,
          ),
          SettingsTile.navigation(
            title: Strings.llmTranslationConfigure,
            leading: Icons.tune_outlined,
            value: settings.llmModel,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    LlmTranslationSettingsScreen(settings: settings),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lyricOverlaySection() {
    return Builder(builder: (context) {
      final settings = GetIt.I<AppSettingsService>();
      final manager = GetIt.I<LyricOverlayManager>();
      return ListenableBuilder(
        listenable: settings,
        builder: (context, _) => SettingsGroup(
          header: Strings.lyricOverlaySection,
          footer: Strings.lyricOverlayUnlockDesc,
          children: [
            SettingsTile.toggle(
              title: Strings.lyricOverlayUnlockTitle,
              leading: Icons.lyrics_outlined,
              value: settings.lyricOverlayUnlocked,
              onChanged: (v) => manager.setUnlockedPreference(v),
            ),
          ],
        ),
      );
    });
  }

  Widget _storageSection(BuildContext context) {
    return SettingsGroup(
      header: Strings.storage,
      children: [
        SettingsTile.navigation(
          title: Strings.cacheManager,
          leading: Icons.storage_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CacheManagerScreen()),
          ),
        ),
      ],
    );
  }
}

class _PlaybackFadeDurationSlider extends StatelessWidget {
  const _PlaybackFadeDurationSlider({required this.settings});

  final AppSettingsService settings;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ms = settings.playbackFadeMs;
    final min = AppSettingsService.minPlaybackFadeMs.toDouble();
    final max = AppSettingsService.maxPlaybackFadeMs.toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space16,
        vertical: AppSpacing.space12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: AppSpacing.space40,
                height: AppSpacing.space40,
                child: Icon(
                  Icons.timer_outlined,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Strings.playbackFadeDuration,
                      style: Theme.of(context).textTheme.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      Strings.playbackFadeDurationDesc,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              Text(
                Strings.playbackFadeDurationMs(ms),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.space40 + AppSpacing.space12,
            ),
            child: Slider(
              value: ms.toDouble(),
              min: min,
              max: max,
              divisions: ((max - min) / 50).round(),
              onChanged: (v) => settings.setPlaybackFadeMs(v.round()),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerBackdropClaritySlider extends StatelessWidget {
  const _PlayerBackdropClaritySlider({required this.settings});

  final AppSettingsService settings;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final clarity = settings.playerBackdropClarity;
    final percentLabel = '${(clarity * 100).round()}%';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space16,
        vertical: AppSpacing.space12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: AppSpacing.space40,
                height: AppSpacing.space40,
                child: Icon(
                  Icons.blur_on_outlined,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Strings.playerBackdropClarity,
                      style: Theme.of(context).textTheme.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      Strings.playerBackdropClarityDesc,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              Text(
                percentLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.space40 + AppSpacing.space12,
            ),
            child: Slider(
              value: clarity,
              onChanged: settings.setPlayerBackdropClarity,
            ),
          ),
        ],
      ),
    );
  }
}
