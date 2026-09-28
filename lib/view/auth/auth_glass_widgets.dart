import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// KOMPONEN GLASS BERSAMA UNTUK HALAMAN LOGIN & DAFTAR
// Simpan di: lib/view/auth/auth_glass_widgets.dart
// ============================================================

const Color kAuthOrange = Color(0xFFFF9500);
const Color kAuthOrangeSoft = Color(0xFFFFB74D);
const Color kAuthOrangeDeep = Color(0xFFFF7A00);

/// Token warna terpusat (light / dark) supaya kedua halaman konsisten.
class AuthTokens {
  final bool isDark;
  const AuthTokens(this.isDark);

  Color get textPrimary => isDark ? Colors.white : const Color(0xFF1D1D1F);

  Color get textSecondary =>
      isDark ? const Color(0xFFA1A1AA) : const Color(0xFF8E8E93);

  Color get fieldFill =>
      isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.55);

  Color get fieldBorder =>
      isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.9);

  Color get bubbleFill =>
      isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.95);

  Color get glassBorder =>
      isDark ? Colors.white.withOpacity(0.16) : Colors.white.withOpacity(0.85);

  Color get pageBackground =>
      isDark ? const Color(0xFF0D0E12) : const Color(0xFFFFF3E6);
}

// ============================================================
// BACKGROUND: gradasi hangat + orb oranye + bola "mutiara"
// ============================================================
class AuthGlassBackground extends StatelessWidget {
  final AuthTokens t;
  final Widget child;

  const AuthGlassBackground({super.key, required this.t, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = t.isDark;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Dasar gradasi
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? const [Color(0xFF0D0E12), Color(0xFF16181F)]
                  : const [
                      Color(0xFFFFF3E6),
                      Color(0xFFFFE9D6),
                      Color(0xFFFFF8F0),
                    ],
            ),
          ),
        ),

        // Watermark logo (samar)
        Positioned(
          bottom: 30,
          right: -50,
          child: IgnorePointer(
            child: Opacity(
              opacity: isDark ? 0.08 : 0.06,
              child: Image.asset(
                'assets/images/logoEWF.png',
                width: 230,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
        ),

        // Orb oranye (kanan atas)
        Positioned(
          top: -70,
          right: -80,
          child: IgnorePointer(child: _Orb(size: 260, isDark: isDark)),
        ),

        // Mutiara besar (kiri bawah)
        Positioned(
          bottom: -60,
          left: -60,
          child: IgnorePointer(child: _PearlSphere(size: 210, isDark: isDark)),
        ),

        // Mutiara kecil (kiri atas) - tampak blur di balik kartu kaca
        Positioned(
          top: 110,
          left: -22,
          child: IgnorePointer(child: _PearlSphere(size: 80, isDark: isDark)),
        ),

        SafeArea(child: child),
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final bool isDark;

  const _Orb({required this.size, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDark ? 0.85 : 1,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-0.35, -0.35),
            radius: 0.95,
            colors: [Color(0xFFFFC46B), Color(0xFFFF9500), Color(0xFFFF7A00)],
            stops: [0.0, 0.6, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: kAuthOrange.withOpacity(0.35),
              blurRadius: 60,
              spreadRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}

class _PearlSphere extends StatelessWidget {
  final double size;
  final bool isDark;

  const _PearlSphere({required this.size, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.95,
          colors: isDark
              ? [
                  const Color(0xFF3A3B42),
                  const Color(0xFF23242A),
                  const Color(0xFFFF7A00).withOpacity(0.55),
                ]
              : const [
                  Colors.white,
                  Color(0xFFFFEFE3),
                  Color(0xFFFFB37A),
                ],
          stops: const [0.0, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.10),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// KARTU KACA (blur ala iOS)
// ============================================================
class AuthGlassCard extends StatelessWidget {
  final AuthTokens t;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const AuthGlassCard({
    super.key,
    required this.t,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.radius = 30,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = t.isDark;

    // Shadow dipasang di luar ClipRRect supaya tidak terpotong.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            width: double.infinity,
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.12),
                        Colors.white.withOpacity(0.04),
                      ]
                    : [
                        Colors.white.withOpacity(0.72),
                        Colors.white.withOpacity(0.38),
                      ],
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: t.glassBorder, width: 1.2),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// INPUT BERBENTUK PIL DENGAN IKON BULAT DI KIRI
// ============================================================
class AuthPillField extends StatefulWidget {
  final AuthTokens t;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;

  const AuthPillField({
    super.key,
    required this.t,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.enabled = true,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.onSubmitted,
    this.trailing,
  });

  @override
  State<AuthPillField> createState() => _AuthPillFieldState();
}

class _AuthPillFieldState extends State<AuthPillField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final focused = _focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      height: 54,
      decoration: BoxDecoration(
        color: t.fieldFill,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: focused ? kAuthOrange : t.fieldBorder,
          width: focused ? 1.6 : 1,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: kAuthOrange.withOpacity(0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: 7),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.bubbleFill,
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: focused ? kAuthOrange : t.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscure,
              enabled: widget.enabled,
              keyboardType: widget.keyboardType,
              textCapitalization: widget.textCapitalization,
              textInputAction: widget.textInputAction,
              onSubmitted: widget.onSubmitted,
              cursorColor: kAuthOrange,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: t.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: widget.hint,
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: t.textSecondary,
                ),
              ),
            ),
          ),
          widget.trailing ?? const SizedBox(width: 16),
        ],
      ),
    );
  }
}

// ============================================================
// PIL KECIL (contoh: "Lupa?" di dalam kolom kata sandi)
// ============================================================
class AuthMiniPill extends StatelessWidget {
  final AuthTokens t;
  final String label;
  final VoidCallback? onTap;

  const AuthMiniPill({
    super.key,
    required this.t,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: t.isDark ? Colors.white.withOpacity(0.16) : Colors.white,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TOMBOL GOOGLE BERBENTUK PIL (pojok kanan atas judul)
// ============================================================
class AuthGooglePill extends StatelessWidget {
  final AuthTokens t;
  final VoidCallback? onTap;

  const AuthGooglePill({super.key, required this.t, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: t.fieldFill,
      shape: StadiumBorder(side: BorderSide(color: t.fieldBorder)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/google.png',
                height: 16,
                width: 16,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.g_mobiledata_rounded,
                  size: 20,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'Google',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TOMBOL AKSI: pil gradasi oranye + glow (tanpa panah)
// ============================================================
class AuthActionButton extends StatelessWidget {
  final AuthTokens t;
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const AuthActionButton({
    super.key,
    required this.t,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null && !isLoading;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: disabled ? 0.55 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: kAuthOrange.withOpacity(t.isDark ? 0.40 : 0.45),
              blurRadius: 22,
              spreadRadius: -2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kAuthOrangeSoft, kAuthOrange, kAuthOrangeDeep],
                stops: [0.0, 0.55, 1.0],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.45),
                width: 1,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              splashColor: Colors.white.withOpacity(0.25),
              highlightColor: Colors.white.withOpacity(0.10),
              onTap: isLoading ? null : onPressed,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 116),
                child: SizedBox(
                  height: 48,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Center(
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              label,
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TAUTAN DI BAWAH KARTU: "Belum punya akun? Daftar"
// ============================================================
class AuthBottomLink extends StatelessWidget {
  final AuthTokens t;
  final String question;
  final String actionLabel;
  final VoidCallback? onTap;

  const AuthBottomLink({
    super.key,
    required this.t,
    required this.question,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              question,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: t.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              actionLabel,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: kAuthOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}