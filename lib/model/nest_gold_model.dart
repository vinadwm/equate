import 'package:equate/model/historical_data_model.dart';

enum NestGoldSignal { buy, sell, neutral, unavailable }

class NestGoldModel {
  // ============================================================
  // TANGGAL
  // ============================================================

  final DateTime calculationDate;
  final DateTime previousDate;

  // ============================================================
  // INPUT
  // ============================================================

  final double? open;
  final double? close;

  // ============================================================
  // DATA HISTORICAL
  // ============================================================

  final HistoricalDataModel? todayData;
  final HistoricalDataModel? previousData;

  // ============================================================
  // STATUS
  // ============================================================

  final bool isAutoFilled;
  final bool isCalculated;

  // ============================================================
  // ERROR
  // ============================================================

  final String? errorMessage;

  // ============================================================
  // SIGNAL
  // ============================================================

  final NestGoldSignal signal;

  const NestGoldModel({
    required this.calculationDate,
    required this.previousDate,
    this.open,
    this.close,
    this.todayData,
    this.previousData,
    this.isAutoFilled = false,
    this.isCalculated = false,
    this.errorMessage,
    this.signal = NestGoldSignal.unavailable,
  });

  // ============================================================
  // INPUT TERSEDIA
  // ============================================================

  bool get hasInput {
    return open != null && close != null;
  }

  // ============================================================
  // DATA HISTORICAL LENGKAP
  // ============================================================

  bool get isHistoricalDataComplete {
    return todayData != null &&
        previousData != null &&
        todayData!.open > 0 &&
        previousData!.close > 0 &&
        !todayData!.isBankHoliday &&
        !previousData!.isBankHoliday;
  }

  // ============================================================
  // OPEN TERSEDIA
  // ============================================================

  bool get isOpenAvailable {
    return open != null && open! > 0;
  }

  // ============================================================
  // CLOSE TERSEDIA
  // ============================================================

  bool get isCloseAvailable {
    return close != null && close! > 0;
  }

  // ============================================================
  // BISA DIHITUNG
  // ============================================================

  bool get canCalculate {
    return isOpenAvailable && isCloseAvailable;
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
  // COPY WITH
  // ============================================================

  NestGoldModel copyWith({
    DateTime? calculationDate,
    DateTime? previousDate,
    double? open,
    double? close,
    HistoricalDataModel? todayData,
    HistoricalDataModel? previousData,
    bool? isAutoFilled,
    bool? isCalculated,
    String? errorMessage,
    NestGoldSignal? signal,
  }) {
    return NestGoldModel(
      calculationDate: calculationDate ?? this.calculationDate,
      previousDate: previousDate ?? this.previousDate,
      open: open ?? this.open,
      close: close ?? this.close,
      todayData: todayData ?? this.todayData,
      previousData: previousData ?? this.previousData,
      isAutoFilled: isAutoFilled ?? this.isAutoFilled,
      isCalculated: isCalculated ?? this.isCalculated,
      errorMessage: errorMessage ?? this.errorMessage,
      signal: signal ?? this.signal,
    );
  }
}
