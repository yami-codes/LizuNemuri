/// Detected LLM API provider from the configured endpoint URL.
enum LlmProviderKind {
  openAi,
  openRouter,
  gemini,
  custom,
}

extension LlmProviderKindX on LlmProviderKind {
  /// All presets attempt `GET /models` for autocomplete (custom included).
  bool get supportsModelAutocomplete => true;

  bool get supportsRemoteBalance => this == LlmProviderKind.openRouter;
}
