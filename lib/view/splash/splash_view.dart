import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../onboarding/onboarding_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  // Flag state untuk mengontrol urutan animasi
  bool _isScaled = false;   // Detik 0.5: Logo membesar di tengah
  bool _isShifted = false;  // Detik 3.0: Logo bergeser ke kiri & teks muncul

  @override
  void initState() {
    super.initState();
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // 1. Detik 0.5: Logo Muncul di Tengah (Zoom In)
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isScaled = true;
      });
    }

    // 2. Detik 3.0: Logo diam selama 2.5 detik, lalu bergeser & teks muncul
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      setState(() {
        _isShifted = true;
      });
    }

    // 3. Detik 6.0: Pindah ke halaman Onboarding
    await Future.delayed(const Duration(milliseconds: 3000));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Latar belakang putih bersih (tanpa warna oranye)
      body: Center(
        child: AnimatedScale(
          scale: _isScaled ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutBack,
          child: Row(
            mainAxisSize: MainAxisSize.min, // Menjaga konten tetap di tengah layar
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center, // Perbaikan typo CrossAxisAlignment
            children: [
              // 1. LOGO GAMBAR (DIPERBESAR)
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

              // 2. WIDGET TEKS (Mengembang dari lebar 0 secara halus agar logo bergeser)
              AnimatedContainer(
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeInOutCubic,
                width: _isShifted ? 210 : 0, // Menggeser logo secara alami
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeIn,
                  opacity: _isShifted ? 1.0 : 0.0, // Fade In Teks
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4), // Jarak SANGAT MEPET dengan logo
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