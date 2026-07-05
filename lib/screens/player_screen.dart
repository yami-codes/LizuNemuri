import 'package:lizunemu/core/platform/lyric_overlay_manager.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lizunemu/presentation/viewmodels/player_viewmodel.dart';
import 'package:lizunemu/core/theme/app_spacing.dart';
import 'package:lizunemu/widgets/player/player_controls.dart';
import 'package:lizunemu/widgets/player/waveform_progress.dart';
import 'package:lizunemu/widgets/player/player_art_panel.dart';
import 'package:lizunemu/widgets/player/volume_control.dart';
import 'package:lizunemu/widgets/player/player_speed_button.dart';
import 'package:lizunemu/widgets/player/sleep_mode_dim_overlay.dart';
import 'package:lizunemu/widgets/player/cover_artwork_background.dart';
import 'package:lizunemu/widgets/player/player_cover_palette_loader.dart';
import 'package:lizunemu/widgets/player/player_immersive_scope.dart';
import 'package:lizunemu/widgets/player/player_surface_transition.dart';
import 'package:lizunemu/presentation/layouts/player_layout_config.dart';
import 'package:lizunemu/screens/detail_screen.dart';
import 'package:lizunemu/widgets/lyrics/components/player_lyric_view.dart';
import 'package:lizunemu/utils/platform_capabilities.dart';
import 'package:lizunemu/core/platform/wakelock_controller.dart';
import 'package:lizunemu/core/platform/sleep_timer_controller.dart';
import 'package:lizunemu/screens/settings/sleep_timer_dialog.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/screens/settings/llm_translation_settings_screen.dart';
import 'package:lizunemu/core/subtitle/subtitle_import_service.dart';
import 'package:lizunemu/widgets/player/player_equalizer_sheet.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _LyricOverlayAction extends StatefulWidget {
  const _LyricOverlayAction({required this.manager});

  final LyricOverlayManager manager;

  @override
  State<_LyricOverlayAction> createState() => _LyricOverlayActionState();
}

class _LyricOverlayActionState extends State<_LyricOverlayAction> {
  Future<void> _onTap() async {
    await widget.manager.toggle(context);
    if (mounted) setState(() {});
  }

  Future<void> _onLongPress() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!widget.manager.isShowing) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(Strings.lyricOverlayEnterFirstHint),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    await widget.manager.toggleEditable();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(widget.manager.isEditable
            ? Strings.lyricOverlayEditEntered
            : Strings.lyricOverlayEditExited),
        duration: const Duration(seconds: 2),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final manager = widget.manager;
    final theme = Theme.of(context);
    final iconColor = manager.isEditable ? theme.colorScheme.primary : null;
    final tooltipMsg = manager.isShowing
        ? (manager.isEditable
            ? Strings.lyricOverlayTooltipExitEdit
            : Strings.lyricOverlayTooltipLongPressHint)
        : Strings.lyricOverlayTooltipEnable;
    return Tooltip(
      message: tooltipMsg,
      child: InkResponse(
        radius: 24,
        onTap: _onTap,
        onLongPress: _onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space12),
          child: Icon(
            manager.isShowing ? Icons.lyrics : Icons.lyrics_outlined,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _showLyrics = false;
  bool _canSwitchView = true;
  late final PlayerViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = GetIt.I<PlayerViewModel>();
    _viewModel.addListener(_onViewModelUpdate);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelUpdate);
    super.dispose();
  }

  void _onViewModelUpdate() {
    final feedback = _viewModel.takeTranslationFeedback();
    if (feedback == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(feedback)),
    );
  }

  Widget _buildViewModeToggle({required bool isWide}) {
    if (isWide) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space8,
        AppSpacing.space16,
        0,
      ),
      child: SegmentedButton<bool>(
        segments: [
          ButtonSegment<bool>(
            value: false,
            label: Text(Strings.playerViewCover),
            icon: const Icon(Icons.album_outlined, size: 18),
          ),
          ButtonSegment<bool>(
            value: true,
            label: Text(Strings.playerViewSubtitles),
            icon: const Icon(Icons.subtitles_outlined, size: 18),
          ),
        ],
        selected: {_showLyrics},
        onSelectionChanged: (selection) {
          setState(() => _showLyrics = selection.first);
        },
      ),
    );
  }

  Widget _buildNarrowContent(double coverSize) {
    return PlayerSurfaceSwitcher(
      showLyrics: _showLyrics,
      coverChild: Center(
        child: PlayerArtPanel(
          viewModel: _viewModel,
          coverSize: coverSize,
        ),
      ),
      lyricsChild: PlayerLyricView(
        onScrollStateChanged: (canSwitch) {
          setState(() => _canSwitchView = canSwitch);
        },
      ),
    );
  }

  Widget _buildWideContent(double coverSize) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: PlayerArtPanel(
                viewModel: _viewModel,
                coverSize: coverSize,
              ),
            ),
          ),
        ),
        VerticalDivider(
          width: 1,
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space16,
                  AppSpacing.space12,
                  AppSpacing.space16,
                  AppSpacing.space8,
                ),
                child: Text(
                  Strings.playerViewSubtitles,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ),
              Expanded(
                child: PlayerLyricView(
                  lockParentViewSwitch: false,
                  compact: true,
                  onScrollStateChanged: (_) {},
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTranslationBanner() {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final status = _viewModel.translationStatus;
        if (!_viewModel.isTranslating || status == null) {
          return const SizedBox.shrink();
        }
        final cs = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space12,
            0,
            AppSpacing.space12,
            AppSpacing.space8,
          ),
          child: Material(
            color: cs.primaryContainer.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space12,
                vertical: AppSpacing.space8,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  Expanded(
                    child: Text(
                      status,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface,
                          ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlsBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space12,
        0,
        AppSpacing.space12,
        AppSpacing.space32,
      ),
      child: const Column(
        children: [
          WaveformProgress(),
          SizedBox(height: AppSpacing.space8),
          PlayerControls(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lyricManager = GetIt.I<LyricOverlayManager>();
    final wakeLockController = GetIt.I<WakeLockController>();
    final sleepTimer = GetIt.I<SleepTimerController>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final coverUrl = _viewModel.currentTrackInfo?.coverUrl;

        return PlayerCoverPaletteLoader(
          coverUrl: coverUrl,
          fallbackPrimary: cs.primary,
          background: cs.surface,
          isDark: isDark,
          builder: (context, palette) {
            final settings = GetIt.I<AppSettingsService>();
            return ListenableBuilder(
              listenable: settings,
              builder: (context, _) {
                final clarity = settings.playerBackdropClarity;
                final immersive = PlayerImmersiveColors.resolve(
                  context: context,
                  palette: palette,
                  coverBackgroundEnabled: true,
                  clarity: clarity,
                );

                return PlayerImmersiveScope(
                  colors: immersive,
                  child: Scaffold(
                extendBodyBehindAppBar: true,
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.expand_more),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  actions: [
                    if (PlatformCapabilities.supportsAndroidEqualizer)
                      IconButton(
                        icon: const Icon(Icons.equalizer),
                        tooltip: Strings.equalizerTitle,
                        onPressed: () => PlayerEqualizerSheet.show(context),
                      ),
                    PlayerVolumeButton(viewModel: _viewModel),
                    PlayerSpeedButton(viewModel: _viewModel),
                    ListenableBuilder(
                      listenable: sleepTimer,
                      builder: (context, _) {
                        return IconButton(
                          icon: Icon(
                            sleepTimer.isActive
                                ? Icons.bedtime
                                : Icons.bedtime_outlined,
                            color:
                                sleepTimer.isActive ? cs.primary : null,
                          ),
                          tooltip: Strings.sleepTimer,
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) =>
                                SleepTimerDialog(controller: sleepTimer),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () {
                        final currentWork = _viewModel.currentContext?.work;
                        if (currentWork != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DetailScreen(
                                work: currentWork,
                                fromPlayer: true,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    ListenableBuilder(
                      listenable: _viewModel,
                      builder: (context, _) {
                        return PopupMenuButton<String>(
                          icon: _viewModel.isTranslating
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: cs.primary,
                                  ),
                                )
                              : Icon(
                                  Icons.subtitles,
                                  color: _viewModel.isLlmTranslated ||
                                          _viewModel.isUserImportedSubtitle
                                      ? cs.primary
                                      : null,
                                ),
                          onSelected: (value) async {
                            if (value == 'import') {
                              final result =
                                  await _viewModel.importSubtitle();
                              if (!context.mounted) return;
                              final message = switch (result) {
                                ImportResult.success => Strings.importSuccess,
                                ImportResult.cancelled => null,
                                ImportResult.invalidFormat =>
                                  Strings.importInvalidFormat,
                                ImportResult.fileTooLarge =>
                                  Strings.importFileTooLarge,
                                ImportResult.parseFailed =>
                                  Strings.importParseFailed,
                                ImportResult.ioError => Strings.importIoError,
                              };
                              if (message != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(message)),
                                );
                              }
                            } else if (value == 'remove') {
                              await _viewModel.removeImportedSubtitle();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(Strings.subtitleRemoved)),
                              );
                            } else if (value == 'llm_translate') {
                              final err =
                                  await _viewModel.translateSubtitlesNow();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    err ?? Strings.llmTranslationDone,
                                  ),
                                ),
                              );
                            } else if (value == 'llm_original') {
                              final err =
                                  await _viewModel.restoreOriginalSubtitles();
                              if (!context.mounted) return;
                              if (err != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(err)),
                                );
                              }
                            } else if (value == 'llm_settings') {
                              if (!context.mounted) return;
                              final settings = GetIt.I<AppSettingsService>();
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LlmTranslationSettingsScreen(
                                      settings: settings),
                                ),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'import',
                              child: Text(Strings.importSubtitle),
                            ),
                            if (_viewModel.hasSubtitles)
                              PopupMenuItem(
                                value: 'llm_translate',
                                enabled: !_viewModel.isTranslating,
                                child: Text(Strings.llmTranslateNow),
                              ),
                            if (_viewModel.isLlmTranslated)
                              PopupMenuItem(
                                value: 'llm_original',
                                enabled: !_viewModel.isTranslating,
                                child: Text(Strings.llmShowOriginal),
                              ),
                            PopupMenuItem(
                              value: 'llm_settings',
                              child: Text(Strings.llmTranslationConfigure),
                            ),
                            if (_viewModel.isUserImportedSubtitle)
                              PopupMenuItem(
                                value: 'remove',
                                child: Text(Strings.removeImportedSubtitle),
                              ),
                          ],
                        );
                      },
                    ),
                    if (PlatformCapabilities.supportsFloatingLyrics)
                      _LyricOverlayAction(manager: lyricManager),
                    ListenableBuilder(
                      listenable: wakeLockController,
                      builder: (context, _) {
                        return IconButton(
                          icon: Icon(
                            wakeLockController.enabled
                                ? Icons.lightbulb
                                : Icons.lightbulb_outline,
                          ),
                          tooltip: wakeLockController.enabled
                              ? Strings.screenAwakeOff
                              : Strings.screenAwakeOn,
                          onPressed: () => wakeLockController.toggle(),
                        );
                      },
                    ),
                  ],
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                ),
                body: Stack(
                  fit: StackFit.expand,
                  children: [
                    CoverArtworkBackground(
                      coverUrl: coverUrl,
                      enabled: true,
                      clarity: clarity,
                      overlayBaseColor: cs.surface,
                      tintBaseColor: palette.backdropTint,
                      isDark: isDark,
                    ),
                    SafeArea(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = PlayerLayoutConfig.isWideLayout(
                              constraints.maxWidth);
                          final coverSize =
                              PlayerLayoutConfig.coverSizeForWidth(
                                  constraints.maxWidth);
                          return Column(
                            children: [
                              _buildViewModeToggle(isWide: isWide),
                              Expanded(
                                child: isWide
                                    ? _buildWideContent(coverSize)
                                    : GestureDetector(
                                        onTap: () {
                                          if (_canSwitchView) {
                                            setState(() =>
                                                _showLyrics = !_showLyrics);
                                          }
                                        },
                                        behavior: HitTestBehavior.opaque,
                                        child: _buildNarrowContent(coverSize),
                                      ),
                              ),
                              _buildTranslationBanner(),
                              _buildControlsBar(),
                            ],
                          );
                        },
                      ),
                    ),
                    SleepModeDimOverlay(controller: sleepTimer),
                  ],
                ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
