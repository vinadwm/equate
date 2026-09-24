import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../model/historical_data_model.dart';
import 'historical_data_viewmodel.dart';
import '../model/pivot_signal.dart';

// Enum PivotSignal hanya satu sumber di model/pivot_signal.dart.
export '../model/pivot_signal.dart';

class PivotGoldViewModel extends ChangeNotifier {
  final HistoricalDataViewModel historicalDataViewModel;

  PivotGoldViewModel({required this.historicalDataViewModel}) {
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

  // Nilai numerik
  double? get highValue => _parseNumber(_high);
  double? get lowValue => _parseNumber(_low);
  double? get closeValue => _parseNumber(_close);
  double? get openValue => _parseNumber(_open);

  // ============================================================
  // JENIS PERHITUNGAN PIVOT
  // ============================================================

  String _type = 'Standard';

  String get type => _type;

  void setType(String value) {
    if (_type == value) return;

    _type = value;
    notifyListeners();
  }

  // ============================================================
  // MODE OTOMATIS / MANUAL
  // ============================================================
  //
  // Mode otomatis:
  // - High  = hari perdagangan terakhir
  // - Low   = hari perdagangan terakhir
  // - Close = hari perdagangan terakhir
  // - Open  = hari ini
  //
  // Semua field tetap dapat diedit manual.

  bool _autoMode = true;

  bool get autoMode => _autoMode;

  void setAutoMode(bool value) {
    if (_autoMode == value) {
      return;
    }

    _autoMode = value;

    if (_autoMode) {
      // Saat kembali ke otomatis, isi ulang H/L/C + Open.
      fillFromHistoricalData();
    } else {
      // Mode manual.
      _isAutoFilled = false;
      _isOpenAutoFilled = false;
      _errorMessage = null;

      _clearCalculationResult(notify: false);

      notifyListeners();
    }
  }

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
  // STATUS AUTO FILL
  // ============================================================

  // Untuk High / Low / Close
  bool _isAutoFilled = false;

  bool get isAutoFilled => _isAutoFilled;

  // Untuk Open
  bool _isOpenAutoFilled = false;

  bool get isOpenAutoFilled => _isOpenAutoFilled;

  // ============================================================
  // ERROR / INFO
  // ============================================================

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  // ============================================================
  // TANGGAL PERHITUNGAN
  // ============================================================

  /// Selalu menggunakan tanggal hari ini.
  DateTime get calculationDate {
    final now = DateTime.now();

    return DateTime(now.year, now.month, now.day);
  }

  /// H-1 secara kalender.
  ///
  /// Jika H-1 tidak memiliki data, historical ViewModel
  /// akan mencari data perdagangan terakhir yang tersedia.
  DateTime get previousDate {
    final d = calculationDate;

    return DateTime(d.year, d.month, d.day - 1);
  }

  // ============================================================
  // DATA GOLD HARI INI
  // UNTUK OPEN DAN SIGNAL
  // ============================================================

  /// Data Gold tepat pada hari ini.
  ///
  /// Tidak menggunakan fallback.
  /// Karena Open harus berasal dari tanggal hari ini.
  HistoricalDataModel? get referenceData {
    final data = historicalDataViewModel.getDataForMarket(
      'LGD Daily',
      date: calculationDate,
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

  /// Harga Open Gold hari ini.
  double? get referenceOpen {
    return referenceData?.open;
  }

  DateTime? get referenceDate {
    return referenceData?.date;
  }

  // ============================================================
  // DATA GOLD HARI PERDAGANGAN TERAKHIR
  // UNTUK HIGH / LOW / CLOSE
  // ============================================================

  HistoricalDataModel? get previousGoldData {
    return historicalDataViewModel.getLatestAvailableData(
      'LGD Daily',
      previousDate,
    );
  }

  DateTime? get previousDataDate {
    return previousGoldData?.date;
  }

  DateTime get previousDataDisplayDate {
    return previousGoldData?.date ?? previousDate;
  }

  /// True jika data H/L/C bukan berasal dari H-1 langsung.
  ///
  /// Contoh:
  /// Hari ini Senin 15 September.
  /// H-1 = Minggu 14 September.
  /// Maka sistem mencari Jumat 12 September.
  bool get isPreviousDataFallback {
    final data = previousGoldData;

    if (data == null) {
      return false;
    }

    return !_isSameCalendarDate(data.date, previousDate);
  }

  // ============================================================
  // STATUS DATA
  // ============================================================

  bool get isOpenDataAvailable {
    return referenceData != null;
  }

  bool get isPreviousDataAvailable {
    final data = previousGoldData;

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

  bool get isHistoricalDataComplete {
    return isOpenDataAvailable && isPreviousDataAvailable;
  }

  String get dataStatusMessage {
    final openAvailable = isOpenDataAvailable;
    final previousAvailable = isPreviousDataAvailable;

    if (openAvailable && previousAvailable) {
      return 'Data historical tersedia.';
    }

    if (!openAvailable && !previousAvailable) {
      return 'Data Open ${_formatDate(calculationDate)} dan '
          'data High, Low, Close belum tersedia.';
    }

    if (!openAvailable) {
      return 'Data Open ${_formatDate(calculationDate)} '
          'belum tersedia.';
    }

    return 'Data High, Low, Close belum tersedia.';
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
  // AUTO FILL SEMUA DATA
  // ============================================================

  bool fillFromHistoricalData() {
    final previousData = previousGoldData;

    bool hlcSuccess = false;

    // ----------------------------------------------------------
    // HIGH / LOW / CLOSE
    // ----------------------------------------------------------

    if (previousData == null) {
      _high = '';
      _low = '';
      _close = '';

      _isAutoFilled = false;

      _errorMessage =
          'Data High, Low, Close sebelum '
          '${_formatDate(calculationDate)} '
          'belum tersedia.';
    } else if (previousData.isBankHoliday) {
      _high = '';
      _low = '';
      _close = '';

      _isAutoFilled = false;

      _errorMessage =
          'Data Gold ${_formatDate(previousData.date)} '
          'tidak tersedia karena hari libur.';
    } else if (previousData.high <= 0 ||
        previousData.low <= 0 ||
        previousData.close <= 0) {
      _high = '';
      _low = '';
      _close = '';

      _isAutoFilled = false;

      _errorMessage =
          'Data High, Low, Close '
          '${_formatDate(previousData.date)} '
          'belum tersedia.';
    } else {
      _high = _numberToInput(previousData.high);
      _low = _numberToInput(previousData.low);
      _close = _numberToInput(previousData.close);

      _isAutoFilled = true;

      hlcSuccess = true;
    }

    // ----------------------------------------------------------
    // OPEN
    // ----------------------------------------------------------

    final openSuccess = _fillOpenFromToday(notify: false);

    // ----------------------------------------------------------
    // ERROR MESSAGE
    // ----------------------------------------------------------

    if (hlcSuccess && !openSuccess) {
      _errorMessage =
          'Data Open ${_formatDate(calculationDate)} '
          'belum tersedia.';
    } else if (hlcSuccess && openSuccess) {
      _errorMessage = null;
    }

    // ----------------------------------------------------------
    // RESET HASIL
    // ----------------------------------------------------------

    _clearCalculationResult(notify: false);

    notifyListeners();

    return hlcSuccess;
  }

  // ============================================================
  // AUTO FILL OPEN HARI INI
  // ============================================================

  bool _fillOpenFromToday({bool notify = true}) {
    final data = referenceData;

    if (data == null) {
      _open = '';
      _isOpenAutoFilled = false;

      if (notify) {
        notifyListeners();
      }

      return false;
    }

    _open = _numberToInput(data.open);
    _isOpenAutoFilled = true;

    if (notify) {
      notifyListeners();
    }

    return true;
  }

  /// Public method jika ingin refresh Open saja.
  bool refreshOpenFromToday() {
    if (!_autoMode) {
      return false;
    }

    final success = _fillOpenFromToday(notify: false);

    if (success) {
      _errorMessage = null;
    } else {
      _errorMessage =
          'Data Open ${_formatDate(calculationDate)} '
          'belum tersedia.';
    }

    notifyListeners();

    return success;
  }

  // ============================================================
  // REFRESH H/L/C + OPEN
  // ============================================================

  bool refreshPreviousDayInput() {
    if (!_autoMode) {
      return false;
    }

    return fillFromHistoricalData();
  }

  // ============================================================
  // INPUT HANDLER
  // ============================================================

  void setHigh(String value) {
    _high = value;

    // H/L/C sudah tidak dianggap sebagai auto-filled
    // karena user mengubah inputnya.
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

  void setOpen(String value) {
    _open = value;

    // PENTING:
    // Mengedit Open tidak mempengaruhi status auto H/L/C.
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

  /// Untuk menghitung Pivot Point sebenarnya Open tidak wajib.
  ///
  /// Open hanya digunakan untuk menentukan signal.
  bool get canCalculate {
    final h = highValue;
    final l = lowValue;
    final c = closeValue;

    if (h == null || l == null || c == null) {
      return false;
    }

    if (h <= 0 || l <= 0 || c <= 0) {
      return false;
    }

    if (l > h) {
      return false;
    }

    return true;
  }

  // ============================================================
  // CALCULATE PIVOT
  // ============================================================

  bool calculatePivot() {
    final h = highValue;
    final l = lowValue;
    final c = closeValue;

    if (h == null || l == null || c == null) {
      _errorMessage =
          'Harap masukkan High, Low, dan Close '
          'dengan format angka yang valid.';

      notifyListeners();

      return false;
    }

    if (h <= 0 || l <= 0 || c <= 0) {
      _errorMessage =
          'Nilai High, Low, dan Close '
          'harus lebih dari 0.';

      notifyListeners();

      return false;
    }

    if (l > h) {
      _errorMessage = 'Nilai Low tidak boleh lebih besar dari High.';

      notifyListeners();

      return false;
    }

    // ----------------------------------------------------------
    // PIVOT POINT
    // ----------------------------------------------------------

    final ppValue = (h + l + c) / 3;
    final diff = h - l;

    _pp = ppValue;

    // Resistance
    _r1 = (2 * ppValue) - l;
    _r2 = ppValue + diff;
    _r3 = ppValue + (diff * 2);
    _r4 = ppValue + (diff * 3);

    // Support
    _s1 = (2 * ppValue) - h;
    _s2 = ppValue - diff;
    _s3 = ppValue - (diff * 2);
    _s4 = ppValue - (diff * 3);

    _isCalculated = true;

    // ----------------------------------------------------------
    // OPEN
    // ----------------------------------------------------------

    if (referenceData == null && openValue == null) {
      _errorMessage =
          'Data Open ${_formatDate(calculationDate)} '
          'belum tersedia, sinyal belum bisa ditentukan.';
    } else {
      _errorMessage = null;
    }

    notifyListeners();

    return true;
  }

  // ============================================================
  // SIGNAL
  // ============================================================

  PivotSignal get signal {
    if (!_isCalculated || _pp == null) {
      return PivotSignal.unavailable;
    }

    final open = openValue;

    if (open == null || open <= 0) {
      return PivotSignal.unavailable;
    }

    if (_pp! > open) {
      return PivotSignal.buy;
    }

    if (_pp! < open) {
      return PivotSignal.sell;
    }

    return PivotSignal.neutral;
  }

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

  String get signalDescription {
    final open = openValue;

    if (_pp == null) {
      return 'Hitung Pivot Point terlebih dahulu.';
    }

    if (open == null || open <= 0) {
      return 'Data Open ${_formatDate(calculationDate)} '
          'belum tersedia.';
    }

    if (_pp! > open) {
      return 'PP lebih tinggi dari harga Open.';
    }

    if (_pp! < open) {
      return 'PP lebih rendah dari harga Open.';
    }

    return 'PP sama dengan harga Open.';
  }

  String get signalComparison {
    if (!_isCalculated || _pp == null) {
      return '-';
    }

    final open = openValue;

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
  // REKOMENDASI
  // ============================================================

  String get recommendationTitle {
    switch (signal) {
      case PivotSignal.buy:
        return 'Pertimbangkan BUY';

      case PivotSignal.sell:
        return 'Pertimbangkan SELL';

      case PivotSignal.neutral:
        return 'Tunggu Konfirmasi';

      case PivotSignal.unavailable:
        return 'Lengkapi Data Terlebih Dahulu';
    }
  }

  List<String> get recommendationSteps {
    switch (signal) {
      case PivotSignal.buy:
        return [
          'Sinyal BUY muncul karena $signalComparison. '
              'Artinya harga Gold berpeluang bergerak naik.',
          'Target profit bertahap: R1 (${formatValue(_r1)}) lebih dulu, '
              'lanjut ke R2 (${formatValue(_r2)}) bila tenaga naik masih kuat.',
          'Batas risiko (stop loss): letakkan di bawah S1 '
              '(${formatValue(_s1)}). Jika harga menembus S1, '
              'anggap sinyal gagal dan keluar.',
          'Cari konfirmasi tambahan seperti pergerakan harga '
              'dan berita ekonomi sebelum membuka posisi.',
          'Gunakan porsi modal yang wajar, jangan memakai '
              'seluruh modal untuk satu posisi.',
        ];

      case PivotSignal.sell:
        return [
          'Sinyal SELL muncul karena $signalComparison. '
              'Artinya harga Gold berpeluang bergerak turun.',
          'Target profit bertahap: S1 (${formatValue(_s1)}) lebih dulu, '
              'lanjut ke S2 (${formatValue(_s2)}) bila tekanan turun masih kuat.',
          'Batas risiko (stop loss): letakkan di atas R1 '
              '(${formatValue(_r1)}). Jika harga menembus R1, '
              'anggap sinyal gagal dan keluar.',
          'Cari konfirmasi tambahan seperti pergerakan harga '
              'dan berita ekonomi sebelum membuka posisi.',
          'Gunakan porsi modal yang wajar, jangan memakai '
              'seluruh modal untuk satu posisi.',
        ];

      case PivotSignal.neutral:
        return [
          'PP sama dengan Open, arah harga belum jelas.',
          'Sebaiknya tunggu sampai harga bergerak menjauh '
              'dari PP (${formatValue(_pp)}) sebelum mengambil posisi.',
          'Perhatikan R1 (${formatValue(_r1)}) dan '
              'S1 (${formatValue(_s1)}) sebagai batas atas '
              'dan bawah untuk menentukan arah.',
          'Hindari memaksakan entry ketika sinyal belum jelas.',
        ];

      case PivotSignal.unavailable:
        return [
          _isCalculated
              ? 'Data Open ${_formatDate(calculationDate)} '
                    'belum tersedia, sehingga sinyal belum bisa ditentukan.'
              : 'Tekan HITUNG terlebih dahulu untuk melihat sinyal.',
          'Sambil menunggu, level PP, Resistance, dan Support '
              'tetap bisa dipakai sebagai acuan area harga.',
          'Buka kembali halaman ini setelah data Open tersedia.',
        ];
    }
  }

  String get recommendationDisclaimer =>
      'Catatan: Ini adalah alat bantu analisis teknikal sederhana, '
      'bukan jaminan hasil dan bukan nasihat keuangan. Selalu lakukan '
      'riset tambahan sebelum mengambil keputusan.';

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
  // CLEAR CALCULATION
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
    // Kalau manual, jangan mengubah input user.
    if (!_autoMode) {
      notifyListeners();
      return;
    }

    final previous = previousGoldData;
    final reference = referenceData;

    bool changed = false;

    // ----------------------------------------------------------
    // UPDATE H/L/C
    // ----------------------------------------------------------

    if (previous != null &&
        _isAutoFilled &&
        _high == _numberToInput(previous.high) &&
        _low == _numberToInput(previous.low) &&
        _close == _numberToInput(previous.close)) {
      // Tidak perlu update H/L/C.
    } else if (previous != null && _isAutoFilled) {
      // Data H/L/C terbaru berubah.
      _high = _numberToInput(previous.high);
      _low = _numberToInput(previous.low);
      _close = _numberToInput(previous.close);

      _isAutoFilled = true;

      changed = true;
    } else if (!_isAutoFilled) {
      // User pernah mengedit H/L/C.
      // Jangan timpa input manual.
    }

    // ----------------------------------------------------------
    // UPDATE OPEN
    // ----------------------------------------------------------

    if (reference != null && _isOpenAutoFilled) {
      final latestOpen = _numberToInput(reference.open);

      if (_open != latestOpen) {
        _open = latestOpen;
        changed = true;
      }
    } else if (reference == null && _isOpenAutoFilled) {
      // Data Open hari ini hilang/tidak tersedia.
      _open = '';
      _isOpenAutoFilled = false;

      changed = true;
    }

    // ----------------------------------------------------------
    // UPDATE ERROR
    // ----------------------------------------------------------

    if (reference == null) {
      _errorMessage =
          'Data Open ${_formatDate(calculationDate)} '
          'belum tersedia.';
    } else {
      _errorMessage = null;
    }

    // Hanya hapus hasil jika memang data berubah.
    if (changed) {
      _clearCalculationResult(notify: false);
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

  String _numberToInput(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  String formatValue(double? value) {
    if (value == null) {
      return '-';
    }

    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

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
  // DATE
  // ============================================================

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  bool _isSameCalendarDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
    final previous = previousGoldData;

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
                  'HASIL KALKULASI PIVOT POINT GOLD',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 12),

                if (previous != null)
                  pw.Text(
                    'Tanggal H/L/C : '
                    '${previous.dateFormatted}',
                  ),

                pw.Text('High : ${formatValue(highValue)}'),

                pw.Text('Low : ${formatValue(lowValue)}'),

                pw.Text('Close : ${formatValue(closeValue)}'),

                pw.SizedBox(height: 8),

                pw.Text(
                  'Tanggal Open : '
                  '${_formatDate(calculationDate)}',
                ),

                pw.Text('Open : ${formatValue(openValue)}'),

                pw.SizedBox(height: 10),

                if (reference != null) ...[
                  pw.Text(
                    'Tanggal Signal : '
                    '${reference.dateFormatted}',
                  ),
                  pw.Text(
                    'Open Newsmaker : '
                    '${reference.openFormatted}',
                  ),
                  pw.Text(
                    'Signal : $signalLabel',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 12),
                ] else ...[
                  pw.Text(
                    'Tanggal Signal : '
                    '${_formatDate(calculationDate)}',
                  ),
                  pw.Text(
                    'Open Newsmaker : '
                    'Data belum tersedia',
                  ),
                  pw.Text(
                    'Signal : BELUM TERSEDIA',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 12),
                ],

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
