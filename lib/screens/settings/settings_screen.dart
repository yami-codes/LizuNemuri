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
import 'package:lizunemu/core/settings/metadata_translation_mode.dart';
import 'package:lizunemu/core/settings/metadata_translation_provider.dart';
import 'package:lizunemu/core/library/scan_roots_store.dart';
import 'package:lizunemu/screens/settings/app_log_viewer_screen.dart';
import 'package:lizunemu/screens/settings/cache_manager_screen.dart';
import 'package:lizunemu/screens/settings/audio_format_order_dialog.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/screens/settings/widgets/settings_group.dart';
import 'package:lizunemu/screens/settings/widgets/settings_tile.dart';
import 'package:lizunemu/screens/settings/widgets/settings_theme.dart';
import 'package:lizunemu/screens/settings/llm_translation_settings_screen.dart';
import 'package:lizunemu/screens/lore/global_character_library_screen.dart';
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
            _metadataTranslationSection(context),
            const SizedBox(height: AppSpacing.space24),
            _loreSection(context),
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
            _LyricAutoScrollResumeSlider(settings: settings),
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
            value: settings.llmMainModel,
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

  Widget _loreSection(BuildContext context) {
    final settings = GetIt.I<AppSettingsService>();
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final lang = settings.loreLanguageCode;
        final langLabel = lang.isEmpty
            ? Strings.loreLanguageFollowApp
            : lang;
        return SettingsGroup(
          header: Strings.loreSettingsTitle,
          children: [
            SettingsTile.navigation(
              title: Strings.loreLanguage,
              subtitle: Strings.loreLanguageDesc,
              leading: Icons.language_outlined,
              value: langLabel,
              onTap: () async {
                final picked = await showDialog<String>(
                  context: context,
                  builder: (ctx) => SimpleDialog(
                    title: Text(Strings.loreLanguage),
                    children: [
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, ''),
                        child: Text(Strings.loreLanguageFollowApp),
                      ),
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, 'zh'),
                        child: const Text('中文'),
                      ),
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, 'en'),
                        child: const Text('English'),
                      ),
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, 'th'),
                        child: const Text('ไทย'),
                      ),
                    ],
                  ),
                );
                if (picked != null) {
                  await settings.setLoreLanguageCode(picked);
                }
              },
            ),
            SettingsTile.navigation(
              title: Strings.loreMaxTracks,
              subtitle: Strings.loreMaxTracksDesc,
              leading: Icons.queue_music_outlined,
              value: '${settings.maxLoreTracksPerGenerate}',
              onTap: () async {
                final controller = TextEditingController(
                  text: '${settings.maxLoreTracksPerGenerate}',
                );
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(Strings.loreMaxTracks),
                    content: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(Strings.loreCancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(Strings.loreSaved),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  final n = int.tryParse(controller.text.trim());
                  if (n != null) {
                    await settings.setMaxLoreTracksPerGenerate(n);
                  }
                }
              },
            ),
            SettingsTile.navigation(
              title: Strings.loreGlobalLibrary,
              subtitle: Strings.loreGlobalLibraryDesc,
              leading: Icons.menu_book_outlined,
              value: '',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GlobalCharacterLibraryScreen(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _metadataTranslationSection(BuildContext context) {
    final settings = GetIt.I<AppSettingsService>();
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => SettingsGroup(
        header: Strings.metadataTranslationTitle,
        footer: Strings.metadataTranslationDesc,
        children: [
          SettingsTile.toggle(
            title: Strings.metadataTranslationEnabled,
            leading: Icons.title_outlined,
            value: settings.metadataTranslationEnabled,
            onChanged: settings.setMetadataTranslationEnabled,
          ),
          SettingsTile.selection(
            title: Strings.metadataTranslationProviderGoogle,
            leading: Icons.g_translate,
            selected: settings.metadataTranslationProvider ==
                MetadataTranslationProvider.google,
            onTap: () => settings.setMetadataTranslationProvider(
              MetadataTranslationProvider.google,
            ),
          ),
          SettingsTile.selection(
            title: Strings.metadataTranslationProviderLlm,
            leading: Icons.smart_toy_outlined,
            selected: settings.metadataTranslationProvider ==
                MetadataTranslationProvider.llm,
            onTap: () => settings.setMetadataTranslationProvider(
              MetadataTranslationProvider.llm,
            ),
          ),
          SettingsTile.selection(
            title: Strings.metadataTranslationModeAuto,
            subtitle: Strings.metadataTranslationModeAutoDesc,
            leading: Icons.auto_fix_high_outlined,
            selected: settings.metadataTranslationMode ==
                MetadataTranslationMode.auto,
            onTap: () => settings.setMetadataTranslationMode(
              MetadataTranslationMode.auto,
            ),
          ),
          SettingsTile.selection(
            title: Strings.metadataTranslationModeManual,
            subtitle: Strings.metadataTranslationModeManualDesc,
            leading: Icons.touch_app_outlined,
            selected: settings.metadataTranslationMode ==
                MetadataTranslationMode.manual,
            onTap: () => settings.setMetadataTranslationMode(
              MetadataTranslationMode.manual,
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
        SettingsTile.navigation(
          title: Strings.logViewerTitle,
          subtitle: Strings.logViewerSettingsDesc,
          leading: Icons.bug_report_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AppLogViewerScreen()),
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

class _LyricAutoScrollResumeSlider extends StatelessWidget {
  const _LyricAutoScrollResumeSlider({required this.settings});

  final AppSettingsService settings;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sec = settings.lyricAutoScrollResumeSec;
    final min = AppSettingsService.minLyricAutoScrollResumeSec.toDouble();
    final max = AppSettingsService.maxLyricAutoScrollResumeSec.toDouble();

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
                  Icons.lyrics_outlined,
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
                      Strings.lyricAutoScrollResume,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      Strings.lyricAutoScrollResumeDesc,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              Text(
                Strings.lyricAutoScrollResumeSec(sec),
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
              value: sec.toDouble(),
              min: min,
              max: max,
              divisions: (max - min).round(),
              onChanged: (v) => settings.setLyricAutoScrollResumeSec(v.round()),
            ),
          ),
        ],
      ),
    );
  }
}

