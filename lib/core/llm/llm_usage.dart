/// Token / cost usage from one LLM chat completion.
class LlmUsage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final double? totalCostUsd;

  const LlmUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    this.totalCostUsd,
  });

  static LlmUsage? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final prompt = _asInt(json['prompt_tokens']);
    final completion = _asInt(json['completion_tokens']);
    final total = _asInt(json['total_tokens']) ?? (prompt ?? 0) + (completion ?? 0);
    if (prompt == null && completion == null && total == 0) return null;

    double? cost;
    final costRaw = json['total_cost'] ?? json['cost'];
    if (costRaw is num) {
      cost = costRaw.toDouble();
    }

    return LlmUsage(
      promptTokens: prompt ?? 0,
      completionTokens: completion ?? 0,
      totalTokens: total,
      totalCostUsd: cost,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }
}

/// Result of a chat completion (streaming or not).
class LlmChatResult {
  final String content;
  final LlmUsage? usage;

  const LlmChatResult({required this.content, this.usage});
}
