import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class GoldPhysicalViewModel extends ChangeNotifier {
  // ============================================================
  // CONSTANT
  // ============================================================

  static const double _toz = 31.1;

  // ============================================================
  // INPUT
  // ============================================================

  String _modal = '';
  String _kurs = '';
  String _hargaBeli = '';
  String _hargaJual = '0,00';

  String get modal => _modal;
  String get kurs => _kurs;
  String get hargaBeli => _hargaBeli;
  String get hargaJual => _hargaJual;

  // ============================================================
  // HASIL
  // ============================================================

  double? _hasilAkhir;

  bool _isCalculated = false;

  double? get hasilAkhir => _hasilAkhir;
  bool get isCalculated => _isCalculated;

  // ============================================================
  // NILAI NUMERIK INPUT
  // ============================================================

  double? get modalValue => _parseNumber(_modal);

  double? get kursValue => _parseNumber(_kurs);

  /// Harga emas dunia saat beli dalam USD/toz
  double? get hargaBeliUsd => _parseNumber(_hargaBeli);

  /// Harga emas dunia saat jual dalam USD/toz
  double? get hargaJualUsd => _parseNumber(_hargaJual);

  // ============================================================
  // FUNGSI TRUNCATE
  // ============================================================

  /// Memotong angka tanpa pembulatan.
  ///
  /// Contoh:
  /// 2009789.0976 -> 2009789
  /// 0.473829 -> 0.47
  double _truncate(double value, int decimalPlaces) {
    final factor = pow(10, decimalPlaces).toDouble();
    return (value * factor).truncateToDouble() / factor;
  }

  // ============================================================
  // HASIL KONVERSI
  // ============================================================

  /// Harga beli dalam Rupiah/gram
  ///
  /// Contoh:
  /// 2.009.789,0976
  /// menjadi
  /// 2.009.789
  double? get hargaBeliPerGram {
    if (kursValue == null || hargaBeliUsd == null) {
      return null;
    }

    final hasil = (hargaBeliUsd! * kursValue!) / _toz;

    return _truncate(hasil, 0);
  }

  /// Harga jual dalam Rupiah/gram
  ///
  /// Contoh:
  /// 2.100.456,8921
  /// menjadi
  /// 2.100.456
  double? get hargaJualPerGram {
    if (kursValue == null || hargaJualUsd == null) {
      return null;
    }

    final hasil = (hargaJualUsd! * kursValue!) / _toz;

    return _truncate(hasil, 0);
  }

  /// Berat emas yang didapat berdasarkan modal
  ///
  /// Maksimal 2 angka di belakang koma,
  /// tanpa pembulatan.
  double? get beratEmas {
    if (modalValue == null || hargaBeliPerGram == null) {
      return null;
    }

    if (hargaBeliPerGram! <= 0) {
      return null;
    }

    final hasil = modalValue! / hargaBeliPerGram!;

    return _truncate(hasil, 2);
  }

  // ============================================================
  // INPUT STATE
  // ============================================================

  bool get hasInput {
    return _modal.isNotEmpty ||
        _kurs.isNotEmpty ||
        _hargaBeli.isNotEmpty ||
        _hargaJual.isNotEmpty;
  }

  bool get canCalculate {
    final modalValue = _parseNumber(_modal);
    final kursValue = _parseNumber(_kurs);
    final hargaBeliValue = _parseNumber(_hargaBeli);
    final hargaJualValue = _parseNumber(_hargaJual);

    return modalValue != null &&
        kursValue != null &&
        hargaBeliValue != null &&
        hargaJualValue != null &&
        modalValue > 0 &&
        kursValue > 0 &&
        hargaBeliValue > 0 &&
        hargaJualValue > 0;
  }

  // ============================================================
  // SET INPUT
  // ============================================================

  void setModal(String value) {
    _modal = value;
    _invalidateResult();
    notifyListeners();
  }

  void setKurs(String value) {
    _kurs = value;
    _invalidateResult();
    notifyListeners();
  }

  void setHargaBeli(String value) {
    _hargaBeli = value;
    _invalidateResult();
    notifyListeners();
  }

  void setHargaJual(String value) {
    _hargaJual = value;
    _invalidateResult();
    notifyListeners();
  }

  // ============================================================
  // PARSE NUMBER
  // ============================================================

  double? _parseNumber(String text) {
    if (text.trim().isEmpty) {
      return null;
    }

    final cleanText = text.replaceAll('.', '').replaceAll(',', '.');

    return double.tryParse(cleanText);
  }

  // ============================================================
  // CALCULATE
  // ============================================================

  bool calculateGoldPhysical() {
    if (!canCalculate) {
      return false;
    }

    final double modalValue = _parseNumber(_modal)!;
    final double kursValue = _parseNumber(_kurs)!;
    final double hargaBeliValue = _parseNumber(_hargaBeli)!;
    final double hargaJualValue = _parseNumber(_hargaJual)!;

    const double toz = 31.1;

    // ==========================================================
    // STEP 1
    // HARGA BELI = (HARGA BELI USD × KURS) / TOZ
    // AMBIL BILANGAN BULAT, TANPA PEMBULATAN
    // ==========================================================

    final double hasilStep1 = (hargaBeliValue * kursValue) / toz;

    final double step1 = hasilStep1.truncateToDouble();

    // ==========================================================
    // STEP 2
    // HARGA JUAL = (HARGA JUAL USD × KURS) / TOZ
    // AMBIL BILANGAN BULAT, TANPA PEMBULATAN
    // ==========================================================

    final double hasilStep2 = (hargaJualValue * kursValue) / toz;

    final double step2 = hasilStep2.truncateToDouble();

    // ==========================================================
    // STEP 3
    // SELISIH HARGA
    // STEP 2 - STEP 1
    // ==========================================================

    final double step3 = step2 - step1;

    // ==========================================================
    // STEP 4
    // BERAT EMAS
    // MODAL / STEP 1
    // MAKSIMAL 2 ANGKA DI BELAKANG KOMA
    // TANPA PEMBULATAN
    // ==========================================================

    final double hasilStep4 = modalValue / step1;

    final double step4 = (hasilStep4 * 100).truncateToDouble() / 100;

    // ==========================================================
    // STEP 5
    // PROFIT / RUGI
    // STEP 3 × STEP 4
    // AMBIL BILANGAN BULAT, TANPA PEMBULATAN
    // ==========================================================

    final double hasilStep5 = step3 * step4;

    final double step5 = hasilStep5.truncateToDouble();

    // ==========================================================
    // SIMPAN HASIL
    // ==========================================================

    _hasilAkhir = step5;
    _isCalculated = true;

    notifyListeners();

    return true;
  }

  // ============================================================
  // INVALIDATE RESULT
  // ============================================================

  void _invalidateResult() {
    _hasilAkhir = null;
    _isCalculated = false;
  }

  // ============================================================
  // STATUS
  // ============================================================

  bool get isProfit {
    if (_hasilAkhir == null) {
      return false;
    }

    return _hasilAkhir! >= 0;
  }

  bool get isLoss {
    if (_hasilAkhir == null) {
      return false;
    }

    return _hasilAkhir! < 0;
  }

  String get resultLabel {
    if (_hasilAkhir == null) {
      return '';
    }

    return _hasilAkhir! < 0 ? 'Rugi' : 'Untung';
  }

  // ============================================================
  // FORMAT CURRENCY
  // ============================================================

  String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );

    return formatter.format(amount.abs()).trim();
  }

  String get formattedHasilAkhir {
    if (_hasilAkhir == null || !_isCalculated) {
      return 'Rp 0';
    }

    final prefix = _hasilAkhir! < 0 ? '-Rp ' : 'Rp ';

    return '$prefix${formatCurrency(_hasilAkhir!)}';
  }

  // ============================================================
  // RESET
  // ============================================================

  void reset() {
    _modal = '';
    _kurs = '';
    _hargaBeli = '';
    _hargaJual = '0,00';

    _hasilAkhir = null;
    _isCalculated = false;

    notifyListeners();
  }
}
