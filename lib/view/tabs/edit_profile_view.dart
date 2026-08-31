import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:equate/viewmodel/auth_viewmodel.dart';
import 'package:equate/viewmodel/theme_viewmodel.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final AuthViewModel _authViewModel = AuthViewModel();
  final ImagePicker _picker = ImagePicker();

  // Controller untuk Form Input
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  DateTime? _selectedDate;
  String? _profileImageUrl;
  File? _selectedImageFile; // Menampung gambar lokal yang baru dipilih

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Ambil data user lama & isi ke controller (Prefill Form)
  Future<void> _loadUserData() async {
    try {
      final user = await _authViewModel.getUserData();
      if (user != null && mounted) {
        setState(() {
          _firstNameController.text = user.firstName;
          _lastNameController.text = user.lastName;
          _emailController.text = user.email;
          _profileImageUrl = user.photoUrl; // Pastikan model User mendukung field photoUrl

          if (user.birthDate != null) {
            _selectedDate = user.birthDate;
            _dobController.text =
                "${user.birthDate!.day.toString().padLeft(2, '0')}/${user.birthDate!.month.toString().padLeft(2, '0')}/${user.birthDate!.year}";
          }
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Gagal memuat data: $e');
      }
    }
  }

  // Bottom Sheet untuk Memilih Sumber Gambar (Kamera / Galeri)
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih Sumber Foto Profil',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Color(0xFFFF9800)),
                title: Text('Galeri', style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFFFF9800)),
                title: Text('Kamera', style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Memilih Gambar & Mengunggah via AuthViewModel
  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 500,
        maxHeight: 500,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
          _isUploadingImage = true;
        });

        // Contoh pemanggilan upload di AuthViewModel (opsional jika langsung upload)
        // String? uploadedUrl = await _authViewModel.uploadProfileImage(_selectedImageFile!);

        if (mounted) {
          setState(() {
            // _profileImageUrl = uploadedUrl;
            _isUploadingImage = false;
          });
          _showSnackBar('Foto profil berhasil dipilih!', isError: false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        _showSnackBar('Gagal mengambil gambar: $e');
      }
    }
  }

  // Simpan perubahan ke Firestore / Backend
  Future<void> _saveProfile() async {
    if (_firstNameController.text.trim().isEmpty) {
      _showSnackBar('Nama depan tidak boleh kosong');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _authViewModel.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        birthDate: _selectedDate,
        // photoUrl: _profileImageUrl, // Tambahkan parameter jika ada
      );

      if (mounted) {
        _showSnackBar('Profil berhasil diperbarui!', isError: false);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal memperbarui profil: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: isError ? Colors.red : const Color(0xFFFF9800),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // Fungsi Pemilih Tanggal
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFFFF9800),
              onPrimary: Colors.white,
              onSurface: ThemeViewModel.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeViewModel.isDarkMode;

    const primaryOrange = Color(0xFFFF9800);
    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final cardBgColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[50];
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final inputBorderColor = isDarkMode ? Colors.grey[800]! : Colors.grey.shade300;

    // Provider Gambar Profil Dinamis
    ImageProvider getProfileImage() {
      if (_selectedImageFile != null) {
        return FileImage(_selectedImageFile!);
      } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
        return NetworkImage(_profileImageUrl!);
      } else {
        return const NetworkImage('https://i.pravatar.cc/300?img=5');
      }
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profil',
          style: GoogleFonts.poppins(
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryOrange))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Foto Profil Section
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _isUploadingImage ? null : _showImageSourceDialog,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundImage: getProfileImage(),
                                  backgroundColor: Colors.grey[300],
                                ),
                                if (_isUploadingImage)
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: primaryOrange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _isUploadingImage ? null : _showImageSourceDialog,
                            child: Text(
                              'Ubah Foto Profil',
                              style: GoogleFonts.poppins(
                                color: primaryOrange,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Form Input: Nama Depan
                    _buildInputField(
                      label: 'Nama Depan',
                      controller: _firstNameController,
                      icon: Icons.badge_outlined,
                      isDarkMode: isDarkMode,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      inputBorderColor: inputBorderColor,
                      cardBgColor: cardBgColor,
                    ),

                    const SizedBox(height: 16),

                    // Form Input: Nama Belakang
                    _buildInputField(
                      label: 'Nama Belakang',
                      controller: _lastNameController,
                      icon: Icons.person_outline_rounded,
                      isDarkMode: isDarkMode,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      inputBorderColor: inputBorderColor,
                      cardBgColor: cardBgColor,
                    ),

                    const SizedBox(height: 16),

                    // Form Input: Email (Disabled)
                    _buildInputField(
                      label: 'Email',
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      enabled: false,
                      isDarkMode: isDarkMode,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      inputBorderColor: inputBorderColor,
                      cardBgColor: cardBgColor,
                    ),

                    const SizedBox(height: 16),

                    // Form Input: Tanggal Lahir
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tanggal Lahir',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: AbsorbPointer(
                            child: TextField(
                              controller: _dobController,
                              style: GoogleFonts.poppins(color: primaryTextColor, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'DD/MM/YYYY',
                                hintStyle: GoogleFonts.poppins(color: secondaryTextColor, fontSize: 13),
                                prefixIcon: Icon(Icons.calendar_today_outlined, color: secondaryTextColor, size: 20),
                                filled: true,
                                fillColor: cardBgColor,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: inputBorderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: inputBorderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: primaryOrange, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 36),

                    // Tombol Simpan Perubahan
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_isSaving || _isUploadingImage) ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryOrange,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Simpan Perubahan',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper Widget Field Input
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    required bool isDarkMode,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color inputBorderColor,
    required Color? cardBgColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(
            color: enabled ? primaryTextColor : secondaryTextColor,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: secondaryTextColor, size: 20),
            filled: true,
            fillColor: cardBgColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: inputBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: inputBorderColor),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: inputBorderColor.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF9800), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}