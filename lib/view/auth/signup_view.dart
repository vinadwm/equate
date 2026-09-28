import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:equate/viewmodel/auth_viewmodel.dart';

import 'auth_glass_widgets.dart';
import '../main_navigation_view.dart';

// ================================================================
// FORM DAFTAR (kartu kaca + tautan di bawahnya)
// Dipakai oleh LoginView (halaman induk), jadi background tidak
// ikut bergeser saat berpindah antara Masuk dan Daftar.
// ================================================================
class SignUpForm extends StatefulWidget {
  final AuthTokens t;

  /// Dipanggil saat pengguna menekan "Masuk" di bawah kartu.
  final VoidCallback onGoToLogin;

  /// Dipanggil setelah akun berhasil dibuat (kembali ke form Masuk).
  final VoidCallback onSignedUp;

  const SignUpForm({
    super.key,
    required this.t,
    required this.onGoToLogin,
    required this.onSignedUp,
  });

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthViewModel _authViewModel = AuthViewModel();

  bool _isObscurePassword = true;
  bool _isObscureConfirmPassword = true;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _authViewModel.dispose();

    super.dispose();
  }

  // ============================================================
  // SIGN UP
  // ============================================================

  Future<void> _handleSignUp() async {
    FocusScope.of(context).unfocus();

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (firstName.isEmpty) {
      _showError('Nama depan wajib diisi.');
      return;
    }

    if (lastName.isEmpty) {
      _showError('Nama belakang wajib diisi.');
      return;
    }

    final emailError = _authViewModel.validateEmail(email);

    if (emailError != null) {
      _showError(emailError);
      return;
    }

    final passwordError = _authViewModel.validatePassword(password);

    if (passwordError != null) {
      _showError(passwordError);
      return;
    }

    if (confirmPassword.isEmpty) {
      _showError('Konfirmasi kata sandi wajib diisi.');
      return;
    }

    if (password != confirmPassword) {
      _showError('Kata sandi dan konfirmasi kata sandi tidak sama.');
      return;
    }

    try {
      await _authViewModel.signUp(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun berhasil dibuat. Silakan masuk.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      widget.onSignedUp();
    } catch (e) {
      if (!mounted) return;

      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ============================================================
  // GOOGLE LOGIN / SIGN UP
  // ============================================================

  Future<void> _handleGoogleSignUp() async {
    FocusScope.of(context).unfocus();

    try {
      await _authViewModel.loginWithGoogle();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationView()),
      );
    } catch (e) {
      if (!mounted) return;

      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ============================================================
  // ICON MATA (tampilkan / sembunyikan kata sandi)
  // ============================================================

  Widget _eyeToggle({
    required AuthTokens t,
    required bool isObscure,
    required bool isLoading,
    required VoidCallback onToggle,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onToggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Icon(
          isObscure
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          size: 18,
          color: t.textSecondary,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final t = widget.t;

    return ListenableBuilder(
      listenable: _authViewModel,
      builder: (context, child) {
        final isLoading = _authViewModel.isLoading;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuthGlassCard(
              t: t,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul + tombol Google
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Buat akun',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.8,
                            color: t.textPrimary,
                          ),
                        ),
                      ),
                      AuthGooglePill(
                        t: t,
                        onTap: isLoading ? null : _handleGoogleSignUp,
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Simpan riwayat perhitunganmu di satu tempat.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: t.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Nama depan
                  AuthPillField(
                    t: t,
                    controller: _firstNameController,
                    hint: 'Nama depan',
                    icon: Icons.person_outline_rounded,
                    enabled: !isLoading,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 12),

                  // Nama belakang
                  AuthPillField(
                    t: t,
                    controller: _lastNameController,
                    hint: 'Nama belakang',
                    icon: Icons.badge_outlined,
                    enabled: !isLoading,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 12),

                  // Email
                  AuthPillField(
                    t: t,
                    controller: _emailController,
                    hint: 'Alamat e-mail',
                    icon: Icons.alternate_email_rounded,
                    enabled: !isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 12),

                  // Kata sandi
                  AuthPillField(
                    t: t,
                    controller: _passwordController,
                    hint: 'Kata sandi',
                    icon: Icons.lock_outline_rounded,
                    obscure: _isObscurePassword,
                    enabled: !isLoading,
                    textInputAction: TextInputAction.next,
                    trailing: _eyeToggle(
                      t: t,
                      isObscure: _isObscurePassword,
                      isLoading: isLoading,
                      onToggle: () {
                        setState(() {
                          _isObscurePassword = !_isObscurePassword;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Konfirmasi kata sandi
                  AuthPillField(
                    t: t,
                    controller: _confirmPasswordController,
                    hint: 'Ulangi kata sandi',
                    icon: Icons.shield_outlined,
                    obscure: _isObscureConfirmPassword,
                    enabled: !isLoading,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!isLoading) _handleSignUp();
                    },
                    trailing: _eyeToggle(
                      t: t,
                      isObscure: _isObscureConfirmPassword,
                      isLoading: isLoading,
                      onToggle: () {
                        setState(() {
                          _isObscureConfirmPassword =
                              !_isObscureConfirmPassword;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Catatan + tombol daftar
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Gunakan kata sandi yang kuat dan mudah kamu ingat.',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            height: 1.45,
                            color: t.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      AuthActionButton(
                        t: t,
                        label: 'Daftar',
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _handleSignUp,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            AuthBottomLink(
              t: t,
              question: 'Sudah punya akun?',
              actionLabel: 'Masuk',
              onTap: isLoading ? null : widget.onGoToLogin,
            ),
          ],
        );
      },
    );
  }
}