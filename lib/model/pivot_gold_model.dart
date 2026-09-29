import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_calculation_history.dart';

class PivotGoldModel extends CalculationHistory {
  final String type; // e.g., 'Standard', 'Fibonacci', 'Camarilla'

  final double open;
  final double high;
  final double low;
  final double close;

  final String? customDetails;

  final double pp;
  final double r1;
  final double r2;
  final double r3;
  final double r4;
  final double s1;
  final double s2;
  final double s3;
  final double s4;

  final String recommendation;

  PivotGoldModel({
    super.id = '',
    super.title = 'Pivot Point Gold',
    required super.result,
    DateTime? createdAt,
    required this.type,

    required this.open,
    required this.high,
    required this.low,
    required this.close,

    String? details,

    required this.pp,
    required this.r1,
    required this.r2,
    required this.r3,
    required this.r4,
    required this.s1,
    required this.s2,
    required this.s3,
    required this.s4,

    required this.recommendation,
  }) : customDetails = details,
       super(category: 'Pivot Gold', createdAt: createdAt ?? DateTime.now());

  // ============================================================
  // DETAILS
  // ============================================================
  @override
  Map<String, String> get details => {
    if (customDetails != null && customDetails!.isNotEmpty)
      'Note': customDetails!,

    'Type': type,

    'Open': open.toStringAsFixed(2),
    'High': high.toStringAsFixed(2),
    'Low': low.toStringAsFixed(2),
    'Close': close.toStringAsFixed(2),

    'Pivot Point': pp.toStringAsFixed(2),

    'Recommendation': recommendation,

    'R1': r1.toStringAsFixed(2),
    'S1': s1.toStringAsFixed(2),
  };

  // ============================================================
  // FROM FIRESTORE
  // ============================================================
  factory PivotGoldModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final input = data['inputData'] as Map<String, dynamic>? ?? {};

    // Helper parser angka aman
    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return PivotGoldModel(
      id: doc.id,
      title: data['title'] ?? 'Pivot Point Gold',
      result: parseDouble(data['result']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),

      type: input['type'] ?? 'Standard',

      open: parseDouble(input['open']),
      high: parseDouble(input['high']),
      low: parseDouble(input['low']),
      close: parseDouble(input['close']),

      details: data['details'] as String?,

      pp: parseDouble(input['pp']),
      r1: parseDouble(input['r1']),
      r2: parseDouble(input['r2']),
      r3: parseDouble(input['r3']),
      r4: parseDouble(input['r4']),
      s1: parseDouble(input['s1']),
      s2: parseDouble(input['s2']),
      s3: parseDouble(input['s3']),
      s4: parseDouble(input['s4']),

      recommendation: input['recommendation'] ?? 'NETRAL',
    );
  }

  // ============================================================
  // TO MAP
  // ============================================================
  @override
  Map<String, dynamic> toMap(String userId) {
    return {
      'userId': userId,
      'title': title,
      'category': category,
      'result': result,
      'details': customDetails,
      'createdAt': Timestamp.fromDate(createdAt),

      'inputData': {
        'type': type,

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

        'recommendation': recommendation,
      },
    };
  }
}
