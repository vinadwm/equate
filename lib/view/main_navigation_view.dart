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

  // ============================================================
  // KEY UNTUK HOME
  // ============================================================

  final GlobalKey<HomeTabViewState> _homeKey = GlobalKey<HomeTabViewState>();

  // ============================================================
  // TABS
  // ============================================================

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();

    _tabs = [HomeTabView(key: _homeKey), const ProfileTabView()];
  }

  // ============================================================
  // GANTI TAB
  // ============================================================

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });

    // ==========================================================
    // JIKA KEMBALI KE HOME
    // MAKA AMBIL DATA USER TERBARU DARI FIRESTORE
    // ==========================================================

    if (index == 0) {
      _homeKey.currentState?.refreshUser();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ======================================================
          // CONTENT HALAMAN
          // ======================================================
          IndexedStack(index: _currentIndex, children: _tabs),

          // ======================================================
          // FLOATING NAVBAR
          // ======================================================
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
                      // ==================================================
                      // HOME
                      // ==================================================
                      _buildNavItem(
                        index: 0,
                        label: 'Beranda',
                        activeIcon: Icons.home_rounded,
                        inactiveIcon: Icons.home_outlined,
                        activeColor: activeColor,
                        inactiveColor: defaultGreyColor,
                      ),

                      // ==================================================
                      // CALCULATOR
                      // ==================================================
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

                      // ==================================================
                      // PROFILE
                      // ==================================================
                      _buildNavItem(
                        index: 1,
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

  // ============================================================
  // NAV ITEM
  // ============================================================

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
        _changeTab(index);
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

// ============================================================
// MATH SYMBOL PAINTER
// ============================================================

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

    // PLUS
    canvas.drawLine(Offset(0, h * 0.22), Offset(w * 0.38, h * 0.22), paint);

    canvas.drawLine(Offset(w * 0.19, 0), Offset(w * 0.19, h * 0.44), paint);

    // MINUS
    canvas.drawLine(Offset(w * 0.62, h * 0.22), Offset(w, h * 0.22), paint);

    // KALI
    canvas.drawLine(Offset(0, h * 0.6), Offset(w * 0.38, h * 0.98), paint);

    canvas.drawLine(Offset(0, h * 0.98), Offset(w * 0.38, h * 0.6), paint);

    // SAMA DENGAN
    canvas.drawLine(Offset(w * 0.62, h * 0.68), Offset(w, h * 0.68), paint);

    canvas.drawLine(Offset(w * 0.62, h * 0.90), Offset(w, h * 0.90), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
