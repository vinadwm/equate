import 'package:cloud_firestore/cloud_firestore.dart';

import 'base_calculation_history.dart';

// Subclass fallback jika ada kategori baru di luar kategori di atas
class GenericHistoryModel extends CalculationHistory {
  final Map<String, dynamic> inputData;

  GenericHistoryModel({
    required super.id,
    required super.title,
    required super.category,
    required super.result,
    required super.createdAt,
    required this.inputData,
  });

  factory GenericHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final rawResult = data['result'];
    final double parsedResult = rawResult is num ? rawResult.toDouble() : 0.0;

    return GenericHistoryModel(
      id: doc.id,
      title: data['title'] ?? '',
      category: data['category'] ?? 'Umum',
      result: parsedResult,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      inputData: Map<String, dynamic>.from(data['inputData'] ?? {}),
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
      'inputData': inputData,
    };
  }
}