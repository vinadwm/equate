import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';

import 'package:equate/model/news_model.dart';

class NewsSource {
  final String name;
  final String url;
  const NewsSource(this.name, this.url);
}

// ================================================================
// DAFTAR SUMBER BERITA (RSS)
// Feed yang gagal dimuat dilewati otomatis, alasannya muncul di
// console dengan awalan "NEWS". Tambah / hapus / ganti URL di sini.
// ================================================================
const List<NewsSource> kNewsSources = [
  NewsSource('Newsmaker.id', 'https://newsmaker.id/index.php/feed'),
  // TradingView tidak punya RSS resmi. Kalau URL ini gagal, sumbernya
  // otomatis dilewati. Ganti dengan feed lain kalau kamu punya.
  NewsSource('TradingView', 'https://www.tradingview.com/feed/'),
  NewsSource('CNBC Indonesia', 'https://www.cnbcindonesia.com/market/rss'),
  NewsSource('Detik Finance', 'https://rss.detik.com/index.php/finance'),
  NewsSource('Investing.com', 'https://www.investing.com/rss/news_11.rss'),
  NewsSource('FXStreet', 'https://www.fxstreet.com/rss/news'),
  NewsSource('Yahoo Finance', 'https://finance.yahoo.com/news/rssindex'),
  NewsSource(
    'MarketWatch',
    'https://feeds.content.dowjones.io/public/rss/mw_topstories',
  ),
];

const Map<String, String> _kHeaders = {
  'User-Agent':
      'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120 Mobile Safari/537.36',
};

class NewsService {
  static Future<List<NewsItem>> fetchAll() async {
    final results = await Future.wait(kNewsSources.map(_fetchOne));
    final all = results.expand((e) => e).toList();

    // Hapus duplikat berdasarkan link, urutkan dari terbaru.
    final seen = <String>{};
    final unique = all.where((e) => seen.add(e.link)).toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    return unique;
  }

  // ==============================================================
  // AMBIL ISI ARTIKEL LENGKAP DARI HALAMAN WEB (best effort)
  // Mengembalikan daftar paragraf. Kosong kalau gagal / diblokir.
  // ==============================================================
  static Future<List<String>> fetchArticle(String url) async {
    try {
      final res = await http
          .get(Uri.parse(url), headers: _kHeaders)
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) return [];

      final doc = html_parser.parse(res.body);

      var nodes = doc.querySelectorAll('article p');
      if (nodes.length < 3) nodes = doc.querySelectorAll('p');

      final seen = <String>{};
      final paragraphs = <String>[];

      for (final p in nodes) {
        final text = p.text.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (text.length < 50) continue;
        if (!seen.add(text)) continue;
        paragraphs.add(text);
        if (paragraphs.length >= 40) break;
      }
      return paragraphs;
    } catch (e) {
      debugPrint('NEWS artikel gagal: $e');
      return [];
    }
  }

  static Future<List<NewsItem>> _fetchOne(NewsSource source) async {
    try {
      final res = await http
          .get(Uri.parse(source.url), headers: _kHeaders)
          .timeout(const Duration(seconds: 12));

      if (res.statusCode != 200) {
        debugPrint('NEWS ${source.name}: HTTP ${res.statusCode}');
        return [];
      }

      final doc = XmlDocument.parse(res.body);
      final items = doc.findAllElements('item').take(15);

      final list = <NewsItem>[];
      for (final node in items) {
        final title = _text(node, 'title');
        final link = _text(node, 'link');
        if (title.isEmpty || link.isEmpty) continue;

        final rawDesc = _text(node, 'description');
        final rawContent = _text(node, 'content:encoded');

        list.add(
          NewsItem(
            title: _clean(title),
            summary: _clean(rawDesc.isNotEmpty ? rawDesc : rawContent),
            content: rawContent.isNotEmpty ? _cleanParagraphs(rawContent) : '',
            link: link.trim(),
            imageUrl: _image(node, rawDesc, rawContent),
            source: source.name,
            publishedAt: _parseDate(_text(node, 'pubDate')),
          ),
        );
      }
      return list;
    } catch (e) {
      debugPrint('NEWS ${source.name} gagal: $e');
      return [];
    }
  }

  static String _text(XmlElement node, String name) {
    final found = node.findElements(name);
    if (found.isEmpty) return '';
    return found.first.innerText.trim();
  }

  static String? _image(XmlElement node, String desc, String encoded) {
    for (final tag in ['media:content', 'media:thumbnail', 'enclosure']) {
      for (final el in node.findElements(tag)) {
        final url = el.getAttribute('url');
        final type = el.getAttribute('type') ?? '';
        if (url != null &&
            url.startsWith('http') &&
            (tag != 'enclosure' || type.isEmpty || type.startsWith('image'))) {
          return url;
        }
      }
    }

    final match = RegExp(
      '<img[^>]+src=["\']([^"\']+)["\']',
    ).firstMatch('$desc $encoded');
    final src = match?.group(1);
    return (src != null && src.startsWith('http')) ? src : null;
  }

  static String _decode(String s) {
    return s
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#8217;', "'")
        .replaceAll('&#8216;', "'")
        .replaceAll('&#8220;', '"')
        .replaceAll('&#8221;', '"')
        .replaceAll('&#8211;', '-')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }

  static String _clean(String input) {
    final s = _decode(input.replaceAll(RegExp(r'<[^>]*>'), ' '));
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // Seperti _clean, tapi mempertahankan batas paragraf.
  static String _cleanParagraphs(String input) {
    var s = input
        .replaceAll(RegExp(r'</p>|<br\s*/?>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), ' ');
    s = _decode(s);

    final parts = s
        .split(RegExp(r'\n{2,}'))
        .map((e) => e.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((e) => e.length > 20)
        .toList();

    return parts.join('\n\n');
  }

  // Format RSS: "Mon, 12 Oct 2026 08:30:00 +0700" / "GMT"
  static DateTime _parseDate(String raw) {
    if (raw.isEmpty) return DateTime.now();

    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso.toLocal();

    try {
      final tz = RegExp(r'([+-]\d{4}|GMT|UTC|Z)$').firstMatch(raw.trim());
      final base = raw.trim().replaceAll(
        RegExp(r'\s*([+-]\d{4}|GMT|UTC|Z)$'),
        '',
      );

      final parsed = DateFormat(
        'EEE, dd MMM yyyy HH:mm:ss',
        'en_US',
      ).parse(base);

      var offset = Duration.zero;
      final z = tz?.group(1) ?? 'GMT';
      if (z.startsWith('+') || z.startsWith('-')) {
        final sign = z.startsWith('-') ? -1 : 1;
        final h = int.parse(z.substring(1, 3));
        final m = int.parse(z.substring(3, 5));
        offset = Duration(hours: h, minutes: m) * sign;
      }

      return DateTime.utc(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
      ).subtract(offset).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }
}