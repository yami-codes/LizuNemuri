/// Backend for translating work titles, track names, and other short metadata.
enum MetadataTranslationProvider {
  /// Free unofficial Google Translate endpoint (no API key).
  google,

  /// OpenAI-compatible LLM using the Lite model slot.
  llm,
}
