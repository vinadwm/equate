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

    // ==========================================================
    // HARGA BELI DALAM RUPIAH PER GRAM
    // ==========================================================

    final double hargaBeliPerGram = (hargaBeliValue * kursValue) / _toz;

    // ==========================================================
    // HARGA JUAL DALAM RUPIAH PER GRAM
    // ==========================================================

    final double hargaJualPerGram = (hargaJualValue * kursValue) / _toz;

    // ==========================================================
    // SELISIH HARGA
    // ==========================================================

    final double selisihHarga = hargaJualPerGram - hargaBeliPerGram;

    // ==========================================================
    // BERAT EMAS YANG DIDAPAT DARI MODAL
    // ==========================================================

    final double beratEmas = modalValue / hargaBeliPerGram;

    // ==========================================================
    // HASIL AKHIR
    // ==========================================================

    final double hasil = selisihHarga * beratEmas;

    _hasilAkhir = hasil;
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
