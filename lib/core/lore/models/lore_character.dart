import 'package:lizunemu/core/lore/models/lore_param.dart';

class LoreKinkTag {
  final String name;
  final String stance; // yes | maybe | no | unknown

  const LoreKinkTag({required this.name, this.stance = 'unknown'});

  Map<String, dynamic> toJson() => {'name': name, 'stance': stance};

  factory LoreKinkTag.fromJson(Map<String, dynamic> json) => LoreKinkTag(
        name: json['name'] as String? ?? '',
        stance: json['stance'] as String? ?? 'unknown',
      );
}

class LoreCharacter {
  final String id;
  final String name;
  final List<String> aliases;
  final String? role;
  final String? appearance;
  final String? personality;
  final String? relationshipToListener;
  final String? voiceActorId;
  final String? voiceActorName;
  final bool vaLinkProposed;
  final bool vaLinkConfirmed;
  final String? globalCharacterId;
  final List<LoreKinkTag> kinks;
  final List<LoreParam> params;
  final String? notes;
  final bool isFocusDefault;

  const LoreCharacter({
    required this.id,
    required this.name,
    this.aliases = const [],
    this.role,
    this.appearance,
    this.personality,
    this.relationshipToListener,
    this.voiceActorId,
    this.voiceActorName,
    this.vaLinkProposed = false,
    this.vaLinkConfirmed = false,
    this.globalCharacterId,
    this.kinks = const [],
    this.params = const [],
    this.notes,
    this.isFocusDefault = false,
  });

  List<LoreParam> get hudPinnedParams =>
      params.where((p) => p.hudPinned).toList(growable: false);

  LoreParam? paramByKey(String key) {
    for (final p in params) {
      if (p.key == key) return p;
    }
    return null;
  }

  LoreCharacter copyWith({
    String? id,
    String? name,
    List<String>? aliases,
    String? role,
    String? appearance,
    String? personality,
    String? relationshipToListener,
    String? voiceActorId,
    String? voiceActorName,
    bool? vaLinkProposed,
    bool? vaLinkConfirmed,
    String? globalCharacterId,
    List<LoreKinkTag>? kinks,
    List<LoreParam>? params,
    String? notes,
    bool? isFocusDefault,
    bool clearGlobalId = false,
  }) {
    return LoreCharacter(
      id: id ?? this.id,
      name: name ?? this.name,
      aliases: aliases ?? this.aliases,
      role: role ?? this.role,
      appearance: appearance ?? this.appearance,
      personality: personality ?? this.personality,
      relationshipToListener:
          relationshipToListener ?? this.relationshipToListener,
      voiceActorId: voiceActorId ?? this.voiceActorId,
      voiceActorName: voiceActorName ?? this.voiceActorName,
      vaLinkProposed: vaLinkProposed ?? this.vaLinkProposed,
      vaLinkConfirmed: vaLinkConfirmed ?? this.vaLinkConfirmed,
      globalCharacterId: clearGlobalId
          ? null
          : (globalCharacterId ?? this.globalCharacterId),
      kinks: kinks ?? this.kinks,
      params: params ?? this.params,
      notes: notes ?? this.notes,
      isFocusDefault: isFocusDefault ?? this.isFocusDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'aliases': aliases,
        if (role != null) 'role': role,
        if (appearance != null) 'appearance': appearance,
        if (personality != null) 'personality': personality,
        if (relationshipToListener != null)
          'relationshipToListener': relationshipToListener,
        if (voiceActorId != null) 'voiceActorId': voiceActorId,
        if (voiceActorName != null) 'voiceActorName': voiceActorName,
        'vaLinkProposed': vaLinkProposed,
        'vaLinkConfirmed': vaLinkConfirmed,
        if (globalCharacterId != null) 'globalCharacterId': globalCharacterId,
        'kinks': kinks.map((e) => e.toJson()).toList(),
        'params': params.map((e) => e.toJson()).toList(),
        if (notes != null) 'notes': notes,
        'isFocusDefault': isFocusDefault,
      };

  factory LoreCharacter.fromJson(Map<String, dynamic> json) {
    return LoreCharacter(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      aliases: (json['aliases'] as List?)?.cast<String>() ?? const [],
      role: json['role'] as String?,
      appearance: json['appearance'] as String?,
      personality: json['personality'] as String?,
      relationshipToListener: json['relationshipToListener'] as String?,
      voiceActorId: json['voiceActorId'] as String?,
      voiceActorName: json['voiceActorName'] as String?,
      vaLinkProposed: json['vaLinkProposed'] as bool? ?? false,
      vaLinkConfirmed: json['vaLinkConfirmed'] as bool? ?? false,
      globalCharacterId: json['globalCharacterId'] as String?,
      kinks: (json['kinks'] as List?)
              ?.whereType<Map>()
              .map((e) => LoreKinkTag.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      params: (json['params'] as List?)
              ?.whereType<Map>()
              .map((e) => LoreParam.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      notes: json['notes'] as String?,
      isFocusDefault: json['isFocusDefault'] as bool? ?? false,
    );
  }
}
