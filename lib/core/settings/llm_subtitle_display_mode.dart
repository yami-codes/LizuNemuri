/// How translated subtitles are shown in the player.
enum LlmSubtitleDisplayMode {
  /// Show only the active line (translation when LLM has run, else original).
  translationOnly,

  /// Stack original under the translation when LLM translation is active.
  dual,
}
