import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:equate/model/kurs_model.dart';

const Map<String, String> _kHeaders = {
  'User-Agent':
      'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120 Mobile Safari/537.36',
};

class KursService {
  static const String quote = 'IDR';

  /// Sumber utama: Yahoo Finance (intraday, tanpa API key, tidak resmi).
  /// Cadangan: Frankfurter (data referensi harian dari ECB, resmi & gratis).
  static Future<KursSeries> fetch(String base, KursRange range) async {
    try {
      return await _fromYahoo(base, range);
    } catch (e) {
      debugPrint('KURS Yahoo gagal ($base): $e');
    }
    return _fromFrankfurter(base, range);
  }

  // ==============================================================
  // YAHOO FINANCE
  // ==============================================================
  static Future<KursSeries> _fromYahoo(String base, KursRange range) async {
    final (r, interval) = switch (range) {
      KursRange.day => ('1d', '5m'),
      KursRange.week => ('7d', '1h'),
      KursRange.month => ('1mo', '1d'),
    };

    final uri = Uri.parse(
      'https://query1.finance.yahoo.com/v8/finance/chart/'
      '$base$quote=X?range=$r&interval=$interval',
    );

    final res = await http
        .get(uri, headers: _kHeaders)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final results = json['chart']?['result'] as List?;
    if (results == null || results.isEmpty) throw Exception('Data kosong');

    final item = results.first as Map<String, dynamic>;
    final timestamps = (item['timestamp'] as List?) ?? const [];
    final closes =
        (item['indicators']?['quote']?[0]?['close'] as List?) ?? const [];

    final points = <KursPoint>[];
    final count = timestamps.length < closes.length
        ? timestamps.length
        : closes.length;

    for (var i = 0; i < count; i++) {
      final value = closes[i];
      if (value == null) continue;
      points.add(
        KursPoint(
          time: DateTime.fromMillisecondsSinceEpoch(
            (timestamps[i] as num).toInt() * 1000,
          ),
          rate: (value as num).toDouble(),
        ),
      );
    }

    if (points.length < 2) throw Exception('Titik data kurang');

    final price = (item['meta']?['regularMarketPrice'] as num?)?.toDouble();

    return KursSeries(
      base: base,
      quote: quote,
      points: points,
      current: price ?? points.last.rate,
      isLive: true,
      source: 'Yahoo Finance',
    );
  }

  // ==============================================================
  // FRANKFURTER (ECB) — cadangan, data harian
  // ==============================================================
  static Future<KursSeries> _fromFrankfurter(
    String base,
    KursRange range,
  ) async {
    final days = range == KursRange.month ? 30 : 7;
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    final fmt = DateFormat('yyyy-MM-dd');

    final uri = Uri.parse(
      'https://api.frankfurter.dev/v1/${fmt.format(start)}..${fmt.format(end)}'
      '?base=$base&symbols=$quote',
    );

    final res = await http
        .get(uri, headers: _kHeaders)
        .timeout(const Duration(seconds: 12));

    if (res.statusCode != 200) {
      throw Exception('Frankfurter HTTP ${res.statusCode}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final rates = (json['rates'] as Map<String, dynamic>?) ?? {};

    final points = <KursPoint>[];
    rates.forEach((date, value) {
      final rate = (value as Map<String, dynamic>)[quote];
      if (rate is num) {
        points.add(
          KursPoint(time: DateTime.parse(date), rate: rate.toDouble()),
        );
      }
    });
    points.sort((a, b) => a.time.compareTo(b.time));

    if (points.length < 2) throw Exception('Titik data kurang');

    return KursSeries(
      base: base,
      quote: quote,
      points: points,
      current: points.last.rate,
      isLive: false,
      source: 'ECB (Frankfurter)',
    );
  }
}