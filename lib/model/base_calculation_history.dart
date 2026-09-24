import 'package:cloud_firestore/cloud_firestore.dart';

abstract class CalculationHistory {
  final String id;
  final String title;
  final String category;
  final double result;
  final DateTime createdAt;

  CalculationHistory({
    this.id = '',
    required this.title,
    required this.category,
    required this.result,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap(String currentUserId);

  /// Default getter details (mengembalikan Map kosong jika subclass tidak mengoverridenya)
  Map<String, String> get details => {};
}