import 'package:flutter/foundation.dart';
import '../model/calculation_history_model.dart';

class CalculatorViewModel extends ChangeNotifier {
  // ==========================
  // INPUT
  // ==========================

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

  // ==========================
  // STATE
  // ==========================

  bool _isCalculated = false;

  bool get isCalculated => _isCalculated;

  bool get hasInput => _high.isNotEmpty || _low.isNotEmpty || _close.isNotEmpty;

  // ==========================
  // HASIL PIVOT POINT
  // ==========================

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

  // ==========================
  // MIDPOINT
  // ==========================

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

  // ==========================
  // HISTORY
  // ==========================

  final List<CalculationHistoryModel> _history = [];

  List<CalculationHistoryModel> get history => List.unmodifiable(_history);

  // ==========================
  // CALCULATE
  // ==========================

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

    // Simpan ke history
    _history.insert(
      0,
      CalculationHistoryModel(
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

  // ==========================
  // RESET
  // ==========================

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

  // ==========================
  // FORMAT
  // ==========================

  String formatValue(double? value) {
    if (value == null) return '-';

    return value.toStringAsFixed(2).replaceAll('.', ',');
  }
}
