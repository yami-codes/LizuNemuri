import 'package:lizunemu/core/audio/models/subtitle.dart';
import 'package:lizunemu/core/subtitle/parsers/subtitle_parser.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

class LrcParser extends BaseSubtitleParser {
  static final _timeTagRegex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2})\]');
  static final _idTagRegex = RegExp(r'^\[(ar|ti|al|by|offset):(.+)\]$');
  
  @override
  bool canParse(String content) {
    final lines = content.trim().split('\n');
    return lines.any((line) => _timeTagRegex.hasMatch(line));
  }
  
  @override
  SubtitleList doParse(String content) {
    final lines = content.split('\n');
    final subtitles = <Subtitle>[];
    final metadata = <String, String>{};
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;
      
      // Check for ID tag
      final idMatch = _idTagRegex.firstMatch(trimmedLine);
      if (idMatch != null) {
        metadata[idMatch.group(1)!] = idMatch.group(2)!;
        continue;
      }
      
      // Parse time tags and lyrics
      final timeMatches = _timeTagRegex.allMatches(trimmedLine);
      if (timeMatches.isEmpty) continue;
      
      // Lyric text with all time tags stripped
      final text = trimmedLine.replaceAll(_timeTagRegex, '').trim();
      if (text.isEmpty) continue;
      
      // One line may have multiple time tags
      for (final match in timeMatches) {
        try {
          final timestamp = _parseTimestamp(
            minutes: match.group(1)!,
            seconds: match.group(2)!,
            milliseconds: match.group(3)!,
          );
          
          subtitles.add(Subtitle(
            start: timestamp,
            end: timestamp + const Duration(seconds: 5), // Default 5s duration
            text: text,
            index: subtitles.length,
          ));
        } catch (e) {
          AppLogger.debug(LogStrings.logLrcTimeTagParseFailedE0589e(e));
          continue;
        }
      }
    }
    
    // Sort by start time
    subtitles.sort((a, b) => a.start.compareTo(b.start));
    
    // Set correct end times
    for (int i = 0; i < subtitles.length - 1; i++) {
      subtitles[i] = Subtitle(
        start: subtitles[i].start,
        end: subtitles[i + 1].start,
        text: subtitles[i].text,
        index: i,
      );
    }
    
    AppLogger.debug(LogStrings.logLrcParseCompleteSubtitlesLen8f25e(subtitles.length, metadata.length));
    return SubtitleList(subtitles);
  }
  
  Duration _parseTimestamp({
    required String minutes,
    required String seconds,
    required String milliseconds,
  }) {
    return Duration(
      minutes: int.parse(minutes),
      seconds: int.parse(seconds),
      milliseconds: int.parse(milliseconds) * 10,
    );
  }
} 