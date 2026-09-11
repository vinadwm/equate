import 'package:cloud_firestore/cloud_firestore.dart';

class DigitalGoldHistoryModel {
  final String id;
  final String uid;

  final int lot;
  final String position;

  final double hargaOpen;
  final double hargaClose;

  final double selisihPoint;
  final double hasilKotor;
  final double fee;
  final double hasilNetto;

  final DateTime createdAt;

  DigitalGoldHistoryModel({
    required this.id,
    required this.uid,
    required this.lot,
    required this.position,
    required this.hargaOpen,
    required this.hargaClose,
    required this.selisihPoint,
    required this.hasilKotor,
    required this.fee,
    required this.hasilNetto,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'lot': lot,
      'position': position,
      'hargaOpen': hargaOpen,
      'hargaClose': hargaClose,
      'selisihPoint': selisihPoint,
      'hasilKotor': hasilKotor,
      'fee': fee,
      'hasilNetto': hasilNetto,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory DigitalGoldHistoryModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final timestamp = data['createdAt'];

    return DigitalGoldHistoryModel(
      id: id,
      uid: data['uid'] ?? '',
      lot: (data['lot'] ?? 0).toInt(),
      position: data['position'] ?? '',
      hargaOpen: (data['hargaOpen'] ?? 0).toDouble(),
      hargaClose: (data['hargaClose'] ?? 0).toDouble(),
      selisihPoint: (data['selisihPoint'] ?? 0).toDouble(),
      hasilKotor: (data['hasilKotor'] ?? 0).toDouble(),
      fee: (data['fee'] ?? 0).toDouble(),
      hasilNetto: (data['hasilNetto'] ?? 0).toDouble(),
      createdAt: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
    );
  }
}
