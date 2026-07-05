import 'package:flutter/services.dart';
import 'package:xuro/utils/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'i_lyric_overlay_controller.dart';
import 'package:xuro/common/constants/log_strings.dart';

class LyricOverlayController implements ILyricOverlayController {
  static const _tag = 'LyricOverlay';
  static const _channel = MethodChannel('com.xuro/lyric_overlay');
  
  @override
  Future<void> initialize() async {
    try {
      AppLogger.debug(LogStrings.logTagInitd4e18(_tag));
      await _channel.invokeMethod('initialize');
    } catch (e) {
      AppLogger.error(LogStrings.logTagInitFailed3648a(_tag), e);
      // 这里我们不抛出异常,而是静默失败
      // 因为这个错误不应该影响应用的主要功能
    }
  }
  
  @override
  Future<void> show() async {
    AppLogger.debug(LogStrings.logTagShowOverlay90227(_tag));
    await _channel.invokeMethod('show');
  }
  
  @override
  Future<void> hide() async {
    AppLogger.debug(LogStrings.logTagHideOverlay4fda2(_tag));
    await _channel.invokeMethod('hide');
  }
  
  @override
  Future<void> updateLyric(String? text) async {
    AppLogger.debug(LogStrings.logLyricOverlayUpdate(_tag, text ?? ''));
    await _channel.invokeMethod('updateLyric', {'text': text});
  }
  
  @override
  Future<bool> checkPermission() async {
    AppLogger.debug(LogStrings.logTagCheckPermissionf3479(_tag));
    return await Permission.systemAlertWindow.isGranted;
  }
  
  @override
  Future<bool> requestPermission() async {
    AppLogger.debug(LogStrings.logTagRequestPermission021a2(_tag));
    final status = await Permission.systemAlertWindow.request();
    return status.isGranted;
  }
  
  @override
  Future<void> dispose() async {
    AppLogger.debug(LogStrings.logTagDisposea3399(_tag));
    await _channel.invokeMethod('dispose');
  }
  
  @override
  Future<bool> isShowing() async {
    final result = await _channel.invokeMethod<bool>('isShowing') ?? false;
    return result;
  }

  @override
  Future<void> setEditable(bool editable) async {
    AppLogger.debug(LogStrings.logTagSetEditable(_tag, editable.toString()));
    await _channel.invokeMethod('setEditable', {'editable': editable});
  }
}