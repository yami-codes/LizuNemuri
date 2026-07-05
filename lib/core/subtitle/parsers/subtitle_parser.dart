import 'package:xuro/core/audio/models/subtitle.dart';
import 'package:xuro/common/constants/log_strings.dart';

/// 字幕解析器接口
abstract class SubtitleParser {
  /// 解析字幕内容
  SubtitleList parse(String content);
  
  /// 检查内容格式是否匹配
  bool canParse(String content);
}

/// 字幕解析器基类
abstract class BaseSubtitleParser implements SubtitleParser {
  @override
  SubtitleList parse(String content) {
    if (!canParse(content)) {
      throw FormatException(LogStrings.logUnsupportedSubtitleFormat);
    }
    return doParse(content);
  }
  
  /// 具体的解析实现
  SubtitleList doParse(String content);
} 