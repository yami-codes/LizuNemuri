import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:xuro/core/image/cache/image_cache_manager.dart';
import 'package:xuro/core/theme/player_hue_derivation.dart';

/// Default backdrop clarity — lower = heavier blur/veil (Eara mid-low).
const double kPlayerCoverBackdropClarity = 0.35;

/// Loads [PlayerHuePalette] from [coverUrl] with animated cross-fade.
class PlayerCoverPaletteLoader extends StatefulWidget {
  const PlayerCoverPaletteLoader({
    super.key,
    required this.coverUrl,
    required this.fallbackPrimary,
    required this.background,
    required this.isDark,
    required this.builder,
  });

  final String? coverUrl;
  final Color fallbackPrimary;
  final Color background;
  final bool isDark;
  final Widget Function(BuildContext context, PlayerHuePalette palette) builder;

  @override
  State<PlayerCoverPaletteLoader> createState() =>
      _PlayerCoverPaletteLoaderState();
}

class _PlayerCoverPaletteLoaderState extends State<PlayerCoverPaletteLoader> {
  PlayerHuePalette? _palette;
  String? _loadedForUrl;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _scheduleLoad();
  }

  @override
  void didUpdateWidget(PlayerCoverPaletteLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coverUrl != widget.coverUrl ||
        oldWidget.isDark != widget.isDark) {
      _scheduleLoad();
    }
  }

  void _scheduleLoad() {
    final url = widget.coverUrl;
    if (url == null || url.isEmpty) {
      setState(() {
        _loadedForUrl = null;
        _palette = derivePlayerHuePalette(
          seed: const Color(0x00000000),
          fallbackPrimary: widget.fallbackPrimary,
          background: widget.background,
          isDark: widget.isDark,
        );
      });
      return;
    }
    if (_loadedForUrl == url && _palette != null) return;

    final gen = ++_generation;
    _loadPalette(url, gen);
  }

  Future<void> _loadPalette(String url, int gen) async {
    try {
      final provider = CachedNetworkImageProvider(
        url,
        cacheManager: ImageCacheManager.instance,
      );
      final generator = await PaletteGenerator.fromImageProvider(
        provider,
        maximumColorCount: 12,
        timeout: const Duration(seconds: 8),
      );
      if (!mounted || gen != _generation) return;

      final seed = generator.dominantColor?.color ??
          generator.vibrantColor?.color ??
          generator.mutedColor?.color ??
          widget.fallbackPrimary;

      setState(() {
        _loadedForUrl = url;
        _palette = derivePlayerHuePalette(
          seed: seed,
          fallbackPrimary: widget.fallbackPrimary,
          background: widget.background,
          isDark: widget.isDark,
        );
      });
    } catch (_) {
      if (!mounted || gen != _generation) return;
      setState(() {
        _loadedForUrl = url;
        _palette = derivePlayerHuePalette(
          seed: const Color(0x00000000),
          fallbackPrimary: widget.fallbackPrimary,
          background: widget.background,
          isDark: widget.isDark,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palette ??
        derivePlayerHuePalette(
          seed: const Color(0x00000000),
          fallbackPrimary: widget.fallbackPrimary,
          background: widget.background,
          isDark: widget.isDark,
        );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey(
          '${widget.coverUrl ?? 'none'}-${palette.backdropTint.value}',
        ),
        child: widget.builder(context, palette),
      ),
    );
  }
}
