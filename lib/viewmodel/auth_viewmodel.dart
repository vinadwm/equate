import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../model/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ============================================================
  // GOOGLE SIGN IN
  // ============================================================

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _isGoogleInitialized = false;

  // Web OAuth Client ID
  static const String _serverClientId =
      '798913006079-afsi20qicdtdhj1eio0vengcrenr7i10.apps.googleusercontent.com';

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser => _auth.currentUser;

  bool get isLoggedIn => _auth.currentUser != null;

  // ============================================================
  // CEK APAKAH USER MEMILIKI PASSWORD
  // ============================================================

  bool get hasPasswordProvider {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    return user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
  }

  // ============================================================
  // CEK APAKAH USER LOGIN GOOGLE
  // ============================================================

  bool get hasGoogleProvider {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    return user.providerData.any(
      (provider) => provider.providerId == 'google.com',
    );
  }

  // ============================================================
  // CEK APAKAH USER GOOGLE BELUM PUNYA PASSWORD
  // ============================================================

  bool get isGoogleOnlyUser {
    return hasGoogleProvider && !hasPasswordProvider;
  }

  // ============================================================
  // INITIALIZE GOOGLE SIGN IN
  // ============================================================

  Future<void> _initializeGoogleSignIn() async {
    if (_isGoogleInitialized) {
      return;
    }

    await _googleSignIn.initialize(serverClientId: _serverClientId);

    _isGoogleInitialized = true;
  }

  // ============================================================
  // SET LOADING
  // ============================================================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    _errorMessage = null;
    notifyListeners();
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
    if (password.isEmpty) {
      return 'Kata sandi wajib diisi.';
    }

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
  // CEK EMAIL TERDAFTAR DI FIRESTORE
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
  // SIGN UP EMAIL & PASSWORD
  // ============================================================

  Future<UserModel> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    DateTime? birthDate,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final updatedFirstName = firstName.trim();
      final updatedLastName = lastName.trim();
      final normalizedEmail = email.trim().toLowerCase();

      // --------------------------------------------------------
      // VALIDASI NAMA
      // --------------------------------------------------------

      if (updatedFirstName.isEmpty) {
        throw Exception('Nama depan wajib diisi.');
      }

      if (updatedLastName.isEmpty) {
        throw Exception('Nama belakang wajib diisi.');
      }

      // --------------------------------------------------------
      // VALIDASI EMAIL
      // --------------------------------------------------------

      final emailError = validateEmail(normalizedEmail);

      if (emailError != null) {
        throw Exception(emailError);
      }

      // --------------------------------------------------------
      // VALIDASI PASSWORD
      // --------------------------------------------------------

      final passwordError = validatePassword(password);

      if (passwordError != null) {
        throw Exception(passwordError);
      }

      // --------------------------------------------------------
      // BUAT AKUN FIREBASE AUTH
      // --------------------------------------------------------

      final credential = await _auth
          .createUserWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception(
                'Koneksi ke Firebase terlalu lama. '
                'Periksa koneksi internet.',
              );
            },
          );

      final user = credential.user;

      if (user == null) {
        throw Exception('Gagal membuat akun.');
      }

      // --------------------------------------------------------
      // UPDATE DISPLAY NAME
      // --------------------------------------------------------

      final displayName = '$updatedFirstName $updatedLastName'.trim();

      await user.updateDisplayName(displayName);

      // --------------------------------------------------------
      // BUAT USER MODEL
      // --------------------------------------------------------

      final userModel = UserModel(
        uid: user.uid,
        firstName: updatedFirstName,
        lastName: updatedLastName,
        email: normalizedEmail,
        birthDate: birthDate,
        photo: null,
      );

      // --------------------------------------------------------
      // SIMPAN USER KE FIRESTORE
      // --------------------------------------------------------

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toMap())
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception(
                'Penyimpanan data terlalu lama. '
                'Periksa koneksi internet dan Firestore Rules.',
              );
            },
          );

      // --------------------------------------------------------
      // LOGOUT SETELAH REGISTER
      // --------------------------------------------------------

      await _auth.signOut();

      return userModel;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e.code);

      throw Exception(_errorMessage);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');

      throw Exception(_errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // LOGIN EMAIL & PASSWORD
  // ============================================================

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final normalizedEmail = email.trim().toLowerCase();

      // --------------------------------------------------------
      // VALIDASI EMAIL
      // --------------------------------------------------------

      final emailError = validateEmail(normalizedEmail);

      if (emailError != null) {
        throw Exception(emailError);
      }

      // --------------------------------------------------------
      // VALIDASI PASSWORD
      // --------------------------------------------------------

      if (password.isEmpty) {
        throw Exception('Kata sandi wajib diisi.');
      }

      // --------------------------------------------------------
      // LOGIN FIREBASE AUTH
      // --------------------------------------------------------
      //
      // Tidak perlu cek Firestore terlebih dahulu.
      // Firebase Authentication yang menentukan apakah
      // email/password benar-benar terdaftar.
      //
      // --------------------------------------------------------

      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e.code);

      throw Exception(_errorMessage);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');

      throw Exception(_errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // GOOGLE LOGIN
  // ============================================================

  Future<UserCredential> loginWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // --------------------------------------------------------
      // INITIALIZE GOOGLE SIGN IN
      // --------------------------------------------------------

      await _initializeGoogleSignIn();

      // --------------------------------------------------------
      // PILIH AKUN GOOGLE
      // --------------------------------------------------------

      final googleUser = await _googleSignIn.authenticate();

      // --------------------------------------------------------
      // AMBIL GOOGLE AUTH
      // --------------------------------------------------------

      final googleAuth = googleUser.authentication;

      // --------------------------------------------------------
      // VALIDASI ID TOKEN
      // --------------------------------------------------------

      if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
        throw Exception(
          'Token Google tidak ditemukan. '
          'Silakan coba login kembali.',
        );
      }

      // --------------------------------------------------------
      // BUAT FIREBASE CREDENTIAL
      // --------------------------------------------------------

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // --------------------------------------------------------
      // LOGIN KE FIREBASE
      // --------------------------------------------------------

      final result = await _auth.signInWithCredential(credential);

      final user = result.user;

      if (user == null) {
        throw Exception('Login Google gagal.');
      }

      // --------------------------------------------------------
      // CEK DATA USER DI FIRESTORE
      // --------------------------------------------------------

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      // --------------------------------------------------------
      // JIKA USER BELUM ADA
      // --------------------------------------------------------

      if (!userDoc.exists) {
        String firstName = 'Pengguna';
        String lastName = '';

        final displayName = user.displayName?.trim() ?? '';

        if (displayName.isNotEmpty) {
          final parts = displayName.split(RegExp(r'\s+'));

          firstName = parts.first;

          if (parts.length > 1) {
            lastName = parts.sublist(1).join(' ');
          }
        }

        final normalizedEmail = user.email?.trim().toLowerCase() ?? '';

        final userModel = UserModel(
          uid: user.uid,
          firstName: firstName,
          lastName: lastName,
          email: normalizedEmail,
          birthDate: null,
          photo: user.photoURL,
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());
      }
      // --------------------------------------------------------
      // USER SUDAH ADA
      // --------------------------------------------------------
      //
      // Sinkronisasi foto Google hanya jika foto lokal
      // di Firestore masih kosong.
      //
      // --------------------------------------------------------
      else {
        final data = userDoc.data();

        final existingPhoto = data?['photo'];

        final googlePhoto = user.photoURL?.trim();

        if ((existingPhoto == null ||
                existingPhoto.toString().trim().isEmpty) &&
            googlePhoto != null &&
            googlePhoto.isNotEmpty) {
          await _firestore.collection('users').doc(user.uid).update({
            'photo': googlePhoto,
          });
        }
      }

      return result;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e.code);

      throw Exception(_errorMessage);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');

      throw Exception(_errorMessage);
    } finally {
      _setLoading(false);
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
  // GET USER PROFILE
  // ============================================================

  Future<UserModel?> getUserProfile() async {
    return getUserData();
  }

  // ============================================================
  // UPLOAD PROFILE IMAGE
  // ============================================================

  Future<String?> uploadProfileImage(File imageFile) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Pengguna tidak ditemukan atau belum login.');
    }

    try {
      final ref = _storage
          .ref()
          .child('profile_pictures')
          .child('${user.uid}.jpg');

      await ref.putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));

      final downloadUrl = await ref.getDownloadURL();

      await _firestore.collection('users').doc(user.uid).update({
        'photo': downloadUrl,
      });

      await user.updatePhotoURL(downloadUrl);

      return downloadUrl;
    } catch (e) {
      throw Exception(
        'Gagal mengunggah gambar profil: '
        '${e.toString()}',
      );
    }
  }

  // ============================================================
  // UPDATE PROFILE
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

      if (updatedLastName.isEmpty) {
        throw Exception('Nama belakang tidak boleh kosong.');
      }

      final updateData = <String, dynamic>{
        'firstName': updatedFirstName,
        'lastName': updatedLastName,
      };

      if (birthDate != null) {
        updateData['birthDate'] = birthDate.toIso8601String();
      }

      if (photo != null) {
        updateData['photo'] = photo;
      }

      await _firestore.collection('users').doc(user.uid).update(updateData);

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
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Tidak masalah jika user bukan login Google.
    }

    await _auth.signOut();
  }

  // ============================================================
  // CHANGE PASSWORD
  // UNTUK USER YANG SUDAH MEMILIKI PASSWORD
  // ============================================================

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User belum login.');
    }

    final email = user.email?.trim();

    if (email == null || email.isEmpty) {
      throw Exception('Email akun tidak ditemukan.');
    }

    // ----------------------------------------------------------
    // PASTIKAN MEMANG PUNYA PASSWORD
    // ----------------------------------------------------------

    if (!hasPasswordProvider) {
      throw Exception(
        'Akun ini belum memiliki kata sandi. '
        'Gunakan fitur buat kata sandi.',
      );
    }

    // ----------------------------------------------------------
    // VALIDASI PASSWORD BARU
    // ----------------------------------------------------------

    final passwordError = validatePassword(newPassword);

    if (passwordError != null) {
      throw Exception(passwordError);
    }

    // ----------------------------------------------------------
    // VALIDASI PASSWORD LAMA
    // ----------------------------------------------------------

    if (oldPassword.isEmpty) {
      throw Exception('Kata sandi saat ini wajib diisi.');
    }

    // ----------------------------------------------------------
    // REAUTHENTICATION
    // ----------------------------------------------------------

    final credential = EmailAuthProvider.credential(
      email: email,
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
  // BUAT PASSWORD UNTUK USER GOOGLE
  // ============================================================
  //
  // Google user:
  //
  //     google.com
  //
  // menjadi:
  //
  //     google.com
  //     password
  //
  // Tanpa membuat akun Firebase baru.
  //
  // ============================================================

  Future<void> createPasswordForGoogleUser({
    required String newPassword,
  }) async {
    final user = _auth.currentUser;

    // ----------------------------------------------------------
    // CEK USER
    // ----------------------------------------------------------

    if (user == null) {
      throw Exception('User belum login.');
    }

    // ----------------------------------------------------------
    // CEK EMAIL
    // ----------------------------------------------------------

    final email = user.email?.trim();

    if (email == null || email.isEmpty) {
      throw Exception('Email akun Google tidak ditemukan.');
    }

    // ----------------------------------------------------------
    // CEK USER GOOGLE
    // ----------------------------------------------------------

    if (!hasGoogleProvider) {
      throw Exception('Akun ini bukan akun Google.');
    }

    // ----------------------------------------------------------
    // CEK APAKAH SUDAH PUNYA PASSWORD
    // ----------------------------------------------------------

    if (hasPasswordProvider) {
      throw Exception(
        'Akun ini sudah memiliki kata sandi. '
        'Gunakan fitur ubah kata sandi.',
      );
    }

    // ----------------------------------------------------------
    // VALIDASI PASSWORD
    // ----------------------------------------------------------

    final passwordError = validatePassword(newPassword);

    if (passwordError != null) {
      throw Exception(passwordError);
    }

    try {
      // --------------------------------------------------------
      // BUAT EMAIL/PASSWORD CREDENTIAL
      // --------------------------------------------------------

      final credential = EmailAuthProvider.credential(
        email: email,
        password: newPassword,
      );

      // --------------------------------------------------------
      // LINK PASSWORD KE AKUN GOOGLE
      // --------------------------------------------------------
      //
      // PENTING:
      // linkWithCredential() tidak membuat akun baru.
      //
      // Provider Google dan password akan berada
      // pada Firebase User yang sama.
      //
      // --------------------------------------------------------

      await user.linkWithCredential(credential);

      // --------------------------------------------------------
      // REFRESH USER
      // --------------------------------------------------------

      await user.reload();

      final refreshedUser = _auth.currentUser;

      // --------------------------------------------------------
      // PASTIKAN PASSWORD SUDAH TERHUBUNG
      // --------------------------------------------------------

      final passwordLinked =
          refreshedUser?.providerData.any(
            (provider) => provider.providerId == 'password',
          ) ??
          false;

      if (!passwordLinked) {
        throw Exception('Kata sandi gagal ditambahkan ke akun.');
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
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
        return 'Email sudah terdaftar. '
            'Silakan gunakan email lain.';

      case 'invalid-email':
        return 'Format email tidak valid.';

      case 'weak-password':
        return 'Password terlalu lemah.';

      case 'user-not-found':
        return 'Email belum terdaftar. '
            'Silakan buat akun terlebih dahulu.';

      case 'wrong-password':
        return 'Password salah.';

      case 'invalid-credential':
        return 'Email atau password salah.';

      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';

      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';

      case 'too-many-requests':
        return 'Terlalu banyak percobaan. '
            'Silakan coba lagi nanti.';

      case 'account-exists-with-different-credential':
        return 'Email sudah terdaftar dengan '
            'metode login lain.';

      case 'popup-closed-by-user':
        return 'Login Google dibatalkan.';

      case 'provider-already-linked':
        return 'Akun ini sudah memiliki '
            'metode login tersebut.';

      case 'credential-already-in-use':
        return 'Email tersebut sudah digunakan '
            'oleh akun lain.';

      case 'requires-recent-login':
        return 'Sesi login sudah terlalu lama. '
            'Silakan login kembali.';

      case 'operation-not-allowed':
        return 'Metode login ini belum diaktifkan '
            'di Firebase Authentication.';

      case 'user-mismatch':
        return 'Credential tidak sesuai dengan '
            'akun yang sedang login.';

      default:
        return 'Terjadi kesalahan. '
            'Silakan coba lagi.';
    }
  }
}
