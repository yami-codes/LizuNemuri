/// Typed + freeform character parameter.
enum LoreParamType {
  gauge,
  enumeration,
  text,
  boolean,
  number,
}

extension LoreParamTypeX on LoreParamType {
  static LoreParamType parse(String? raw) {
    return LoreParamType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => LoreParamType.text,
    );
  }
}

class LoreParam {
  final String key;
  final String module;
  final String label;
  final LoreParamType type;
  final dynamic value;
  final bool speculative;
  final bool hudPinned;
  final String? accentHex;
  final String? unit;
  final List<String>? enumOptions;

  const LoreParam({
    required this.key,
    required this.module,
    required this.label,
    required this.type,
    this.value,
    this.speculative = false,
    this.hudPinned = false,
    this.accentHex,
    this.unit,
    this.enumOptions,
  });

  LoreParam copyWith({
    String? key,
    String? module,
    String? label,
    LoreParamType? type,
    dynamic value,
    bool? speculative,
    bool? hudPinned,
    String? accentHex,
    String? unit,
    List<String>? enumOptions,
    bool clearValue = false,
  }) {
    return LoreParam(
      key: key ?? this.key,
      module: module ?? this.module,
      label: label ?? this.label,
      type: type ?? this.type,
      value: clearValue ? value : (value ?? this.value),
      speculative: speculative ?? this.speculative,
      hudPinned: hudPinned ?? this.hudPinned,
      accentHex: accentHex ?? this.accentHex,
      unit: unit ?? this.unit,
      enumOptions: enumOptions ?? this.enumOptions,
    );
  }

  double? get gaugeValue {
    if (value is num) return (value as num).toDouble().clamp(0.0, 100.0);
    if (value is String) return double.tryParse(value!);
    return null;
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'module': module,
        'label': label,
        'type': type.name,
        'value': value,
        'speculative': speculative,
        'hudPinned': hudPinned,
        if (accentHex != null) 'accentHex': accentHex,
        if (unit != null) 'unit': unit,
        if (enumOptions != null) 'enumOptions': enumOptions,
      };

  factory LoreParam.fromJson(Map<String, dynamic> json) {
    return LoreParam(
      key: json['key'] as String? ?? '',
      module: json['module'] as String? ?? 'custom',
      label: json['label'] as String? ?? json['key'] as String? ?? '',
      type: LoreParamTypeX.parse(json['type'] as String?),
      value: json['value'],
      speculative: json['speculative'] as bool? ?? false,
      hudPinned: json['hudPinned'] as bool? ?? false,
      accentHex: json['accentHex'] as String?,
      unit: json['unit'] as String?,
      enumOptions: (json['enumOptions'] as List?)?.cast<String>(),
    );
  }
}
