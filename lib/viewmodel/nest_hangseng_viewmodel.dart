import 'package:flutter/foundation.dart';

import 'package:equate/model/historical_data_model.dart';
import 'historical_data_viewmodel.dart';
import 'package:equate/model/nest_hangseng_model.dart';

class NestHangsengViewModel extends ChangeNotifier {
  final HistoricalDataViewModel historicalDataViewModel;

  NestHangsengViewModel({required this.historicalDataViewModel}) {
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
  // DATA HANGSENG HARI INI (DENGAN FALLBACK)
  // ============================================================

  HistoricalDataModel? get todayHangsengData {
    final data = historicalDataViewModel.getLatestAvailableData(
      'HSI Daily',
      calculationDate,
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
    return todayHangsengData?.open;
  }

  bool get isTodayDataFallback {
    final data = todayHangsengData;

    if (data == null) {
      return false;
    }

    return !_isSameCalendarDate(data.date, calculationDate);
  }

  DateTime get todayDataDisplayDate {
    return todayHangsengData?.date ?? calculationDate;
  }

  // ============================================================
  // DATA HANGSENG HARI KEMARIN (DENGAN FALLBACK)
  // ============================================================
  //
  // Kalau H-1 tidak ada (mis. Sabtu/Minggu atau libur newsmaker),
  // otomatis mundur mengambil data valid terakhir yang tersedia.
  // Contoh: H-1 = tanggal 19 tidak ada -> ambil tanggal 18.

  HistoricalDataModel? get yesterdayHangsengData {
    return historicalDataViewModel.getLatestAvailableData(
      'HSI Daily',
      previousDate,
    );
  }

  double? get yesterdayClose {
    return yesterdayHangsengData?.close;
  }

  bool get isPreviousDataFallback {
    final data = yesterdayHangsengData;

    if (data == null) {
      return false;
    }

    return !_isSameCalendarDate(data.date, previousDate);
  }

  DateTime get previousDataDisplayDate {
    return yesterdayHangsengData?.date ?? previousDate;
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
    final currentData = todayHangsengData;
    final previousData = yesterdayHangsengData;

    // ==========================================================
    // OPEN TIDAK TERSEDIA
    // ==========================================================

    if (currentData == null) {
      _open = '';

      _isAutoFilled = false;

      _errorMessage =
          'Data Open Hangseng ${_formatDate(calculationDate)} belum tersedia.';

      _clearCalculationResult(notify: false);

      notifyListeners();

      return false;
    }

    // ==========================================================
    // CLOSE TIDAK TERSEDIA
    // ==========================================================

    if (previousData == null) {
      _close = '';

      _isAutoFilled = false;

      _errorMessage =
          'Data Close Hangseng ${_formatDate(previousDate)} belum tersedia.';

      _clearCalculationResult(notify: false);

      notifyListeners();

      return false;
    }

    // ==========================================================
    // VALIDASI OPEN
    // ==========================================================

    if (currentData.open <= 0) {
      _open = '';

      _isAutoFilled = false;

      _errorMessage =
          'Data Open Hangseng ${_formatDate(currentData.date)} belum tersedia.';

      _clearCalculationResult(notify: false);

      notifyListeners();

      return false;
    }

    // ==========================================================
    // VALIDASI CLOSE
    // ==========================================================

    if (previousData.close <= 0) {
      _close = '';

      _isAutoFilled = false;

      _errorMessage =
          'Data Close Hangseng ${_formatDate(previousData.date)} belum tersedia.';

      _clearCalculationResult(notify: false);

      notifyListeners();

      return false;
    }

    // ==========================================================
    // AUTO FILL
    // Open  -> data hari ini (atau fallback terakhir)
    // Close -> data hari kemarin (atau fallback terakhir)
    // ==========================================================

    _open = _numberToInput(currentData.open);
    _close = _numberToInput(previousData.close);

    _isAutoFilled = true;
    _errorMessage = null;

    _clearCalculationResult(notify: false);

    notifyListeners();

    return true;
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

  NestHangsengModel? buildResultModel() {
    if (!_isCalculated) {
      return null;
    }

    final openValue = _parseNumber(_open);
    final closeValue = _parseNumber(_close);

    if (openValue == null || closeValue == null) {
      return null;
    }

    return NestHangsengModel(
      calculationDate: calculationDate,
      previousDate: previousDate,
      open: openValue,
      close: closeValue,
      result: closeValue,
      isAutoFilled: _isAutoFilled,
      isCalculated: _isCalculated,
      signal: signal,
    );
  }

  // ============================================================
  // SIGNAL
  // ============================================================

  NestHangsengSignal get signal {
    if (!_isCalculated) {
      return NestHangsengSignal.unavailable;
    }

    final openValue = _parseNumber(_open);
    final closeValue = _parseNumber(_close);

    if (openValue == null || closeValue == null) {
      return NestHangsengSignal.unavailable;
    }

    // Close > Open → BUY
    if (closeValue > openValue) {
      return NestHangsengSignal.buy;
    }

    // Close < Open → SELL
    if (closeValue < openValue) {
      return NestHangsengSignal.sell;
    }

    // Close = Open
    return NestHangsengSignal.neutral;
  }

  // ============================================================
  // SIGNAL LABEL
  // ============================================================

  String get signalLabel {
    switch (signal) {
      case NestHangsengSignal.buy:
        return 'BUY';

      case NestHangsengSignal.sell:
        return 'SELL';

      case NestHangsengSignal.neutral:
        return 'BUY/SELL';

      case NestHangsengSignal.unavailable:
        return 'BELUM TERSEDIA';
    }
  }

  // ============================================================
  // SIGNAL DESCRIPTION
  // ============================================================

  String get signalDescription {
    switch (signal) {
      case NestHangsengSignal.buy:
        return 'Close lebih tinggi dari Open.';

      case NestHangsengSignal.sell:
        return 'Close lebih rendah dari Open.';

      case NestHangsengSignal.neutral:
        return 'Close sama dengan Open.';

      case NestHangsengSignal.unavailable:
        return 'Silakan masukkan Open dan Close terlebih dahulu.';
    }
  }

  // ============================================================
  // REKOMENDASI / SARAN AKSI
  // ============================================================

  String get recommendationTitle {
    switch (signal) {
      case NestHangsengSignal.buy:
        return 'Pertimbangkan BUY';

      case NestHangsengSignal.sell:
        return 'Pertimbangkan SELL';

      case NestHangsengSignal.neutral:
        return 'Tunggu Konfirmasi';

      case NestHangsengSignal.unavailable:
        return 'Lengkapi Data Terlebih Dahulu';
    }
  }

  List<String> get recommendationSteps {
    switch (signal) {
      case NestHangsengSignal.buy:
        return [
          'Close lebih tinggi dari Open menandakan momentum harga sedang naik (bullish).',
          'Cari konfirmasi tambahan (berita ekonomi, volume) sebelum membuka posisi Buy.',
          'Pasang stop loss di bawah harga terendah terakhir untuk membatasi risiko.',
          'Sesuaikan ukuran posisi dengan manajemen risiko pribadi Anda.',
        ];

      case NestHangsengSignal.sell:
        return [
          'Close lebih rendah dari Open menandakan momentum harga sedang turun (bearish).',
          'Cari konfirmasi tambahan sebelum membuka posisi Sell.',
          'Pasang stop loss di atas harga tertinggi terakhir untuk membatasi risiko.',
          'Sesuaikan ukuran posisi dengan manajemen risiko pribadi Anda.',
        ];

      case NestHangsengSignal.neutral:
        return [
          'Close sama dengan Open, belum terlihat arah pergerakan yang jelas.',
          'Sebaiknya tunggu data sesi berikutnya sebelum mengambil posisi.',
          'Hindari memaksakan entry ketika sinyal belum jelas.',
        ];

      case NestHangsengSignal.unavailable:
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