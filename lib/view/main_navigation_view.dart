import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:equate/viewmodel/theme_viewmodel.dart';
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

  final List<Widget> _tabs = const [HomeTabView(), ProfileTabView()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Content Halaman (Menggunakan Safe Indexing)
          IndexedStack(
            index: _currentIndex > 1 ? 0 : _currentIndex,
            children: _tabs,
          ),

          // Floating Navbar Utama
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeViewModel.themeMode,
            builder: (context, currentThemeMode, child) {
              final isDarkMode = ThemeViewModel.isDarkMode;

              final navBgColor = isDarkMode
                  ? const Color(0xFF1E1E1E)
                  : Colors.white;
              final navBorderColor = isDarkMode
                  ? Colors.grey[800]!
                  : Colors.transparent;
              final defaultGreyColor = isDarkMode
                  ? const Color(0xFFA0A0A0)
                  : const Color(0xFF9E9E9E);
              final activeColor = isDarkMode
                  ? const Color(0xFFFF9800)
                  : defaultGreyColor;

              return Positioned(
                left: 70,
                right: 70,
                bottom: 20,
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: navBgColor,
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(color: navBorderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          isDarkMode ? 0.3 : 0.08,
                        ),
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
                        activeColor: activeColor,
                        inactiveColor: defaultGreyColor,
                      ),

                      // 2. CALCULATOR BUTTON (BUKA HALAMAN BARU TANPA NAVBAR)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CalculatorTabView(),
                            ),
                          );
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF9800),
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
                        index: 1, // Index disesuaikan menjadi 1
                        label: 'Profil',
                        activeIcon: Icons.person_rounded,
                        inactiveIcon: Icons.person_outline_rounded,
                        activeColor: activeColor,
                        inactiveColor: defaultGreyColor,
                      ),
                    ],
                  ),
                ),
              );
            },
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
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final isSelected = _currentIndex == index;
    final itemColor = isSelected ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 55,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              size: 22,
              color: itemColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: itemColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

    // --- 1. SIMBOL PLUS (+) ---
    canvas.drawLine(Offset(0, h * 0.22), Offset(w * 0.38, h * 0.22), paint);
    canvas.drawLine(Offset(w * 0.19, 0), Offset(w * 0.19, h * 0.44), paint);

    // --- 2. SIMBOL MINUS (-) ---
    canvas.drawLine(Offset(w * 0.62, h * 0.22), Offset(w, h * 0.22), paint);

    // --- 3. SIMBOL KALI (X) ---
    canvas.drawLine(Offset(0, h * 0.6), Offset(w * 0.38, h * 0.98), paint);
    canvas.drawLine(Offset(0, h * 0.98), Offset(w * 0.38, h * 0.6), paint);

    // --- 4. SIMBOL SAMA DENGAN (=) ---
    canvas.drawLine(Offset(w * 0.62, h * 0.68), Offset(w, h * 0.68), paint);
    canvas.drawLine(Offset(w * 0.62, h * 0.90), Offset(w, h * 0.90), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
