import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:equate/model/kurs_model.dart';
import 'package:equate/service/kurs_service.dart';

class KursViewModel extends ChangeNotifier {
  String base = 'USD';
  KursRange range = KursRange.day;

  KursSeries? series;
  bool isLoading = false;
  bool hasError = false;
  DateTime? lastUpdated;

  Timer? _timer;
  bool _disposed = false;
  int _requestId = 0;

  void start() {
    load();
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => load(silent: true),
    );
  }

  Future<void> load({bool silent = false}) async {
    final id = ++_requestId;

    if (!silent) {
      isLoading = true;
      hasError = false;
      _notify();
    }

    try {
      final result = await KursService.fetch(base, range);

      if (id != _requestId) return;

      series = result;
      lastUpdated = DateTime.now();
      hasError = false;
    } catch (e) {
      if (id != _requestId) return;
      debugPrint('KURS gagal: $e');
      hasError = series == null;
    }

    isLoading = false;
    _notify();
  }

  void selectBase(String value) {
    if (value == base) return;
    base = value;
    series = null;
    load();
  }

  void selectRange(KursRange value) {
    if (value == range) return;
    range = value;
    series = null;
    load();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
