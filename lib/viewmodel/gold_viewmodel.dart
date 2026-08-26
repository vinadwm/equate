import 'package:flutter/material.dart';
import 'package:equate/model/gold_price_model.dart';
import 'package:equate/service/gold_service.dart';

class GoldViewModel extends ChangeNotifier {
  final GoldService _goldService = GoldService();

  GoldPriceModel? _goldData;
  bool _isLoading = false;
  String? _errorMessage;

  GoldPriceModel? get goldData => _goldData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Mengambil harga emas live
  Future<void> loadGoldPrice() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('--> [GoldViewModel] Memanggil API harga emas...');
      final result = await _goldService.fetchLiveGoldPrice();

      if (result != null) {
        _goldData = result;
        print('--> [GoldViewModel] Berhasil mendapatkan harga emas!');
      } else {
        _errorMessage = 'Gagal mengambil harga emas terbaru (Result Null)';
        print('--> [GoldViewModel] Error: fetchLiveGoldPrice() mengembalikan NULL.');
      }
    } catch (e, stackTrace) {
      _errorMessage = e.toString();
      print('================ ERROR GOLD SERVICE ================');
      print('Detail Error: $e');
      print('Stacktrace: $stackTrace');
      print('==================================================');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}