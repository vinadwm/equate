import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tabs/home_tab_view.dart';
import 'tabs/calculator_tab_view.dart';
import 'tabs/profile_tab_view.dart';

class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    HomeTabView(),
    CalculatorTabView(),
    ProfileTabView(),
  ];

  @override
  Widget build(BuildContext context) {
    const defaultGreyColor = Color(0xFF9E9E9E); // Abu-abu konstan

    return Scaffold(
      body: Stack(
        children: [
          // Content Halaman
          _tabs[_currentIndex],

          // Floating Navbar Utama
          Positioned(
            left: 70,  // Nilai lebih besar membuat navbar lebih ramping horizontal
            right: 70, // Nilai lebih besar membuat navbar lebih ramping horizontal
            bottom: 20,
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 1. HOME TAB
                  _buildNavItem(
                    index: 0,
                    label: 'Beranda',
                    activeIcon: Icons.home_rounded,
                    inactiveIcon: Icons.home_outlined,
                    color: defaultGreyColor,
                  ),

                  // 2. CALCULATOR TAB (Icon Presisi & Tebal)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentIndex = 1;
                      });
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF9800), // Background Oranye
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: CustomPaint(
                          size: const Size(18, 18),
                          painter: MathSymbolsPainter(),
                        ),
                      ),
                    ),
                  ),

                  // 3. PROFILE TAB
                  _buildNavItem(
                    index: 2,
                    label: 'Profil',
                    activeIcon: Icons.person_rounded,
                    inactiveIcon: Icons.person_outline_rounded,
                    color: defaultGreyColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required Color color,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 55, // Kunci lebar item agar tetap presisi di tengah
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              size: 22,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter untuk Menggambar Simbol + - x = Tebal & Presisi
class MathSymbolsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // --- 1. SIMBOL PLUS (+) [Pojok Kiri Atas] ---
    canvas.drawLine(Offset(0, h * 0.22), Offset(w * 0.38, h * 0.22), paint);
    canvas.drawLine(Offset(w * 0.19, 0), Offset(w * 0.19, h * 0.44), paint);

    // --- 2. SIMBOL MINUS (-) [Pojok Kanan Atas] ---
    canvas.drawLine(Offset(w * 0.62, h * 0.22), Offset(w, h * 0.22), paint);

    // --- 3. SIMBOL KALI (X) [Pojok Kiri Bawah] ---
    canvas.drawLine(Offset(0, h * 0.6), Offset(w * 0.38, h * 0.98), paint);
    canvas.drawLine(Offset(0, h * 0.98), Offset(w * 0.38, h * 0.6), paint);

    // --- 4. SIMBOL SAMA DENGAN (=) [Pojok Kanan Bawah] ---
    canvas.drawLine(Offset(w * 0.62, h * 0.68), Offset(w, h * 0.68), paint);
    canvas.drawLine(Offset(w * 0.62, h * 0.90), Offset(w, h * 0.90), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}