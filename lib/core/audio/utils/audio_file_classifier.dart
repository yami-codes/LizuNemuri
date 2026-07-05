import 'package:lizunemu/data/models/files/child.dart';

/// Shared audio vs video file classification for playback and detail UI.
class AudioFileClassifier {
  AudioFileClassifier._();

  static const videoExtensions = {
    'mp4',
    'mkv',
    'mov',
    'avi',
    'webm',
    'm4v',
  };

  /// True when API marks audio and the extension is not a known video type.
  static bool isAudioChild(Child file) {
    if ((file.type ?? '').toLowerCase() != 'audio') return false;
    final ext = file.title?.split('.').last.toLowerCase();
    return ext == null || !videoExtensions.contains(ext);
  }

  static bool isVideoChild(Child file) {
    if ((file.type ?? '').toLowerCase() == 'video') return true;
    final ext = file.title?.split('.').last.toLowerCase();
    return ext != null && videoExtensions.contains(ext);
  }

  static bool isPlayableAudio(Child file) =>
      isAudioChild(file) && file.mediaDownloadUrl != null;
}
