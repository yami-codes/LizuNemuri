import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/media/work_media_url_refresher.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/data/models/files/files.dart';
import 'package:lizunemu/data/services/api_service.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeApiService extends ApiService {
  _FakeApiService() : super(settings: AppSettingsService(_FakeApiService._prefs));

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  }

  Files? nextFiles;

  @override
  Future<Files> getWorkFiles(String workId, {CancelToken? cancelToken}) async {
    return nextFiles ?? Files(type: 'folder', children: const []);
  }
}

Child _leaf(String title, {String? url}) => Child(
      type: 'audio',
      title: title,
      hash: title,
      mediaDownloadUrl: url,
    );

void main() {
  late _FakeApiService api;

  setUp(() async {
    await _FakeApiService.init();
    api = _FakeApiService();
  });

  test('returns fresh URL even when patchInto tree is unmodifiable', () async {
    final stale = _leaf('track.wav', url: 'https://old.example/track.wav');
    final fresh = _leaf('track.wav', url: 'https://new.example/track.wav');
    api.nextFiles = Files(type: 'folder', children: [fresh]);

    final immutableTree = Files(type: 'folder', children: [stale]);
    final refresher = WorkMediaUrlRefresher(api);

    final result = await refresher.refreshFile(
      workId: '123',
      file: stale,
      patchInto: immutableTree,
    );

    expect(result.mediaDownloadUrl, 'https://new.example/track.wav');
  });
}
