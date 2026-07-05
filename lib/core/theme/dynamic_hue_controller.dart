import 'package:flutter/material.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/core/theme/app_colors.dart';
import 'package:lizunemu/core/theme/cover_palette_loader.dart';
import 'package:lizunemu/core/theme/player_hue_derivation.dart';
import 'package:lizunemu/presentation/viewmodels/player_viewmodel.dart';

/// App-wide Monet accent from now-playing (or last) cover art — Milestone C.
class DynamicHueController extends ChangeNotifier {
  DynamicHueController({required PlayerViewModel playerViewModel})
      : _playerViewModel = playerViewModel {
    _playerViewModel.addListener(_onPlayerChanged);
    _onPlayerChanged();
  }

  final PlayerViewModel _playerViewModel;

  static const Color _idleFallbackPrimary = Color(0xFF0066FF);

  ColorScheme _lightScheme =
      AppColors.lightSchemeFor(ColorVariant.blue);
  ColorScheme _darkScheme = AppColors.darkSchemeFor(ColorVariant.blue);

  String? _loadedCoverUrl;
  int _generation = 0;

  ColorScheme get lightScheme => _lightScheme;
  ColorScheme get darkScheme => _darkScheme;

  void _onPlayerChanged() {
    final url = _playerViewModel.currentTrackInfo?.coverUrl;
    if (url == _loadedCoverUrl) return;
    _schedulePaletteLoad(url);
  }

  void _schedulePaletteLoad(String? url) {
    final gen = ++_generation;
    _loadPalettes(url, gen);
  }

  Future<void> _loadPalettes(String? url, int gen) async {
    final lightBg = AppColors.lightSchemeFor(ColorVariant.blue).surface;
    final darkBg = AppColors.darkSchemeFor(ColorVariant.blue).surface;

    final lightPalette = await loadCoverPalette(
      coverUrl: url,
      fallbackPrimary: _idleFallbackPrimary,
      background: lightBg,
      isDark: false,
    );
    if (gen != _generation) return;

    final darkPalette = await loadCoverPalette(
      coverUrl: url,
      fallbackPrimary: _idleFallbackPrimary,
      background: darkBg,
      isDark: true,
    );
    if (gen != _generation) return;

    _loadedCoverUrl = url;
    _applyPalettes(lightPalette, darkPalette);
  }

  void _applyPalettes(PlayerHuePalette light, PlayerHuePalette dark) {
    _lightScheme = AppColors.schemeFromPlayerPalette(light, Brightness.light);
    _darkScheme = AppColors.schemeFromPlayerPalette(dark, Brightness.dark);
    notifyListeners();
  }

  @override
  void dispose() {
    _playerViewModel.removeListener(_onPlayerChanged);
    super.dispose();
  }
}
