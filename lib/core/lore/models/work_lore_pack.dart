import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:lizunemu/core/lore/models/lore_character.dart';
import 'package:lizunemu/core/lore/models/lore_content_level.dart';
import 'package:lizunemu/core/lore/models/lore_event.dart';
import 'package:lizunemu/core/lore/models/lore_ontology.dart';

enum LoreSeedScope { work, character, keyed }

class LoreSeedNote {
  final String id;
  final LoreSeedScope scope;
  final String? characterId;
  final List<String> keys;
  final String content;
  final bool alwaysActive;

  const LoreSeedNote({
    required this.id,
    required this.scope,
    this.characterId,
    this.keys = const [],
    required this.content,
    this.alwaysActive = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'scope': scope.name,
        if (characterId != null) 'characterId': characterId,
        'keys': keys,
        'content': content,
        'alwaysActive': alwaysActive,
      };

  factory LoreSeedNote.fromJson(Map<String, dynamic> json) {
    final scopeName = json['scope'] as String? ?? 'work';
    return LoreSeedNote(
      id: json['id'] as String? ?? '',
      scope: LoreSeedScope.values.firstWhere(
        (e) => e.name == scopeName,
        orElse: () => LoreSeedScope.work,
      ),
      characterId: json['characterId'] as String?,
      keys: (json['keys'] as List?)?.cast<String>() ?? const [],
      content: json['content'] as String? ?? '',
      alwaysActive: json['alwaysActive'] as bool? ?? false,
    );
  }
}

class WorkLorePack {
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final int ontologyVersion;
  final String workId;
  final String? sourceId;
  final String? workTitle;
  final LoreContentLevel contentLevel;
  final bool explicitRevealed;
  final String synopsis;
  final List<LoreCharacter> characters;
  final List<LoreTrackSummary> trackSummaries;
  final List<LoreTimelineEvent> events;
  final List<LoreSeedNote> seedNotes;
  final String? focusCharacterId;
  final DateTime updatedAt;
  final String loreHash;
  final String? languageCode;

  const WorkLorePack({
    this.schemaVersion = currentSchemaVersion,
    this.ontologyVersion = LoreOntology.version,
    required this.workId,
    this.sourceId,
    this.workTitle,
    this.contentLevel = LoreContentLevel.suggestive,
    this.explicitRevealed = false,
    this.synopsis = '',
    this.characters = const [],
    this.trackSummaries = const [],
    this.events = const [],
    this.seedNotes = const [],
    this.focusCharacterId,
    required this.updatedAt,
    required this.loreHash,
    this.languageCode,
  });

  bool get hasLore =>
      synopsis.trim().isNotEmpty ||
      characters.isNotEmpty ||
      trackSummaries.isNotEmpty ||
      events.isNotEmpty;

  LoreCharacter? characterById(String? id) {
    if (id == null) return null;
    for (final c in characters) {
      if (c.id == id) return c;
    }
    return null;
  }

  String? get defaultFocusCharacterId {
    if (focusCharacterId != null && characterById(focusCharacterId) != null) {
      return focusCharacterId;
    }
    for (final c in characters) {
      if (c.isFocusDefault) return c.id;
    }
    return characters.isEmpty ? null : characters.first.id;
  }

  WorkLorePack copyWith({
    int? schemaVersion,
    int? ontologyVersion,
    String? workId,
    String? sourceId,
    String? workTitle,
    LoreContentLevel? contentLevel,
    bool? explicitRevealed,
    String? synopsis,
    List<LoreCharacter>? characters,
    List<LoreTrackSummary>? trackSummaries,
    List<LoreTimelineEvent>? events,
    List<LoreSeedNote>? seedNotes,
    String? focusCharacterId,
    DateTime? updatedAt,
    String? loreHash,
    String? languageCode,
    bool clearFocus = false,
  }) {
    return WorkLorePack(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      ontologyVersion: ontologyVersion ?? this.ontologyVersion,
      workId: workId ?? this.workId,
      sourceId: sourceId ?? this.sourceId,
      workTitle: workTitle ?? this.workTitle,
      contentLevel: contentLevel ?? this.contentLevel,
      explicitRevealed: explicitRevealed ?? this.explicitRevealed,
      synopsis: synopsis ?? this.synopsis,
      characters: characters ?? this.characters,
      trackSummaries: trackSummaries ?? this.trackSummaries,
      events: events ?? this.events,
      seedNotes: seedNotes ?? this.seedNotes,
      focusCharacterId:
          clearFocus ? null : (focusCharacterId ?? this.focusCharacterId),
      updatedAt: updatedAt ?? this.updatedAt,
      loreHash: loreHash ?? this.loreHash,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'ontologyVersion': ontologyVersion,
        'workId': workId,
        if (sourceId != null) 'sourceId': sourceId,
        if (workTitle != null) 'workTitle': workTitle,
        'contentLevel': contentLevel.name,
        'explicitRevealed': explicitRevealed,
        'synopsis': synopsis,
        'characters': characters.map((e) => e.toJson()).toList(),
        'trackSummaries': trackSummaries.map((e) => e.toJson()).toList(),
        'events': events.map((e) => e.toJson()).toList(),
        'seedNotes': seedNotes.map((e) => e.toJson()).toList(),
        if (focusCharacterId != null) 'focusCharacterId': focusCharacterId,
        'updatedAt': updatedAt.toIso8601String(),
        'loreHash': loreHash,
        if (languageCode != null) 'languageCode': languageCode,
      };

  factory WorkLorePack.fromJson(Map<String, dynamic> json) {
    return WorkLorePack(
      schemaVersion: json['schemaVersion'] as int? ?? currentSchemaVersion,
      ontologyVersion: json['ontologyVersion'] as int? ?? LoreOntology.version,
      workId: json['workId'] as String? ?? '',
      sourceId: json['sourceId'] as String?,
      workTitle: json['workTitle'] as String?,
      contentLevel: LoreContentLevelX.parse(json['contentLevel'] as String?),
      explicitRevealed: json['explicitRevealed'] as bool? ?? false,
      synopsis: json['synopsis'] as String? ?? '',
      characters: (json['characters'] as List?)
              ?.whereType<Map>()
              .map((e) => LoreCharacter.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      trackSummaries: (json['trackSummaries'] as List?)
              ?.whereType<Map>()
              .map(
                  (e) => LoreTrackSummary.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      events: (json['events'] as List?)
              ?.whereType<Map>()
              .map((e) =>
                  LoreTimelineEvent.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      seedNotes: (json['seedNotes'] as List?)
              ?.whereType<Map>()
              .map((e) => LoreSeedNote.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      focusCharacterId: json['focusCharacterId'] as String?,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      loreHash: json['loreHash'] as String? ?? '',
      languageCode: json['languageCode'] as String?,
    );
  }

  /// Content hash used to invalidate CCv2 cache when lore changes.
  static String computeLoreHash(WorkLorePack pack) {
    final payload = jsonEncode({
      'synopsis': pack.synopsis,
      'characters': pack.characters.map((e) => e.toJson()).toList(),
      'trackSummaries': pack.trackSummaries.map((e) => e.toJson()).toList(),
      'events': pack.events.map((e) => e.toJson()).toList(),
      'contentLevel': pack.contentLevel.name,
    });
    return sha256.convert(utf8.encode(payload)).toString();
  }

  WorkLorePack withRecomputedHash() {
    final hashed = copyWith(loreHash: 'pending');
    return hashed.copyWith(loreHash: computeLoreHash(hashed));
  }
}
