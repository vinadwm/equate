import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equate/model/historical_data_model.dart';
import 'base_calculation_history.dart';

enum NestGoldSignal { buy, sell, neutral, unavailable }

class NestGoldModel extends CalculationHistory {
  // ============================================================
  // FIELD TAMBAHAN UNTUK USER & TANGGAL
  // ============================================================
  final String userId;
  final DateTime calculationDate;
  final DateTime previousDate;

  // ============================================================
  // INPUT & HASIL
  // ============================================================
  final double? open;
  final double? high; // Tambahan untuk UI Detail Sheet
  final double? low;  // Tambahan untuk UI Detail Sheet
  final double? close;

  // ============================================================
  // DATA HISTORICAL (OPTIONAL SAAT DI RIWAYAT)
  // ============================================================
  final HistoricalDataModel? todayData;
  final HistoricalDataModel? previousData;

  // ============================================================
  // STATUS & ERROR
  // ============================================================
  final bool isAutoFilled;
  final bool isCalculated;
  final String? errorMessage;
  final NestGoldSignal signal;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================
  NestGoldModel({
    super.id = '',
    this.userId = '',
    super.category = 'NEST Gold',
    super.createdAt,
    required this.calculationDate,
    required this.previousDate,
    this.open,
    this.high,
    this.low,
    this.close,
    this.todayData,
    this.previousData,
    this.isAutoFilled = false,
    this.isCalculated = false,
    this.errorMessage,
    this.signal = NestGoldSignal.unavailable,
  }) : super(
          title: 'NEST Gold',
          result: close ?? 0.0,
        );

  // ============================================================
  // IMPLEMENTASI GETTER DETAILS (UNTUK DETAIL BOTTOM SHEET)
  // ============================================================
  @override
  Map<String, String> get details => {
        'Open': open?.toStringAsFixed(2) ?? '-',
        'High': high?.toStringAsFixed(2) ?? '-',
        'Low': low?.toStringAsFixed(2) ?? '-',
        'Close': close?.toStringAsFixed(2) ?? '-',
        'Signal': signalLabel,
      };

  // ============================================================
  // CONVERT TO FIRESTORE (toMap)
  // ============================================================
  @override
  Map<String, dynamic> toMap(String currentUserId) {
    return {
      'userId': currentUserId,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'calculationDate': Timestamp.fromDate(calculationDate),
      'previousDate': Timestamp.fromDate(previousDate),
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'signal': signal.name,
      'isCalculated': isCalculated,
      'isAutoFilled': isAutoFilled,
    };
  }

  // ============================================================
  // READ FROM FIRESTORE (fromFirestore)
  // ============================================================
  factory NestGoldModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    double? parseNullableDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    NestGoldSignal parseSignal(String? sigStr) {
      return NestGoldSignal.values.firstWhere(
        (e) => e.name == sigStr,
        orElse: () => NestGoldSignal.unavailable,
      );
    }

    return NestGoldModel(
      id: doc.id,
      userId: (data['userId'] ?? '').toString(),
      category: (data['category'] ?? 'NEST Gold').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      calculationDate: (data['calculationDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      previousDate: (data['previousDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      open: parseNullableDouble(data['open']),
      high: parseNullableDouble(data['high']),
      low: parseNullableDouble(data['low']),
      close: parseNullableDouble(data['close']),
      signal: parseSignal(data['signal']),
      isCalculated: data['isCalculated'] as bool? ?? false,
      isAutoFilled: data['isAutoFilled'] as bool? ?? false,
    );
  }

  // ============================================================
  // HELPER GETTERS
  // ============================================================
  bool get hasInput => open != null && close != null;

  bool get isHistoricalDataComplete {
    return todayData != null &&
        previousData != null &&
        todayData!.open > 0 &&
        previousData!.close > 0 &&
        !todayData!.isBankHoliday &&
        !previousData!.isBankHoliday;
  }

  bool get isOpenAvailable => open != null && open! > 0;
  bool get isCloseAvailable => close != null && close! > 0;
  bool get canCalculate => isOpenAvailable && isCloseAvailable;

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
    String? id,
    String? userId,
    String? category,
    DateTime? createdAt,
    DateTime? calculationDate,
    DateTime? previousDate,
    double? open,
    double? high,
    double? low,
    double? close,
    HistoricalDataModel? todayData,
    HistoricalDataModel? previousData,
    bool? isAutoFilled,
    bool? isCalculated,
    String? errorMessage,
    NestGoldSignal? signal,
  }) {
    return NestGoldModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      calculationDate: calculationDate ?? this.calculationDate,
      previousDate: previousDate ?? this.previousDate,
      open: open ?? this.open,
      high: high ?? this.high,
      low: low ?? this.low,
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