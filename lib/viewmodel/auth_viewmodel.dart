import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../model/user_model.dart';

class AuthViewModel {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? get currentUser => _auth.currentUser;

  // ============================================================
  // UPLOAD PROFILE IMAGE TO FIREBASE STORAGE (FITUR BARU)
  // ============================================================

  Future<String?> uploadProfileImage(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Pengguna tidak ditemukan atau belum login.');
    }

    try {
      // 1. Lokasi penyimpanan gambar: profile_pictures/{uid}.jpg
      final ref = _storage.ref().child('profile_pictures').child('${user.uid}.jpg');

      // 2. Unggah file gambar
      await ref.putFile(imageFile);

      // 3. Ambil Download URL publik dari Firebase Storage
      final String downloadUrl = await ref.getDownloadURL();

      // 4. Update URL gambar di Firestore & Firebase Auth secara langsung
      await _firestore.collection('users').doc(user.uid).update({
        'photo': downloadUrl,
      });
      await user.updatePhotoURL(downloadUrl);

      return downloadUrl;
    } catch (e) {
      throw Exception('Gagal mengunggah gambar profil: ${e.toString()}');
    }
  }

  // ============================================================
  // VALIDASI EMAIL
  // ============================================================

  String? validateEmail(String email) {
    final value = email.trim();

    if (value.isEmpty) {
      return 'Email wajib diisi.';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid.';
    }

    return null;
  }

  // ============================================================
  // VALIDASI PASSWORD
  // ============================================================

  String? validatePassword(String password) {
    if (password.length < 8) {
      return 'Kata sandi minimal 8 karakter.';
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Kata sandi harus memiliki minimal 1 huruf kapital.';
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Kata sandi harus memiliki minimal 1 angka.';
    }

    return null;
  }

  // ============================================================
  // CEK EMAIL TERDAFTAR
  // ============================================================

  Future<bool> isEmailRegistered(String email) async {
    final normalizedEmail = email.trim().toLowerCase();

    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // ============================================================
  // SIGN UP
  // ============================================================

  Future<UserModel> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      final emailError = validateEmail(normalizedEmail);
      if (emailError != null) {
        throw Exception(emailError);
      }

      final passwordError = validatePassword(password);
      if (passwordError != null) {
        throw Exception(passwordError);
      }

      final credential = await _auth
          .createUserWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception(
                'Koneksi ke Firebase terlalu lama. Periksa koneksi internet.',
              );
            },
          );

      final user = credential.user;

      if (user == null) {
        throw Exception('Gagal membuat akun.');
      }

      await user.updateDisplayName(
        '${firstName.trim()} ${lastName.trim()}'.trim(),
      );

      final userModel = UserModel(
        uid: user.uid,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: normalizedEmail,
        birthDate: null,
        photo: null,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toMap())
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception(
                'Penyimpanan data terlalu lama. Periksa koneksi internet dan Firestore Rules.',
              );
            },
          );

      await _auth.signOut();

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ============================================================
  // GET USER DATA
  // ============================================================

  Future<UserModel?> getUserData() async {
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
  // EDIT / UPDATE PROFILE
  // ============================================================

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    DateTime? birthDate,
    String? photo,
  }) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('Pengguna tidak ditemukan atau belum login.');
      }

      final updatedFirstName = firstName.trim();
      final updatedLastName = lastName.trim();

      if (updatedFirstName.isEmpty) {
        throw Exception('Nama depan tidak boleh kosong.');
      }

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'firstName': updatedFirstName,
        'lastName': updatedLastName,
        if (birthDate != null) 'birthDate': birthDate.toIso8601String(),
        if (photo != null) 'photo': photo,
      });

      // Update Firebase Auth Display Name & Photo URL (opsional agar sync)
      await user.updateDisplayName('$updatedFirstName $updatedLastName'.trim());
      if (photo != null) {
        await user.updatePhotoURL(photo);
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      final emailError = validateEmail(normalizedEmail);
      if (emailError != null) {
        throw Exception(emailError);
      }

      final passwordError = validatePassword(password);
      if (passwordError != null) {
        throw Exception(passwordError);
      }

      final registered = await isEmailRegistered(normalizedEmail);
      if (!registered) {
        throw Exception(
          'Email belum terdaftar. Silakan buat akun terlebih dahulu.',
        );
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ============================================================
  // GOOGLE LOGIN
  // ============================================================

  Future<UserCredential> loginWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn.instance.authenticate();

      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);

      final user = result.user;

      if (user == null) {
        throw Exception('Login Google gagal.');
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        String firstName = 'Pengguna';
        String lastName = '';

        if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
          final parts = user.displayName!.trim().split(' ');

          firstName = parts.first;

          if (parts.length > 1) {
            lastName = parts.sublist(1).join(' ');
          }
        }

        final userModel = UserModel(
          uid: user.uid,
          firstName: firstName,
          lastName: lastName,
          email: user.email ?? '',
          birthDate: null,
          photo: user.photoURL,
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('Login Google gagal: ${e.toString()}');
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await GoogleSignIn.instance.signOut();
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
      throw Exception('User belum login.');
    }

    if (user.email == null) {
      throw Exception('Akun ini tidak menggunakan email/password.');
    }

    final passwordError = validatePassword(newPassword);

    if (passwordError != null) {
      throw Exception(passwordError);
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: oldPassword,
    );

    try {
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    }
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================

  Future<void> resetPassword(String email) async {
    final emailError = validateEmail(email);

    if (emailError != null) {
      throw Exception(emailError);
    }

    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    }
  }

  // ============================================================
  // FIREBASE AUTH ERROR
  // ============================================================

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan gunakan email lain.';

      case 'invalid-email':
        return 'Format email tidak valid.';

      case 'weak-password':
        return 'Password terlalu lemah.';

      case 'user-not-found':
        return 'Email belum terdaftar. Silakan buat akun terlebih dahulu.';

      case 'wrong-password':
        return 'Password salah.';

      case 'invalid-credential':
        return 'Password salah.';

      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';

      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';

      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Silakan coba lagi nanti.';

      default:
        return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }
}