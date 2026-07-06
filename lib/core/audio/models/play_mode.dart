import 'package:just_audio/just_audio.dart';

enum PlayMode {
  single,     // Single-track repeat
  loop,       // Playlist repeat
  sequence;   // Sequential play

  LoopMode toLoopMode() {
    switch (this) {
      case PlayMode.single:
        return LoopMode.one;
      case PlayMode.loop:
        return LoopMode.all;
      case PlayMode.sequence:
        return LoopMode.off;
    }
  }
}
