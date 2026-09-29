import 'package:cloud_firestore/cloud_firestore.dart';

import 'base_calculation_history.dart';

class PhysicalGoldModel extends CalculationHistory {
  // ============================================================
  // DATA EMAS
  // ============================================================

  final double weightInGram;

  // ============================================================
  // INPUT ASLI
  // ============================================================

  /// Modal dalam Rupiah
  final double modal;

  /// Kurs USD ke Rupiah
  final double kurs;

  /// Harga emas dunia saat beli (USD/toz)
  final double hargaBeliUsd;

  /// Harga emas dunia saat jual (USD/toz)
  final double hargaJualUsd;

  // ============================================================
  // HASIL KONVERSI
  // ============================================================

  /// Harga beli setelah dikonversi menjadi Rupiah/gram
  final double buyPrice;

  /// Harga jual setelah dikonversi menjadi Rupiah/gram
  final double currentPricePerGram;

  /// Biaya cetak / sertifikat (opsional)
  final double certificateFee;

  PhysicalGoldModel({
    super.id = '',
    super.title = 'Kalkulasi Emas Fisik',
    required super.result,
    DateTime? createdAt,
    required this.weightInGram,
    required this.modal,
    required this.kurs,
    required this.hargaBeliUsd,
    required this.hargaJualUsd,
    required this.buyPrice,
    required this.currentPricePerGram,
    this.certificateFee = 0.0,
  }) : super(category: 'Emas Fisik', createdAt: createdAt ?? DateTime.now());

  // ============================================================
  // GETTER ALIAS UNTUK KOMPATIBILITAS UI
  // ============================================================

  double get currentPrice => currentPricePerGram;

  double get profitLoss => result;

  // ============================================================
  // FROM FIRESTORE
  // ============================================================

  factory PhysicalGoldModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final input = data['inputData'] as Map<String, dynamic>? ?? {};

    double parseDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }

      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }

      return 0.0;
    }

    return PhysicalGoldModel(
      id: doc.id,

      title: (data['title'] ?? 'Kalkulasi Emas Fisik').toString(),

      result: parseDouble(data['result']),

      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),

      // ==========================================================
      // DATA EMAS
      // ==========================================================
      weightInGram: parseDouble(input['weightInGram']),

      // ==========================================================
      // INPUT ASLI
      // ==========================================================
      modal: parseDouble(input['modal']),

      kurs: parseDouble(input['kurs']),

      hargaBeliUsd: parseDouble(input['hargaBeliUsd']),

      hargaJualUsd: parseDouble(input['hargaJualUsd']),

      // ==========================================================
      // HASIL KONVERSI
      // ==========================================================
      buyPrice: parseDouble(input['buyPrice']),

      currentPricePerGram: parseDouble(input['currentPricePerGram']),

      certificateFee: parseDouble(input['certificateFee']),
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
      'createdAt': FieldValue.serverTimestamp(),

      'inputData': {
        // ========================================================
        // DATA EMAS
        // ========================================================

        'weightInGram': weightInGram,

        // ========================================================
        // INPUT ASLI
        // ========================================================
        'modal': modal,
        'kurs': kurs,
        'hargaBeliUsd': hargaBeliUsd,
        'hargaJualUsd': hargaJualUsd,

        // ========================================================
        // HASIL KONVERSI
        // ========================================================
        'buyPrice': buyPrice,
        'currentPricePerGram': currentPricePerGram,

        // ========================================================
        // BIAYA TAMBAHAN
        // ========================================================
        'certificateFee': certificateFee,
      },
    };
  }
}
