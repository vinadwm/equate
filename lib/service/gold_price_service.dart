import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/gold_price_model.dart';

class GoldPriceService {
  static const String rawUrl = 'https://www.newsmaker.id/api/historical-data';

  // Nama method disesuaikan menjadi fetchGoldPrices agar cocok dengan GoldViewModel
  Future<List<GoldPriceModel>> fetchGoldPrices() async {
    final response = await http.get(Uri.parse(rawUrl));

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengambil data harga emas. '
        'Status code: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    print('RESPONSE NEWSMAKER: $data');

    if (data is List) {
      return data
          .map(
            (item) => GoldPriceModel.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList()
          .cast<GoldPriceModel>(); // Ditambahkan agar tidak error List<dynamic>
    }

    if (data is Map<String, dynamic>) {
      final list = data['data'];

      if (list is List) {
        return list
            .map(
              (item) => GoldPriceModel.fromMap(Map<String, dynamic>.from(item)),
            )
            .toList()
            .cast<GoldPriceModel>(); // Ditambahkan agar tidak error List<dynamic>
      }
    }

    throw Exception('Format data dari Newsmaker tidak dikenali.');
  }

  Future<GoldPriceModel> getLatestGoldPrice() async {
    final prices = await fetchGoldPrices();

    if (prices.isEmpty) {
      throw Exception('Data harga emas kosong.');
    }

    return prices.first;
  }
}