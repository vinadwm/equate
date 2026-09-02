import 'package:flutter/material.dart';

import 'package:equate/view/auth/login_view.dart';
import 'package:equate/viewmodel/auth_viewmodel.dart';
import '../main_navigation_view.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
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

    // ----------------------------------------------------------
    // VALIDASI NAMA DEPAN
    // ----------------------------------------------------------

    if (firstName.isEmpty) {
      _showError('Nama depan wajib diisi.');
      return;
    }

    // ----------------------------------------------------------
    // VALIDASI NAMA BELAKANG
    // ----------------------------------------------------------

    if (lastName.isEmpty) {
      _showError('Nama belakang wajib diisi.');
      return;
    }

    // ----------------------------------------------------------
    // VALIDASI EMAIL
    // ----------------------------------------------------------

    final emailError = _authViewModel.validateEmail(email);

    if (emailError != null) {
      _showError(emailError);
      return;
    }

    // ----------------------------------------------------------
    // VALIDASI PASSWORD
    // ----------------------------------------------------------

    final passwordError = _authViewModel.validatePassword(password);

    if (passwordError != null) {
      _showError(passwordError);
      return;
    }

    // ----------------------------------------------------------
    // VALIDASI KONFIRMASI PASSWORD
    // ----------------------------------------------------------

    if (confirmPassword.isEmpty) {
      _showError('Konfirmasi kata sandi wajib diisi.');
      return;
    }

    if (password != confirmPassword) {
      _showError('Kata sandi dan konfirmasi kata sandi tidak sama.');
      return;
    }

    // ----------------------------------------------------------
    // SIGN UP
    // ----------------------------------------------------------

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

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
        (route) => false,
      );
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFFF9800);

    return ListenableBuilder(
      listenable: _authViewModel,
      builder: (context, child) {
        final isLoading = _authViewModel.isLoading;

        return Scaffold(
          backgroundColor: const Color(0xFFFAFAFA),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ==================================================
                  // ILUSTRASI
                  // ==================================================
                  Center(
                    child: CircleAvatar(
                      radius: 75,
                      backgroundColor: Colors.transparent,
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/photoRegis.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person_pin,
                              size: 80,
                              color: primaryOrange,
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // TITLE
                  // ==================================================
                  const Text(
                    'Selamat Datang!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Text(
                        'Sudah punya akun? ',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: isLoading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginView(),
                                  ),
                                );
                              },
                        child: const Text(
                          'Masuk',
                          style: TextStyle(
                            color: primaryOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // FORM CARD
                  // ==================================================
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // NAMA DEPAN
                        const Text(
                          'Nama Depan',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 6),

                        TextField(
                          controller: _firstNameController,
                          textCapitalization: TextCapitalization.words,
                          enabled: !isLoading,
                          decoration: _inputDecoration(),
                        ),

                        const SizedBox(height: 16),

                        // NAMA BELAKANG
                        const Text(
                          'Nama Belakang',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 6),

                        TextField(
                          controller: _lastNameController,
                          textCapitalization: TextCapitalization.words,
                          enabled: !isLoading,
                          decoration: _inputDecoration(),
                        ),

                        const SizedBox(height: 16),

                        // EMAIL
                        const Text(
                          'E-Mail',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 6),

                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !isLoading,
                          decoration: _inputDecoration(),
                        ),

                        const SizedBox(height: 16),

                        // PASSWORD
                        const Text(
                          'Kata Sandi',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 6),

                        TextField(
                          controller: _passwordController,
                          obscureText: _isObscurePassword,
                          enabled: !isLoading,
                          decoration: _inputDecoration(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey,
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _isObscurePassword =
                                            !_isObscurePassword;
                                      });
                                    },
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Minimal 8 karakter, 1 huruf kapital, dan 1 angka.',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),

                        const SizedBox(height: 16),

                        // KONFIRMASI PASSWORD
                        const Text(
                          'Konfirmasi Kata Sandi',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 6),

                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _isObscureConfirmPassword,
                          enabled: !isLoading,
                          decoration: _inputDecoration(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey,
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _isObscureConfirmPassword =
                                            !_isObscureConfirmPassword;
                                      });
                                    },
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // BUTTON DAFTAR
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryOrange,
                              disabledBackgroundColor: primaryOrange
                                  .withOpacity(0.5),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: isLoading ? null : _handleSignUp,
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Daftar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ==================================================
                  // ATAU
                  // ==================================================
                  Row(
                    children: const [
                      Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'ATAU',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // GOOGLE
                  // ==================================================
                  Center(
                    child: InkWell(
                      onTap: isLoading ? null : _handleGoogleSignUp,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/google.png',
                          height: 28,
                          width: 28,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.g_mobiledata,
                              size: 32,
                              color: Colors.red,
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF7F7F9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF9800), width: 1.5),
      ),
      suffixIcon: suffixIcon,
    );
  }
}
