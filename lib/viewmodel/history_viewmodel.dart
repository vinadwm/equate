import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../model/base_calculation_history.dart';
import '../model/calculation_history_model.dart';
import '../model/digital_gold_model.dart';
import '../model/physical_gold_model.dart';
import '../model/pivot_gold_model.dart';
import '../model/nest_gold_model.dart';          // 👈 Import model Nest Gold
import '../model/pivot_hangseng_model.dart';      // 👈 Import model Pivot Hangseng
import '../model/nest_hangseng_model.dart';       // 👈 Import model Nest Hangseng

class HistoryViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _selectedCategory = 'Semua';
  String get selectedCategory => _selectedCategory;

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Stream Data Real-time
  Stream<List<CalculationHistory>> get historyStream {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('⚠️ historyStream: User belum login (currentUser null)');
      return Stream.value([]);
    }

    Query query = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('histories')
        .orderBy('createdAt', descending: true);

    if (_selectedCategory != 'Semua') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return query.snapshots().map((snapshot) {
      final list = <CalculationHistory>[];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final category = (data['category'] ?? '').toString().trim();

          switch (category) {
            // --- EMAS ---
            case 'Emas Digital':
              list.add(DigitalGoldModel.fromFirestore(doc) as CalculationHistory);
              break;

            case 'Emas Fisik':
              list.add(PhysicalGoldModel.fromFirestore(doc) as CalculationHistory);
              break;

            case 'Pivot Gold':
            case 'Pivot Point Gold':
            case 'Pivot Point (Gold)':
              list.add(PivotGoldModel.fromFirestore(doc) as CalculationHistory);
              break;

            case 'NEST Gold':
            case 'NEST (Gold)':
              list.add(NestGoldModel.fromFirestore(doc) as CalculationHistory);
              break;

            // --- HANGSENG ---
            case 'Pivot Hangseng':
            case 'Pivot Point Hangseng':
            case 'Pivot Point (Hangseng)':
              list.add(PivotHangsengModel.fromFirestore(doc) as CalculationHistory);
              break;

            case 'NEST Hangseng':
            case 'NEST (Hangseng)':
              list.add(NestHangsengModel.fromFirestore(doc) as CalculationHistory);
              break;

            // --- FALLBACK / UNKNOWN CATEGORY ---
            default:
              list.add(GenericHistoryModel.fromFirestore(doc) as CalculationHistory);
              break;
          }
        } catch (e) {
          debugPrint('❌ Gagal parsing dokumen ID [${doc.id}]: $e');
        }
      }

      return list;
    });
  }

  // Tambah Riwayat Baru
  Future<void> addHistory(CalculationHistory history) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ Gagal simpan riwayat: User belum terautentikasi (null).');
      throw Exception('User belum terautentikasi.');
    }

    try {
      debugPrint('🔄 Mencoba menyimpan riwayat ke Firestore untuk UID: ${user.uid}');
      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('histories')
          .add(history.toMap(user.uid));

      debugPrint('✅ Berhasil menyimpan riwayat dengan ID Dokumen: ${docRef.id}');
    } catch (e) {
      debugPrint('❌ FIRESTORE ERROR saat addHistory: $e');
      rethrow;
    }
  }

  // Hapus Satu Item
  Future<void> deleteHistory(String historyId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('histories')
          .doc(historyId)
          .delete();
      debugPrint('✅ Berhasil menghapus riwayat ID: $historyId');
    } catch (e) {
      debugPrint('❌ Gagal menghapus riwayat: $e');
      rethrow;
    }
  }

  // Hapus Semua Riwayat
  Future<void> clearAllHistory() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('histories')
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('✅ Berhasil menghapus semua riwayat.');
    } catch (e) {
      debugPrint('❌ Gagal menghapus semua riwayat: $e');
      rethrow;
    }
  }
}