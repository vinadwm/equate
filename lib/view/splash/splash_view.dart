import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../onboarding/onboarding_view.dart';
import '../main_navigation_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  bool _isScaled = false;
  bool _isShifted = false;

  @override
  void initState() {
    super.initState();
    _startAnimationSequence();
  }

  Future<void> _startAnimationSequence() async {
    // ============================================================
    // 1. LOGO MUNCUL
    // ============================================================

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      _isScaled = true;
    });

    // ============================================================
    // 2. LOGO BERGESER + TEKS MUNCUL
    // ============================================================

    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    setState(() {
      _isShifted = true;
    });

    // ============================================================
    // 3. TUNGGU SELESAI ANIMASI
    // ============================================================

    await Future.delayed(const Duration(milliseconds: 3000));

    if (!mounted) return;

    // ============================================================
    // 4. CEK STATUS LOGIN
    // ============================================================

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // ==========================================================
      // USER MASIH LOGIN
      // → LANGSUNG HOME
      // ==========================================================

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigationView()),
      );
    } else {
      // ==========================================================
      // USER BELUM LOGIN / SUDAH LOGOUT
      // → ONBOARDING
      // ==========================================================

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Ukuran logo menyesuaikan ukuran layar
    final double logoSize = screenWidth < 360 ? 90 : 110;

    // Lebar maksimum area teks
    final double availableTextWidth = screenWidth - logoSize - 40;

    final double textWidth = availableTextWidth.clamp(150.0, 210.0);

    return Scaffold(
      backgroundColor: Colors.white,

      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),

          child: AnimatedScale(
            scale: _isScaled ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutBack,

            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,

              children: [
                // =====================================================
                // LOGO
                // =====================================================

                SizedBox(
                  width: logoSize,
                  height: logoSize,

                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,

                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.analytics_outlined,
                        size: logoSize * 0.7,
                        color: Colors.amber[800],
                      );
                    },
                  ),
                ),

                // =====================================================
                // TEXT
                // =====================================================
                AnimatedContainer(
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeInOutCubic,

                  width: _isShifted ? textWidth : 0,

                  // PENTING:
                  // Jangan gunakan Clip.hardEdge ketika width = 0
                  clipBehavior: Clip.none,

                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeIn,

                    opacity: _isShifted ? 1.0 : 0.0,

                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),

                      child: SizedBox(
                        width: textWidth,

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          mainAxisSize: MainAxisSize.min,

                          children: [
                            // =================================================
                            // EQUATE
                            // =================================================

                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,

                              child: Text(
                                'Equate',
                                maxLines: 1,

                                style: GoogleFonts.poppins(
                                  fontSize: 46,
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FontStyle.italic,
                                  color: const Color(0xFF1A1A1A),
                                  letterSpacing: -1.5,
                                  height: 1.0,
                                ),
                              ),
                            ),

                            const SizedBox(height: 2),

                            // =================================================
                            // SUBTITLE
                            // =================================================
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,

                              child: Text(
                                'Gold & Pivot Analysis',
                                maxLines: 1,

                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.amber[800],
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
