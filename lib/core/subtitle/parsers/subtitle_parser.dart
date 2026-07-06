import 'package:lizunemu/core/audio/models/subtitle.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

/// Subtitle parser interface.
abstract class SubtitleParser {
  /// Parses subtitle content.
  SubtitleList parse(String content);
  
  /// Whether content matches this format.
  bool canParse(String content);
}

/// Base subtitle parser.
abstract class BaseSubtitleParser implements SubtitleParser {
  @override
  SubtitleList parse(String content) {
    if (!canParse(content)) {
      throw FormatException(LogStrings.logUnsupportedSubtitleFormat);
    }
    return doParse(content);
  }
  
  /// Concrete parse implementation.
  SubtitleList doParse(String content);
} 