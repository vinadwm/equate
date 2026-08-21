import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:equate/viewmodel/theme_viewmodel.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearConfirmPassword() {
    setState(() {
      _confirmPasswordController.clear();
    });
  }

  // Fungsi untuk me-reset semua input kata sandi
  void _resetAllFields() {
    setState(() {
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFFFA800);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeViewModel.themeMode,
      builder: (context, currentThemeMode, child) {
        final isDarkMode = ThemeViewModel.isDarkMode;

        // Penyesuaian Warna Dinamis
        final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
        final inputFillColor = isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFAFAFA);
        final primaryTextColor = isDarkMode ? Colors.white : const Color(0xFF1D1D1F);
        final secondaryTextColor = isDarkMode ? Colors.grey[400]! : const Color(0xFF6E6E73);
        final iconColor = isDarkMode ? Colors.white : Colors.black;
        final borderColor = isDarkMode ? Colors.grey[800]! : const Color(0xFFE5E5EA);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            titleSpacing: 0, // Menghilangkan jarak bawaan antara panah dan judul
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: iconColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'UBAH KATA SANDI',
              style: GoogleFonts.plusJakartaSans(
                color: primaryTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Ikon Gembok + Subjudul)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.grey[800]!.withOpacity(0.5)
                            : const Color(0xFFF2F2F7),
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor),
                      ),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        color: primaryTextColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Perbarui kata sandi Anda untuk meningkatkan keamanan akun.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: secondaryTextColor,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Divider(color: borderColor, height: 1),
                const SizedBox(height: 20),

                // 1. Kata Sandi Saat Ini
                _buildLabel('Kata Sandi Saat Ini', primaryTextColor, isRequired: true),
                const SizedBox(height: 8),
                _buildPasswordField(
                  controller: _oldPasswordController,
                  hintText: '••••••••••••',
                  isObscure: _obscureOld,
                  onToggleObscure: () =>
                      setState(() => _obscureOld = !_obscureOld),
                  primaryOrange: primaryOrange,
                  inputFillColor: inputFillColor,
                  textColor: primaryTextColor,
                  borderColor: borderColor,
                ),

                const SizedBox(height: 18),

                // 2. Kata Sandi Baru
                _buildLabel('Kata Sandi Baru', primaryTextColor, isRequired: true),
                const SizedBox(height: 8),
                _buildPasswordField(
                  controller: _newPasswordController,
                  hintText: '••••••••••••',
                  isObscure: _obscureNew,
                  onToggleObscure: () =>
                      setState(() => _obscureNew = !_obscureNew),
                  primaryOrange: primaryOrange,
                  inputFillColor: inputFillColor,
                  textColor: primaryTextColor,
                  borderColor: borderColor,
                ),

                const SizedBox(height: 18),

                // 3. Konfirmasi Kata Sandi Baru
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLabel('Konfirmasi Kata Sandi Baru', primaryTextColor, isRequired: true),
                    GestureDetector(
                      onTap: _clearConfirmPassword,
                      child: Text(
                        'Hapus',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  hintText: '••••••••••••',
                  isObscure: _obscureConfirm,
                  onToggleObscure: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  primaryOrange: primaryOrange,
                  inputFillColor: inputFillColor,
                  textColor: primaryTextColor,
                  borderColor: borderColor,
                ),

                const SizedBox(height: 16),

                // Daftar Syarat Validasi
                Text(
                  'Kata sandi harus mengandung:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                _buildValidationItem('Minimal 1 huruf kapital', isChecked: true, secondaryTextColor: secondaryTextColor),
                const SizedBox(height: 6),
                _buildValidationItem('Minimal 1 angka', isChecked: false, secondaryTextColor: secondaryTextColor),
                const SizedBox(height: 6),
                _buildValidationItem('Minimal 8 karakter', isChecked: false, secondaryTextColor: secondaryTextColor),

                const SizedBox(height: 32),

                // Tombol Aksi (Reset & Simpan Perubahan)
                Row(
                  children: [
                    // Tombol Reset
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _resetAllFields,
                          child: Text(
                            'Reset',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: primaryTextColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Tombol Simpan Perubahan
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            if (_newPasswordController.text ==
                                _confirmPasswordController.text) {
                              Navigator.pop(context);
                            }
                          },
                          child: Text(
                            'Simpan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text, Color textColor, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          color: textColor,
          fontSize: 13,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: Color(0xFFE53935),
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool isObscure,
    required VoidCallback onToggleObscure,
    required Color primaryOrange,
    required Color inputFillColor,
    required Color textColor,
    required Color borderColor,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.plusJakartaSans(
          color: Colors.grey[400],
          fontSize: 14,
          letterSpacing: 2,
        ),
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryOrange, width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey[500],
            size: 18,
          ),
          onPressed: onToggleObscure,
        ),
      ),
    );
  }

  Widget _buildValidationItem(String text,
      {required bool isChecked, required Color secondaryTextColor}) {
    return Row(
      children: [
        Icon(
          isChecked ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 16,
          color: isChecked ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: secondaryTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}