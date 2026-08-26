import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:equate/model/gold_price_model.dart';

class GoldService {
  // Endpoint API publik harga emas Indonesia gratis & aktif
  static const String _url = 'https://indonesia-public-static-api.vercel.app/api/harga-emas';

  Future<GoldPriceModel?> fetchLiveGoldPrice() async {
    try {
      final response = await http.get(Uri.parse(_url));

      print('--> [GoldService] Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        
        // Ambil harga per gram dari data JSON
        double priceGram = 0.0;
        if (body['harga'] != null) {
          priceGram = (body['harga'] as num).toDouble();
        }

        return GoldPriceModel(
          pricePerGram: priceGram,
          currency: 'IDR',
          updatedAt: DateTime.now(),
        );
      } else {
        print('--> [GoldService] Server Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('--> [GoldService] Exception: $e');
      return null;
    }
  }
}