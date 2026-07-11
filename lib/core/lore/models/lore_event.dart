class LoreTrackSummary {
  final String trackKey;
  final String trackTitle;
  final int trackIndex;
  final String summary;
  final bool lowConfidence;
  final bool hasSubtitles;

  const LoreTrackSummary({
    required this.trackKey,
    required this.trackTitle,
    required this.trackIndex,
    required this.summary,
    this.lowConfidence = false,
    this.hasSubtitles = true,
  });

  LoreTrackSummary copyWith({
    String? trackKey,
    String? trackTitle,
    int? trackIndex,
    String? summary,
    bool? lowConfidence,
    bool? hasSubtitles,
  }) {
    return LoreTrackSummary(
      trackKey: trackKey ?? this.trackKey,
      trackTitle: trackTitle ?? this.trackTitle,
      trackIndex: trackIndex ?? this.trackIndex,
      summary: summary ?? this.summary,
      lowConfidence: lowConfidence ?? this.lowConfidence,
      hasSubtitles: hasSubtitles ?? this.hasSubtitles,
    );
  }

  Map<String, dynamic> toJson() => {
        'trackKey': trackKey,
        'trackTitle': trackTitle,
        'trackIndex': trackIndex,
        'summary': summary,
        'lowConfidence': lowConfidence,
        'hasSubtitles': hasSubtitles,
      };

  factory LoreTrackSummary.fromJson(Map<String, dynamic> json) {
    return LoreTrackSummary(
      trackKey: json['trackKey'] as String? ?? '',
      trackTitle: json['trackTitle'] as String? ?? '',
      trackIndex: json['trackIndex'] as int? ?? 0,
      summary: json['summary'] as String? ?? '',
      lowConfidence: json['lowConfidence'] as bool? ?? false,
      hasSubtitles: json['hasSubtitles'] as bool? ?? true,
    );
  }
}

enum LoreEventKind {
  beat,
  paramChange,
  addition,
  relationship,
  location,
  clothing,
  body,
  other,
}

extension LoreEventKindX on LoreEventKind {
  static LoreEventKind parse(String? raw) {
    return LoreEventKind.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => LoreEventKind.other,
    );
  }
}

class LoreParamDelta {
  final String key;
  final dynamic from;
  final dynamic to;

  const LoreParamDelta({required this.key, this.from, this.to});

  Map<String, dynamic> toJson() => {'key': key, 'from': from, 'to': to};

  factory LoreParamDelta.fromJson(Map<String, dynamic> json) => LoreParamDelta(
        key: json['key'] as String? ?? '',
        from: json['from'],
        to: json['to'],
      );

  /// True when both ends are numeric — eligible for span lerp.
  bool get isNumeric {
    return asNum(from) != null && asNum(to) != null;
  }

  static double? asNum(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

class LoreTimelineEvent {
  final String id;
  final String trackKey;
  /// Span start (inclusive). Point events still use this as the cue time.
  final int? atMs;
  /// Span end (exclusive for mid-lerp; value settles to [LoreParamDelta.to] at/after).
  /// When null, projector derives a short ramp from evidence / next event.
  final int? endMs;
  final LoreEventKind kind;
  final String title;
  final String detail;
  final String? characterId;
  final List<LoreParamDelta> deltas;
  final String? evidenceQuote;
  final int? evidenceStartMs;
  final int? evidenceEndMs;
  final bool speculative;
  final double? confidence;

  const LoreTimelineEvent({
    required this.id,
    required this.trackKey,
    this.atMs,
    this.endMs,
    required this.kind,
    required this.title,
    this.detail = '',
    this.characterId,
    this.deltas = const [],
    this.evidenceQuote,
    this.evidenceStartMs,
    this.evidenceEndMs,
    this.speculative = false,
    this.confidence,
  });

  LoreTimelineEvent copyWith({
    String? id,
    String? trackKey,
    int? atMs,
    int? endMs,
    LoreEventKind? kind,
    String? title,
    String? detail,
    String? characterId,
    List<LoreParamDelta>? deltas,
    String? evidenceQuote,
    int? evidenceStartMs,
    int? evidenceEndMs,
    bool? speculative,
    double? confidence,
  }) {
    return LoreTimelineEvent(
      id: id ?? this.id,
      trackKey: trackKey ?? this.trackKey,
      atMs: atMs ?? this.atMs,
      endMs: endMs ?? this.endMs,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      characterId: characterId ?? this.characterId,
      deltas: deltas ?? this.deltas,
      evidenceQuote: evidenceQuote ?? this.evidenceQuote,
      evidenceStartMs: evidenceStartMs ?? this.evidenceStartMs,
      evidenceEndMs: evidenceEndMs ?? this.evidenceEndMs,
      speculative: speculative ?? this.speculative,
      confidence: confidence ?? this.confidence,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'trackKey': trackKey,
        if (atMs != null) 'atMs': atMs,
        if (endMs != null) 'endMs': endMs,
        'kind': kind.name,
        'title': title,
        'detail': detail,
        if (characterId != null) 'characterId': characterId,
        'deltas': deltas.map((e) => e.toJson()).toList(),
        if (evidenceQuote != null) 'evidenceQuote': evidenceQuote,
        if (evidenceStartMs != null) 'evidenceStartMs': evidenceStartMs,
        if (evidenceEndMs != null) 'evidenceEndMs': evidenceEndMs,
        'speculative': speculative,
        if (confidence != null) 'confidence': confidence,
      };

  factory LoreTimelineEvent.fromJson(Map<String, dynamic> json) {
    return LoreTimelineEvent(
      id: json['id'] as String? ?? '',
      trackKey: json['trackKey'] as String? ?? '',
      atMs: json['atMs'] as int?,
      endMs: json['endMs'] as int?,
      kind: LoreEventKindX.parse(json['kind'] as String?),
      title: json['title'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      characterId: json['characterId'] as String?,
      deltas: (json['deltas'] as List?)
              ?.whereType<Map>()
              .map((e) => LoreParamDelta.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      evidenceQuote: json['evidenceQuote'] as String?,
      evidenceStartMs: json['evidenceStartMs'] as int?,
      evidenceEndMs: json['evidenceEndMs'] as int?,
      speculative: json['speculative'] as bool? ?? false,
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }
}
