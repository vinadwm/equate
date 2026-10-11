import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:equate/view/auth/auth_glass_widgets.dart';
import 'package:equate/view/help/help_widgets.dart';
import 'package:equate/viewmodel/historical_data_viewmodel.dart';
import 'package:equate/viewmodel/language_viewmodel.dart';

import 'tabs/calculator_tab_view.dart';
import 'tabs/home_tab_view.dart';
import 'tabs/news_tab_view.dart';
import 'tabs/profile_tab_view.dart';

class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  /// Index tab aktif. Bisa diubah dari halaman mana pun.
  static final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  final GlobalKey<HomeTabViewState> _homeKey = GlobalKey<HomeTabViewState>();

  final HistoricalDataViewModel _historicalDataViewModel =
      HistoricalDataViewModel();

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();

    MainNavigationView.tabIndex.value = 0;
    MainNavigationView.tabIndex.addListener(_onTabChanged);

    _tabs = [
      HomeTabView(
        key: _homeKey,
        historicalDataViewModel: _historicalDataViewModel,
      ),
      const NewsTabView(),
      const ProfileTabView(),
    ];
  }

  @override
  void dispose() {
    MainNavigationView.tabIndex.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (MainNavigationView.tabIndex.value == 0) {
      _homeKey.currentState?.refreshUser();
    }
  }

  void _openCalculator() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalculatorTabView(
          historicalDataViewModel: _historicalDataViewModel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeLang(
      builder: (context, isDark, t) {
        return ValueListenableBuilder<int>(
          valueListenable: MainNavigationView.tabIndex,
          builder: (context, index, _) {
            final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

            return Scaffold(
              backgroundColor: isDark ? const Color(0xFF0D0E12) : Colors.white,
              body: Stack(
                children: [
                  IndexedStack(index: index, children: _tabs),

                  if (!keyboardOpen)
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 18,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: _buildGlassBar(index, isDark, t)),
                          const SizedBox(width: 12),
                          _buildCalculatorButton(isDark),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // BAR KACA: Beranda, Berita, Profil
  // Jarak kiri/kanan/atas/bawah antara bar dan pil oranye dibuat
  // sama (6px), dan pil aktif selalu mengisi lebar jatahnya.
  // ============================================================
  Widget _buildGlassBar(int index, bool isDark, AuthTokens t) {
    final items = [
      (Icons.home_rounded, Icons.home_outlined, tr('Beranda', 'Home')),
      (Icons.newspaper_rounded, Icons.newspaper_outlined, tr('Berita', 'News')),
      (
        Icons.person_rounded,
        Icons.person_outline_rounded,
        tr('Profil', 'Profile'),
      ),
    ];

    const double barHeight = 66;
    const double gap = 6;
    const double selectedFlex = 1.8;

    return Container(
      height: barHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(barHeight / 2),
        boxShadow: [
          BoxShadow(
            color: kAuthOrange.withOpacity(isDark ? 0.12 : 0.10),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(barHeight / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            padding: const EdgeInsets.all(gap),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(barHeight / 2),
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.white.withOpacity(0.62),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.12)
                    : Colors.white.withOpacity(0.75),
                width: 1,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final unit =
                    constraints.maxWidth / (items.length - 1 + selectedFlex);

                return Row(
                  children: List.generate(items.length, (i) {
                    final selected = index == i;
                    final item = items[i];

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => MainNavigationView.tabIndex.value = i,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        width: unit * (selected ? selectedFlex : 1),
                        height: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            (barHeight - gap * 2 - 2) / 2,
                          ),
                          gradient: selected
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    kAuthOrangeSoft,
                                    kAuthOrange,
                                    kAuthOrangeDeep,
                                  ],
                                )
                              : null,
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: kAuthOrange.withOpacity(0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  selected ? item.$1 : item.$2,
                                  size: 22,
                                  color: selected
                                      ? Colors.white
                                      : t.textSecondary,
                                ),
                                if (selected) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    item.$3,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOMBOL KALKULATOR (bulat oranye, terpisah dari bar)
  // ============================================================
  Widget _buildCalculatorButton(bool isDark) {
    return GestureDetector(
      onTap: _openCalculator,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kAuthOrangeSoft, kAuthOrange, kAuthOrangeDeep],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(isDark ? 0.25 : 0.7),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: kAuthOrange.withOpacity(0.42),
              blurRadius: 22,
              spreadRadius: -2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: CustomPaint(
            size: const Size(24, 24),
            painter: MathSymbolsPainter(),
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
      ..strokeWidth = 2.2
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}