import 'dart:async';
import 'package:flutter/foundation.dart';
import '../service/gold_price_service.dart';
import '../model/gold_price_model.dart';
import '../service/gold_api_service.dart';

class GoldViewModel extends ChangeNotifier {
  final GoldApiService _service = GoldApiService();

  GoldPriceModel? goldPrice;

  bool isLoading = false;

  Future<void> fetchGoldPrice() async {
    try {
      isLoading = true;
      notifyListeners();

      final data = await _service.getGoldData();

      // ambil data terbaru
      final latest = data.first;

      // convert ke GoldPriceModel
      goldPrice = GoldPriceModel.fromJson(latest);
    } catch (e) {
      debugPrint('Gold API Error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}