import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizunemu/core/image/cache/asmr_http_file_service.dart';
import 'package:lizunemu/data/services/asmr_api_headers.dart';

class _CapturingFileService extends FileService {
  Map<String, String>? lastHeaders;
  String? lastUrl;

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    lastUrl = url;
    lastHeaders = headers;
    return _FakeResponse();
  }
}

class _FakeResponse implements FileServiceResponse {
  @override
  Stream<List<int>> get content => Stream.value(Uint8List(0));

  @override
  int? get contentLength => 0;

  @override
  int get statusCode => 200;

  @override
  DateTime get validTill => DateTime.now().add(const Duration(days: 1));

  @override
  String? get eTag => null;

  @override
  String get fileExtension => '.jpg';
}

void main() {
  test('AsmrHttpFileService injects CDN Accept-Language headers', () async {
    final capturing = _CapturingFileService();
    final service = AsmrHttpFileService(inner: capturing);

    await service.get('https://media.asmr.one/cover.jpg');

    expect(capturing.lastUrl, 'https://media.asmr.one/cover.jpg');
    expect(
      capturing.lastHeaders?['Accept-Language'],
      AsmrApiHeaders.acceptLanguage,
    );
    expect(capturing.lastHeaders?['User-Agent'], isNotEmpty);
    expect(capturing.lastHeaders?['Accept'], '*/*');
    expect(capturing.lastHeaders?['Accept-Language'], isNot(contains('en')));
  });

  test('AsmrHttpFileService merges caller headers without dropping CDN defaults',
      () async {
    final capturing = _CapturingFileService();
    final service = AsmrHttpFileService(inner: capturing);

    await service.get(
      'https://media.asmr.one/cover.jpg',
      headers: {'If-None-Match': 'etag-1'},
    );

    expect(capturing.lastHeaders?['If-None-Match'], 'etag-1');
    expect(
      capturing.lastHeaders?['Accept-Language'],
      AsmrApiHeaders.acceptLanguage,
    );
  });
}
