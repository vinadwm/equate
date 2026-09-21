import 'package:equate/model/historical_data_model.dart';

enum PivotSignal { buy, sell, neutral, unavailable }

class PivotHangsengModel {
  // ============================================================
  // TANGGAL
  // ============================================================

  final DateTime calculationDate;
  final DateTime? previousDataDate;
  final DateTime? referenceDate;

  // ============================================================
  // INPUT H / L / C
  // ============================================================

  final double? high;
  final double? low;
  final double? close;

  // ============================================================
  // OPEN UNTUK SIGNAL
  // ============================================================

  final double? open;

  // ============================================================
  // HASIL PIVOT POINT
  // ============================================================

  final double? pp;

  final double? r1;
  final double? r2;
  final double? r3;
  final double? r4;

  final double? s1;
  final double? s2;
  final double? s3;
  final double? s4;

  // ============================================================
  // SIGNAL
  // ============================================================

  final PivotSignal signal;

  // ============================================================
  // DATA HISTORICAL
  // ============================================================

  final HistoricalDataModel? previousData;
  final HistoricalDataModel? referenceData;

  const PivotHangsengModel({
    required this.calculationDate,
    this.previousDataDate,
    this.referenceDate,
    this.high,
    this.low,
    this.close,
    this.open,
    this.pp,
    this.r1,
    this.r2,
    this.r3,
    this.r4,
    this.s1,
    this.s2,
    this.s3,
    this.s4,
    this.signal = PivotSignal.unavailable,
    this.previousData,
    this.referenceData,
  });

  // ============================================================
  // HASIL PERHITUNGAN
  // ============================================================

  bool get isCalculated => pp != null;

  // ============================================================
  // DATA INPUT LENGKAP
  // ============================================================

  bool get hasInput {
    return high != null && low != null && close != null;
  }

  // ============================================================
  // DATA HISTORICAL LENGKAP
  // ============================================================

  bool get isHistoricalDataComplete {
    return referenceData != null && previousData != null;
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  PivotHangsengModel copyWith({
    DateTime? calculationDate,
    DateTime? previousDataDate,
    DateTime? referenceDate,
    double? high,
    double? low,
    double? close,
    double? open,
    double? pp,
    double? r1,
    double? r2,
    double? r3,
    double? r4,
    double? s1,
    double? s2,
    double? s3,
    double? s4,
    PivotSignal? signal,
    HistoricalDataModel? previousData,
    HistoricalDataModel? referenceData,
  }) {
    return PivotHangsengModel(
      calculationDate: calculationDate ?? this.calculationDate,
      previousDataDate: previousDataDate ?? this.previousDataDate,
      referenceDate: referenceDate ?? this.referenceDate,
      high: high ?? this.high,
      low: low ?? this.low,
      close: close ?? this.close,
      open: open ?? this.open,
      pp: pp ?? this.pp,
      r1: r1 ?? this.r1,
      r2: r2 ?? this.r2,
      r3: r3 ?? this.r3,
      r4: r4 ?? this.r4,
      s1: s1 ?? this.s1,
      s2: s2 ?? this.s2,
      s3: s3 ?? this.s3,
      s4: s4 ?? this.s4,
      signal: signal ?? this.signal,
      previousData: previousData ?? this.previousData,
      referenceData: referenceData ?? this.referenceData,
    );
  }
}
