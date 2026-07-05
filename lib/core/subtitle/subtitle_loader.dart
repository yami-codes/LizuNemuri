import 'dart:io';
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

  // 查找字幕文件
  Child? findSubtitleFile(Child audioFile, Files files) {
    if (files.children == null || audioFile.title == null) {
      AppLogger.debug(LogStrings.logCannotFindSubtitleReason(files.children == null ? LogStrings.logFileListEmpty : LogStrings.logCurrentFileNameEmpty));
      return null;
    }

    AppLogger.debug(LogStrings.logStartFindingSubtitleFileb7fbb);
    
    // 使用 FilePath 获取同级文件
    final siblings = FilePath.getSiblings(audioFile, files);
    
    // 使用 SubtitleMatcher 查找匹配的字幕文件
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

  // 修改: 加载字幕内容
  Future<SubtitleList?> loadSubtitleContent(String url) async {
    try {
      // 首先尝试从缓存加载
      final cachedContent = await SubtitleCacheManager.getCachedContent(url);
      if (cachedContent != null) {
        AppLogger.debug(LogStrings.logLoadSubtitleFromCacheUrle52f3(url));
        return _parseSubtitleContent(cachedContent);
      }

      // 缓存未命中，从网络加载
      AppLogger.debug(LogStrings.logLoadSubtitleFromNetworkUrl9145d(url));
      final response = await _dio.get(url);
      AppLogger.debug(LogStrings.logSubtitlefiledownloadstateResd5fd5(response.statusCode));
      
      if (response.statusCode == 200) {
        final content = response.data as String;
        
        // 保存到缓存
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

  /// 取字幕**原始文本**（预览 / 离线用）：优先本地已下载文件，
  /// 否则走网络（带 [SubtitleCacheManager] 缓存）。不做解析，
  /// 调用方自行决定按时间轴解析还是原样展示。
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

  /// 把原始文本按时间轴解析；不支持的格式 **或解析抛错** 都返回 null
  /// （调用方据此回退原文展示，不应把解析异常当成"加载失败"）。
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

  // 新增: 解析字幕内容的私有方法
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