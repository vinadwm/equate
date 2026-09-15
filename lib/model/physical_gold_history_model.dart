import 'package:cloud_firestore/cloud_firestore.dart';

class PhysicalGoldHistoryModel {
  final String id;
  final String uid;

  // ============================================================
  // INPUT
  // ============================================================

  final double modal;
  final double kurs;
  final double hargaBeli;
  final double hargaJual;

  // ============================================================
  // HASIL PERHITUNGAN
  // ============================================================

  final double hasilAkhir;

  // ============================================================
  // WAKTU
  // ============================================================

  final DateTime createdAt;

  PhysicalGoldHistoryModel({
    required this.id,
    required this.uid,
    required this.modal,
    required this.kurs,
    required this.hargaBeli,
    required this.hargaJual,
    required this.hasilAkhir,
    required this.createdAt,
  });

  // ============================================================
  // FIRESTORE
  // ============================================================

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'modal': modal,
      'kurs': kurs,
      'hargaBeli': hargaBeli,
      'hargaJual': hargaJual,
      'hasilAkhir': hasilAkhir,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // ============================================================
  // FROM FIRESTORE
  // ============================================================

  factory PhysicalGoldHistoryModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final timestamp = data['createdAt'];

    return PhysicalGoldHistoryModel(
      id: id,
      uid: data['uid'] ?? '',
      modal: (data['modal'] ?? 0).toDouble(),
      kurs: (data['kurs'] ?? 0).toDouble(),
      hargaBeli: (data['hargaBeli'] ?? 0).toDouble(),
      hargaJual: (data['hargaJual'] ?? 0).toDouble(),
      hasilAkhir: (data['hasilAkhir'] ?? 0).toDouble(),
      createdAt: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
    );
  }
}
