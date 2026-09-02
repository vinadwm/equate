import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'package:equate/model/user_model.dart';

class ProfileViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();

  UserModel? _user;

  bool _isLoading = true;
  bool _isUploadingPhoto = false;
  bool _isSaving = false;

  String? _errorMessage;

  // ============================================================
  // CLOUDINARY
  // ============================================================

  // Ganti dengan Cloud Name Cloudinary kamu
  final String _cloudinaryCloudName = "khk6eg6e";

  // Ganti dengan Upload Preset Cloudinary kamu
  final String _cloudinaryUploadPreset = 'UploadImage';

  // ============================================================
  // GETTER
  // ============================================================

  UserModel? get user => _user;

  bool get isLoading => _isLoading;

  bool get isUploadingPhoto => _isUploadingPhoto;

  bool get isSaving => _isSaving;

  String? get errorMessage => _errorMessage;

  // ============================================================
  // USER DATA
  // ============================================================

  String get fullName {
    if (_user == null) {
      return 'Pengguna Equate';
    }

    final firstName = _user!.firstName.trim();
    final lastName = _user!.lastName.trim();

    final name = '$firstName $lastName'.trim();

    return name.isNotEmpty ? name : 'Pengguna Equate';
  }

  String get email {
    return _user?.email ?? '-';
  }

  String get photo {
    return _user?.photo?.trim() ?? '';
  }

  bool get hasPhoto {
    return photo.isNotEmpty;
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final firebaseUser = _auth.currentUser;

      if (firebaseUser == null) {
        _user = null;
        _errorMessage = 'User belum login.';
        return;
      }

      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!doc.exists || doc.data() == null) {
        _user = null;
        _errorMessage = 'Data profil tidak ditemukan.';
        return;
      }

      _user = UserModel.fromMap(doc.data()!, firebaseUser.uid);
    } catch (e) {
      debugPrint('Load profile error: $e');
      _errorMessage = 'Gagal mengambil data profil.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // PICK AND UPLOAD PHOTO
  // ============================================================

  Future<bool> pickAndUploadPhoto(ImageSource source) async {
    try {
      _errorMessage = null;

      final firebaseUser = _auth.currentUser;

      if (firebaseUser == null) {
        _errorMessage = 'User belum login.';
        notifyListeners();
        return false;
      }

      // ========================================================
      // PILIH FOTO
      // ========================================================

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      // User membatalkan pemilihan foto
      if (pickedFile == null) {
        return false;
      }

      _isUploadingPhoto = true;
      notifyListeners();

      final File imageFile = File(pickedFile.path);

      // ========================================================
      // UPLOAD KE CLOUDINARY
      // ========================================================

      final uploadUrl = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uploadUrl);

      request.fields['upload_preset'] = _cloudinaryUploadPreset;

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final response = await request.send();

      final responseData = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        debugPrint('Cloudinary error: $responseData');

        throw Exception('Gagal mengunggah foto ke Cloudinary.');
      }

      // ========================================================
      // AMBIL RESPONSE CLOUDINARY
      // ========================================================

      final jsonMap = jsonDecode(responseData);

      final String? downloadUrl = jsonMap['secure_url'];

      if (downloadUrl == null || downloadUrl.isEmpty) {
        throw Exception('URL foto dari Cloudinary tidak ditemukan.');
      }

      // ========================================================
      // SIMPAN URL KE FIRESTORE
      // ========================================================

      await _firestore.collection('users').doc(firebaseUser.uid).update({
        'photo': downloadUrl,
      });

      // ========================================================
      // UPDATE FOTO FIREBASE AUTH
      // ========================================================

      await firebaseUser.updatePhotoURL(downloadUrl);

      // ========================================================
      // UPDATE USER MODEL
      // ========================================================

      if (_user != null) {
        _user = UserModel(
          uid: _user!.uid,
          firstName: _user!.firstName,
          lastName: _user!.lastName,
          email: _user!.email,
          birthDate: _user!.birthDate,
          photo: downloadUrl,
        );
      }

      _errorMessage = null;

      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');

      _errorMessage = 'Gagal mengubah foto profil.';

      return false;
    } finally {
      _isUploadingPhoto = false;
      notifyListeners();
    }
  }

  // ============================================================
  // DELETE PHOTO
  // ============================================================

  Future<void> deletePhoto() async {
    try {
      final firebaseUser = _auth.currentUser;

      if (firebaseUser == null) {
        throw Exception('User belum login.');
      }

      _isUploadingPhoto = true;
      _errorMessage = null;

      notifyListeners();

      // ========================================================
      // HAPUS URL DARI FIRESTORE
      // ========================================================

      await _firestore.collection('users').doc(firebaseUser.uid).update({
        'photo': null,
      });

      // ========================================================
      // HAPUS FOTO DARI FIREBASE AUTH
      // ========================================================

      await firebaseUser.updatePhotoURL(null);

      // ========================================================
      // UPDATE USER MODEL
      // ========================================================

      if (_user != null) {
        _user = UserModel(
          uid: _user!.uid,
          firstName: _user!.firstName,
          lastName: _user!.lastName,
          email: _user!.email,
          birthDate: _user!.birthDate,
          photo: null,
        );
      }

      _errorMessage = null;
    } catch (e) {
      debugPrint('Delete photo error: $e');

      _errorMessage = 'Gagal menghapus foto profil.';
    } finally {
      _isUploadingPhoto = false;
      notifyListeners();
    }
  }

  // ============================================================
  // UPDATE PROFILE
  // ============================================================

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    DateTime? birthDate,
  }) async {
    try {
      final firebaseUser = _auth.currentUser;

      if (firebaseUser == null) {
        throw Exception('User belum login.');
      }

      if (firstName.trim().isEmpty) {
        throw Exception('Nama depan tidak boleh kosong.');
      }

      _isSaving = true;
      _errorMessage = null;

      notifyListeners();

      // ========================================================
      // UPDATE FIRESTORE
      // ========================================================

      final Map<String, dynamic> data = {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
      };

      if (birthDate != null) {
        data['birthDate'] = Timestamp.fromDate(birthDate);
      } else {
        data['birthDate'] = null;
      }

      await _firestore.collection('users').doc(firebaseUser.uid).update(data);

      // ========================================================
      // UPDATE DISPLAY NAME FIREBASE AUTH
      // ========================================================

      await firebaseUser.updateDisplayName(
        '${firstName.trim()} ${lastName.trim()}'.trim(),
      );

      // ========================================================
      // UPDATE USER MODEL
      // ========================================================

      if (_user != null) {
        _user = UserModel(
          uid: _user!.uid,
          firstName: firstName.trim(),
          lastName: lastName.trim(),
          email: _user!.email,
          birthDate: birthDate,
          photo: _user!.photo,
        );
      }

      _errorMessage = null;
    } catch (e) {
      debugPrint('Update profile error: $e');

      _errorMessage = e.toString().replaceFirst('Exception: ', '');

      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // ============================================================
  // REFRESH PROFILE
  // ============================================================

  Future<void> refreshProfile() async {
    await loadProfile();
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    try {
      await _auth.signOut();

      _user = null;
      _errorMessage = null;

      notifyListeners();
    } catch (e) {
      throw Exception('Gagal keluar dari akun.');
    }
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
