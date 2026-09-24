import 'package:cloud_firestore/cloud_firestore.dart';

import 'base_calculation_history.dart';

class PhysicalGoldModel extends CalculationHistory {
  final double weightInGram;
  final int karat; // Contoh: 24, 22, 18, dll.
  final double buyPrice;
  final double currentPricePerGram;
  final double certificateFee; // Biaya cetak / sertifikat (opsional)

  PhysicalGoldModel({
    super.id = '',
    super.title = 'Kalkulasi Emas Fisik',
    required super.result,
    DateTime? createdAt,
    required this.weightInGram,
    required this.karat,
    required this.buyPrice,
    required this.currentPricePerGram,
    this.certificateFee = 0.0,
  }) : super(
          category: 'Emas Fisik',
          createdAt: createdAt ?? DateTime.now(),
        );

  // ============================================================
  // GETTER ALIAS UNTUK KOMPATIBILITAS UI
  // ============================================================
  double get currentPrice => currentPricePerGram;
  double get profitLoss => result;

  factory PhysicalGoldModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final input = data['inputData'] as Map<String, dynamic>? ?? {};

    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 24;
      return 24;
    }

    return PhysicalGoldModel(
      id: doc.id,
      title: (data['title'] ?? 'Kalkulasi Emas Fisik').toString(),
      result: parseDouble(data['result']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weightInGram: parseDouble(input['weightInGram']),
      karat: parseInt(input['karat']),
      buyPrice: parseDouble(input['buyPrice']),
      currentPricePerGram: parseDouble(input['currentPricePerGram']),
      certificateFee: parseDouble(input['certificateFee']),
    );
  }

  @override
  Map<String, dynamic> toMap(String userId) {
    return {
      'userId': userId,
      'title': title,
      'category': category,
      'result': result,
      'createdAt': FieldValue.serverTimestamp(),
      'inputData': {
        'weightInGram': weightInGram,
        'karat': karat,
        'buyPrice': buyPrice,
        'currentPricePerGram': currentPricePerGram,
        'certificateFee': certificateFee,
      },
    };
  }
}