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
  // GET DATA BERDASARKAN MARKET DAN TANGGAL
  // ============================================================

  HistoricalDataModel? getDataForMarket(String category, {DateTime? date}) {
    final targetCategory = category.trim().toUpperCase();

    final marketData = _allData.where((item) {
      return item.category.trim().toUpperCase() == targetCategory;
    }).toList();

    if (marketData.isEmpty) {
      debugPrint('❌ Tidak ada data untuk category: $targetCategory');
      return null;
    }

    marketData.sort((a, b) => b.date.compareTo(a.date));

    if (date == null) {
      return marketData.first;
    }

    for (final item in marketData) {
      if (_isSameDate(item.date, date)) {
        return item;
      }
    }

    debugPrint(
      '❌ Tidak ada $targetCategory untuk tanggal '
      '${date.day}/${date.month}/${date.year}',
    );

    return null;
  }

  // ============================================================
  // GET DATA GOLD HARI SEBELUMNYA
  // ============================================================

  // ============================================================
  // GET DATA MARKET HARI SEBELUMNYA
  // ============================================================

  HistoricalDataModel? getPreviousMarketData(DateTime date, String category) {
    final targetCategory = category.trim().toUpperCase();

    final marketData = _allData.where((item) {
      return item.category.trim().toUpperCase() == targetCategory;
    }).toList();

    if (marketData.isEmpty) {
      return null;
    }

    // Urutkan dari tanggal terbaru → terlama
    marketData.sort((a, b) => b.date.compareTo(a.date));

    final targetDate = DateTime(date.year, date.month, date.day);

    // Ambil data terakhir yang benar-benar
    // berada sebelum tanggal kalkulasi.
    //
    // Contoh:
    // Senin 21
    // Minggu 20 -> tidak ada
    // Sabtu 19  -> tidak ada
    // Jumat 18  -> ambil Jumat
    //
    // Kalau Jumat juga libur:
    // Kamis 17 -> ambil Kamis

    for (final item in marketData) {
      if (item.isBankHoliday) {
        continue;
      }

      final itemDate = DateTime(item.date.year, item.date.month, item.date.day);

      if (itemDate.isBefore(targetDate)) {
        return item;
      }
    }

    return null;
  }

  HistoricalDataModel? getGoldDataForDate(DateTime date) {
    for (final item in _allData) {
      final itemDate = DateTime(item.date.year, item.date.month, item.date.day);

      if (item.category.trim().toUpperCase() == 'LGD DAILY' &&
          itemDate.year == date.year &&
          itemDate.month == date.month &&
          itemDate.day == date.day) {
        return item;
      }
    }

    return null;
  }

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
    final data = marketData;

    if (data.isEmpty) {
      return [];
    }

    if (_chartDays == -1) {
      return data.reversed.toList();
    }

    final count = data.length < _chartDays ? data.length : _chartDays;

    return data.sublist(0, count).reversed.toList();
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
