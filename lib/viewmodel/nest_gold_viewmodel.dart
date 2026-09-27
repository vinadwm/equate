import 'package:flutter/foundation.dart';

import 'package:equate/model/historical_data_model.dart';
import 'historical_data_viewmodel.dart';
import 'package:equate/model/nest_gold_model.dart';

class NestGoldViewModel extends ChangeNotifier {
  final HistoricalDataViewModel historicalDataViewModel;

  NestGoldViewModel({required this.historicalDataViewModel}) {
    historicalDataViewModel.addListener(_onHistoricalDataChanged);

    _initializeFromHistoricalData();
  }

  // ============================================================
  // INPUT
  // ============================================================

  String _close = '';
  String _open = '';

  String get close => _close;
  String get open => _open;

  // ============================================================
  // STATUS
  // ============================================================

  bool _isCalculated = false;
  bool _isAutoFilled = false;

  bool get isCalculated => _isCalculated;
  bool get isAutoFilled => _isAutoFilled;

  // ============================================================
  // MODE OTOMATIS / MANUAL
  // ============================================================

  bool _autoMode = true;

  bool get autoMode => _autoMode;

  void setAutoMode(bool value) {
    if (_autoMode == value) {
      return;
    }

    _autoMode = value;

    if (_autoMode) {
      fillFromHistoricalData();
    } else {
      _isAutoFilled = false;
      _errorMessage = null;

      _clearCalculationResult(notify: false);

      notifyListeners();
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  // ============================================================
  // TANGGAL
  // ============================================================

  DateTime get calculationDate {
    final now = DateTime.now();

    return DateTime(now.year, now.month, now.day);
  }

  DateTime get previousDate {
    return calculationDate.subtract(const Duration(days: 1));
  }

  // ============================================================
  // DATA GOLD HARI INI (DENGAN FALLBACK)
  // ============================================================

  HistoricalDataModel? get todayGoldData {
    // OPEN HANYA BOLEH MENGAMBIL DATA HARI INI.
    // Tidak ada fallback ke hari sebelumnya.
    final data = historicalDataViewModel.getDataForMarket(
      'LGD Daily',
      date: calculationDate,
    );

    if (data == null) {
      return null;
    }

    if (data.open <= 0) {
      return null;
    }

    return data;
  }

  double? get todayOpen {
    return todayGoldData?.open;
  }

  bool get isTodayDataFallback => false;

  DateTime? get todayDataDisplayDate {
    return todayGoldData?.date;
  }

  // ============================================================
  // DATA GOLD HARI KEMARIN (DENGAN FALLBACK)
  // ============================================================
  //
  // Kalau H-1 tidak ada (mis. Sabtu/Minggu atau libur newsmaker),
  // otomatis mundur mengambil data valid terakhir yang tersedia.
  // Contoh: H-1 = tanggal 19 tidak ada -> ambil tanggal 18.

  HistoricalDataModel? get yesterdayGoldData {
    return historicalDataViewModel.getLatestAvailableData(
      'LGD Daily',
      previousDate,
    );
  }

  double? get yesterdayClose {
    return yesterdayGoldData?.close;
  }

  bool get isPreviousDataFallback {
    final data = yesterdayGoldData;

    if (data == null) {
      return false;
    }

    return !_isSameCalendarDate(data.date, previousDate);
  }

  DateTime get previousDataDisplayDate {
    return yesterdayGoldData?.date ?? previousDate;
  }

  // ============================================================
  // STATUS DATA
  // ============================================================

  bool get isOpenDataAvailable {
    return todayOpen != null;
  }

  bool get isCloseDataAvailable {
    return yesterdayClose != null;
  }

  bool get isHistoricalDataComplete {
    return isOpenDataAvailable && isCloseDataAvailable;
  }

  String get dataStatusMessage {
    final openAvailable = isOpenDataAvailable;
    final closeAvailable = isCloseDataAvailable;

    if (openAvailable && closeAvailable) {
      return 'Data historical tersedia.';
    }

    if (!openAvailable && !closeAvailable) {
      return 'Data Open ${_formatDate(calculationDate)} dan '
          'Close ${_formatDate(previousDate)} belum tersedia.';
    }

    if (!openAvailable) {
      return 'Data Open ${_formatDate(calculationDate)} belum tersedia.';
    }

    return 'Data Close ${_formatDate(previousDate)} belum tersedia.';
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initializeFromHistoricalData() async {
    await Future<void>.delayed(Duration.zero);

    if (_autoMode) {
      fillFromHistoricalData();
    }
  }

  // ============================================================
  // AUTO FILL
  // ============================================================

  bool fillFromHistoricalData() {
    final currentData = todayGoldData;
    final previousData = yesterdayGoldData;

    bool openFilled = false;
    bool closeFilled = false;

    // ==========================================================
    // OPEN
    // HANYA DATA HARI INI
    // ==========================================================

    if (currentData != null && currentData.open > 0) {
      _open = _numberToInput(currentData.open);
      openFilled = true;
    } else {
      // Kalau data hari ini belum tersedia,
      // Open harus tetap kosong.
      _open = '';
    }

    // ==========================================================
    // CLOSE
    // DATA TERAKHIR YANG TERSEDIA
    // ==========================================================

    if (previousData != null && previousData.close > 0) {
      _close = _numberToInput(previousData.close);
      closeFilled = true;
    } else {
      _close = '';
    }

    // ==========================================================
    // STATUS AUTO FILL
    // ==========================================================

    _isAutoFilled = openFilled || closeFilled;

    // ==========================================================
    // ERROR / STATUS
    // ==========================================================

    if (!openFilled && !closeFilled) {
      _errorMessage =
          'Data Open ${_formatDate(calculationDate)} dan '
          'Close ${_formatDate(previousDate)} belum tersedia.';
    } else if (!openFilled) {
      _errorMessage =
          'Data Open Gold ${_formatDate(calculationDate)} '
          'belum tersedia.';
    } else if (!closeFilled) {
      _errorMessage = 'Data Close Gold belum tersedia.';
    } else {
      _errorMessage = null;
    }

    _clearCalculationResult(notify: false);

    notifyListeners();

    return openFilled && closeFilled;
  }

  // ============================================================
  // REFRESH
  // ============================================================

  bool refreshData() {
    if (!_autoMode) {
      return false;
    }

    return fillFromHistoricalData();
  }

  // ============================================================
  // INPUT HANDLER
  // ============================================================

  void setOpen(String value) {
    _open = value;

    _isAutoFilled = false;
    _errorMessage = null;

    _clearCalculationResult(notify: false);

    notifyListeners();
  }

  void setClose(String value) {
    _close = value;

    _isAutoFilled = false;
    _errorMessage = null;

    _clearCalculationResult(notify: false);

    notifyListeners();
  }

  // ============================================================
  // INPUT STATE
  // ============================================================

  bool get hasInput {
    return _open.trim().isNotEmpty || _close.trim().isNotEmpty;
  }

  bool get canCalculate {
    final openValue = _parseNumber(_open);
    final closeValue = _parseNumber(_close);

    if (openValue == null || closeValue == null) {
      return false;
    }

    if (openValue <= 0 || closeValue <= 0) {
      return false;
    }

    return true;
  }

  // ============================================================
  // CALCULATE NEST
  // ============================================================

  bool calculateNest() {
    final openValue = _parseNumber(_open);
    final closeValue = _parseNumber(_close);

    if (openValue == null || closeValue == null) {
      _errorMessage =
          'Harap masukkan Open dan Close dengan format angka yang valid.';

      _isCalculated = false;

      notifyListeners();

      return false;
    }

    if (openValue <= 0 || closeValue <= 0) {
      _errorMessage = 'Nilai Open dan Close harus lebih dari 0.';

      _isCalculated = false;

      notifyListeners();

      return false;
    }

    _isCalculated = true;
    _errorMessage = null;

    notifyListeners();

    return true;
  }

  // ============================================================
  // BUILD RESULT MODEL (UNTUK DISIMPAN KE RIWAYAT)
  // ============================================================

  NestGoldModel? buildResultModel() {
    if (!_isCalculated) {
      return null;
    }

    final openValue = _parseNumber(_open);
    final closeValue = _parseNumber(_close);

    if (openValue == null || closeValue == null) {
      return null;
    }

    return NestGoldModel(
      calculationDate: calculationDate,
      previousDate: previousDate,
      open: openValue,
      close: closeValue,
      isAutoFilled: _isAutoFilled,
      isCalculated: _isCalculated,
      signal: signal,
    );
  }

  // ============================================================
  // SIGNAL
  // ============================================================

  NestGoldSignal get signal {
    if (!_isCalculated) {
      return NestGoldSignal.unavailable;
    }

    final openValue = _parseNumber(_open);
    final closeValue = _parseNumber(_close);

    if (openValue == null || closeValue == null) {
      return NestGoldSignal.unavailable;
    }

    // Close > Open → BUY
    if (closeValue > openValue) {
      return NestGoldSignal.buy;
    }

    // Close < Open → SELL
    if (closeValue < openValue) {
      return NestGoldSignal.sell;
    }

    // Close = Open
    return NestGoldSignal.neutral;
  }

  // ============================================================
  // SIGNAL LABEL
  // ============================================================

  String get signalLabel {
    switch (signal) {
      case NestGoldSignal.buy:
        return 'BUY';

      case NestGoldSignal.sell:
        return 'SELL';

      case NestGoldSignal.neutral:
        return 'BUY/SELL';

      case NestGoldSignal.unavailable:
        return 'BELUM TERSEDIA';
    }
  }

  // ============================================================
  // SIGNAL DESCRIPTION
  // ============================================================

  String get signalDescription {
    switch (signal) {
      case NestGoldSignal.buy:
        return 'Close lebih tinggi dari Open.';

      case NestGoldSignal.sell:
        return 'Close lebih rendah dari Open.';

      case NestGoldSignal.neutral:
        return 'Close sama dengan Open.';

      case NestGoldSignal.unavailable:
        return 'Silakan masukkan Open dan Close terlebih dahulu.';
    }
  }

  // ============================================================
  // REKOMENDASI / SARAN AKSI
  // ============================================================

  String get recommendationTitle {
    switch (signal) {
      case NestGoldSignal.buy:
        return 'Pertimbangkan BUY';

      case NestGoldSignal.sell:
        return 'Pertimbangkan SELL';

      case NestGoldSignal.neutral:
        return 'Tunggu Konfirmasi';

      case NestGoldSignal.unavailable:
        return 'Lengkapi Data Terlebih Dahulu';
    }
  }

  List<String> get recommendationSteps {
    switch (signal) {
      case NestGoldSignal.buy:
        return [
          'Close lebih tinggi dari Open menandakan momentum harga sedang naik (bullish).',
          'Cari konfirmasi tambahan (berita ekonomi, volume) sebelum membuka posisi Buy.',
          'Pasang stop loss di bawah harga terendah terakhir untuk membatasi risiko.',
          'Sesuaikan ukuran posisi dengan manajemen risiko pribadi Anda.',
        ];

      case NestGoldSignal.sell:
        return [
          'Close lebih rendah dari Open menandakan momentum harga sedang turun (bearish).',
          'Cari konfirmasi tambahan sebelum membuka posisi Sell.',
          'Pasang stop loss di atas harga tertinggi terakhir untuk membatasi risiko.',
          'Sesuaikan ukuran posisi dengan manajemen risiko pribadi Anda.',
        ];

      case NestGoldSignal.neutral:
        return [
          'Close sama dengan Open, belum terlihat arah pergerakan yang jelas.',
          'Sebaiknya tunggu data sesi berikutnya sebelum mengambil posisi.',
          'Hindari memaksakan entry ketika sinyal belum jelas.',
        ];

      case NestGoldSignal.unavailable:
        return [
          'Masukkan nilai Open dan Close terlebih dahulu.',
          'Pastikan format angka valid dan bernilai lebih dari 0.',
        ];
    }
  }

  String get recommendationDisclaimer =>
      'Catatan: Ini adalah alat bantu analisis teknikal sederhana, bukan '
      'jaminan hasil dan bukan nasihat keuangan. Selalu lakukan riset '
      'tambahan sebelum mengambil keputusan.';

  // ============================================================
  // RESET
  // ============================================================

  void reset() {
    _open = '';
    _close = '';

    _isAutoFilled = false;
    _isCalculated = false;
    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // CLEAR RESULT
  // ============================================================

  void _clearCalculationResult({bool notify = true}) {
    _isCalculated = false;

    if (notify) {
      notifyListeners();
    }
  }

  // ============================================================
  // HISTORICAL LISTENER
  // ============================================================

  void _onHistoricalDataChanged() {
    if (_autoMode && _isAutoFilled) {
      fillFromHistoricalData();
    }
  }

  // ============================================================
  // PARSE NUMBER
  // ============================================================

  double? _parseNumber(String value) {
    final text = value.trim();

    if (text.isEmpty) {
      return null;
    }

    if (text.contains('.') && text.contains(',')) {
      final normalized = text.replaceAll('.', '').replaceAll(',', '.');

      return double.tryParse(normalized);
    }

    if (text.contains(',')) {
      return double.tryParse(text.replaceAll(',', '.'));
    }

    return double.tryParse(text);
  }

  // ============================================================
  // FORMAT INPUT
  // ============================================================

  String _numberToInput(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  bool _isSameCalendarDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void dispose() {
    historicalDataViewModel.removeListener(_onHistoricalDataChanged);

    super.dispose();
  }
}
