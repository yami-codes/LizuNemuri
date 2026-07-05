import 'dart:async';

import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/core/audio/models/subtitle.dart';
import 'package:lizunemu/core/platform/i_lyric_overlay_controller.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:lizunemu/core/subtitle/i_subtitle_service.dart';
import 'package:lizunemu/presentation/viewmodels/player_viewmodel.dart';
import 'package:flutter/material.dart';

class LyricOverlayManager {
  final ILyricOverlayController _controller;
  final ISubtitleService _subtitleService;
  final AppSettingsService _settings;
  final PlayerViewModel _playerViewModel;
  StreamSubscription? _subscription;

  void _onOverlayLyricContextChanged() {
    if (_isShowing) {
      unawaited(_pushOverlayLyric(_subtitleService.currentSubtitle));
    }
  }
  bool _isShowing = false;
  bool _isEditable = false;

  LyricOverlayManager({
    required ILyricOverlayController controller,
    required ISubtitleService subtitleService,
    required AppSettingsService settings,
    required PlayerViewModel playerViewModel,
  }) : _controller = controller,
       _subtitleService = subtitleService,
       _settings = settings,
       _playerViewModel = playerViewModel;

  Future<void> initialize() async {
    await _controller.initialize();
    _subscription = _subtitleService.currentSubtitleStream.listen((subtitle) {
      if (_isShowing) {
        unawaited(_pushOverlayLyric(subtitle));
      }
    });
    _settings.addListener(_onOverlayLyricContextChanged);
    _playerViewModel.addListener(_onOverlayLyricContextChanged);
    
    _isShowing = await _controller.isShowing();
    
    if (_isShowing) {
      await show();
    }
  }
  
  Future<void> dispose() async {
    _settings.removeListener(_onOverlayLyricContextChanged);
    _playerViewModel.removeListener(_onOverlayLyricContextChanged);
    await _subscription?.cancel();
    await _controller.dispose();
  }

  Future<void> _pushOverlayLyric(Subtitle? subtitle) async {
    await _controller.updateLyric(
      _playerViewModel.overlayTextForSubtitle(subtitle),
    );
  }
  
  Future<bool> checkPermission() async {
    return await _controller.checkPermission();
  }

  Future<bool> requestPermission() async {
    return await _controller.requestPermission();
  }

  Future<void> show() async {
    await _controller.show();
    _isShowing = true;
    final currentSubtitle = _subtitleService.currentSubtitleWithState;
    await _pushOverlayLyric(currentSubtitle?.subtitle);
    // 显示后统一以持久化偏好为准（锁定 / 解锁拖动）。
    await setEditable(_settings.lyricOverlayUnlocked);
  }

  Future<void> hide() async {
    await _controller.hide();
    _isShowing = false;
    _isEditable = false;
  }

  bool get isShowing => _isShowing;

  bool get isEditable => _isEditable;

  /// 切换悬浮窗可拖动状态。仅在悬浮窗显示中生效；隐藏时自动恢复为不可拖动。
  Future<void> setEditable(bool editable) async {
    if (!_isShowing) {
      _isEditable = false;
      return;
    }
    await _controller.setEditable(editable);
    _isEditable = editable;
  }

  Future<void> toggleEditable() => setEditable(!_isEditable);

  /// 持久化「解锁悬浮歌词位置」偏好，并在悬浮窗显示时立即应用。
  Future<void> setUnlockedPreference(bool unlocked) async {
    await _settings.setLyricOverlayUnlocked(unlocked);
    if (_isShowing) {
      await setEditable(unlocked);
    }
  }

  /// 处理显示悬浮歌词的完整流程
  Future<void> showWithPermissionCheck(BuildContext context) async {
    final hasPermission = await checkPermission();
    if (hasPermission) {
      await show();
      return;
    }

    if (!context.mounted) return;

    final shouldRequest = await _showPermissionDialog(context);
    if (shouldRequest && context.mounted) {
      final granted = await requestPermission();
      if (granted && context.mounted) {
        await show();
      }
    }
  }

  Future<bool> _showPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Strings.lyricOverlayPermTitle),
        content: Text(Strings.lyricOverlayPermContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(Strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(Strings.dialogConfirm),
          ),
        ],
      ),
    ) ?? false;
  }

  /// 切换显示/隐藏状态
  Future<void> toggle(BuildContext context) async {
    if (_isShowing) {
      await hide();
    } else {
      await showWithPermissionCheck(context);
    }
  }
  
  // 其他控制方法...

  Future<void> syncState() async {
    _isShowing = await _controller.isShowing();
  }
} 