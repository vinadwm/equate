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

  // ============================================================
  // CHART RANGE
  // ============================================================

  int _chartDays = 30;

  // ============================================================
  // HISTORY TABLE RANGE
  // 7 / 30 / 90 / 365 hari
  // ============================================================

  int _historyDays = 7;

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  HistoricalMarket get selectedMarket => _selectedMarket;

  DateTime? get selectedDate => _selectedDate;

  int get chartDays => _chartDays;

  int get historyDays => _historyDays;

  HistoricalDataModel? get liveGoldData => _liveGoldData;

  HistoricalDataModel? get liveHangsengData => _liveHangsengData;

  // ============================================================
  // GET DATA FOR MARKET
  // ============================================================

  HistoricalDataModel? getDataForMarket(String category, {DateTime? date}) {
    final targetCategory = category.trim().toUpperCase();

    final marketData = _allData.where((item) {
      return item.category.trim().toUpperCase() == targetCategory;
    }).toList();

    if (marketData.isEmpty) {
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

    return null;
  }

  // ============================================================
  // PREVIOUS GOLD DATA
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

  // ============================================================
  // GOLD DATA FOR SPECIFIC DATE
  // ============================================================

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
  // LATEST AVAILABLE DATA
  // ============================================================

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
  // SELECTED CATEGORY
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
  // SELECTED DATA
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
  // HISTORICAL TABLE DATA
  //
  // Data terbaru berada di atas.
  //
  // Range dihitung berdasarkan tanggal DATA TERBARU,
  // bukan DateTime.now(), supaya tidak bermasalah ketika
  // data API terakhir bukan hari ini.
  // ============================================================

  List<HistoricalDataModel> get filteredHistoricalData {
    final data = List<HistoricalDataModel>.from(marketData);

    if (data.isEmpty) {
      return [];
    }

    data.sort((a, b) => b.date.compareTo(a.date));

    // Semua data
    if (_historyDays == -1) {
      return data;
    }

    final latestDate = DateTime(
      data.first.date.year,
      data.first.date.month,
      data.first.date.day,
    );

    final startDate = latestDate.subtract(Duration(days: _historyDays - 1));

    return data.where((item) {
      final itemDate = DateTime(item.date.year, item.date.month, item.date.day);

      return !itemDate.isBefore(startDate) && !itemDate.isAfter(latestDate);
    }).toList();
  }

  // ============================================================
  // HISTORY RANGE LABEL
  // ============================================================

  String get historyRangeLabel {
    switch (_historyDays) {
      case 7:
        return '7 Hari';

      case 30:
        return '30 Hari';

      case 90:
        return '90 Hari';

      case 365:
        return '1 Tahun';

      case -1:
        return 'Semua';

      default:
        return '$_historyDays Hari';
    }
  }

  // ============================================================
  // LOAD HISTORICAL DATA
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

      // ========================================================
      // GANTI DATA HISTORICAL DENGAN LIVE DATA
      // jika category + tanggal sama.
      // ========================================================

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

  // ============================================================
  // FIND LIVE DATA
  // ============================================================

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
  // CHANGE HISTORY TABLE RANGE
  // ============================================================

  void changeHistoryRange(int days) {
    if (_historyDays == days) {
      return;
    }

    _historyDays = days;

    notifyListeners();
  }

  // ============================================================
  // SET DEFAULT DATE
  // ============================================================

  void _setDefaultDate() {
    if (marketData.isEmpty) {
      _selectedDate = null;
      return;
    }

    _selectedDate = marketData.first.date;
  }

  // ============================================================
  // SAME DATE
  // ============================================================

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  // ============================================================
  // DATE AVAILABLE
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
