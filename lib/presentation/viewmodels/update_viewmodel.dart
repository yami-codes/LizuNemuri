import 'package:flutter/foundation.dart';
import 'package:lizunemu/utils/platform_capabilities.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lizunemu/common/constants/strings.dart';
import 'package:lizunemu/data/models/update_info.dart';
import 'package:lizunemu/data/services/exceptions/update_exception.dart';
import 'package:lizunemu/data/services/update_service.dart';
import 'package:lizunemu/utils/logger.dart';

class UpdateViewModel extends ChangeNotifier {
  final UpdateService _service;

  bool _isChecking = false;
  bool _checked = false;
  bool _disposed = false;
  String? _error;
  UpdateInfo? _latest;
  bool _hasUpdate = false;
  String _currentVersion = '';

  UpdateViewModel({required UpdateService service}) : _service = service;

  @override
  void dispose() {
    // When the dialog is dismissed mid-check, the local VM is disposed;
    // in-flight completion must not notifyListeners on a disposed ChangeNotifier.
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  bool get isChecking => _isChecking;

  /// Whether at least one check has completed (vs initial "checking" / "up to date").
  bool get checked => _checked;
  String? get error => _error;
  UpdateInfo? get latest => _latest;
  bool get hasUpdate => _hasUpdate;
  String get currentVersion => _currentVersion;

  Future<void> check() async {
    if (_isChecking) return;

    _isChecking = true;
    _error = null;
    _safeNotify();

    try {
      final r = await _service.checkForUpdate();
      _latest = r.latest;
      _hasUpdate = r.hasUpdate;
      _currentVersion = r.currentVersion;
    } on UpdateException catch (e) {
      // Use GitHub-specific copy; do not depend on NetworkException.
      AppLogger.error(LogStrings.logUpdateviewmodelUpdateCheckFacead5, e);
      _error = e.userMessage;
    } catch (e) {
      AppLogger.error(LogStrings.logUpdateviewmodelUpdateCheckUn69571, e);
      _error = Strings.updateErrorUnknown;
    } finally {
      _isChecking = false;
      _checked = true;
      _safeNotify();
    }
  }

  /// Open download URL externally. Android prefers `.apk` asset; else release page.
  Future<bool> openDownload() async {
    final info = _latest;
    if (info == null) return false;

    final preferApk = PlatformCapabilities.isAndroid && info.apkDownloadUrl != null;
    final target = preferApk ? info.apkDownloadUrl! : info.htmlUrl;

    try {
      return await launchUrl(
        Uri.parse(target),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      AppLogger.error(LogStrings.logUpdateviewmodelOpenDownloadFf03f5, e);
      return false;
    }
  }
}
