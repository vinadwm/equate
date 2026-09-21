import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../model/historical_data_model.dart';
import '../model/pivot_hangseng_model.dart';
import 'historical_data_viewmodel.dart';

class PivotHangsengViewModel extends ChangeNotifier {
  final HistoricalDataViewModel historicalDataViewModel;

  PivotHangsengViewModel({required this.historicalDataViewModel}) {
    historicalDataViewModel.addListener(_onHistoricalDataChanged);

    _initializeFromHistoricalData();
  }

  // ============================================================
  // INPUT H / L / C / OPEN
  // ============================================================

  String _high = '';
  String _low = '';
  String _close = '';
  String _open = '';

  String get high => _high;
  String get low => _low;
  String get close => _close;
  String get open => _open;

  // ============================================================
  // HASIL PIVOT
  // ============================================================

  double? _pp;

  double? _r1;
  double? _r2;
  double? _r3;
  double? _r4;

  double? _s1;
  double? _s2;
  double? _s3;
  double? _s4;

  double? get pp => _pp;

  double? get r1 => _r1;
  double? get r2 => _r2;
  double? get r3 => _r3;
  double? get r4 => _r4;

  double? get s1 => _s1;
  double? get s2 => _s2;
  double? get s3 => _s3;
  double? get s4 => _s4;

  bool _isCalculated = false;

  bool get isCalculated => _isCalculated;

  // ============================================================
  // AUTO FILL
  // ============================================================

  bool _isAutoFilled = false;
  bool _isOpenAutoFilled = false;

  bool get isAutoFilled => _isAutoFilled;
  bool get isOpenAutoFilled => _isOpenAutoFilled;

  // ============================================================
  // ERROR / INFO
  // ============================================================

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  // ============================================================
  // TANGGAL PERHITUNGAN
  // ============================================================

  DateTime get calculationDate {
    final now = DateTime.now();

    return DateTime(now.year, now.month, now.day);
  }

  // ============================================================
  // DATA HANGSENG HARI INI
  // ============================================================

  /// Mengambil data Hangseng TEPAT pada tanggal perhitungan.
  ///
  /// Digunakan untuk mengambil:
  /// Open
  ///
  /// Tidak menggunakan fallback.
  HistoricalDataModel? get referenceData {
    final date = calculationDate;

    final data = historicalDataViewModel.getDataForMarket(
      'LGD Daily',
      date: date,
    );

    if (data == null) {
      return null;
    }

    if (data.isBankHoliday) {
      return null;
    }

    if (data.open <= 0) {
      return null;
    }

    return data;
  }

  // ============================================================
  // OPEN HARI INI
  // ============================================================

  /// Open yang sedang digunakan oleh kalkulator.
  ///
  /// Nilainya bisa berasal dari auto-fill Newsmaker
  /// atau hasil edit manual user.
  double? get openValue {
    return _parseNumber(_open);
  }

  /// Open asli dari Newsmaker.
  ///
  /// Ini hanya digunakan sebagai sumber auto-fill.
  double? get referenceOpen {
    return referenceData?.open;
  }

  // ============================================================
  // TANGGAL OPEN / SIGNAL
  // ============================================================

  DateTime? get referenceDate {
    return referenceData?.date;
  }

  // ============================================================
  // DATA HANGSENG HARI SEBELUMNYA
  // ============================================================

  /// Mengambil data Hangseng TEPAT satu hari kalender sebelum
  /// tanggal perhitungan.
  HistoricalDataModel? get previousHangsengData {
    return historicalDataViewModel.getPreviousMarketData(
      calculationDate,
      'HSI Daily',
    );
  }

  // ============================================================
  // TANGGAL DATA H/L/C
  // ============================================================

  DateTime? get previousDataDate {
    return previousHangsengData?.date;
  }

  // ============================================================
  // STATUS DATA
  // ============================================================

  bool get isOpenDataAvailable {
    final open = openValue;

    return open != null && open > 0;
  }

  bool get isPreviousDataAvailable {
    final data = previousHangsengData;

    if (data == null) {
      return false;
    }

    if (data.isBankHoliday) {
      return false;
    }

    if (data.high <= 0 || data.low <= 0 || data.close <= 0) {
      return false;
    }

    return true;
  }

  /// Apakah data H/L/C dan Open lengkap.
  bool get isHistoricalDataComplete {
    return isOpenDataAvailable && isPreviousDataAvailable;
  }

  // ============================================================
  // DATA STATUS MESSAGE
  // ============================================================

  String get dataStatusMessage {
    final openAvailable = isOpenDataAvailable;
    final previousAvailable = isPreviousDataAvailable;

    if (openAvailable && previousAvailable) {
      return 'Data historical tersedia.';
    }

    if (!openAvailable && !previousAvailable) {
      return 'Data Open ${_formatDate(calculationDate)} dan '
          'data High, Low, Close '
          '${_formatDate(calculationDate.subtract(const Duration(days: 1)))} '
          'belum tersedia.';
    }

    if (!openAvailable) {
      return 'Data Open ${_formatDate(calculationDate)} '
          'belum tersedia.';
    }

    return 'Data High, Low, Close '
        '${_formatDate(calculationDate.subtract(const Duration(days: 1)))} '
        'belum tersedia.';
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initializeFromHistoricalData() async {
    await Future<void>.delayed(Duration.zero);

    fillFromPreviousDay();
  }

  // ============================================================
  // AUTO FILL H / L / C / OPEN
  // ============================================================

  bool fillFromPreviousDay() {
    final previousData = previousHangsengData;

    // ==========================================================
    // DATA TIDAK TERSEDIA
    // ==========================================================
    if (previousData == null) {
      _high = '';
      _low = '';
      _close = '';

      _isAutoFilled = false;

      _errorMessage =
          'Data High, Low, Close Hangseng sebelum '
          '${_formatDate(calculationDate)} belum tersedia.';

      _clearCalculationResult(notify: false);

      notifyListeners();

      return false;
    }

    // ==========================================================
    // BANK HOLIDAY
    // ==========================================================
    if (previousData.isBankHoliday) {
      _high = '';
      _low = '';
      _close = '';

      _isAutoFilled = false;

      _errorMessage =
          'Data Hangseng ${_formatDate(previousData.date)} '
          'tidak tersedia karena hari libur.';

      _clearCalculationResult(notify: false);

      notifyListeners();

      return false;
    }

    // ==========================================================
    // VALIDASI H/L/C
    // ==========================================================
    if (previousData.high <= 0 ||
        previousData.low <= 0 ||
        previousData.close <= 0) {
      _high = '';
      _low = '';
      _close = '';

      _isAutoFilled = false;

      _errorMessage =
          'Data High, Low, Close Hangseng '
          '${_formatDate(previousData.date)} belum tersedia.';

      _clearCalculationResult(notify: false);

      notifyListeners();

      return false;
    }

    // ==========================================================
    // AUTO FILL H/L/C
    // ==========================================================
    _high = _numberToInput(previousData.high);
    _low = _numberToInput(previousData.low);
    _close = _numberToInput(previousData.close);

    _isAutoFilled = true;

    _errorMessage = null;

    _clearCalculationResult(notify: false);

    notifyListeners();

    return true;
  }
  // ============================================================
  // REFRESH H/L/C + OPEN
  // ============================================================

  bool refreshPreviousDayInput() {
    return fillFromPreviousDay();
  }

  // ============================================================
  // INPUT HANDLER
  // ============================================================

  void setHigh(String value) {
    _high = value;

    _isAutoFilled = false;

    _errorMessage = null;

    _clearCalculationResult(notify: false);

    notifyListeners();
  }

  void setLow(String value) {
    _low = value;

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

  /// Open juga bisa diedit manual oleh user.
  ///
  /// Setelah user mengubah Open:
  /// - nilai Open akan menggunakan input manual tersebut
  /// - signal akan membandingkan PP dengan Open manual
  /// - hasil kalkulasi sebelumnya dihapus
  void setOpen(String value) {
    _open = value;

    // User sudah mengubah Open secara manual.
    _isOpenAutoFilled = false;

    _errorMessage = null;

    _clearCalculationResult(notify: false);

    notifyListeners();
  }

  // ============================================================
  // INPUT STATE
  // ============================================================

  bool get hasInput {
    return _high.trim().isNotEmpty ||
        _low.trim().isNotEmpty ||
        _close.trim().isNotEmpty ||
        _open.trim().isNotEmpty;
  }

  bool get canCalculate {
    final highValue = _parseNumber(_high);
    final lowValue = _parseNumber(_low);
    final closeValue = _parseNumber(_close);

    if (highValue == null || lowValue == null || closeValue == null) {
      return false;
    }

    if (highValue <= 0 || lowValue <= 0 || closeValue <= 0) {
      return false;
    }

    if (lowValue > highValue) {
      return false;
    }

    return true;
  }

  // ============================================================
  // CALCULATE PIVOT
  // ============================================================

  bool calculatePivot() {
    final highValue = _parseNumber(_high);
    final lowValue = _parseNumber(_low);
    final closeValue = _parseNumber(_close);

    // ----------------------------------------------------------
    // VALIDASI FORMAT
    // ----------------------------------------------------------

    if (highValue == null || lowValue == null || closeValue == null) {
      _errorMessage =
          'Harap masukkan High, Low, dan Close '
          'dengan format angka yang valid.';

      notifyListeners();

      return false;
    }

    // ----------------------------------------------------------
    // VALIDASI NILAI
    // ----------------------------------------------------------

    if (highValue <= 0 || lowValue <= 0 || closeValue <= 0) {
      _errorMessage = 'Nilai High, Low, dan Close harus lebih dari 0.';

      notifyListeners();

      return false;
    }

    // ----------------------------------------------------------
    // VALIDASI HIGH / LOW
    // ----------------------------------------------------------

    if (lowValue > highValue) {
      _errorMessage = 'Nilai Low tidak boleh lebih besar dari High.';

      notifyListeners();

      return false;
    }

    // ----------------------------------------------------------
    // PIVOT POINT
    // ----------------------------------------------------------

    final ppValue = (highValue + lowValue + closeValue) / 3;

    final diff = highValue - lowValue;

    _pp = ppValue;

    // ----------------------------------------------------------
    // RESISTANCE
    // ----------------------------------------------------------

    _r1 = (2 * ppValue) - lowValue;
    _r2 = ppValue + diff;
    _r3 = ppValue + (diff * 2);
    _r4 = ppValue + (diff * 3);

    // ----------------------------------------------------------
    // SUPPORT
    // ----------------------------------------------------------

    _s1 = (2 * ppValue) - highValue;
    _s2 = ppValue - diff;
    _s3 = ppValue - (diff * 2);
    _s4 = ppValue - (diff * 3);

    // ----------------------------------------------------------
    // STATUS
    // ----------------------------------------------------------

    _isCalculated = true;

    _errorMessage = null;

    notifyListeners();

    return true;
  }

  // ============================================================
  // SIGNAL
  // ============================================================

  PivotSignal get signal {
    debugPrint('========== SIGNAL DEBUG ==========');
    debugPrint('PP: $_pp');
    debugPrint('Open String: "$_open"');
    debugPrint('Open Value: $openValue');
    debugPrint('Reference Open: $referenceOpen');
    debugPrint('Reference Date: $referenceDate');
    debugPrint('Calculation Date: $calculationDate');
    debugPrint('==================================');
    // Belum hitung Pivot
    if (!_isCalculated || _pp == null) {
      return PivotSignal.unavailable;
    }

    // Ambil Open yang sedang ada di input
    // Bisa berasal dari auto-fill maupun input manual.
    final open = _parseNumber(_open);

    // Open kosong / tidak valid
    if (open == null || open <= 0) {
      return PivotSignal.unavailable;
    }

    // PP > Open = BUY
    if (_pp! > open) {
      return PivotSignal.buy;
    }

    // PP < Open = SELL
    if (_pp! < open) {
      return PivotSignal.sell;
    }

    // PP = Open = NEUTRAL
    return PivotSignal.neutral;
  }
  // ============================================================
  // SIGNAL LABEL
  // ============================================================

  String get signalLabel {
    switch (signal) {
      case PivotSignal.buy:
        return 'BUY';

      case PivotSignal.sell:
        return 'SELL';

      case PivotSignal.neutral:
        return 'BUY/SELL';

      case PivotSignal.unavailable:
        return 'BELUM TERSEDIA';
    }
  }

  // ============================================================
  // SIGNAL DESCRIPTION
  // ============================================================

  String get signalDescription {
    final open = _parseNumber(_open);

    if (_pp == null) {
      return 'Hitung Pivot Point terlebih dahulu.';
    }

    if (open == null || open <= 0) {
      return 'Data Open ${_formatDate(calculationDate)} '
          'belum tersedia.';
    }

    switch (signal) {
      case PivotSignal.buy:
        return 'PP lebih tinggi dari harga Open.';

      case PivotSignal.sell:
        return 'PP lebih rendah dari harga Open.';

      case PivotSignal.neutral:
        return 'PP sama dengan harga Open.';

      case PivotSignal.unavailable:
        return 'Data Open belum tersedia.';
    }
  }

  // ============================================================
  // SIGNAL COMPARISON
  // ============================================================

  String get signalComparison {
    if (!_isCalculated || _pp == null) {
      return '-';
    }

    final open = _parseNumber(_open);

    if (open == null || open <= 0) {
      return 'Open belum tersedia';
    }

    final ppText = formatValue(_pp!);
    final openText = formatValue(open);

    if (_pp! > open) {
      return 'PP $ppText > Open $openText';
    }

    if (_pp! < open) {
      return 'PP $ppText < Open $openText';
    }

    return 'PP $ppText = Open $openText';
  }
  // ============================================================
  // RESET
  // ============================================================

  void reset() {
    _high = '';
    _low = '';
    _close = '';
    _open = '';

    _pp = null;

    _r1 = null;
    _r2 = null;
    _r3 = null;
    _r4 = null;

    _s1 = null;
    _s2 = null;
    _s3 = null;
    _s4 = null;

    _isCalculated = false;

    _isAutoFilled = false;
    _isOpenAutoFilled = false;

    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // CLEAR CALCULATION RESULT
  // ============================================================

  void _clearCalculationResult({bool notify = true}) {
    _pp = null;

    _r1 = null;
    _r2 = null;
    _r3 = null;
    _r4 = null;

    _s1 = null;
    _s2 = null;
    _s3 = null;
    _s4 = null;

    _isCalculated = false;

    if (notify) {
      notifyListeners();
    }
  }

  // ============================================================
  // HISTORICAL DATA LISTENER
  // ============================================================

  void _onHistoricalDataChanged() {
    final previousData = previousHangsengData;
    final reference = referenceData;

    // ==========================================================
    // DATA HISTORICAL BELUM ADA
    // ==========================================================

    if (previousData == null) {
      // Hanya hapus H/L/C kalau memang masih auto-fill.
      if (_isAutoFilled) {
        _high = '';
        _low = '';
        _close = '';

        _isAutoFilled = false;

        _clearCalculationResult(notify: false);
      }

      // Open tetap mengikuti kondisi:
      // - Kalau masih auto-fill → update dari Newsmaker
      // - Kalau sudah manual → jangan ditimpa
      if (_isOpenAutoFilled) {
        if (reference != null && reference.open > 0) {
          _open = _numberToInput(reference.open);
        } else {
          _open = '';
          _isOpenAutoFilled = false;
        }
      }

      if (reference == null) {
        _errorMessage =
            'Data Open ${_formatDate(calculationDate)} dan '
            'data High, Low, Close '
            '${_formatDate(calculationDate.subtract(const Duration(days: 1)))} '
            'belum tersedia.';
      } else {
        _errorMessage =
            'Data High, Low, Close '
            '${_formatDate(calculationDate.subtract(const Duration(days: 1)))} '
            'belum tersedia.';
      }

      notifyListeners();

      return;
    }

    // ==========================================================
    // DATA BANK HOLIDAY
    // ==========================================================

    if (previousData.isBankHoliday) {
      if (_isAutoFilled) {
        _high = '';
        _low = '';
        _close = '';

        _isAutoFilled = false;

        _clearCalculationResult(notify: false);
      }

      _errorMessage =
          'Data Hangseng ${_formatDate(previousData.date)} '
          'tidak tersedia karena hari libur.';

      notifyListeners();

      return;
    }

    // ==========================================================
    // DATA VALID
    // ==========================================================

    if (previousData.high > 0 &&
        previousData.low > 0 &&
        previousData.close > 0) {
      // Hanya update H/L/C kalau masih auto-fill.
      if (_isAutoFilled || (_high.isEmpty && _low.isEmpty && _close.isEmpty)) {
        _high = _numberToInput(previousData.high);
        _low = _numberToInput(previousData.low);
        _close = _numberToInput(previousData.close);

        _isAutoFilled = true;

        _clearCalculationResult(notify: false);
      }
    }

    // ==========================================================
    // UPDATE OPEN OTOMATIS
    // ==========================================================

    // Kalau Open masih auto-filled,
    // boleh diperbarui dari Newsmaker.
    //
    // Kalau user sudah mengedit Open manual,
    // _isAutoFilled akan false sehingga tidak ditimpa.
    if (_isAutoFilled) {
      if (reference != null && reference.open > 0) {
        _open = _numberToInput(reference.open);
      } else {
        _open = '';
      }
    }

    // ==========================================================
    // ERROR OPEN
    // ==========================================================

    if (reference == null) {
      _errorMessage =
          'Data Open ${_formatDate(calculationDate)} '
          'belum tersedia.';
    } else {
      _errorMessage = null;
    }

    notifyListeners();
  }

  // ============================================================
  // NUMBER PARSER
  // ============================================================

  double? _parseNumber(String value) {
    var cleaned = value.trim();

    if (cleaned.isEmpty) {
      return null;
    }

    // Contoh:
    // 3500
    // 3500.50
    // 3500,50
    // 3.500,50

    if (cleaned.contains('.') && cleaned.contains(',')) {
      cleaned = cleaned.replaceAll('.', '');
      cleaned = cleaned.replaceAll(',', '.');
    } else if (cleaned.contains(',')) {
      cleaned = cleaned.replaceAll(',', '.');
    }

    return double.tryParse(cleaned);
  }

  // ============================================================
  // NUMBER TO INPUT
  // ============================================================

  String _numberToInput(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  // ============================================================
  // FORMAT VALUE
  // ============================================================

  String formatValue(double? value) {
    if (value == null) {
      return '-';
    }

    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  // ============================================================
  // FORMAT INPUT VALUE
  // ============================================================

  String formatInputValue(double? value) {
    if (value == null) {
      return '-';
    }

    return _numberToInput(value);
  }

  // ============================================================
  // MIDPOINT
  // ============================================================

  double midpoint(double a, double b) {
    return (a + b) / 2;
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // ============================================================
  // BUILD PDF
  // ============================================================

  Future<Uint8List> buildPdf() async {
    if (!_isCalculated) {
      throw StateError('Hasil Pivot Point belum dihitung.');
    }

    final pdf = pw.Document();

    final reference = referenceData;
    final previous = previousHangsengData;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'HASIL KALKULASI PIVOT POINT HANGSENG',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 12),

                // ==================================================
                // TANGGAL DATA H/L/C
                // ==================================================
                if (previous != null)
                  pw.Text(
                    'Tanggal H/L/C : '
                    '${previous.dateFormatted}',
                  ),

                pw.Text(
                  'High : '
                  '${formatValue(_parseNumber(_high))}',
                ),

                pw.Text(
                  'Low : '
                  '${formatValue(_parseNumber(_low))}',
                ),

                pw.Text(
                  'Close : '
                  '${formatValue(_parseNumber(_close))}',
                ),

                pw.SizedBox(height: 10),

                // ==================================================
                // DATA OPEN
                // ==================================================
                pw.Text(
                  'Tanggal Signal : '
                  '${reference != null ? reference.dateFormatted : _formatDate(calculationDate)}',
                ),

                pw.Text(
                  'Open : '
                  '${formatValue(openValue)}',
                ),

                if (reference != null)
                  pw.Text(
                    'Open Newsmaker : '
                    '${reference.openFormatted}',
                  ),

                pw.Text(
                  'Signal : $signalLabel',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),

                pw.SizedBox(height: 12),

                // ==================================================
                // PIVOT TABLE
                // ==================================================
                pw.Table.fromTextArray(
                  headers: ['Tingkat', 'Nilai'],
                  data: [
                    ['Resistance 4 (R4)', formatValue(_r4)],

                    if (_r4 != null && _r3 != null)
                      ['Midpoint R4-R3', formatValue(midpoint(_r4!, _r3!))],

                    ['Resistance 3 (R3)', formatValue(_r3)],

                    if (_r3 != null && _r2 != null)
                      ['Midpoint R3-R2', formatValue(midpoint(_r3!, _r2!))],

                    ['Resistance 2 (R2)', formatValue(_r2)],

                    if (_r2 != null && _r1 != null)
                      ['Midpoint R2-R1', formatValue(midpoint(_r2!, _r1!))],

                    ['Resistance 1 (R1)', formatValue(_r1)],

                    if (_r1 != null && _pp != null)
                      ['Midpoint R1-PP', formatValue(midpoint(_r1!, _pp!))],

                    ['Pivot Point (PP)', formatValue(_pp)],

                    if (_pp != null && _s1 != null)
                      ['Midpoint PP-S1', formatValue(midpoint(_pp!, _s1!))],

                    ['Support 1 (S1)', formatValue(_s1)],

                    if (_s1 != null && _s2 != null)
                      ['Midpoint S1-S2', formatValue(midpoint(_s1!, _s2!))],

                    ['Support 2 (S2)', formatValue(_s2)],

                    if (_s2 != null && _s3 != null)
                      ['Midpoint S2-S3', formatValue(midpoint(_s2!, _s3!))],

                    ['Support 3 (S3)', formatValue(_s3)],

                    if (_s3 != null && _s4 != null)
                      ['Midpoint S3-S4', formatValue(midpoint(_s3!, _s4!))],

                    ['Support 4 (S4)', formatValue(_s4)],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    historicalDataViewModel.removeListener(_onHistoricalDataChanged);

    super.dispose();
  }
}
