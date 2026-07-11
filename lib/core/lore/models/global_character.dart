import 'package:lizunemu/core/lore/models/lore_character.dart';
import 'package:lizunemu/core/lore/models/lore_param.dart';

/// First-class global character bible entry (promoted from work-local).
class GlobalCharacter {
  final String id;
  final String name;
  final List<String> aliases;
  final String? appearance;
  final String? personality;
  final List<LoreKinkTag> kinks;
  final List<LoreParam> baselineParams;
  final String? notes;
  final DateTime updatedAt;
  final List<String> linkedWorkIds;

  const GlobalCharacter({
    required this.id,
    required this.name,
    this.aliases = const [],
    this.appearance,
    this.personality,
    this.kinks = const [],
    this.baselineParams = const [],
    this.notes,
    required this.updatedAt,
    this.linkedWorkIds = const [],
  });

  GlobalCharacter copyWith({
    String? id,
    String? name,
    List<String>? aliases,
    String? appearance,
    String? personality,
    List<LoreKinkTag>? kinks,
    List<LoreParam>? baselineParams,
    String? notes,
    DateTime? updatedAt,
    List<String>? linkedWorkIds,
  }) {
    return GlobalCharacter(
      id: id ?? this.id,
      name: name ?? this.name,
      aliases: aliases ?? this.aliases,
      appearance: appearance ?? this.appearance,
      personality: personality ?? this.personality,
      kinks: kinks ?? this.kinks,
      baselineParams: baselineParams ?? this.baselineParams,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
      linkedWorkIds: linkedWorkIds ?? this.linkedWorkIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'aliases': aliases,
        if (appearance != null) 'appearance': appearance,
        if (personality != null) 'personality': personality,
        'kinks': kinks.map((e) => e.toJson()).toList(),
        'baselineParams': baselineParams.map((e) => e.toJson()).toList(),
        if (notes != null) 'notes': notes,
        'updatedAt': updatedAt.toIso8601String(),
        'linkedWorkIds': linkedWorkIds,
      };

  factory GlobalCharacter.fromJson(Map<String, dynamic> json) {
    return GlobalCharacter(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      aliases: (json['aliases'] as List?)?.cast<String>() ?? const [],
      appearance: json['appearance'] as String?,
      personality: json['personality'] as String?,
      kinks: (json['kinks'] as List?)
              ?.whereType<Map>()
              .map((e) => LoreKinkTag.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      baselineParams: (json['baselineParams'] as List?)
              ?.whereType<Map>()
              .map((e) => LoreParam.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      notes: json['notes'] as String?,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      linkedWorkIds:
          (json['linkedWorkIds'] as List?)?.cast<String>() ?? const [],
    );
  }

  factory GlobalCharacter.fromLocal(
    LoreCharacter local, {
    required String id,
    required String workId,
  }) {
    return GlobalCharacter(
      id: id,
      name: local.name,
      aliases: local.aliases,
      appearance: local.appearance,
      personality: local.personality,
      kinks: local.kinks,
      baselineParams: local.params,
      notes: local.notes,
      updatedAt: DateTime.now().toUtc(),
      linkedWorkIds: [workId],
    );
  }
}

/// Field-level merge choice when promoting/linking.
class LoreFieldMergeChoice {
  final String fieldKey;
  final dynamic localValue;
  final dynamic globalValue;
  final bool preferLocal;

  const LoreFieldMergeChoice({
    required this.fieldKey,
    this.localValue,
    this.globalValue,
    this.preferLocal = true,
  });
}
