/// One purchased DLsite Play work in the user's library.
class DlsiteAlbum {
  const DlsiteAlbum({
    required this.workno,
    required this.title,
    this.circle,
    this.cv,
    this.tags = const [],
    this.coverUrl,
    this.purchaseDate,
  });

  final String workno;
  final String title;
  final String? circle;
  final String? cv;
  final List<String> tags;
  final String? coverUrl;
  final String? purchaseDate;

  String get subtitle {
    final parts = <String>[];
    if (circle != null && circle!.isNotEmpty) parts.add(circle!);
    if (cv != null && cv!.isNotEmpty) parts.add(cv!);
    if (purchaseDate != null && purchaseDate!.isNotEmpty) {
      parts.add(purchaseDate!);
    }
    return parts.join(' · ');
  }
}

/// Streamable audio leaf from DLsite Play ziptree.
class DlsiteAudioTrack {
  const DlsiteAudioTrack({
    required this.displayPath,
    required this.streamUrl,
    this.durationSeconds,
  });

  final String displayPath;
  final String streamUrl;
  final double? durationSeconds;
}
