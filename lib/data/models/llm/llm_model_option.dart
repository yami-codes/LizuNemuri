/// One selectable model from a provider catalog (autocomplete row).
class LlmModelOption {
  final String id;
  final String? name;
  final String? description;
  final int? contextLength;
  final String? priceHint;

  const LlmModelOption({
    required this.id,
    this.name,
    this.description,
    this.contextLength,
    this.priceHint,
  });

  String get displayLabel {
    if (name != null && name!.trim().isNotEmpty && name != id) {
      return '$id — ${name!.trim()}';
    }
    return id;
  }

  String? get subtitle {
    final parts = <String>[];
    if (contextLength != null) {
      parts.add('${contextLength! ~/ 1000}k ctx');
    }
    if (priceHint != null && priceHint!.isNotEmpty) {
      parts.add(priceHint!);
    }
    if (description != null && description!.trim().isNotEmpty) {
      parts.add(description!.trim());
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }
}
