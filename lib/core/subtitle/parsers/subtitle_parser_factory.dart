import 'package:xuro/core/subtitle/parsers/subtitle_parser.dart';
import 'package:xuro/core/subtitle/parsers/vtt_parser.dart';
import 'package:xuro/core/subtitle/parsers/lrc_parser.dart';
import 'package:xuro/utils/logger.dart';
import 'package:xuro/common/constants/log_strings.dart';

class SubtitleParserFactory {
  static final List<SubtitleParser> _parsers = [
    VttParser(),
    LrcParser(),
  ];
  
  static SubtitleParser? getParser(String content) {
    try {
      return _parsers.firstWhere((parser) => parser.canParse(content));
    } catch (e) {
      AppLogger.debug(LogStrings.logNoMatchingSubtitleParser8b7bb);
      return null;
    }
  }
} 