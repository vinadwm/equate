import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:equate/model/historical_data_model.dart';

class HistoricalDataService {
  static const String _baseUrl = 'https://newsmaker.id/api/historical-data';
  static const String _liveQuotesUrl =
      'https://www.newsmaker.id/api/live-quotes';

  Future<List<HistoricalDataModel>> getLiveMarketData() async {
    final response = await http.get(
      Uri.parse(_liveQuotesUrl),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Server mengembalikan status ${response.statusCode}');
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic> || decoded['data'] is! List) {
      throw Exception('Format response live quotes tidak valid.');
    }

    final quotes = decoded['data'] as List;
    const markets = {
      'XUL10': ('LGD Daily', -1),
      'HKK50_BBJ': ('HSI Daily', -2),
    };
    final result = <HistoricalDataModel>[];

    for (final quote in quotes) {
      if (quote is! Map) {
        continue;
      }

      final market = markets[quote['symbol']?.toString()];
      if (market == null) continue;

      final date = DateTime.tryParse(
        quote['date_time']?.toString() ??
            quote['serverDateTime']?.toString() ??
            '',
      );

      if (date == null) {
        throw Exception('Tanggal quote Gold tidak valid.');
      }

      result.add(
        HistoricalDataModel.fromJson({
          'id': market.$2,
          'tanggal': date.toIso8601String(),
          'open': quote['open'],
          'high': quote['high'],
          'low': quote['low'],
          'close': quote['last'] ?? quote['price'],
          'category': market.$1,
        }),
      );
    }

    return result;
  }

  Future<List<HistoricalDataModel>> getHistoricalData() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {'Accept': 'application/json'},
      );

      if (kDebugMode) {
        debugPrint('========== HISTORICAL API ==========');
        debugPrint('STATUS CODE: ${response.statusCode}');
        debugPrint('BODY LENGTH: ${response.body.length}');
        debugPrint('BODY: ${response.body}');
        debugPrint('====================================');
      }

      if (response.statusCode != 200) {
        throw Exception('Server mengembalikan status ${response.statusCode}');
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Format response API tidak valid.');
      }

      if (kDebugMode) {
        debugPrint('API KEYS: ${decoded.keys.toList()}');
      }

      final dynamic status = decoded['status'];

      if (kDebugMode) {
        debugPrint('API STATUS: $status');
      }

      if (status != null &&
          status.toString() != '200' &&
          status.toString().toLowerCase() != 'success') {
        throw Exception(
          decoded['message']?.toString() ?? 'API mengembalikan status gagal.',
        );
      }

      final dynamic rawData = decoded['data'];

      if (kDebugMode) {
        debugPrint('TIPE DATA: ${rawData.runtimeType}');
      }

      if (rawData is! List) {
        throw Exception(
          'Field data bukan List. '
          'Tipe yang diterima: ${rawData.runtimeType}',
        );
      }

      if (kDebugMode) {
        debugPrint('JUMLAH RAW DATA: ${rawData.length}');
      }

      final List<HistoricalDataModel> result = [];

      for (final item in rawData) {
        if (item is! Map) {
          continue;
        }

        final map = Map<String, dynamic>.from(item);

        final model = HistoricalDataModel.fromJson(map);

        result.add(model);

        if (kDebugMode && model.category.toUpperCase().contains('LGD')) {
          debugPrint(
            'GOLD: '
            '${model.dateFormatted} | '
            'Open=${model.open} | '
            'High=${model.high} | '
            'Low=${model.low} | '
            'Close=${model.close} | '
            'Category=${model.category}',
          );
        }
      }

      if (kDebugMode) {
        debugPrint('HASIL MODEL: ${result.length}');
        debugPrint('====================================');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('HISTORICAL SERVICE ERROR: $e');
      }

      throw Exception('Gagal mengambil data historical: $e');
    }
  }
}
