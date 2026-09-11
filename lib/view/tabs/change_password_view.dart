import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:equate/viewmodel/theme_viewmodel.dart';
import 'package:equate/viewmodel/auth_viewmodel.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final TextEditingController _oldPasswordController = TextEditingController();

  final TextEditingController _newPasswordController = TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // ============================================================
  // PASSWORD VISIBILITY
  // ============================================================

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = false;

  bool _hasPassword = false;
  bool _checkingPassword = true;

  // ============================================================
  // PASSWORD VALIDATION
  // ============================================================

  bool _hasUppercase = false;
  bool _hasDigits = false;
  bool _hasMinLength = false;

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _newPasswordController.addListener(_validatePassword);

    _checkPasswordStatus();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _newPasswordController.removeListener(_validatePassword);

    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    // JANGAN dispose AuthViewModel di sini.
    // AuthViewModel dikelola oleh Provider di main.dart.

    super.dispose();
  }

  // ============================================================
  // VALIDASI PASSWORD REAL-TIME
  // ============================================================

  void _validatePassword() {
    final text = _newPasswordController.text;

    if (!mounted) return;

    setState(() {
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(text);

      _hasDigits = RegExp(r'[0-9]').hasMatch(text);

      _hasMinLength = text.length >= 8;
    });
  }

  // ============================================================
  // CEK STATUS PASSWORD
  // ============================================================

  void _checkPasswordStatus() {
    final authViewModel = context.read<AuthViewModel>();

    final hasPassword = authViewModel.hasPasswordProvider;

    if (!mounted) return;

    setState(() {
      _hasPassword = hasPassword;
      _checkingPassword = false;
    });
  }

  // ============================================================
  // CLEAR CONFIRM PASSWORD
  // ============================================================

  void _clearConfirmPassword() {
    _confirmPasswordController.clear();
  }

  // ============================================================
  // RESET SEMUA FIELD
  // ============================================================

  void _resetAllFields() {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    if (!mounted) return;

    setState(() {
      _hasUppercase = false;
      _hasDigits = false;
      _hasMinLength = false;
    });
  }

  // ============================================================
  // HANDLE CHANGE / CREATE PASSWORD
  // ============================================================

  Future<void> _handleChangePassword() async {
    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // ==========================================================
    // VALIDASI PASSWORD BARU
    // ==========================================================

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Harap isi semua bidang yang wajib diisi.');
      return;
    }

    // ==========================================================
    // VALIDASI KRITERIA PASSWORD
    // ==========================================================

    if (!_hasUppercase || !_hasDigits || !_hasMinLength) {
      _showSnackBar('Password baru belum memenuhi semua kriteria keamanan.');
      return;
    }

    // ==========================================================
    // VALIDASI KONFIRMASI PASSWORD
    // ==========================================================

    if (newPassword != confirmPassword) {
      _showSnackBar('Konfirmasi kata sandi tidak cocok.');
      return;
    }

    // ==========================================================
    // JIKA USER SUDAH PUNYA PASSWORD
    // ==========================================================

    if (_hasPassword && oldPassword.isEmpty) {
      _showSnackBar('Kata sandi saat ini wajib diisi.');
      return;
    }

    // ==========================================================
    // START LOADING
    // ==========================================================

    setState(() {
      _isLoading = true;
    });

    try {
      final authViewModel = context.read<AuthViewModel>();

      // ========================================================
      // USER SUDAH PUNYA PASSWORD
      // → UBAH PASSWORD
      // ========================================================

      if (_hasPassword) {
        await authViewModel.changePassword(
          oldPassword: oldPassword,
          newPassword: newPassword,
        );
      }
      // ========================================================
      // USER GOOGLE BELUM PUNYA PASSWORD
      // → BUAT DAN LINK PASSWORD
      // ========================================================
      else {
        await authViewModel.createPasswordForGoogleUser(
          newPassword: newPassword,
        );

        // Setelah berhasil link password,
        // status user sekarang sudah memiliki password.
        if (mounted) {
          setState(() {
            _hasPassword = true;
          });
        }
      }

      // ========================================================
      // BERHASIL
      // ========================================================

      if (!mounted) return;

      _showSnackBar(
        _hasPassword
            ? 'Kata sandi berhasil diperbarui!'
            : 'Kata sandi berhasil dibuat!',
        isError: false,
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      final message = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('Exception:', '');

      _showSnackBar(message);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError
            ? const Color(0xFFE53935)
            : const Color(0xFFFFA800),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFFFA800);

    // ==========================================================
    // LOADING SAAT CEK PROVIDER
    // ==========================================================

    if (_checkingPassword) {
      return ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeViewModel.themeMode,
        builder: (context, currentThemeMode, child) {
          final isDarkMode = ThemeViewModel.isDarkMode;

          return Scaffold(
            backgroundColor: isDarkMode
                ? const Color(0xFF121212)
                : Colors.white,
            body: const Center(
              child: CircularProgressIndicator(color: primaryOrange),
            ),
          );
        },
      );
    }

    // ==========================================================
    // MAIN VIEW
    // ==========================================================

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeViewModel.themeMode,
      builder: (context, currentThemeMode, child) {
        final isDarkMode = ThemeViewModel.isDarkMode;

        final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;

        final inputFillColor = isDarkMode
            ? const Color(0xFF1E1E1E)
            : const Color(0xFFFAFAFA);

        final primaryTextColor = isDarkMode
            ? Colors.white
            : const Color(0xFF1D1D1F);

        final secondaryTextColor = isDarkMode
            ? Colors.grey[400]!
            : const Color(0xFF6E6E73);

        final iconColor = isDarkMode ? Colors.white : Colors.black;

        final borderColor = isDarkMode
            ? Colors.grey[800]!
            : const Color(0xFFE5E5EA);

        return Scaffold(
          backgroundColor: bgColor,

          // ======================================================
          // APP BAR
          // ======================================================
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            titleSpacing: 0,

            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: iconColor),
              onPressed: _isLoading ? null : () => Navigator.pop(context),
            ),

            title: Text(
              _hasPassword ? 'UBAH KATA SANDI' : 'BUAT KATA SANDI',
              style: GoogleFonts.plusJakartaSans(
                color: primaryTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),

            centerTitle: false,
          ),

          // ======================================================
          // BODY
          // ======================================================
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // HEADER
                // ==================================================
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
                        _hasPassword
                            ? 'Perbarui kata sandi Anda untuk meningkatkan keamanan akun.'
                            : 'Buat kata sandi untuk menambahkan metode login email ke akun Anda.',

                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: secondaryTextColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Divider(color: borderColor, height: 1),

                const SizedBox(height: 20),

                // ==================================================
                // KATA SANDI SAAT INI
                // HANYA UNTUK USER YANG SUDAH PUNYA PASSWORD
                // ==================================================
                if (_hasPassword) ...[
                  _buildLabel(
                    'Kata Sandi Saat Ini',
                    primaryTextColor,
                    isRequired: true,
                  ),

                  const SizedBox(height: 8),

                  _buildPasswordField(
                    controller: _oldPasswordController,
                    hintText: '••••••••••••',
                    isObscure: _obscureOld,

                    onToggleObscure: () {
                      setState(() {
                        _obscureOld = !_obscureOld;
                      });
                    },

                    primaryOrange: primaryOrange,
                    inputFillColor: inputFillColor,
                    textColor: primaryTextColor,
                    borderColor: borderColor,

                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.password],
                  ),

                  const SizedBox(height: 18),
                ],

                // ==================================================
                // KATA SANDI BARU
                // ==================================================
                _buildLabel(
                  'Kata Sandi Baru',
                  primaryTextColor,
                  isRequired: true,
                ),

                const SizedBox(height: 8),

                _buildPasswordField(
                  controller: _newPasswordController,
                  hintText: '••••••••••••',
                  isObscure: _obscureNew,

                  onToggleObscure: () {
                    setState(() {
                      _obscureNew = !_obscureNew;
                    });
                  },

                  primaryOrange: primaryOrange,
                  inputFillColor: inputFillColor,
                  textColor: primaryTextColor,
                  borderColor: borderColor,

                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                ),

                const SizedBox(height: 18),

                // ==================================================
                // KONFIRMASI PASSWORD
                // ==================================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLabel(
                      'Konfirmasi Kata Sandi Baru',
                      primaryTextColor,
                      isRequired: true,
                    ),

                    GestureDetector(
                      onTap: _isLoading ? null : _clearConfirmPassword,

                      child: Text(
                        'Hapus',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isLoading
                              ? secondaryTextColor.withOpacity(0.5)
                              : secondaryTextColor,
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

                  onToggleObscure: () {
                    setState(() {
                      _obscureConfirm = !_obscureConfirm;
                    });
                  },

                  primaryOrange: primaryOrange,
                  inputFillColor: inputFillColor,
                  textColor: primaryTextColor,
                  borderColor: borderColor,

                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                ),

                const SizedBox(height: 16),

                // ==================================================
                // PASSWORD REQUIREMENTS
                // ==================================================
                Text(
                  'Kata sandi harus mengandung:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 8),

                _buildValidationItem(
                  'Minimal 1 huruf kapital',
                  isChecked: _hasUppercase,
                  secondaryTextColor: secondaryTextColor,
                ),

                const SizedBox(height: 6),

                _buildValidationItem(
                  'Minimal 1 angka',
                  isChecked: _hasDigits,
                  secondaryTextColor: secondaryTextColor,
                ),

                const SizedBox(height: 6),

                _buildValidationItem(
                  'Minimal 8 karakter',
                  isChecked: _hasMinLength,
                  secondaryTextColor: secondaryTextColor,
                ),

                const SizedBox(height: 32),

                // ==================================================
                // BUTTON
                // ==================================================
                Row(
                  children: [
                    // =================================================
                    // RESET
                    // =================================================
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

                          onPressed: _isLoading ? null : _resetAllFields,

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

                    // =================================================
                    // SIMPAN
                    // =================================================
                    Expanded(
                      child: SizedBox(
                        height: 46,

                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryOrange,

                            disabledBackgroundColor: primaryOrange.withOpacity(
                              0.5,
                            ),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),

                            elevation: 0,
                          ),

                          onPressed: _isLoading ? null : _handleChangePassword,

                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,

                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
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

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

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

  // ============================================================
  // PASSWORD FIELD
  // ============================================================

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool isObscure,
    required VoidCallback onToggleObscure,
    required Color primaryOrange,
    required Color inputFillColor,
    required Color textColor,
    required Color borderColor,
    TextInputAction? textInputAction,
    Iterable<String>? autofillHints,
  }) {
    return TextField(
      controller: controller,

      obscureText: isObscure,

      textInputAction: textInputAction,

      autofillHints: autofillHints,

      enableSuggestions: false,

      autocorrect: false,

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
            isObscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,

            color: Colors.grey[500],

            size: 18,
          ),

          onPressed: onToggleObscure,
        ),
      ),
    );
  }

  // ============================================================
  // VALIDATION ITEM
  // ============================================================

  Widget _buildValidationItem(
    String text, {
    required bool isChecked,
    required Color secondaryTextColor,
  }) {
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

            color: isChecked ? const Color(0xFF4CAF50) : secondaryTextColor,

            fontWeight: isChecked ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
