import 'package:lizunemu/core/audio/utils/audio_error_handler.dart';
import 'package:lizunemu/core/audio/utils/audio_file_classifier.dart';
import 'package:lizunemu/data/models/works/work.dart';
import 'package:lizunemu/data/models/files/files.dart';
import 'package:lizunemu/data/models/files/child.dart';
import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/core/audio/models/play_mode.dart';
import 'package:lizunemu/core/audio/models/file_path.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

class PlaybackContext {
  final Work work;
  final Files files;
  final Child currentFile;
  final List<Child> playlist;
  final int currentIndex;
  final PlayMode playMode;

  void validate() {
    if (playlist.isEmpty) {
      throw AudioError(
        AudioErrorType.state,
        LogStrings.logPlaylistEmpty,
      );
    }
    
    if (currentIndex < 0 || currentIndex >= playlist.length) {
      throw AudioError(
        AudioErrorType.state,
        LogStrings.logPlaylistIndexInvalid(currentIndex.toString(), playlist.length.toString()),
      );
    }

    if (!playlist.contains(currentFile)) {
      throw AudioError(
        AudioErrorType.state,
        LogStrings.logCurrentFileNotInPlaylist,
      );
    }
  }

  // Private constructor
  const PlaybackContext._({
    required this.work,
    required this.files,
    required this.currentFile,
    required this.playlist,
    required this.currentIndex,
    this.playMode = PlayMode.sequence,
  });

  // Public factory constructor; only basic parameters required
  factory PlaybackContext({
    required Work work,
    required Files files,
    required Child currentFile,
    PlayMode playMode = PlayMode.sequence,
  }) {
    var playlist = _getPlaylistFromSameDirectory(currentFile, files);
    if (playlist.isEmpty && AudioFileClassifier.isPlayableAudio(currentFile)) {
      playlist = [currentFile];
    }
    final currentIndex = playlist.indexWhere((file) => file == currentFile);
    if (currentIndex < 0) {
      final byTitle = playlist.indexWhere((file) => file.title == currentFile.title);
      final index = byTitle >= 0 ? byTitle : 0;
      return PlaybackContext._(
        work: work,
        files: files,
        currentFile: playlist[index],
        playlist: playlist,
        currentIndex: index,
        playMode: playMode,
      );
    }

    return PlaybackContext._(
      work: work,
      files: files,
      currentFile: currentFile,
      playlist: playlist,
      currentIndex: currentIndex,
      playMode: playMode,
    );
  }

  // Sibling files in the same directory, extension, and playable audio
  static List<Child> _getPlaylistFromSameDirectory(Child currentFile, Files files) {
    if (!AudioFileClassifier.isPlayableAudio(currentFile)) {
      final extension = currentFile.title?.split('.').last.toLowerCase();
      AppLogger.debug(LogStrings.logUnsupportedFileTypeExtension332f4(extension));
      return [];
    }

    final extension = currentFile.title!.split('.').last.toLowerCase();
    final siblings = FilePath.getSiblings(currentFile, files);

    return siblings
        .where(
          (file) =>
              AudioFileClassifier.isPlayableAudio(file) &&
              (file.title?.toLowerCase().endsWith('.$extension') ?? false),
        )
        .toList();
  }

  /// Create a context with a pre-filtered playlist (e.g. after skipping failed audio sources).
  /// `playlist` must be a subset of the original and `currentFile` must be in it.
  factory PlaybackContext.withFilteredPlaylist({
    required Work work,
    required Files files,
    required Child currentFile,
    required List<Child> playlist,
    PlayMode playMode = PlayMode.sequence,
  }) {
    final currentIndex = playlist.indexWhere((f) => f.title == currentFile.title);
    return PlaybackContext._(
      work: work,
      files: files,
      currentFile: currentFile,
      playlist: playlist,
      currentIndex: currentIndex >= 0 ? currentIndex : 0,
      playMode: playMode,
    );
  }

  // Convenience: whether a next track exists
  bool get hasNext => currentIndex < playlist.length - 1;

  // Convenience: whether a previous track exists
  bool get hasPrevious => currentIndex > 0;

  // Next track (respects play mode)
  Child? getNextFile() {
    if (playlist.isEmpty) return null;
    
    switch (playMode) {
      case PlayMode.single:
        return currentFile;  // Single-repeat returns the current file
      case PlayMode.loop:
        // Playlist loop: last track wraps to first, otherwise next
        return hasNext ? playlist[currentIndex + 1] : playlist[0];
      case PlayMode.sequence:
        // Sequential: return next if available, otherwise null
        return hasNext ? playlist[currentIndex + 1] : null;
    }
  }

  // Previous track
  Child? getPreviousFile() {
    if (playlist.isEmpty) return null;
    
    switch (playMode) {
      case PlayMode.single:
        return currentFile;
      case PlayMode.loop:
        // Playlist loop: first track wraps to last, otherwise previous
        return hasPrevious ? playlist[currentIndex - 1] : playlist[playlist.length - 1];
      case PlayMode.sequence:
        // Sequential: return previous if available, otherwise null
        return hasPrevious ? playlist[currentIndex - 1] : null;
    }
  }

  // copyWith* methods follow immutable-object design: update state by creating
  // new instances instead of mutating existing ones (predictable state, thread-safe,
  // easier debugging, functional style).

  // New context when switching files
  PlaybackContext copyWithFile(Child newFile) {
    return PlaybackContext(
      work: work,
      files: files,
      currentFile: newFile,
      playMode: playMode,
    );
  }

  // New context when switching play mode
  PlaybackContext copyWithMode(PlayMode newMode) {
    return PlaybackContext(
      work: work,
      files: files,
      currentFile: currentFile,
      playMode: newMode,
    );
  }

  // Convenience: list of playable files
  List<Child> getPlayableFiles() {
    if (files.children == null) return [];
    return files.children!.where((file) => 
      file.mediaDownloadUrl != null && 
      file.type?.toLowerCase() != 'vtt'
    ).toList();
  }

  // Helper: file base name without extension
  String? _getBaseName(String? filename) {
    if (filename == null) return null;
    return filename.replaceAll(RegExp(r'\.[^.]+$'), '');
  }
} 