import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:equate/viewmodel/theme_viewmodel.dart';

import 'signup_view.dart';
import 'auth_glass_widgets.dart';
import '../main_navigation_view.dart';
import '../../viewmodel/auth_viewmodel.dart';

// ================================================================
// HALAMAN INDUK (LOGIN + DAFTAR)
// Background dipasang sekali di sini dan tidak ikut bergeser.
// Hanya kartu kaca (form) yang berganti dengan animasi geser.
// ================================================================
class LoginView extends StatefulWidget {
  /// Set true kalau ingin langsung membuka form Daftar.
  final bool startWithSignUp;

  const LoginView({super.key, this.startWithSignUp = false});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late bool _showSignUp;

  @override
  void initState() {
    super.initState();
    _showSignUp = widget.startWithSignUp;
  }

  void _switchTo({required bool signUp}) {
    FocusScope.of(context).unfocus();
    setState(() => _showSignUp = signUp);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeViewModel.themeMode,
      builder: (context, currentThemeMode, _) {
        final t = AuthTokens(ThemeViewModel.isDarkMode);

        return Scaffold(
          backgroundColor: t.pageBackground,
          body: AuthGlassBackground(
            t: t,
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 340),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      transitionBuilder: (child, animation) {
                        // Daftar masuk dari kanan, Masuk masuk dari kiri.
                        final isSignUp = child.key == const ValueKey('signup');
                        final offset = Tween<Offset>(
                          begin: Offset(isSignUp ? 0.3 : -0.3, 0),
                          end: Offset.zero,
                        ).animate(animation);

                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: offset,
                            child: child,
                          ),
                        );
                      },
                      child: _showSignUp
                          ? SignUpForm(
                              key: const ValueKey('signup'),
                              t: t,
                              onGoToLogin: () => _switchTo(signUp: false),
                              onSignedUp: () => _switchTo(signUp: false),
                            )
                          : LoginForm(
                              key: const ValueKey('login'),
                              t: t,
                              onGoToSignUp: () => _switchTo(signUp: true),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ================================================================
// FORM LOGIN (kartu kaca + tautan di bawahnya)
// ================================================================
class LoginForm extends StatefulWidget {
  final AuthTokens t;
  final VoidCallback onGoToSignUp;

  const LoginForm({super.key, required this.t, required this.onGoToSignUp});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthViewModel _authViewModel = AuthViewModel();

  bool _isObscure = true;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    _authViewModel.dispose();

    super.dispose();
  }

  // ============================================================
  // LOGIN EMAIL
  // ============================================================

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

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

    try {
      await _authViewModel.login(email: email, password: password);

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
  // LOGIN GOOGLE
  // ============================================================

  Future<void> _handleGoogleLogin() async {
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
  // LUPA KATA SANDI
  // ============================================================

  Future<void> _handleForgotPassword() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (dialogContext) {
        return _ForgotPasswordDialog(
          authViewModel: _authViewModel,
          tokens: AuthTokens(ThemeViewModel.isDarkMode),
          initialEmail: _emailController.text.trim(),
        );
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Link reset kata sandi telah dikirim ke email kamu. '
            'Silakan cek inbox atau folder spam.',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
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
                          'Masuk',
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
                        onTap: isLoading ? null : _handleGoogleLogin,
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Lanjutkan memantau emas dan Hang Seng.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: t.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 22),

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

                  // Kata sandi + "Lupa?"
                  AuthPillField(
                    t: t,
                    controller: _passwordController,
                    hint: 'Kata sandi',
                    icon: Icons.lock_outline_rounded,
                    obscure: _isObscure,
                    enabled: !isLoading,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!isLoading) _handleLogin();
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _isObscure = !_isObscure;
                                  });
                                },
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            child: Icon(
                              _isObscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                              color: t.textSecondary,
                            ),
                          ),
                        ),
                        AuthMiniPill(
                          t: t,
                          label: 'Lupa?',
                          onTap: isLoading ? null : _handleForgotPassword,
                        ),
                        const SizedBox(width: 7),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Catatan + tombol masuk
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Pastikan e-mail dan kata sandimu sudah benar.',
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
                        label: 'Masuk',
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _handleLogin,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: Text(
                      'Riwayat perhitunganmu tersimpan aman di akunmu.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: t.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            AuthBottomLink(
              t: t,
              question: 'Belum punya akun?',
              actionLabel: 'Daftar',
              onTap: isLoading ? null : widget.onGoToSignUp,
            ),
          ],
        );
      },
    );
  }
}

// ================================================================
// DIALOG LUPA KATA SANDI (kaca)
// ================================================================
class _ForgotPasswordDialog extends StatefulWidget {
  final AuthViewModel authViewModel;
  final AuthTokens tokens;
  final String initialEmail;

  const _ForgotPasswordDialog({
    required this.authViewModel,
    required this.tokens,
    required this.initialEmail,
  });

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _emailController;

  bool _isSending = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();

    final emailError = widget.authViewModel.validateEmail(email);

    if (emailError != null) {
      setState(() => _errorText = emailError);
      return;
    }

    setState(() {
      _isSending = true;
      _errorText = null;
    });

    try {
      await widget.authViewModel.resetPassword(email);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSending = false;
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: AuthGlassCard(
          t: t,
          radius: 30,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lupa kata sandi?',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.4,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Masukkan email akunmu. Kami akan mengirim link untuk membuat kata sandi baru.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  height: 1.5,
                  color: t.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              AuthPillField(
                t: t,
                controller: _emailController,
                hint: 'Alamat e-mail',
                icon: Icons.alternate_email_rounded,
                enabled: !_isSending,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (!_isSending) _submit();
                },
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    _errorText!,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: const Color(0xFFFF3B30),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSending
                        ? null
                        : () => Navigator.pop(context, false),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: t.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AuthActionButton(
                    t: t,
                    label: 'Kirim link',
                    isLoading: _isSending,
                    onPressed: _isSending ? null : _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}