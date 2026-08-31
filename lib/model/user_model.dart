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

  // Getter nama lengkap
  String get fullName => '$firstName $lastName'.trim();

  // Getter alias agar photoUrl tetap kompatibel dengan EditProfileView
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
      photo: map['photo'] ?? map['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'birthDate': birthDate?.toIso8601String(),
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