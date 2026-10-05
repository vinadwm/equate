import 'package:flutter/foundation.dart';

import 'package:equate/model/historical_data_model.dart';
import 'package:equate/service/historical_data_service.dart';

enum HistoricalMarket { gold, hkk, jpk }

class HistoricalDataViewModel extends ChangeNotifier {
  final HistoricalDataService _service = HistoricalDataService();

  bool _isLoading = false;
  String? _errorMessage;

  List<HistoricalDataModel> _allData = [];
  HistoricalDataModel? _liveGoldData;
  HistoricalDataModel? _liveHangsengData;

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

  HistoricalDataModel? get liveGoldData => _liveGoldData;

  HistoricalDataModel? get liveHangsengData => _liveHangsengData;

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

  HistoricalDataModel? getPreviousGoldData(DateTime date) {
    final previousDate = DateTime(date.year, date.month, date.day - 1);

    for (final item in _allData) {
      final itemDate = DateTime(item.date.year, item.date.month, item.date.day);

      if (item.category.trim().toUpperCase() == 'LGD DAILY' &&
          itemDate.year == previousDate.year &&
          itemDate.month == previousDate.month &&
          itemDate.day == previousDate.day) {
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
  // DATA TERAKHIR YANG TERSEDIA (FALLBACK LIBUR / WEEKEND)
  // ============================================================
  //
  // Mencari data `category` TEPAT pada `onOrBeforeDate`. Kalau tidak ada
  // (misalnya karena weekend/hari libur newsmaker), otomatis mundur
  // hari demi hari sampai maksimal `maxLookbackDays` untuk menemukan
  // data valid terakhir yang tersedia.
  //
  // Contoh:
  // onOrBeforeDate = tanggal 19 (Minggu, tidak ada data)
  // -> mundur ke 18 (Sabtu, tidak ada data juga)
  // -> mundur ke 17 (Jumat, ADA data) -> dikembalikan
  //
  // Data yang bank holiday atau close-nya 0 dianggap tidak valid
  // dan akan dilewati.
  HistoricalDataModel? getLatestAvailableData(
    String category,
    DateTime onOrBeforeDate, {
    int maxLookbackDays = 10,
  }) {
    final targetCategory = category.trim().toUpperCase();

    final marketData = _allData.where((item) {
      return item.category.trim().toUpperCase() == targetCategory;
    }).toList();

    if (marketData.isEmpty) {
      return null;
    }

    for (var i = 0; i <= maxLookbackDays; i++) {
      final checkDate = onOrBeforeDate.subtract(Duration(days: i));

      for (final item in marketData) {
        if (!_isSameDate(item.date, checkDate)) {
          continue;
        }

        if (item.isBankHoliday) {
          continue;
        }

        if (item.close <= 0) {
          continue;
        }

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
    } catch (e) {
      debugPrint('Historical data error: $e');
      _errorMessage = 'Gagal mengambil data historical.';
    }

    try {
      final liveData = await _service.getLiveMarketData();
      _liveGoldData = _findLiveData(liveData, 'LGD Daily');
      _liveHangsengData = _findLiveData(liveData, 'HSI Daily');

      for (final quote in liveData) {
        _allData.removeWhere(
          (item) =>
              item.category.trim().toUpperCase() ==
                  quote.category.trim().toUpperCase() &&
              _isSameDate(item.date, quote.date),
        );
        _allData.add(quote);
      }
    } catch (e) {
      debugPrint('Live market quote error: $e');
      _liveGoldData = null;
      _liveHangsengData = null;
    } finally {
      _setDefaultDate();
      _isLoading = false;
      notifyListeners();
    }
  }

  HistoricalDataModel? _findLiveData(
    List<HistoricalDataModel> data,
    String category,
  ) {
    for (final item in data) {
      if (item.category.trim().toUpperCase() == category.toUpperCase()) {
        return item;
      }
    }

    return null;
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
