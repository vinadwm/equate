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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedScale(
          scale: _isScaled ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutBack,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.analytics_outlined,
                      size: 80,
                      color: Colors.amber[800],
                    );
                  },
                ),
              ),

              AnimatedContainer(
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeInOutCubic,
                width: _isShifted ? 210 : 0,
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeIn,
                  opacity: _isShifted ? 1.0 : 0.0,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Equate',
                            style: GoogleFonts.poppins(
                              fontSize: 46,
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFF1A1A1A),
                              letterSpacing: -1.5,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Gold & Pivot Analysis',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.amber[800],
                              letterSpacing: 0.2,
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
    );
  }
}
