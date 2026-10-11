class NewsItem {
  final String title;
  final String summary;

  /// Isi artikel dari RSS (kalau ada), paragraf dipisah baris kosong.
  final String content;

  final String link;
  final String? imageUrl;
  final String source;
  final DateTime publishedAt;

  const NewsItem({
    required this.title,
    required this.summary,
    this.content = '',
    required this.link,
    required this.imageUrl,
    required this.source,
    required this.publishedAt,
  });
}