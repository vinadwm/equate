import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:equate/model/historical_data_model.dart';

class HistoricalDataService {
  static const String _baseUrl = 'https://newsmaker.id/api/historical-data';

  Future<List<HistoricalDataModel>> getHistoricalData() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode != 200) {
        throw Exception('Server mengembalikan status ${response.statusCode}');
      }

      final Map<String, dynamic> jsonData = jsonDecode(response.body);

      if (jsonData['status'] != 200) {
        throw Exception(
          jsonData['message']?.toString() ?? 'Gagal mengambil data historical.',
        );
      }

      final List<dynamic> data = jsonData['data'] as List<dynamic>? ?? [];

      return data
          .map(
            (item) =>
                HistoricalDataModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data historical: $e');
    }
  }
}
