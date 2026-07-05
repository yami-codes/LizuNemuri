/// How subtitle lines are grouped before sending to the LLM.
enum LlmBatchSplitMode {
  /// Send the entire subtitle file in one request.
  none,

  /// Split batches using the provider model context window (OpenRouter /models).
  provider,

  /// Split using [AppSettingsService.llmManualBatchSize].
  manual,
}
