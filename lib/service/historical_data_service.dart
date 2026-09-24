import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:equate/model/historical_data_model.dart';

class HistoricalDataService {
  static const String _baseUrl = 'https://newsmaker.id/api/historical-data';

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
