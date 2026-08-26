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

  // Nama lengkap
  String get fullName {
    return '$firstName $lastName'.trim();
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      birthDate: map['birthDate'] != null
          ? DateTime.tryParse(map['birthDate'])
          : null,
      photo: map['photo'],
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
}
