import 'package:lizunemu/utils/logger.dart';
import 'package:lizunemu/common/constants/log_strings.dart';

enum AudioErrorType {
  playback,    // Playback error
  playlist,    // Playlist error
  state,       // State error
  context,     // Context error
  init,        // Initialization error
}

class AudioError implements Exception {
  final AudioErrorType type;
  final String message;
  final dynamic originalError;

  AudioError(this.type, this.message, [this.originalError]);

  @override
  String toString() => '$message${originalError != null ? ': $originalError' : ''}';
}

class AudioErrorHandler {
  static void handleError(
    AudioErrorType type,
    String operation,
    dynamic error, [
    StackTrace? stack,
  ]) {
    final message = _getErrorMessage(type, operation);
    AppLogger.error(message, error, stack);
  }
  
  static Never throwError(
    AudioErrorType type,
    String operation,
    dynamic error,
  ) {
    final message = _getErrorMessage(type, operation);
    throw AudioError(type, message, error);
  }

  static String _getErrorMessage(AudioErrorType type, String operation) {
    switch (type) {
      case AudioErrorType.playback:
        return LogStrings.logPlaybackOperationFailed(operation);
      case AudioErrorType.playlist:
        return LogStrings.logPlaylistOperationFailed(operation);
      case AudioErrorType.state:
        return LogStrings.logStateOperationFailed(operation);
      case AudioErrorType.context:
        return LogStrings.logContextOperationFailed(operation);
      case AudioErrorType.init:
        return LogStrings.logInitOperationFailed(operation);
    }
  }
} 