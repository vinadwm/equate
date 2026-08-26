import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../model/user_model.dart';

class AuthViewModel {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // ============================================================
  // SIGN UP
  // ============================================================

  Future<UserModel> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    DateTime? birthDate,
  }) async {
    // 1. Membuat akun di Firebase Authentication
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('Gagal membuat akun');
    }

    // 2. Menyimpan nama lengkap ke Firebase Auth
    final fullName = '$firstName $lastName'.trim();

    await user.updateDisplayName(fullName);

    // 3. Membuat UserModel
    final userModel = UserModel(
      uid: user.uid,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim(),
      birthDate: birthDate,
      photo: user.photoURL,
    );

    // 4. Menyimpan data profil ke Firestore
    await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

    return userModel;
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ============================================================
  // GOOGLE LOGIN
  // ============================================================

  Future<UserCredential> loginWithGoogle() async {
    // Membuka Google Sign-In
    final googleUser = await GoogleSignIn.instance.authenticate();

    // Mengambil authentication dari akun Google
    final googleAuth = googleUser.authentication;

    // Membuat Firebase credential
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    // Login ke Firebase Authentication
    final result = await _auth.signInWithCredential(credential);

    final user = result.user;

    if (user == null) {
      throw Exception('Login Google gagal');
    }

    // Cek apakah data profil user sudah ada di Firestore
    final doc = await _firestore.collection('users').doc(user.uid).get();

    // Kalau belum ada, buat data user baru
    if (!doc.exists) {
      final fullName = user.displayName ?? 'Pengguna';

      // Memisahkan nama Google menjadi nama depan & belakang
      final nameParts = fullName.trim().split(' ');

      final firstName = nameParts.isNotEmpty ? nameParts.first : '';

      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      final userModel = UserModel(
        uid: user.uid,
        firstName: firstName,
        lastName: lastName,
        email: user.email ?? '',
        birthDate: null,
        photo: user.photoURL,
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
    }

    return result;
  }

  // ============================================================
  // GET USER PROFILE
  // ============================================================

  Future<UserModel?> getUserProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return UserModel.fromMap(doc.data()!, user.uid);
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Abaikan jika user bukan login menggunakan Google
    }

    await _auth.signOut();
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User belum login');
    }

    if (user.email == null) {
      throw Exception('Akun ini tidak menggunakan email/password');
    }

    // Re-authentication menggunakan password lama
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: oldPassword,
    );

    await user.reauthenticateWithCredential(credential);

    // Mengubah password di Firebase Authentication
    await user.updatePassword(newPassword);
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}
