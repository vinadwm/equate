import 'dart:convert';

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

      print('========== HISTORICAL API ==========');
      print('STATUS CODE: ${response.statusCode}');
      print('BODY LENGTH: ${response.body.length}');
      print('BODY: ${response.body}');
      print('====================================');

      if (response.statusCode != 200) {
        throw Exception('Server mengembalikan status ${response.statusCode}');
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Format response API tidak valid.');
      }

      print('API KEYS: ${decoded.keys.toList()}');

      final dynamic status = decoded['status'];

      print('API STATUS: $status');

      if (status != null &&
          status.toString() != '200' &&
          status.toString().toLowerCase() != 'success') {
        throw Exception(
          decoded['message']?.toString() ?? 'API mengembalikan status gagal.',
        );
      }

      final dynamic rawData = decoded['data'];

      print('TIPE DATA: ${rawData.runtimeType}');

      if (rawData is! List) {
        throw Exception(
          'Field data bukan List. '
          'Tipe yang diterima: ${rawData.runtimeType}',
        );
      }

      print('JUMLAH RAW DATA: ${rawData.length}');

      final List<HistoricalDataModel> result = [];

      for (final item in rawData) {
        if (item is! Map) {
          continue;
        }

        final map = Map<String, dynamic>.from(item);

        final model = HistoricalDataModel.fromJson(map);

        result.add(model);

        if (model.category.toUpperCase().contains('LGD')) {
          print(
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

      print('HASIL MODEL: ${result.length}');
      print('====================================');

      return result;
    } catch (e) {
      print('HISTORICAL SERVICE ERROR: $e');

      throw Exception('Gagal mengambil data historical: $e');
    }
  }
}
