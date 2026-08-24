class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photo;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photo,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photo: map['photo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'email': email, 'photo': photo};
  }
}
