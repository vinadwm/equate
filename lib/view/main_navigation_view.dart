import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:equate/viewmodel/theme_viewmodel.dart';
import 'tabs/home_tab_view.dart';
import 'tabs/calculator_tab_view.dart';
import 'tabs/profile_tab_view.dart';
import 'package:equate/viewmodel/historical_data_viewmodel.dart';

class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  int _currentIndex = 0;

  final GlobalKey<HomeTabViewState> _homeKey = GlobalKey<HomeTabViewState>();

  final HistoricalDataViewModel _historicalDataViewModel =
      HistoricalDataViewModel();

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();

    _tabs = [
      HomeTabView(
        key: _homeKey,
        historicalDataViewModel: _historicalDataViewModel,
      ),
      const ProfileTabView(),
    ];
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
          // FLOATING NAVBAR — GLASSMORPHISM iOS VIBES
          // ======================================================
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeViewModel.themeMode,
            builder: (context, currentThemeMode, child) {
              final isDarkMode = ThemeViewModel.isDarkMode;

              const primaryOrange = Color(0xFFFF9500);
              const secondaryOrange = Color(0xFFFFB700);

              // Glass fill & border, senada dengan Home tab.
              final navGlassFill = isDarkMode
                  ? Colors.white.withOpacity(0.06)
                  : Colors.white.withOpacity(0.55);

              final navGlassBorder = isDarkMode
                  ? Colors.white.withOpacity(0.12)
                  : Colors.white.withOpacity(0.75);

              final defaultGreyColor = isDarkMode
                  ? const Color(0xFFA0A0A0)
                  : const Color(0xFF9E9E9E);

              final activeColor = primaryOrange;

              return Positioned(
                left: 60,
                right: 60,
                bottom: 20,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: Container(
                      height: 68,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: navGlassFill,
                        borderRadius: BorderRadius.circular(35),
                        border: Border.all(color: navGlassBorder, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: primaryOrange.withOpacity(
                              isDarkMode ? 0.12 : 0.10,
                            ),
                            blurRadius: 26,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDarkMode ? 0.35 : 0.06,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
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
                            isDarkMode: isDarkMode,
                          ),

                          // ==================================================
                          // CALCULATOR (FAB gradasi oranye)
                          // ==================================================
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CalculatorTabView(
                                    historicalDataViewModel:
                                        _historicalDataViewModel,
                                  ),
                                ),
                              );
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [secondaryOrange, primaryOrange],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(
                                    isDarkMode ? 0.15 : 0.6,
                                  ),
                                  width: 1.5,
                                ),
                                // Glow dikurangi supaya tidak terlalu
                                // mencolok dibanding navbar-nya sendiri.
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryOrange.withOpacity(0.22),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
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
                            isDarkMode: isDarkMode,
                          ),
                        ],
                      ),
                    ),
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
  // NAV ITEM (dengan pill highlight gradasi oranye tipis saat aktif)
  // ============================================================

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required Color activeColor,
    required Color inactiveColor,
    required bool isDarkMode,
  }) {
    final isSelected = _currentIndex == index;

    final itemColor = isSelected ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: () {
        _changeTab(index);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 58,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: itemColor,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  key: ValueKey(isSelected),
                  size: 22,
                  color: itemColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
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