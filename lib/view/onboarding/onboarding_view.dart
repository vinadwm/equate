import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:equate/viewmodel/theme_viewmodel.dart'; // Sesuaikan path jika berbeda
import 'package:equate/view/auth/login_view.dart';     // Sesuaikan path ke LoginView milikmu

// Model Data Onboarding
class OnboardingItem {
  final String title;
  final String description;
  final Widget illustration;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.illustration,
  });
}

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _nextIndex = 0;

  late AnimationController _animController;
  late Animation<double> _slideAnimation;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'Kalkulator Emas\nPresisi & Akurat',
      description: 'Hitung nilai investasi, zakat emas, dan potensi keuntungan portofolio emasmu secara instan.',
      illustration: const _GoldCalculatorIllustration(),
    ),
    OnboardingItem(
      title: 'Pantau Grafik &\nTren Harga Real-Time',
      description: 'Analisis pergerakan harga emas harian hingga tahunan dengan grafik interaktif yang mudah dibaca.',
      illustration: const _GoldChartIllustration(),
    ),
    OnboardingItem(
      title: 'Simulasi Keuntungan\n& Target Emas',
      description: 'Rencanakan target masa depanmu dan hitung estimasi nilai beli kembali (buyback) dengan akurat.',
      illustration: const _GoldSimulationIllustration(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _slideAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentIndex = _nextIndex;
        });
        _animController.reset();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _nextSlide() {
    if (_animController.isAnimating) return;

    if (_currentIndex < _items.length - 1) {
      setState(() {
        _nextIndex = _currentIndex + 1;
      });
      _animController.forward();
    } else {
      _finishOnboarding();
    }
  }

  // Navigasi Mengarah Langsung ke Halaman Login
  void _finishOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()), // Ganti LoginView sesuai nama class login kamu
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeViewModel.isDarkMode;
    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _nextSlide,
          child: Stack(
            children: [
              // 1. Layer Halaman Utama
              _buildPageContent(_items[_currentIndex]),

              // 2. Layer Slide Transisi Bergelombang (Liquid Slide)
              if (_animController.isAnimating)
                AnimatedBuilder(
                  animation: _slideAnimation,
                  builder: (context, child) {
                    return ClipPath(
                      clipper: WaveSlideClipper(progress: _slideAnimation.value),
                      child: Container(
                        color: bgColor,
                        child: _buildPageContent(_items[_nextIndex]),
                      ),
                    );
                  },
                ),

              // 3. Header Navigasi (Indikator & Skip)
              Positioned(
                top: 16,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Dot Indicator
                    Row(
                      children: List.generate(
                        _items.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 6),
                          height: 6,
                          width: _currentIndex == index ? 18 : 6,
                          decoration: BoxDecoration(
                            color: _currentIndex == index
                                ? const Color(0xFFFF9800)
                                : (isDarkMode ? Colors.grey[800] : Colors.grey[300]),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),

                    // Tombol Lewati -> Berpindah ke Login
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        'Lewati',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Layout Tata Letak: Judul di Atas Animasi
  Widget _buildPageContent(OnboardingItem item) {
    final isDarkMode = ThemeViewModel.isDarkMode;
    final primaryTextColor = isDarkMode ? Colors.white : const Color(0xFF1F1F1F);
    final secondaryTextColor = isDarkMode ? Colors.grey[400]! : const Color(0xFF757575);

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 3),

          // 1. Teks Judul di Atas
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
              color: primaryTextColor,
            ),
          ),

          const Spacer(flex: 1),

          // 2. Area Animasi Lottie Besar di Tengah
          SizedBox(
            height: 340,
            child: Center(child: item.illustration),
          ),

          const Spacer(flex: 1),

          // 3. Teks Deskripsi di Bawah Animasi
          Text(
            item.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: secondaryTextColor,
              height: 1.5,
            ),
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

// =========================================================================
// CLIPPER ANIMASI TRANSISI SLIDE DENGAN GELOMBANG (LIQUID SLIDE)
// =========================================================================
class WaveSlideClipper extends CustomClipper<Path> {
  final double progress;

  WaveSlideClipper({required this.progress});

  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;

    double x = width * progress;

    path.moveTo(0, 0);
    path.lineTo(x, 0);

    path.cubicTo(
      x + (width * 0.25 * (1 - progress)),
      height * 0.3,
      x - (width * 0.25 * (1 - progress)),
      height * 0.7,
      x,
      height,
    );

    path.lineTo(0, height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant WaveSlideClipper oldClipper) => true;
}

// =========================================================================
// CUSTOM PAINTER MULTI-BLOB (BACKGROUND ORGANIK ABU MUDA/SOFT)
// =========================================================================
class RichMultiBlobPainter extends CustomPainter {
  final Color baseColor;

  RichMultiBlobPainter({required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Layer 1: Soft Large Background Blob
    final paint1 = Paint()
      ..color = baseColor.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(w * 0.1, h * 0.2);
    path1.cubicTo(w * 0.5, -h * 0.05, w * 1.05, h * 0.15, w * 0.9, h * 0.6);
    path1.cubicTo(w * 0.8, h * 0.95, w * 0.2, h * 1.05, -w * 0.05, h * 0.7);
    path1.cubicTo(-w * 0.1, h * 0.4, -w * 0.05, h * 0.3, w * 0.1, h * 0.2);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Layer 2: Blob Tambahan di Sudut Kanan Atas
    final paint2 = Paint()
      ..color = baseColor.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(w * 0.5, h * 0.1);
    path2.cubicTo(w * 0.8, h * 0.0, w * 1.0, h * 0.2, w * 0.95, h * 0.45);
    path2.cubicTo(w * 0.85, h * 0.6, w * 0.6, h * 0.5, w * 0.5, h * 0.35);
    path2.cubicTo(w * 0.4, h * 0.25, w * 0.35, h * 0.15, w * 0.5, h * 0.1);
    path2.close();
    canvas.drawPath(path2, paint2);

    // Layer 3: Blob Tambahan di Kiri Bawah
    final paint3 = Paint()
      ..color = baseColor.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final path3 = Path();
    path3.moveTo(w * 0.05, h * 0.5);
    path3.cubicTo(w * 0.35, h * 0.45, w * 0.5, h * 0.75, w * 0.3, h * 0.9);
    path3.cubicTo(w * 0.15, h * 1.0, -w * 0.1, h * 0.85, -w * 0.02, h * 0.65);
    path3.close();
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =========================================================================
// WIDGET LOTTIE ANIMATIONS
// =========================================================================

// 1. Animasi Batang Emas (Kalkulator Emas)
class _GoldCalculatorIllustration extends StatelessWidget {
  const _GoldCalculatorIllustration();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeViewModel.isDarkMode;
    final blobColor = isDarkMode ? const Color(0xFF222222) : const Color(0xFFF3F4F6);

    return SizedBox(
      width: 340,
      height: 340,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  blobColor,
                  blobColor.withOpacity(0.0),
                ],
              ),
            ),
          ),
          CustomPaint(
            size: const Size(320, 320),
            painter: RichMultiBlobPainter(baseColor: blobColor),
          ),
          Lottie.asset(
            'assets/animations/little_sparkle.json',
            width: 320,
            height: 320,
            fit: BoxFit.contain,
          ),
          Lottie.asset(
            'assets/animations/gold_bar.json',
            width: 230,
            height: 230,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

// 2. Animasi Chart / Grafik
class _GoldChartIllustration extends StatelessWidget {
  const _GoldChartIllustration();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeViewModel.isDarkMode;
    final blobColor = isDarkMode ? const Color(0xFF222222) : const Color(0xFFF3F4F6);

    return SizedBox(
      width: 340,
      height: 340,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  blobColor,
                  blobColor.withOpacity(0.0),
                ],
              ),
            ),
          ),
          CustomPaint(
            size: const Size(320, 320),
            painter: RichMultiBlobPainter(baseColor: blobColor),
          ),
          Lottie.asset(
            'assets/animations/finance.json',
            width: 250,
            height: 250,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

// 3. Animasi Simulasi Keuntungan
class _GoldSimulationIllustration extends StatelessWidget {
  const _GoldSimulationIllustration();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeViewModel.isDarkMode;
    final blobColor = isDarkMode ? const Color(0xFF222222) : const Color(0xFFF3F4F6);

    return SizedBox(
      width: 340,
      height: 340,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  blobColor,
                  blobColor.withOpacity(0.0),
                ],
              ),
            ),
          ),
          CustomPaint(
            size: const Size(320, 320),
            painter: RichMultiBlobPainter(baseColor: blobColor),
          ),
          Lottie.asset(
            'assets/animations/little_sparkle.json',
            width: 260,
            height: 260,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}