import 'package:lizunemu/core/audio/models/subtitle.dart';

abstract class ISubtitleService {
  // Subtitle loading
  Future<void> loadSubtitle(String url);

  /// Load subtitle from an already-parsed SubtitleList (for local imports)
  Future<void> loadSubtitleFromContent(SubtitleList subtitleList);
  
  // Subtitle state stream
  Stream<SubtitleList?> get subtitleStream;
  
  // Current subtitle stream
  Stream<Subtitle?> get currentSubtitleStream;
  
  // Current subtitle
  Subtitle? get currentSubtitle;
  
  // Update playback position
  void updatePosition(Duration position);
  
  // Release resources
  void dispose();
  
  // Added:
  SubtitleList? get subtitleList;  // Current subtitle list
  
  // Clear loaded subtitles
  void clearSubtitle();
  
  Stream<SubtitleWithState?> get currentSubtitleWithStateStream;
  SubtitleWithState? get currentSubtitleWithState;
} 