/// UI/content intensity for a work lore pack.
enum LoreContentLevel {
  sfw,
  suggestive,
  explicit,
}

extension LoreContentLevelX on LoreContentLevel {
  bool get showsExplicitBlocks =>
      this == LoreContentLevel.suggestive || this == LoreContentLevel.explicit;

  static LoreContentLevel parse(String? raw) {
    return LoreContentLevel.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => LoreContentLevel.suggestive,
    );
  }
}
