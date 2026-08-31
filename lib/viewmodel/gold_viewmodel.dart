import 'dart:async';
import 'package:flutter/foundation.dart';
import '../service/gold_price_service.dart';
import '../model/gold_price_model.dart';

class GoldViewModel extends ChangeNotifier {
  // Gunakan GoldPriceService sesuai service yang ada
  final GoldPriceService _service = GoldPriceService();

  GoldPriceModel? goldPrice;
  List<GoldPriceModel> historyList = [];
  bool isLoading = false;
  Timer? _timer;

  Future<void> fetchGoldPrice() async {
    try {
      isLoading = true;
      notifyListeners();

      // Memanggil method fetch dari GoldPriceService
      final data = await _service.fetchGoldPrices();

      if (data.isNotEmpty) {
        historyList = data;
        goldPrice = data.first;
      }
    } catch (e) {
      debugPrint('Gold API Error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Method ini dipanggil oleh home_tab_view.dart
  Future<void> startLivePriceUpdates() async {
    await fetchGoldPrice();
    
    // Optional: Jalankan timer otomatis per 1 menit jika ingin live refresh
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      fetchGoldPrice();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}