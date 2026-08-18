import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:equate/view/auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 🎯 MASUKKAN GAMBAR KAMU DAN TEKS DI SINI
  final List<Map<String, String>> _onboardingData = [
    {
      'titleHighlight': 'Stay Organized',
      'titleNormal': 'With Our Team',
      'subtitle':
          'Understand the contributions our colleagues make to our team.',
      'image': 'assets/images/logo.png', // Ganti dengan path gambar kamu 1
    },
    {
      'titleHighlight': 'Gold & Pivot',
      'titleNormal': 'Analysis Strategy',
      'subtitle':
          'Pantau pergerakan harga emas dan analisis titik pivot dengan presisi tinggi.',
      'image': 'assets/images/logo.png', // Ganti dengan path gambar kamu 2
    },
    {
      'titleHighlight': 'Maximize Your',
      'titleNormal': 'Trading Potential',
      'subtitle':
          'Dapatkan wawasan pasar secara otomatis untuk keputusan investasi yang lebih cerdas.',
      'image': 'assets/images/logo.png', // Ganti dengan path gambar kamu 3
    },
  ];

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // 🎯 AKSI SAAT SLIDE TERAKHIR SELESAI (Pindah Halaman)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // ==========================================
            // 1. TOMBOL SKIP (Pojok Kanan Atas)
            // ==========================================
            Positioned(
              top: 16,
              right: 24,
              child: TextButton(
                onPressed: () {
                  // Aksi skip langsung ke halaman utama/login
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginView()),
                  );
                },
                child: Text(
                  'Skip',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),

            // ==========================================
            // 2. CAROUSEL CONTENT (Judul + Gambar)
            // ==========================================
            Column(
              children: [
                const SizedBox(height: 60),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _onboardingData.length,
                    itemBuilder: (context, index) {
                      final item = _onboardingData[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Judul dua warna (Highlight Orange & Normal)
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${item['titleHighlight']}\n',
                                    style: TextStyle(
                                      color: Colors
                                          .amber[800], // Warna Oranye/Emas
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(
                                    text: item['titleNormal'],
                                    style: const TextStyle(
                                      color: Color(0xFF1A1A1A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 30,
                                height: 1.25,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Subtitle
                            Text(
                              item['subtitle']!,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                                height: 1.5,
                              ),
                            ),

                            const Spacer(),

                            // 🎯 GAMBAR KAMU SENDIRI
                            Center(
                              child: Container(
                                height: 260,
                                width: double.infinity,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(
                                    0xFFFFF8ED,
                                  ), // Accent Lingkaran Latar belakang
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Image.asset(
                                    item['image']!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.image_outlined,
                                        size: 100,
                                        color: Colors.amber[800],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),

                            const Spacer(),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 80), // Ruang untuk Bottom Bar
              ],
            ),

            // ==========================================
            // 3. INDIKATOR TITIK (Pojok Kiri Bawah)
            // ==========================================
            Positioned(
              bottom: 36,
              left: 28,
              child: Row(
                children: List.generate(
                  _onboardingData.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 6.0),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? const Color(0xFF1A1A1A)
                          : Colors.amber[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // ==========================================
            // 4. TOMBOL PANAH LENGKUNG (Pojok Kanan Bawah)
            // ==========================================
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _nextPage,
                child: CustomPaint(
                  size: const Size(110, 110),
                  painter: CurvedCornerPainter(),
                  child: SizedBox(
                    width: 110,
                    height: 110,
                    child: Align(
                      alignment: const Alignment(0.4, 0.4),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber[800],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Painter Custom untuk membuat latar hitam melengkung di pojok kanan bawah
class CurvedCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width, 0);
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.2, 0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
