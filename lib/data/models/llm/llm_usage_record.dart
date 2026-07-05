/// One persisted LLM API usage entry.
class LlmUsageRecord {
  final String id;
  final DateTime timestamp;
  final String model;
  final String operation;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final double? totalCostUsd;
  final String? workId;
  final String? trackName;

  const LlmUsageRecord({
    required this.id,
    required this.timestamp,
    required this.model,
    required this.operation,
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    this.totalCostUsd,
    this.workId,
    this.trackName,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'model': model,
        'operation': operation,
        'promptTokens': promptTokens,
        'completionTokens': completionTokens,
        'totalTokens': totalTokens,
        if (totalCostUsd != null) 'totalCostUsd': totalCostUsd,
        if (workId != null) 'workId': workId,
        if (trackName != null) 'trackName': trackName,
      };

  factory LlmUsageRecord.fromJson(Map<String, dynamic> json) {
    return LlmUsageRecord(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      model: json['model'] as String? ?? '',
      operation: json['operation'] as String? ?? 'unknown',
      promptTokens: json['promptTokens'] as int? ?? 0,
      completionTokens: json['completionTokens'] as int? ?? 0,
      totalTokens: json['totalTokens'] as int? ?? 0,
      totalCostUsd: (json['totalCostUsd'] as num?)?.toDouble(),
      workId: json['workId'] as String?,
      trackName: json['trackName'] as String?,
    );
  }
}

/// OpenRouter `/auth/key` account summary.
class LlmAccountBalance {
  final double? usageUsd;
  final double? limitUsd;
  final bool isFreeTier;
  final String? label;

  const LlmAccountBalance({
    this.usageUsd,
    this.limitUsd,
    this.isFreeTier = false,
    this.label,
  });

  static LlmAccountBalance? fromOpenRouterJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final data = json['data'];
    if (data is! Map) return null;
    final map = data.map((k, v) => MapEntry(k.toString(), v));
    return LlmAccountBalance(
      usageUsd: (map['usage'] as num?)?.toDouble(),
      limitUsd: (map['limit'] as num?)?.toDouble(),
      isFreeTier: map['is_free_tier'] == true,
      label: map['label'] as String?,
    );
  }
}
