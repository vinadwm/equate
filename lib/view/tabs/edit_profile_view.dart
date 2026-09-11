import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:equate/viewmodel/profile_viewmodel.dart';
import 'package:equate/viewmodel/theme_viewmodel.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  // ============================================================
  // VIEWMODEL
  // ============================================================

  final ProfileViewModel _profileViewModel = ProfileViewModel();

  // ============================================================
  // CONTROLLER
  // ============================================================

  final TextEditingController _firstNameController = TextEditingController();

  final TextEditingController _lastNameController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _dobController = TextEditingController();

  // ============================================================
  // STATE UI
  // ============================================================

  DateTime? _selectedDate;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _profileViewModel.addListener(_onViewModelChanged);

    _loadUserData();
  }

  // ============================================================
  // VIEWMODEL LISTENER
  // ============================================================

  void _onViewModelChanged() {
    if (!mounted) return;

    setState(() {});
  }

  // ============================================================
  // LOAD USER DATA
  // ============================================================

  Future<void> _loadUserData() async {
    await _profileViewModel.loadProfile();

    if (!mounted) return;

    final user = _profileViewModel.user;

    if (user == null) return;

    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _emailController.text = user.email;

    if (user.birthDate != null) {
      _selectedDate = user.birthDate;

      _dobController.text =
          '${user.birthDate!.day.toString().padLeft(2, '0')}/'
          '${user.birthDate!.month.toString().padLeft(2, '0')}/'
          '${user.birthDate!.year}';
    }
  }

  // ============================================================
  // IMAGE SOURCE BOTTOM SHEET
  // ============================================================

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeViewModel.isDarkMode
          ? const Color(0xFF1E1E1E)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isDarkMode = ThemeViewModel.isDarkMode;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pilih Sumber Foto Profil',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),

                const SizedBox(height: 16),

                // ==================================================
                // GALERI
                // ==================================================
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_rounded,
                    color: Color(0xFFFF9800),
                  ),
                  title: Text(
                    'Galeri',
                    style: GoogleFonts.poppins(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);

                    _pickPhoto(ImageSource.gallery);
                  },
                ),

                // ==================================================
                // KAMERA
                // ==================================================
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFFFF9800),
                  ),
                  title: Text(
                    'Kamera',
                    style: GoogleFonts.poppins(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);

                    _pickPhoto(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PICK & UPLOAD PHOTO
  // ============================================================

  Future<void> _pickPhoto(ImageSource source) async {
    final success = await _profileViewModel.pickAndUploadPhoto(source);

    if (!mounted) return;

    if (_profileViewModel.errorMessage != null) {
      _showSnackBar(_profileViewModel.errorMessage!, isError: true);

      _profileViewModel.clearError();

      return;
    }

    if (success) {
      _showSnackBar('Foto profil berhasil diperbarui.', isError: false);
    }
  }

  // ============================================================
  // SELECT DATE
  // ============================================================

  Future<void> _selectDate() async {
    final isDarkMode = ThemeViewModel.isDarkMode;

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
              onSurface: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;

      _dobController.text =
          '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.month.toString().padLeft(2, '0')}/'
          '${picked.year}';
    });
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    if (_firstNameController.text.trim().isEmpty) {
      _showSnackBar('Nama depan tidak boleh kosong.', isError: true);
      return;
    }

    await _profileViewModel.updateProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      birthDate: _selectedDate,
    );

    if (!mounted) return;

    if (_profileViewModel.errorMessage != null) {
      _showSnackBar(_profileViewModel.errorMessage!, isError: true);

      _profileViewModel.clearError();

      return;
    }

    _showSnackBar('Profil berhasil diperbarui.', isError: false);

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFFFF9800),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _profileViewModel.removeListener(_onViewModelChanged);

    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _dobController.dispose();

    _profileViewModel.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeViewModel.isDarkMode;

    const primaryOrange = Color(0xFFFF9800);

    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;

    final cardBgColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[50]!;

    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;

    final secondaryTextColor = isDarkMode
        ? Colors.grey[400]!
        : Colors.grey[600]!;

    final inputBorderColor = isDarkMode
        ? Colors.grey[800]!
        : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: bgColor,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,

        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: primaryTextColor,
            size: 20,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
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

      // ========================================================
      // BODY
      // ========================================================
      body: _profileViewModel.isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryOrange))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // FOTO PROFIL
                    // ==================================================
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _profileViewModel.isUploadingPhoto
                                ? null
                                : _showImageSourceDialog,

                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // FOTO PROFIL
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.grey[300],

                                  backgroundImage: _profileViewModel.hasPhoto
                                      ? NetworkImage(_profileViewModel.photo)
                                      : null,

                                  child: !_profileViewModel.hasPhoto
                                      ? Icon(
                                          Icons.person_rounded,
                                          size: 50,
                                          color: Colors.grey[600],
                                        )
                                      : null,
                                ),

                                // ==================================================
                                // LOADING UPLOAD
                                // ==================================================
                                if (_profileViewModel.isUploadingPhoto)
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

                                // ==================================================
                                // CAMERA ICON
                                // ==================================================
                                if (!_profileViewModel.isUploadingPhoto)
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
                            onPressed: _profileViewModel.isUploadingPhoto
                                ? null
                                : _showImageSourceDialog,

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

                    // ==================================================
                    // NAMA DEPAN
                    // ==================================================
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

                    // ==================================================
                    // NAMA BELAKANG
                    // ==================================================
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

                    // ==================================================
                    // EMAIL
                    // ==================================================
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

                    // ==================================================
                    // TANGGAL LAHIR
                    // ==================================================
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
                          onTap: _selectDate,

                          child: AbsorbPointer(
                            child: TextField(
                              controller: _dobController,

                              style: GoogleFonts.poppins(
                                color: primaryTextColor,
                                fontSize: 14,
                              ),

                              decoration: InputDecoration(
                                hintText: 'DD/MM/YYYY',

                                hintStyle: GoogleFonts.poppins(
                                  color: secondaryTextColor,
                                  fontSize: 13,
                                ),

                                prefixIcon: Icon(
                                  Icons.calendar_today_outlined,
                                  color: secondaryTextColor,
                                  size: 20,
                                ),

                                filled: true,

                                fillColor: cardBgColor,

                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),

                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: inputBorderColor,
                                  ),
                                ),

                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: inputBorderColor,
                                  ),
                                ),

                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: primaryOrange,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 36),

                    // ==================================================
                    // BUTTON SIMPAN
                    // ==================================================
                    SizedBox(
                      width: double.infinity,
                      height: 50,

                      child: ElevatedButton(
                        onPressed:
                            (_profileViewModel.isSaving ||
                                _profileViewModel.isUploadingPhoto)
                            ? null
                            : _saveProfile,

                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryOrange,

                          disabledBackgroundColor: primaryOrange.withOpacity(
                            0.5,
                          ),

                          elevation: 0,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),

                        child: _profileViewModel.isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
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

  // ============================================================
  // INPUT FIELD
  // ============================================================

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
    required Color cardBgColor,
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

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),

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
              borderSide: const BorderSide(
                color: Color(0xFFFF9800),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
