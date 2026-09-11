import 'package:flutter/foundation.dart';

import 'package:equate/model/historical_data_model.dart';
import 'package:equate/service/historical_data_service.dart';

enum HistoricalMarket { gold, hkk, jpk }

class HistoricalDataViewModel extends ChangeNotifier {
  final HistoricalDataService _service = HistoricalDataService();

  bool _isLoading = false;
  String? _errorMessage;

  List<HistoricalDataModel> _allData = [];

  HistoricalMarket _selectedMarket = HistoricalMarket.gold;
  DateTime? _selectedDate;

  int _chartDays = 30;

  // ============================================================
  // GETTER
  // ============================================================

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  HistoricalMarket get selectedMarket => _selectedMarket;

  DateTime? get selectedDate => _selectedDate;

  int get chartDays => _chartDays;

  // ============================================================
  // CATEGORY
  // ============================================================

  String get selectedCategory {
    switch (_selectedMarket) {
      case HistoricalMarket.gold:
        return 'LGD Daily';

      case HistoricalMarket.hkk:
        return 'HSI Daily';

      case HistoricalMarket.jpk:
        return 'SNI Daily';
    }
  }

  // ============================================================
  // MARKET NAME
  // ============================================================

  String get marketName {
    switch (_selectedMarket) {
      case HistoricalMarket.gold:
        return 'Emas';

      case HistoricalMarket.hkk:
        return 'HKK';

      case HistoricalMarket.jpk:
        return 'JPK';
    }
  }

  // ============================================================
  // MARKET DATA
  // ============================================================

  List<HistoricalDataModel> get marketData {
    final data = _allData
        .where(
          (item) =>
              item.category.toLowerCase() == selectedCategory.toLowerCase(),
        )
        .toList();

    data.sort((a, b) => b.date.compareTo(a.date));

    return data;
  }

  // ============================================================
  // DATA SESUAI TANGGAL YANG DIPILIH
  // ============================================================

  HistoricalDataModel? get selectedData {
    if (_selectedDate == null) {
      return marketData.isNotEmpty ? marketData.first : null;
    }

    for (final item in marketData) {
      if (_isSameDate(item.date, _selectedDate!)) {
        return item;
      }
    }

    return null;
  }

  // ============================================================
  // CHART DATA
  // ============================================================

  List<HistoricalDataModel> get chartData {
    final data = List<HistoricalDataModel>.from(marketData);

    data.sort((a, b) => a.date.compareTo(b.date));

    if (_chartDays == -1) {
      return data;
    }

    if (data.length <= _chartDays) {
      return data;
    }

    return data.sublist(data.length - _chartDays);
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> loadHistoricalData() async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _allData = await _service.getHistoricalData();

      _setDefaultDate();
    } catch (e) {
      debugPrint('Historical data error: $e');

      _errorMessage = 'Gagal mengambil data historical.';
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // CHANGE MARKET
  // ============================================================

  void changeMarket(HistoricalMarket market) {
    if (_selectedMarket == market) {
      return;
    }

    _selectedMarket = market;

    _setDefaultDate();

    notifyListeners();
  }

  // ============================================================
  // CHANGE DATE
  // ============================================================

  void changeDate(DateTime date) {
    _selectedDate = date;

    notifyListeners();
  }

  // ============================================================
  // CHANGE CHART RANGE
  // ============================================================

  void changeChartRange(int days) {
    if (_chartDays == days) {
      return;
    }

    _chartDays = days;

    notifyListeners();
  }

  // ============================================================
  // DEFAULT DATE
  // ============================================================

  void _setDefaultDate() {
    if (marketData.isEmpty) {
      _selectedDate = null;
      return;
    }

    _selectedDate = marketData.first.date;
  }

  // ============================================================
  // CHECK DATE
  // ============================================================

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  // ============================================================
  // CHECK AVAILABLE DATE
  // ============================================================

  bool isDateAvailable(DateTime date) {
    return marketData.any((item) => _isSameDate(item.date, date));
  }

  // ============================================================
  // AVAILABLE DATES
  // ============================================================

  List<DateTime> get availableDates {
    return marketData.map((item) => item.date).toList();
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    _errorMessage = null;

    notifyListeners();
  }
}
