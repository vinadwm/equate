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

      // ==========================
      // CEK STATUS HTTP
      // ==========================
      if (response.statusCode != 200) {
        throw Exception('Server mengembalikan status ${response.statusCode}');
      }

      // ==========================
      // DECODE JSON
      // ==========================
      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Format response API tidak valid.');
      }

      print('API KEYS: ${decoded.keys.toList()}');

      // ==========================
      // CEK STATUS API
      // ==========================
      final dynamic status = decoded['status'];

      print('API STATUS: $status');
      print('API MESSAGE: ${decoded['message']}');

      if (status != null &&
          status.toString() != '200' &&
          status.toString().toLowerCase() != 'success') {
        throw Exception(
          decoded['message']?.toString() ?? 'API mengembalikan status gagal.',
        );
      }

      // ==========================
      // AMBIL DATA
      // ==========================
      final dynamic rawData = decoded['data'];

      print('TIPE DATA: ${rawData.runtimeType}');
      print('RAW DATA: $rawData');

      if (rawData is! List) {
        throw Exception(
          'Field data bukan List. '
          'Tipe yang diterima: ${rawData.runtimeType}',
        );
      }

      print('JUMLAH RAW DATA: ${rawData.length}');

      // ==========================
      // PARSING DATA
      // ==========================
      final List<HistoricalDataModel> result = [];

      for (final item in rawData) {
        if (item is! Map) {
          print('SKIP ITEM karena bukan Map: $item');
          continue;
        }

        final map = Map<String, dynamic>.from(item);

        try {
          final model = HistoricalDataModel.fromJson(map);

          result.add(model);

          // ==========================
          // DEBUG GOLD
          // ==========================
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
        } catch (e) {
          print('GAGAL PARSING ITEM: $map');
          print('ERROR: $e');
        }
      }

      // ==========================
      // HASIL AKHIR
      // ==========================
      print('========== HASIL HISTORICAL ==========');
      print('TOTAL MODEL: ${result.length}');

      if (result.isNotEmpty) {
        print(
          'DATA PERTAMA: '
          '${result.first.dateFormatted} | '
          '${result.first.category}',
        );

        print(
          'DATA TERAKHIR: '
          '${result.last.dateFormatted} | '
          '${result.last.category}',
        );
      } else {
        print('⚠️ TIDAK ADA DATA YANG BERHASIL DIPARSING');
      }

      print('======================================');

      return result;
    } catch (e, stackTrace) {
      print('========== HISTORICAL SERVICE ERROR ==========');
      print('ERROR: $e');
      print('STACK TRACE: $stackTrace');
      print('==============================================');

      throw Exception('Gagal mengambil data historical: $e');
    }
  }
}
