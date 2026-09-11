import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../model/pivot_gold_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/digital_gold_history_model.dart';

enum PositionType { buy, sell }

class GoldDigitalViewModel extends ChangeNotifier {
  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // PIVOT POINT - INPUT
  // ============================================================

  String _high = '';
  String _low = '';
  String _close = '';

  String get high => _high;
  String get low => _low;
  String get close => _close;

  void setHigh(String value) {
    _high = value;
    notifyListeners();
  }

  void setLow(String value) {
    _low = value;
    notifyListeners();
  }

  void setClose(String value) {
    _close = value;
    notifyListeners();
  }

  // ============================================================
  // PIVOT POINT - STATE
  // ============================================================

  bool _isCalculated = false;

  bool get isCalculated => _isCalculated;

  bool get hasInput => _high.isNotEmpty || _low.isNotEmpty || _close.isNotEmpty;

  // ============================================================
  // HASIL PIVOT POINT
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

  // ============================================================
  // MIDPOINT
  // ============================================================

  double midpoint(double a, double b) {
    return (a + b) / 2;
  }

  double? get midpointR4R3 =>
      _r4 != null && _r3 != null ? midpoint(_r4!, _r3!) : null;

  double? get midpointR3R2 =>
      _r3 != null && _r2 != null ? midpoint(_r3!, _r2!) : null;

  double? get midpointR2R1 =>
      _r2 != null && _r1 != null ? midpoint(_r2!, _r1!) : null;

  double? get midpointR1PP =>
      _r1 != null && _pp != null ? midpoint(_r1!, _pp!) : null;

  double? get midpointPPS1 =>
      _pp != null && _s1 != null ? midpoint(_pp!, _s1!) : null;

  double? get midpointS1S2 =>
      _s1 != null && _s2 != null ? midpoint(_s1!, _s2!) : null;

  double? get midpointS2S3 =>
      _s2 != null && _s3 != null ? midpoint(_s2!, _s3!) : null;

  double? get midpointS3S4 =>
      _s3 != null && _s4 != null ? midpoint(_s3!, _s4!) : null;

  // ============================================================
  // HISTORY - PIVOT POINT
  // ============================================================

  final List<PivotGoldModel> _history = [];

  List<PivotGoldModel> get history => List.unmodifiable(_history);

  // ============================================================
  // CALCULATE PIVOT POINT
  // ============================================================

  bool calculatePivot() {
    final double? high = double.tryParse(_high.replaceAll(',', '.'));

    final double? low = double.tryParse(_low.replaceAll(',', '.'));

    final double? close = double.tryParse(_close.replaceAll(',', '.'));

    if (high == null || low == null || close == null) {
      return false;
    }

    if (high <= 0 || low <= 0 || close <= 0) {
      return false;
    }

    if (high < low) {
      return false;
    }

    final double ppValue = (high + low + close) / 3;

    final double diff = high - low;

    _pp = ppValue;

    _r1 = (2 * ppValue) - low;
    _r2 = ppValue + diff;
    _r3 = ppValue + (diff * 2);
    _r4 = ppValue + (diff * 3);

    _s1 = (2 * ppValue) - high;
    _s2 = ppValue - diff;
    _s3 = ppValue - (diff * 2);
    _s4 = ppValue - (diff * 3);

    _isCalculated = true;

    _history.insert(
      0,
      PivotGoldModel(
        type: 'Pivot Point',
        createdAt: DateTime.now(),
        high: high,
        low: low,
        close: close,
        pp: _pp!,
        r1: _r1!,
        r2: _r2!,
        r3: _r3!,
        r4: _r4!,
        s1: _s1!,
        s2: _s2!,
        s3: _s3!,
        s4: _s4!,
      ),
    );

    notifyListeners();

    return true;
  }

  // ============================================================
  // EMAS DIGITAL - CONSTANT
  // ============================================================

  /// Fee untuk 1 lot
  static const double _feePerLot = 333000.0;

  /// Nilai 1 point untuk 1 lot
  static const double _multiplierPerPoint = 1000000.0;

  // ============================================================
  // EMAS DIGITAL - INPUT
  // ============================================================

  String _digitalLot = '0';

  String _digitalHargaOpen = '0,00';

  String _digitalHargaClose = '0,00';

  /// Buy/Sell hanya diperlukan pada Open Position.
  PositionType? _digitalOpenPosition;

  // ============================================================
  // EMAS DIGITAL - HASIL
  // ============================================================

  double? _digitalHasilNetto;

  double? _digitalSelisihPoint;

  double? _digitalGross;

  double? _digitalTotalFee;

  bool _digitalIsCalculated = false;

  // ============================================================
  // EMAS DIGITAL - GETTER
  // ============================================================

  String get digitalLot => _digitalLot;

  String get digitalHargaOpen => _digitalHargaOpen;

  String get digitalHargaClose => _digitalHargaClose;

  PositionType? get digitalOpenPosition => _digitalOpenPosition;

  double? get digitalHasilNetto => _digitalHasilNetto;

  double? get digitalSelisihPoint => _digitalSelisihPoint;

  double? get digitalGross => _digitalGross;

  double? get digitalTotalFee => _digitalTotalFee;

  bool get digitalIsCalculated => _digitalIsCalculated;

  // ============================================================
  // EMAS DIGITAL - PARSE NUMBER
  // ============================================================

  double _parseDigitalNumber(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  // ============================================================
  // EMAS DIGITAL - INPUT STATE
  // ============================================================

  /// Tombol HAPUS aktif apabila user sudah mulai
  /// mengisi salah satu data atau memilih posisi.
  bool get digitalHasInput {
    return _parseDigitalNumber(_digitalLot) > 0 ||
        _parseDigitalNumber(_digitalHargaOpen) > 0 ||
        _parseDigitalNumber(_digitalHargaClose) > 0 ||
        _digitalOpenPosition != null;
  }

  /// Tombol Buy/Sell pada Open Position.
  ///
  /// Awalnya disabled.
  /// Akan aktif setelah user mulai mengisi data.
  bool get digitalPositionButtonsEnabled {
    return digitalHasInput;
  }

  /// Tombol HITUNG hanya aktif apabila semua
  /// data yang diperlukan sudah lengkap.
  bool get digitalCanCalculate {
    final lot = _parseDigitalNumber(_digitalLot);

    final hargaOpen = _parseDigitalNumber(_digitalHargaOpen);

    final hargaClose = _parseDigitalNumber(_digitalHargaClose);

    return lot > 0 &&
        hargaOpen > 0 &&
        hargaClose > 0 &&
        _digitalOpenPosition != null;
  }

  // ============================================================
  // EMAS DIGITAL - SET INPUT
  // ============================================================

  void setDigitalLot(String value) {
    _digitalLot = value;

    _invalidateDigitalResult();

    notifyListeners();
  }

  void setDigitalHargaOpen(String value) {
    _digitalHargaOpen = value;

    _invalidateDigitalResult();

    notifyListeners();
  }

  void setDigitalHargaClose(String value) {
    _digitalHargaClose = value;

    _invalidateDigitalResult();

    notifyListeners();
  }

  // ============================================================
  // EMAS DIGITAL - SELECT OPEN POSITION
  // ============================================================

  void selectDigitalOpenPosition(PositionType type) {
    if (!digitalPositionButtonsEnabled) {
      return;
    }

    _digitalOpenPosition = type;

    _invalidateDigitalResult();

    notifyListeners();
  }

  // ============================================================
  // EMAS DIGITAL - INVALIDATE RESULT
  // ============================================================

  void _invalidateDigitalResult() {
    _digitalIsCalculated = false;

    _digitalHasilNetto = null;

    _digitalSelisihPoint = null;

    _digitalGross = null;

    _digitalTotalFee = null;
  }

  // ============================================================
  // EMAS DIGITAL - CALCULATE
  // ============================================================

  Future<bool> calculateGoldDigital() async {
    if (!digitalCanCalculate) {
      return false;
    }

    final double lot = _parseDigitalNumber(_digitalLot);

    final double hargaOpen = _parseDigitalNumber(_digitalHargaOpen);

    final double hargaClose = _parseDigitalNumber(_digitalHargaClose);

    // ==========================================================
    // TENTUKAN SELISIH BERDASARKAN OPEN POSITION
    // ==========================================================
    //
    // BUY
    // Close > Open = profit
    // Close < Open = loss
    //
    // SELL
    // Close < Open = profit
    // Close > Open = loss
    //
    // ==========================================================

    final double selisihPoint;

    if (_digitalOpenPosition == PositionType.buy) {
      selisihPoint = hargaClose - hargaOpen;
    } else {
      selisihPoint = hargaOpen - hargaClose;
    }

    // ==========================================================
    // GROSS
    // ==========================================================
    //
    // Selisih Point × Lot × 1.000.000
    //
    // ==========================================================

    final double gross = selisihPoint * lot * _multiplierPerPoint;

    // ==========================================================
    // FEE
    // ==========================================================
    //
    // Rp333.000 × Lot
    //
    // ==========================================================

    final double totalFee = lot * _feePerLot;

    // ==========================================================
    // HASIL NETTO
    // ==========================================================
    //
    // Gross - Fee
    //
    // ==========================================================

    final double hasilNetto = gross - totalFee;

    // ==========================================================
    // SIMPAN HASIL KE STATE
    // ==========================================================

    _digitalSelisihPoint = selisihPoint;

    _digitalGross = gross;

    _digitalTotalFee = totalFee;

    _digitalHasilNetto = hasilNetto;

    _digitalIsCalculated = true;

    notifyListeners();

    // ==========================================================
    // SIMPAN HISTORY KE FIRESTORE
    // ==========================================================

    try {
      await saveDigitalGoldHistory();
    } catch (e) {
      debugPrint('Gagal menyimpan history emas digital: $e');

      // Perhitungan tetap dianggap berhasil
      // meskipun penyimpanan history gagal.
    }

    return true;
  }

  // ============================================================
  // EMAS DIGITAL - SAVE HISTORY
  // ============================================================

  Future<bool> saveDigitalGoldHistory() async {
    final User? user = _auth.currentUser;

    // User harus login.
    if (user == null) {
      debugPrint('History tidak disimpan karena user belum login.');

      return false;
    }

    // Pastikan hasil perhitungan tersedia.
    if (!_digitalIsCalculated ||
        _digitalOpenPosition == null ||
        _digitalHasilNetto == null ||
        _digitalSelisihPoint == null ||
        _digitalGross == null ||
        _digitalTotalFee == null) {
      return false;
    }

    final double hargaOpen = _parseDigitalNumber(_digitalHargaOpen);

    final double hargaClose = _parseDigitalNumber(_digitalHargaClose);

    final int lot = int.tryParse(_digitalLot) ?? 0;

    if (lot <= 0 || hargaOpen <= 0 || hargaClose <= 0) {
      return false;
    }

    // ==========================================================
    // BUAT DOCUMENT ID
    // ==========================================================

    final DocumentReference historyRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('digital_gold_history')
        .doc();

    // ==========================================================
    // BUAT MODEL HISTORY
    // ==========================================================

    final DigitalGoldHistoryModel history = DigitalGoldHistoryModel(
      id: historyRef.id,
      uid: user.uid,
      lot: lot,
      position: _digitalOpenPosition == PositionType.buy ? 'buy' : 'sell',
      hargaOpen: hargaOpen,
      hargaClose: hargaClose,
      selisihPoint: _digitalSelisihPoint!,
      hasilKotor: _digitalGross!,
      fee: _digitalTotalFee!,
      hasilNetto: _digitalHasilNetto!,
      createdAt: DateTime.now(),
    );

    // ==========================================================
    // SIMPAN KE FIRESTORE
    // ==========================================================

    await historyRef.set(history.toFirestore());

    debugPrint(
      'History emas digital berhasil disimpan: '
      '${historyRef.id}',
    );

    return true;
  }

  // ============================================================
  // EMAS DIGITAL - GET HISTORY
  // ============================================================

  Future<List<DigitalGoldHistoryModel>> getDigitalGoldHistory() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return [];
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('digital_gold_history')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return DigitalGoldHistoryModel.fromFirestore(doc.id, doc.data());
      }).toList();
    } catch (e) {
      debugPrint('Gagal mengambil history emas digital: $e');

      return [];
    }
  }

  // ============================================================
  // EMAS DIGITAL - DELETE HISTORY
  // ============================================================

  Future<bool> deleteDigitalGoldHistory(String historyId) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('digital_gold_history')
          .doc(historyId)
          .delete();

      return true;
    } catch (e) {
      debugPrint('Gagal menghapus history emas digital: $e');

      return false;
    }
  }

  // ============================================================
  // EMAS DIGITAL - DELETE ALL HISTORY
  // ============================================================

  Future<bool> deleteAllDigitalGoldHistory() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('digital_gold_history')
          .get();

      if (snapshot.docs.isEmpty) {
        return true;
      }

      final WriteBatch batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      return true;
    } catch (e) {
      debugPrint('Gagal menghapus semua history emas digital: $e');

      return false;
    }
  }

  // ============================================================
  // EMAS DIGITAL - HASIL STATUS
  // ============================================================

  bool get digitalIsProfit {
    if (_digitalHasilNetto == null) {
      return false;
    }

    return _digitalHasilNetto! >= 0;
  }

  bool get digitalIsLoss {
    if (_digitalHasilNetto == null) {
      return false;
    }

    return _digitalHasilNetto! < 0;
  }

  String get digitalResultLabel {
    if (_digitalHasilNetto == null) {
      return '';
    }

    return _digitalHasilNetto! < 0 ? 'Rugi' : 'Untung';
  }

  // ============================================================
  // EMAS DIGITAL - FORMAT CURRENCY
  // ============================================================

  String formatDigitalCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );

    return formatter.format(amount.abs()).trim();
  }

  // ============================================================
  // EMAS DIGITAL - RESET
  // ============================================================

  void resetGoldDigital() {
    _digitalLot = '0';

    _digitalHargaOpen = '0,00';

    _digitalHargaClose = '0,00';

    _digitalOpenPosition = null;

    _digitalHasilNetto = null;

    _digitalSelisihPoint = null;

    _digitalGross = null;

    _digitalTotalFee = null;

    _digitalIsCalculated = false;

    notifyListeners();
  }

  // ============================================================
  // RESET PIVOT POINT
  // ============================================================

  void reset() {
    _high = '';
    _low = '';
    _close = '';

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

    notifyListeners();
  }

  // ============================================================
  // FORMAT PIVOT POINT
  // ============================================================

  String formatValue(double? value) {
    if (value == null) {
      return '-';
    }

    return value.toStringAsFixed(2).replaceAll('.', ',');
  }
}
