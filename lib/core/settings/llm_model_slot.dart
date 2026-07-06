/// Which configured LLM model to use for a translation operation.
enum LlmModelSlot {
  /// Subtitle translation (higher quality / larger model).
  main,

  /// Work titles, track names, tags, and other short metadata.
  lite,
}
