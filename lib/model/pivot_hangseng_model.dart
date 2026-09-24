import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equate/model/historical_data_model.dart';
import 'base_calculation_history.dart';
import 'pivot_signal.dart';

// PivotSignal kini tinggal di 'pivot_signal.dart'. Di-export ulang agar file
// lama yang mengambil PivotSignal dari model ini tetap jalan tanpa diubah.
export 'pivot_signal.dart';

class PivotHangsengModel extends CalculationHistory {
  final DateTime calculationDate;
  final DateTime? previousDataDate;
  final DateTime? referenceDate;

  final double? high;
  final double? low;
  final double? close;
  final double? open;

  final double? pp;
  final double? r1;
  final double? r2;
  final double? r3;
  final double? r4;
  final double? s1;
  final double? s2;
  final double? s3;
  final double? s4;

  final String? customDetails; // 👈 Properti internal untuk menyimpan custom string details
  final PivotSignal signal;
  final HistoricalDataModel? previousData;
  final HistoricalDataModel? referenceData;

  PivotHangsengModel({
    super.id = '',
    super.title = 'Pivot Point Hangseng',
    super.result = 0.0,
    DateTime? createdAt,
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
    String? details, // 👈 Parameter opsional agar kompatibel dengan UI
    this.signal = PivotSignal.unavailable,
    this.previousData,
    this.referenceData,
  })  : customDetails = details,
        super(
          category: 'Pivot Hangseng',
          createdAt: createdAt ?? DateTime.now(),
        );

  // 👈 Override getter details dari CalculationHistory
  @override
  Map<String, String> get details => {
        if (customDetails != null) 'Info': customDetails!,
        'Pivot Point (PP)': pp?.toStringAsFixed(2) ?? '-',
        'High': high?.toStringAsFixed(2) ?? '-',
        'Low': low?.toStringAsFixed(2) ?? '-',
        'Close': close?.toStringAsFixed(2) ?? '-',
        'Open': open?.toStringAsFixed(2) ?? '-',
        'Signal': signalLabel,
      };

  @override
  Map<String, dynamic> toMap(String currentUserId) {
    return {
      'userId': currentUserId,
      'title': title,
      'category': category,
      'result': result,
      'createdAt': Timestamp.fromDate(createdAt),
      'calculationDate': Timestamp.fromDate(calculationDate),
      'previousDataDate': previousDataDate != null
          ? Timestamp.fromDate(previousDataDate!)
          : null,
      'referenceDate': referenceDate != null
          ? Timestamp.fromDate(referenceDate!)
          : null,
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'pp': pp,
      'r1': r1,
      'r2': r2,
      'r3': r3,
      'r4': r4,
      's1': s1,
      's2': s2,
      's3': s3,
      's4': s4,
      'details': customDetails,
      'signal': signal.name,
    };
  }

  factory PivotHangsengModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    double? parseNullableDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    PivotSignal parseSignal(String? sigStr) {
      return PivotSignal.values.firstWhere(
        (e) => e.name == sigStr,
        orElse: () => PivotSignal.unavailable,
      );
    }

    return PivotHangsengModel(
      id: doc.id,
      title: (data['title'] ?? 'Pivot Point Hangseng').toString(),
      result: parseNullableDouble(data['result']) ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      calculationDate:
          (data['calculationDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      previousDataDate: (data['previousDataDate'] as Timestamp?)?.toDate(),
      referenceDate: (data['referenceDate'] as Timestamp?)?.toDate(),
      open: parseNullableDouble(data['open']),
      high: parseNullableDouble(data['high']),
      low: parseNullableDouble(data['low']),
      close: parseNullableDouble(data['close']),
      pp: parseNullableDouble(data['pp']),
      r1: parseNullableDouble(data['r1']),
      r2: parseNullableDouble(data['r2']),
      r3: parseNullableDouble(data['r3']),
      r4: parseNullableDouble(data['r4']),
      s1: parseNullableDouble(data['s1']),
      s2: parseNullableDouble(data['s2']),
      s3: parseNullableDouble(data['s3']),
      s4: parseNullableDouble(data['s4']),
      details: data['details'] as String?,
      signal: parseSignal(data['signal']),
    );
  }

  String get signalLabel {
    switch (signal) {
      case PivotSignal.buy:
        return 'BUY';
      case PivotSignal.sell:
        return 'SELL';
      case PivotSignal.neutral:
        return 'NEUTRAL';
      case PivotSignal.unavailable:
        return 'BELUM TERSEDIA';
    }
  }

  String get signalDescription {
    switch (signal) {
      case PivotSignal.buy:
        return 'Harga Open berada di atas Pivot Point (PP).';
      case PivotSignal.sell:
        return 'Harga Open berada di bawah Pivot Point (PP).';
      case PivotSignal.neutral:
        return 'Harga Open sama dengan Pivot Point (PP).';
      case PivotSignal.unavailable:
        return 'Masukkan harga Open untuk menampilkan sinyal.';
    }
  }

  PivotHangsengModel copyWith({
    String? id,
    String? title,
    double? result,
    DateTime? createdAt,
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
    String? details,
    PivotSignal? signal,
    HistoricalDataModel? previousData,
    HistoricalDataModel? referenceData,
  }) {
    return PivotHangsengModel(
      id: id ?? this.id,
      title: title ?? this.title,
      result: result ?? this.result,
      createdAt: createdAt ?? this.createdAt,
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
      details: details ?? customDetails,
      signal: signal ?? this.signal,
      previousData: previousData ?? this.previousData,
      referenceData: referenceData ?? this.referenceData,
    );
  }
}