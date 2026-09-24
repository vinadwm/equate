import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equate/model/historical_data_model.dart';
import 'base_calculation_history.dart';

enum NestHangsengSignal { buy, sell, neutral, unavailable }

class NestHangsengModel extends CalculationHistory {
  // ============================================================
  // TANGGAL
  // ============================================================
  final DateTime calculationDate;
  final DateTime previousDate;

  // ============================================================
  // INPUT & PROPERTI HARGA
  // ============================================================
  final double? open;
  final double? close;
  final double? high;
  final double? low;

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

  // ============================================================
  // SIGNAL
  // ============================================================
  final NestHangsengSignal signal;

  NestHangsengModel({
    super.id = '',
    super.title = 'NEST Hangseng',
    super.result = 0.0,
    DateTime? createdAt,
    required this.calculationDate,
    required this.previousDate,
    this.open,
    this.close,
    this.high,
    this.low,
    this.todayData,
    this.previousData,
    this.isAutoFilled = false,
    this.isCalculated = false,
    this.errorMessage,
    this.signal = NestHangsengSignal.unavailable,
  }) : super(
          category: 'NEST Hangseng',
          createdAt: createdAt ?? DateTime.now(),
        );

  // ============================================================
  // GETTER DETAILS (Untuk BottomSheet/UI Detail Riwayat)
  // ============================================================
  @override
  Map<String, String> get details => {
        'Open': open?.toStringAsFixed(2) ?? '-',
        'Close': close?.toStringAsFixed(2) ?? '-',
        'High': high?.toStringAsFixed(2) ?? '-',
        'Low': low?.toStringAsFixed(2) ?? '-',
        'Signal': signalLabel,
      };

  // ============================================================
  // CONVERT TO FIRESTORE (toMap)
  // ============================================================
  @override
  Map<String, dynamic> toMap(String currentUserId) {
    return {
      'userId': currentUserId,
      'title': title,
      'category': category,
      'result': result,
      'createdAt': Timestamp.fromDate(createdAt),
      'calculationDate': Timestamp.fromDate(calculationDate),
      'previousDate': Timestamp.fromDate(previousDate),
      'open': open,
      'close': close,
      'high': high,
      'low': low,
      'signal': signal.name,
      'isCalculated': isCalculated,
      'isAutoFilled': isAutoFilled,
    };
  }

  // ============================================================
  // READ FROM FIRESTORE (fromFirestore)
  // ============================================================
  factory NestHangsengModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    double? parseNullableDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    NestHangsengSignal parseSignal(String? sigStr) {
      return NestHangsengSignal.values.firstWhere(
        (e) => e.name == sigStr,
        orElse: () => NestHangsengSignal.unavailable,
      );
    }

    return NestHangsengModel(
      id: doc.id,
      title: data['title'] ?? 'NEST Hangseng',
      result: parseNullableDouble(data['result']) ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      calculationDate:
          (data['calculationDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      previousDate:
          (data['previousDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      open: parseNullableDouble(data['open']),
      close: parseNullableDouble(data['close']),
      high: parseNullableDouble(data['high']),
      low: parseNullableDouble(data['low']),
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
      case NestHangsengSignal.buy:
        return 'BUY';
      case NestHangsengSignal.sell:
        return 'SELL';
      case NestHangsengSignal.neutral:
        return 'BUY/SELL';
      case NestHangsengSignal.unavailable:
        return 'BELUM TERSEDIA';
    }
  }

  String get signalDescription {
    switch (signal) {
      case NestHangsengSignal.buy:
        return 'Close lebih tinggi dari Open.';
      case NestHangsengSignal.sell:
        return 'Close lebih rendah dari Open.';
      case NestHangsengSignal.neutral:
        return 'Close sama dengan Open.';
      case NestHangsengSignal.unavailable:
        return 'Silakan masukkan Open dan Close terlebih dahulu.';
    }
  }

  // ============================================================
  // COPY WITH
  // ============================================================
  NestHangsengModel copyWith({
    String? id,
    String? title,
    double? result,
    DateTime? createdAt,
    DateTime? calculationDate,
    DateTime? previousDate,
    double? open,
    double? close,
    double? high,
    double? low,
    HistoricalDataModel? todayData,
    HistoricalDataModel? previousData,
    bool? isAutoFilled,
    bool? isCalculated,
    String? errorMessage,
    NestHangsengSignal? signal,
  }) {
    return NestHangsengModel(
      id: id ?? this.id,
      title: title ?? this.title,
      result: result ?? this.result,
      createdAt: createdAt ?? this.createdAt,
      calculationDate: calculationDate ?? this.calculationDate,
      previousDate: previousDate ?? this.previousDate,
      open: open ?? this.open,
      close: close ?? this.close,
      high: high ?? this.high,
      low: low ?? this.low,
      todayData: todayData ?? this.todayData,
      previousData: previousData ?? this.previousData,
      isAutoFilled: isAutoFilled ?? this.isAutoFilled,
      isCalculated: isCalculated ?? this.isCalculated,
      errorMessage: errorMessage ?? this.errorMessage,
      signal: signal ?? this.signal,
    );
  }
}