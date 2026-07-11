import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:lizunemu/data/services/asmr_api_headers.dart';

/// Injects asmr CDN headers into every image cache fetch.
///
/// [CachedNetworkImage] / [ImageCacheManager] use [HttpFileService] by default
/// with no [Accept-Language]; mirrors block those requests.
class AsmrHttpFileService extends FileService {
  AsmrHttpFileService({FileService? inner}) : _inner = inner ?? HttpFileService();

  final FileService _inner;

  @override
  int get concurrentFetches => _inner.concurrentFetches;

  @override
  set concurrentFetches(int value) => _inner.concurrentFetches = value;

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) {
    final merged = <String, String>{...AsmrApiHeaders.cdnFetchHeaders};
    if (headers != null) merged.addAll(headers);
    return _inner.get(url, headers: merged);
  }
}
