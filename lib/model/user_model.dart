import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final DateTime? birthDate;
  final String? photo;

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.birthDate,
    this.photo,
  });

  String get fullName => '$firstName $lastName'.trim();
  String? get photoUrl => photo;

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    DateTime? parsedDate;
    if (map['birthDate'] != null) {
      if (map['birthDate'] is Timestamp) {
        parsedDate = (map['birthDate'] as Timestamp).toDate();
      } else {
        parsedDate = DateTime.tryParse(map['birthDate'].toString());
      }
    }

    return UserModel(
      uid: uid,
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      birthDate: parsedDate,
      // Membaca 'photo' atau fallback ke 'photoUrl' (jika ada data lama di Firestore)
      photo: (map['photo'] as String?) ?? (map['photoUrl'] as String?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'birthDate': birthDate != null
          ? Timestamp.fromDate(birthDate!)
          : null, // Lebih disarankan menggunakan Timestamp untuk Firestore
      'photo': photo,
    };
  }

  UserModel copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    String? email,
    DateTime? birthDate,
    String? photo,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      birthDate: birthDate ?? this.birthDate,
      photo: photo ?? this.photo,
    );
  }
}
