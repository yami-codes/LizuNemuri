import 'package:universal_io/io.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/data/models/files/files.dart';
import 'package:lizunemu/core/audio/models/file_path.dart';
import 'package:lizunemu/core/audio/models/subtitle.dart';
import 'package:dio/dio.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/core/subtitle/utils/subtitle_matcher.dart';
import 'package:lizunemu/core/subtitle/parsers/subtitle_parser_factory.dart';
import 'package:lizunemu/core/subtitle/cache/subtitle_cache_manager.dart';

class SubtitleLoader {
  final Dio _dio;

  SubtitleLoader({required Dio dio}) : _dio = dio;

  // Find subtitle file
  Child? findSubtitleFile(Child audioFile, Files files) {
    if (files.children == null || audioFile.title == null) {
      AppLogger.debug(LogStrings.logCannotFindSubtitleReason(files.children == null ? LogStrings.logFileListEmpty : LogStrings.logCurrentFileNameEmpty));
      return null;
    }

    AppLogger.debug(LogStrings.logStartFindingSubtitleFileb7fbb);
    
    // Use FilePath to get sibling files
    final siblings = FilePath.getSiblings(audioFile, files);
    
    // Use SubtitleMatcher to find a matching subtitle file
    final subtitleFile = SubtitleMatcher.findMatchingSubtitle(
      audioFile.title!,
      siblings
    );
    
    if (subtitleFile != null) {
      AppLogger.debug(LogStrings.logFoundSubtitleFileSubtitlefilefa0b(subtitleFile.title, subtitleFile.mediaDownloadUrl));
    } else {
      AppLogger.debug(LogStrings.logNoSubtitleInCurrentDirectoryb005d);
    }
    
    return subtitleFile;
  }

  // Load subtitle content
  Future<SubtitleList?> loadSubtitleContent(String url) async {
    try {
      // Try cache first
      final cachedContent = await SubtitleCacheManager.getCachedContent(url);
      if (cachedContent != null) {
        AppLogger.debug(LogStrings.logLoadSubtitleFromCacheUrle52f3(url));
        return _parseSubtitleContent(cachedContent);
      }

      // Cache miss — load from network
      AppLogger.debug(LogStrings.logLoadSubtitleFromNetworkUrl9145d(url));
      final response = await _dio.get(url);
      AppLogger.debug(LogStrings.logSubtitlefiledownloadstateResd5fd5(response.statusCode));
      
      if (response.statusCode == 200) {
        final content = response.data as String;
        
        // Save to cache
        await SubtitleCacheManager.cacheContent(url, content);
        
        return _parseSubtitleContent(content);
      } else {
        throw Exception(LogStrings.logSubtitleDownloadFailedCode(response.statusCode.toString()));
      }
    } catch (e) {
      AppLogger.debug(LogStrings.logSubtitleLoadFailedEfb464(e));
      rethrow;
    }
  }

  /// Returns raw subtitle text (preview / offline). Prefers a locally downloaded file;
  /// otherwise fetches over the network (with [SubtitleCacheManager] caching). No parsing —
  /// callers choose timeline parsing or raw display.
  Future<String> loadRawContent({String? localPath, String? url}) async {
    if (localPath != null) {
      return File(localPath).readAsString();
    }
    if (url == null || url.isEmpty) {
      throw Exception(LogStrings.logSubtitleUrlEmpty);
    }
    final cached = await SubtitleCacheManager.getCachedContent(url);
    if (cached != null) return cached;
    final response = await _dio.get(url);
    if (response.statusCode != 200) {
      throw Exception(LogStrings.logSubtitleDownloadFailedCode(response.statusCode.toString()));
    }
    final content = response.data as String;
    await SubtitleCacheManager.cacheContent(url, content);
    return content;
  }

  /// Parses raw text into a timeline; unsupported formats **or parse errors** return null
  /// (callers fall back to raw text — parse failures are not "load failed").
  SubtitleList? parseOrNull(String content) {
    try {
      final parser = SubtitleParserFactory.getParser(content);
      if (parser == null) return null;
      final list = parser.parse(content);
      return list.subtitles.isNotEmpty ? list : null;
    } catch (e) {
      AppLogger.debug(LogStrings.logTimelineParseFailedFallbackT8e556(e));
      return null;
    }
  }

  // Private helper to parse subtitle content
  SubtitleList? _parseSubtitleContent(String content) {
    AppLogger.debug(LogStrings.logSubtitleContentPreview(content.substring(0, content.length > 100 ? 100 : content.length)));
    
    final parser = SubtitleParserFactory.getParser(content);
    if (parser == null) {
      throw Exception(LogStrings.logUnsupportedSubtitleFormat);
    }
    
    final subtitleList = parser.parse(content);
    AppLogger.debug(LogStrings.logSubtitleParseCompleteSubtitlae958(subtitleList.subtitles.length));
    
    return subtitleList;
  }
} 