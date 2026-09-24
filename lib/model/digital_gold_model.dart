import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_calculation_history.dart';

class DigitalGoldModel extends CalculationHistory {
  final double weightInGram;
  final double buyPrice;
  final double currentPrice;
  final double profitLoss;

  DigitalGoldModel({
    super.id = '',
    super.title = 'Kalkulasi Emas Digital',
    required super.result,
    DateTime? createdAt,
    required this.weightInGram,
    required this.buyPrice,
    required this.currentPrice,
    required this.profitLoss,
  }) : super(
          category: 'Emas Digital',
          createdAt: createdAt ?? DateTime.now(),
        );

  factory DigitalGoldModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final input = data['inputData'] as Map<String, dynamic>? ?? {};

    // Helper parsing angka agar tidak crash jika tipe data int/double
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return DigitalGoldModel(
      id: doc.id,
      title: data['title'] ?? 'Kalkulasi Emas Digital',
      result: parseDouble(data['result']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weightInGram: parseDouble(input['weightInGram']),
      buyPrice: parseDouble(input['buyPrice']),
      currentPrice: parseDouble(input['currentPrice']),
      profitLoss: parseDouble(input['profitLoss']),
    );
  }

  @override
  Map<String, dynamic> toMap(String userId) {
    return {
      'userId': userId,
      'title': title,
      'category': category,
      'result': result,
      // ✅ Gunakan Timestamp dari waktu lokal agar langsung terbaca oleh query orderBy
      'createdAt': Timestamp.fromDate(createdAt),
      'inputData': {
        'weightInGram': weightInGram,
        'buyPrice': buyPrice,
        'currentPrice': currentPrice,
        'profitLoss': profitLoss,
      },
    };
  }
}