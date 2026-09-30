import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:equate/viewmodel/theme_viewmodel.dart';
import 'package:equate/view/auth/login_view.dart';
import 'package:equate/view/auth/signup_view.dart' show SignUpForm;
import 'package:equate/view/auth/auth_glass_widgets.dart'
    show
        AuthGlassBackground,
        AuthTokens,
        kAuthOrange,
        kAuthOrangeSoft,
        kAuthOrangeDeep;

// ================================================================
// ONBOARDING
//  - Slide 1 : intro ala referensi. Panel oranye kecil di bawah
//              menyatu dengan latar slide 2. Panah ke ATAS -> geser VERTIKAL.
//  - Slide 2 : kalkulator emas (oranye penuh, kartu 3D)
//  - Slide 3 : tren harga. Tombol panah memanjang jadi "Masuk",
//              di bawahnya tombol transparan "Daftar akun".
//              Slide 2 -> 3 geser HORIZONTAL.
// ================================================================
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView>
    with SingleTickerProviderStateMixin {
  final PageController _outer = PageController(); // vertikal: intro | (2 & 3)
  final PageController _inner = PageController(); // horizontal: slide 2 | 3
  late final AnimationController _float;

  double get _outerP => _outer.hasClients ? (_outer.page ?? 0.0) : 0.0;
  double get _innerP => _inner.hasClients ? (_inner.page ?? 0.0) : 0.0;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _float.dispose();
    _outer.dispose();
    _inner.dispose();
    super.dispose();
  }

  int get _index => (_outerP.clamp(0.0, 1.0) + _innerP.clamp(0.0, 1.0)).round();

  void _next() {
    final i = _index;
    if (i == 0) {
      if (_inner.hasClients) _inner.jumpToPage(0);
      _outer.animateToPage(
        1,
        duration: const Duration(milliseconds: 720),
        curve: Curves.easeInOutCubic,
      );
    } else if (i == 1) {
      _inner.animateToPage(
        1,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    } else {
      _openLogin(); // slide terakhir: tombol panjang = "Masuk"
    }
  }

  Future<void> _skip() async {
    if (_outerP < 0.99) {
      await _outer.animateToPage(
        1,
        duration: const Duration(milliseconds: 620),
        curve: Curves.easeInOutCubic,
      );
    }
    if (!mounted) return;
    if (_inner.hasClients) {
      _inner.animateToPage(
        1,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _openLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  void _openSignup() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const _SignUpPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeViewModel.themeMode,
      builder: (context, _, __) {
        final p = _Palette(ThemeViewModel.isDarkMode);
        final pillW = MediaQuery.of(context).size.width - 48;

        return Scaffold(
          backgroundColor: p.bg,
          body: AnimatedBuilder(
            animation: Listenable.merge([_outer, _inner]),
            builder: (context, _) {
              final outerP = _outerP.clamp(0.0, 1.0);
              final innerP = _innerP.clamp(0.0, 1.0);
              final t = outerP + innerP; // 0..2
              final m = (t - 1).clamp(0.0, 1.0); // 0..1 menuju slide terakhir
              final lockOuter = innerP > 0.5; // di slide 3 kunci geser vertikal

              final skipOpacity = (1.6 - t).clamp(0.0, 1.0);

              return Stack(
                fit: StackFit.expand,
                children: [
                  // ------------------------------------------------
                  // HALAMAN
                  // ------------------------------------------------
                  PageView(
                    controller: _outer,
                    scrollDirection: Axis.vertical,
                    physics: lockOuter
                        ? const NeverScrollableScrollPhysics()
                        : const PageScrollPhysics(),
                    children: [
                      _IntroSlide(p: p, progress: outerP, float: _float),
                      PageView(
                        controller: _inner,
                        physics: const PageScrollPhysics(),
                        children: [
                          _CalcSlide(
                            p: p,
                            delta: innerP,
                            enter: outerP,
                            float: _float,
                          ),
                          _TrendSlide(p: p, delta: innerP - 1),
                        ],
                      ),
                    ],
                  ),

                  // ------------------------------------------------
                  // OVERLAY ATAS: titik tiga (kiri) + lewati (kanan)
                  // Tanpa frame / background.
                  // ------------------------------------------------
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                        child: Row(
                          children: [
                            _Dots(t: t, p: p),
                            const Spacer(),
                            IgnorePointer(
                              ignoring: skipOpacity < 0.5,
                              child: Opacity(
                                opacity: skipOpacity,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _skip,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 6,
                                    ),
                                    child: Text(
                                      'Lewati',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: p.ink.withOpacity(0.7),
                                      ),
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

                  // ------------------------------------------------
                  // OVERLAY BAWAH: tombol panah -> memanjang jadi "Masuk"
                  // + tombol transparan "Daftar akun" di slide terakhir
                  // ------------------------------------------------
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _NavOrb(
                              t: t,
                              p: p,
                              pillWidth: pillW,
                              onTap: _next,
                            ),
                            ClipRect(
                              child: Align(
                                alignment: Alignment.topCenter,
                                heightFactor: m,
                                child: IgnorePointer(
                                  ignoring: m < 0.5,
                                  child: Opacity(
                                    opacity: m,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: _GhostButton(
                                        p: p,
                                        label: 'Daftar akun',
                                        width: pillW,
                                        onTap: _openSignup,
                                      ),
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
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ================================================================
// HALAMAN DAFTAR (pembungkus untuk SignUpForm)
// ================================================================
class _SignUpPage extends StatelessWidget {
  const _SignUpPage();

  void _goToLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (ctx) => const LoginView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeViewModel.themeMode,
      builder: (context, _, __) {
        final t = AuthTokens(ThemeViewModel.isDarkMode);

        return Scaffold(
          backgroundColor: t.pageBackground,
          body: AuthGlassBackground(
            t: t,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: SignUpForm(
                  t: t,
                  onGoToLogin: () => _goToLogin(context),
                  onSignedUp: () => _goToLogin(context),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ================================================================
// PALET WARNA BERDASARKAN TEMA
// ================================================================
class _Palette {
  final bool isDark;
  const _Palette(this.isDark);

  Color get bg => isDark ? const Color(0xFF07080B) : const Color(0xFFFBF7F2);
  Color get ink => isDark ? Colors.white : const Color(0xFF111114);
  Color get sub => isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B6B72);
  Color get glass =>
      isDark ? Colors.white.withOpacity(0.07) : Colors.white.withOpacity(0.62);
  Color get glassBorder =>
      isDark ? Colors.white.withOpacity(0.13) : Colors.white.withOpacity(0.9);
  Color get solidCard => isDark ? const Color(0xFF1B1C21) : Colors.white;
}

Widget _bob(Animation<double> a, double phase, double amp, Widget child) {
  return AnimatedBuilder(
    animation: a,
    child: child,
    builder: (_, c) => Transform.translate(
      offset: Offset(0, math.sin((a.value + phase) * 2 * math.pi) * amp),
      child: c,
    ),
  );
}

// ================================================================
// SLIDE 1 — INTRO (gaya referensi)
// ================================================================
class _IntroSlide extends StatelessWidget {
  final _Palette p;
  final double progress; // 0..1 (seberapa jauh sudah digeser ke atas)
  final Animation<double> float;

  const _IntroSlide({
    required this.p,
    required this.progress,
    required this.float,
  });

  Widget _orb(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).padding.bottom;

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final drift = -progress * 70;
        final fade = (1 - progress * 0.7).clamp(0.0, 1.0);
        final o = p.isDark ? 0.78 : 0.95;

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(child: ColoredBox(color: p.bg)),

            // ---------- ORB BLUR BESAR ----------
            Positioned.fill(
              child: RepaintBoundary(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: 42,
                    sigmaY: 42,
                    tileMode: TileMode.decal,
                  ),
                  child: Transform.translate(
                    offset: Offset(0, drift * 0.6),
                    child: Stack(
                      children: [
                        Positioned(
                          left: -w * 0.28,
                          top: h * 0.02,
                          child: _orb(w * 0.9, kAuthOrange, o),
                        ),
                        Positioned(
                          right: -w * 0.18,
                          top: -h * 0.06,
                          child: _orb(w * 0.5, kAuthOrangeDeep, o),
                        ),
                        Positioned(
                          right: -w * 0.28,
                          top: h * 0.38,
                          child: _orb(w * 0.6, kAuthOrangeSoft, o),
                        ),
                        Positioned(
                          left: w * 0.05,
                          top: h * 0.40,
                          child: _orb(w * 0.45, kAuthOrange, o * 0.9),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ---------- FADE KE LATAR DI BAWAH ----------
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.50, 0.70],
                      colors: [
                        p.bg.withOpacity(0),
                        p.bg.withOpacity(0),
                        p.bg,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ---------- PANEL ORANYE KECIL: sambungan ke slide 2 ----------
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 84 + inset,
              child: _PeekPanel(isDark: p.isDark),
            ),

            // ---------- KARTU-KARTU MIRING ----------
            Positioned.fill(
              child: Opacity(
                opacity: fade,
                child: Transform.translate(
                  offset: Offset(0, drift),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // putih (di belakang)
                      Positioned(
                        right: -52,
                        top: h * 0.185,
                        child: _bob(
                          float,
                          0.30,
                          5,
                          Transform.rotate(
                            angle: -0.26,
                            child: _WhiteStatCard(
                              p: p,
                              value: '24/7',
                              label: 'Real-time',
                              alignEnd: false,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -58,
                        top: h * 0.365,
                        child: _bob(
                          float,
                          0.65,
                          6,
                          Transform.rotate(
                            angle: -0.26,
                            child: _WhiteStatCard(
                              p: p,
                              value: '100%',
                              label: 'Akurat',
                              alignEnd: true,
                            ),
                          ),
                        ),
                      ),
                      // kaca (di depan)
                      Positioned(
                        left: w * 0.20,
                        top: h * 0.215,
                        child: _bob(
                          float,
                          0.0,
                          7,
                          Transform.rotate(
                            angle: -0.52,
                            child: const _GlassStatCard(
                              value: '+3',
                              label: 'Kalkulator',
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: w * 0.36,
                        top: h * 0.325,
                        child: _bob(
                          float,
                          0.45,
                          8,
                          Transform.rotate(
                            angle: -0.80,
                            child: const _GlassStatCard(
                              value: '24K',
                              label: 'Emas Antam',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ---------- TEKS ----------
            Positioned(
              left: 28,
              right: 28,
              bottom: 150 + inset,
              child: Opacity(
                opacity: fade,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pantau',
                      style: GoogleFonts.poppins(
                        fontSize: 54,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                        letterSpacing: -1.6,
                        color: p.ink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Sebuah',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: p.sub,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _TagChip(p: p, text: '# ringkasan'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'dari',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: p.sub,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _TagChip(p: p, text: '# investasi emasmu', hatch: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Panel oranye kecil di dasar slide 1. Warna paling bawahnya sama persis
/// dengan warna paling atas slide 2, sehingga saat digeser keduanya tampak
/// satu permukaan yang menyambung (titik-titik pun disejajarkan dari
/// garis sambungan).
class _PeekPanel extends StatelessWidget {
  final bool isDark;
  const _PeekPanel({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF2E170A), const Color(0xFF1C0D05)]
                    : [kAuthOrangeSoft, kAuthOrange],
              ),
            ),
          ),
          CustomPaint(
            painter: _DotGridPainter(
              Colors.white.withOpacity(isDark ? 0.07 : 0.16),
              0,
              fromBottom: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassStatCard extends StatelessWidget {
  final String value;
  final String label;
  const _GlassStatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.34),
                Colors.white.withOpacity(0.10),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.45)),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _HatchPainter(Colors.white.withOpacity(0.22)),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: Colors.white.withOpacity(0.92),
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
}

class _WhiteStatCard extends StatelessWidget {
  final _Palette p;
  final String value;
  final String label;
  final bool alignEnd;

  const _WhiteStatCard({
    required this.p,
    required this.value,
    required this.label,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      height: 88,
      padding: EdgeInsets.only(left: alignEnd ? 0 : 26, right: alignEnd ? 26 : 0),
      decoration: BoxDecoration(
        color: p.solidCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(p.isDark ? 0.35 : 0.10),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              height: 1.1,
              color: p.ink,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: p.sub),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final _Palette p;
  final String text;
  final bool hatch;
  const _TagChip({required this.p, required this.text, this.hatch = false});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        color: p.ink.withOpacity(0.06),
        child: Stack(
          children: [
            if (hatch)
              Positioned.fill(
                child: CustomPaint(
                  painter: _HatchPainter(p.ink.withOpacity(0.10)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: p.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// SLIDE 2 — KALKULATOR (oranye penuh, kartu 3D, layout rata kiri)
// Gradasi vertikal: bagian atasnya menyambung dengan _PeekPanel.
// ================================================================
class _CalcSlide extends StatelessWidget {
  final _Palette p;
  final double delta; // 0 saat aktif, >0 saat bergeser ke kiri
  final double enter; // 0..1 saat masuk dari bawah
  final Animation<double> float;

  const _CalcSlide({
    required this.p,
    required this.delta,
    required this.enter,
    required this.float,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = p.isDark;
    final fade = (1 - delta.abs()).clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        // latar gradasi (atasnya = warna dasar _PeekPanel)
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [const Color(0xFF1C0D05), const Color(0xFF0B0605)]
                  : [kAuthOrange, kAuthOrangeDeep],
            ),
          ),
        ),
        // cahaya (diturunkan sedikit supaya sambungan dengan panel mulus)
        Positioned(
          top: 30,
          right: -90 - delta * 40,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (isDark ? kAuthOrange : Colors.white)
                      .withOpacity(isDark ? 0.45 : 0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // grid titik (sejajar dengan grid di _PeekPanel)
        Positioned.fill(
          child: CustomPaint(
            painter: _DotGridPainter(
              Colors.white.withOpacity(isDark ? 0.07 : 0.16),
              delta * 40,
            ),
          ),
        ),
        // watermark "Au"
        Positioned(
          right: -34 - delta * 90,
          top: 70,
          child: Text(
            'Au',
            style: GoogleFonts.poppins(
              fontSize: 300,
              fontWeight: FontWeight.w800,
              height: 1.0,
              color: Colors.white.withOpacity(isDark ? 0.04 : 0.13),
            ),
          ),
        ),

        SafeArea(
          child: Opacity(
            opacity: fade,
            child: Column(
              children: [
                const SizedBox(height: 60),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 44,
                          vertical: 26,
                        ),
                        child: Transform.translate(
                          offset: Offset(-delta * 50, 0),
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.0012)
                              ..rotateX(0.10)
                              ..rotateY(-0.28 + delta * 0.8),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const _CalcCard(),
                                Positioned(
                                  left: -40,
                                  top: 42,
                                  child: _bob(
                                    float,
                                    0.10,
                                    6,
                                    _FloatChip(
                                      isDark: isDark,
                                      icon: Icons.mosque_outlined,
                                      text: 'Zakat 2,5%',
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: -36,
                                  top: 150,
                                  child: _bob(
                                    float,
                                    0.55,
                                    7,
                                    _FloatChip(
                                      isDark: isDark,
                                      icon: Icons.sell_outlined,
                                      text: 'Buyback',
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 14,
                                  bottom: -22,
                                  child: _bob(
                                    float,
                                    0.80,
                                    5,
                                    _FloatChip(
                                      isDark: isDark,
                                      icon: Icons.trending_up_rounded,
                                      text: 'Profit +8%',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Transform.translate(
                    offset: Offset(-delta * 40, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 22,
                              height: 2,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'PRESISI SETIAP SAAT',
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.6,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.w400,
                              height: 1.2,
                              letterSpacing: -0.6,
                              color: Colors.white,
                            ),
                            children: [
                              const TextSpan(text: 'Kalkulator emas\nyang '),
                              TextSpan(
                                text: 'akurat',
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Hitung nilai investasi, zakat, dan potensi keuntungan portofolio emasmu secara instan.',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            height: 1.55,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 132),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CalcCard extends StatelessWidget {
  const _CalcCard();

  Widget _key(String k, bool active) {
    return Expanded(
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          k,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: active ? kAuthOrangeDeep : Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['7', '8', '9'],
      ['4', '5', '6'],
      ['1', '2', '3'],
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: 268,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.30),
                Colors.white.withOpacity(0.10),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.40)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Estimasi buyback',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  const Spacer(),
                  const _MiniPill('24K'),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Rp 12.480.000',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const _MiniPill('▲ 4,2% dari modal'),
              const SizedBox(height: 16),
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      for (int i = 0; i < row.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        _key(row[i], row[i] == '5'),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String text;
  const _MiniPill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _FloatChip extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String text;
  const _FloatChip({
    required this.isDark,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF22242A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: kAuthOrange),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF111114),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// SLIDE 3 — TREN HARGA (tombol Masuk / Daftar ada di overlay bawah)
// ================================================================
class _TrendSlide extends StatefulWidget {
  final _Palette p;
  final double delta; // 0 saat aktif, <0 saat masuk dari kanan

  const _TrendSlide({required this.p, required this.delta});

  @override
  State<_TrendSlide> createState() => _TrendSlideState();
}

class _TrendSlideState extends State<_TrendSlide> {
  static const _periods = ['1H', '1M', '1B', '1T'];
  static const _data = <List<double>>[
    [0.50, 0.46, 0.55, 0.52, 0.60, 0.57, 0.66, 0.62, 0.70, 0.74, 0.72, 0.80],
    [0.30, 0.38, 0.33, 0.50, 0.45, 0.58, 0.52, 0.66, 0.60, 0.78, 0.74, 0.90],
    [0.55, 0.42, 0.48, 0.30, 0.40, 0.52, 0.46, 0.64, 0.58, 0.72, 0.86, 0.80],
    [0.12, 0.20, 0.18, 0.30, 0.26, 0.40, 0.44, 0.52, 0.50, 0.68, 0.78, 0.92],
  ];
  int _selected = 2;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final delta = widget.delta;
    final progress = (1 - delta.abs()).clamp(0.0, 1.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: p.bg),
        // cincin radar
        Positioned(
          top: -70,
          right: -110 + delta * 60,
          child: CustomPaint(
            size: const Size(360, 360),
            painter:
                _RingsPainter(kAuthOrange.withOpacity(p.isDark ? 0.34 : 0.40)),
          ),
        ),
        // orb bawah
        Positioned(
          bottom: -120,
          left: -100,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  kAuthOrange.withOpacity(p.isDark ? 0.20 : 0.30),
                  kAuthOrange.withOpacity(0),
                ],
              ),
            ),
          ),
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Opacity(
              opacity: progress,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  _GlassChip(
                    p: p,
                    dense: true,
                    child: Text(
                      'DATA SELALU TERBARU',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: kAuthOrange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                        letterSpacing: -0.6,
                        color: p.ink,
                      ),
                      children: [
                        const TextSpan(text: 'Pantau tren harga\nsecara '),
                        TextSpan(
                          text: 'real-time',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                            color: kAuthOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Analisis pergerakan harga emas harian hingga tahunan lewat grafik yang mudah dibaca.',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      height: 1.55,
                      color: p.sub,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // kartu grafik
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      decoration: BoxDecoration(
                        color: p.glass,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: p.glassBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emas 24K · contoh ilustrasi',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: p.sub,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                'Rp 1.421.000',
                                style: GoogleFonts.poppins(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                  color: p.ink,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: kAuthOrange.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '▲ 2,1%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: kAuthOrange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // pilihan periode
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: p.ink.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: List.generate(_periods.length, (i) {
                                final on = i == _selected;
                                return Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => setState(() => _selected = i),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      height: 28,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(11),
                                        gradient: on
                                            ? LinearGradient(
                                                colors: [
                                                  kAuthOrange,
                                                  kAuthOrangeDeep,
                                                ],
                                              )
                                            : null,
                                      ),
                                      child: Text(
                                        _periods[i],
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: on ? Colors.white : p.sub,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: CustomPaint(
                              size: Size.infinite,
                              painter: _ChartPainter(
                                data: _data[_selected],
                                progress: progress,
                                line: kAuthOrange,
                                line2: kAuthOrangeSoft,
                                grid: p.ink.withOpacity(0.08),
                                dotCore: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ruang untuk tombol "Masuk" + "Daftar akun" (overlay)
                  const SizedBox(height: 164),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> data;
  final double progress;
  final Color line;
  final Color line2;
  final Color grid;
  final Color dotCore;

  _ChartPainter({
    required this.data,
    required this.progress,
    required this.line,
    required this.line2,
    required this.grid,
    required this.dotCore,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || data.length < 2) return;

    // grid
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (int i = 0; i < 4; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // titik-titik
    final n = data.length;
    final pts = <Offset>[
      for (int i = 0; i < n; i++)
        Offset(
          size.width * i / (n - 1),
          size.height * (1 - (0.08 + 0.84 * data[i])),
        ),
    ];

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < n; i++) {
      final a = pts[i - 1];
      final b = pts[i];
      final cx = (a.dx + b.dx) / 2;
      path.cubicTo(cx, a.dy, cx, b.dy, b.dx, b.dy);
    }

    final metric = path.computeMetrics().first;
    final len = metric.length * progress;
    if (len <= 0) return;

    final sub = metric.extractPath(0, len);
    final end = metric.getTangentForOffset(len)?.position ?? pts.first;

    // area di bawah garis
    final area = Path.from(sub)
      ..lineTo(end.dx, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [line.withOpacity(0.35), line.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // garis
    canvas.drawPath(
      sub,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(colors: [line2, line]).createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        ),
    );

    // garis vertikal putus-putus
    final dash = Paint()
      ..color = line.withOpacity(0.45)
      ..strokeWidth = 1;
    for (double y = end.dy; y < size.height; y += 6) {
      canvas.drawLine(
        Offset(end.dx, y),
        Offset(end.dx, math.min(y + 3, size.height)),
        dash,
      );
    }

    // titik akhir
    canvas.drawCircle(end, 12, Paint()..color = line.withOpacity(0.25));
    canvas.drawCircle(end, 6, Paint()..color = dotCore);
    canvas.drawCircle(
      end,
      6,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.progress != progress || old.data != data || old.line != line;
}

// ================================================================
// TOMBOL HITAM DENGAN PANAH
//  - slide 1 & 2 : bulat, 1 stroke kotak membulat yang terisi bertahap
//  - slide 3     : memanjang jadi pill "Masuk →", ring ikut membungkus
//  - saat ditekan: mengecil sedikit & stroke menebal
// ================================================================
class _NavOrb extends StatefulWidget {
  final double t; // 0..2
  final _Palette p;
  final double pillWidth; // lebar ring saat memanjang (slide terakhir)
  final VoidCallback onTap;

  const _NavOrb({
    required this.t,
    required this.p,
    required this.pillWidth,
    required this.onTap,
  });

  @override
  State<_NavOrb> createState() => _NavOrbState();
}

class _NavOrbState extends State<_NavOrb> {
  bool _down = false;

  void _setDown(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final ink = p.isDark ? Colors.white : const Color(0xFF0B0B0D);
    final onInk = p.isDark ? const Color(0xFF0B0B0D) : Colors.white;

    final t = widget.t.clamp(0.0, 2.0);
    final m = (t - 1).clamp(0.0, 1.0); // 0 = bulat, 1 = pill panjang

    // 0 = panah ke atas, 1 = miring kanan (45°), 2 = lurus ke kanan
    final angle = t * math.pi / 4;
    // slide 1 = 1/3, slide 2 = 2/3, slide 3 = penuh
    final progress = ((t + 1) / 3).clamp(0.0, 1.0);

    final ringW = 88 + (widget.pillWidth - 88) * m;
    final ringH = 88 - 14 * m;
    final coreW = 62 + ((widget.pillWidth - 18) - 62) * m;
    final coreH = 62 - 6 * m;
    final wrapH = 96 - 12 * m;
    final radiusFactor = 0.38 + 0.12 * m;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setDown(true),
      onTapUp: (_) => _setDown(false),
      onTapCancel: () => _setDown(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: SizedBox(
          width: ringW + 8,
          height: wrapH,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(ringW, ringH),
                painter: _OrbRingPainter(
                  progress: progress,
                  color: ink,
                  strokeWidth: _down ? 3.2 : 2.4,
                  radiusFactor: radiusFactor,
                ),
              ),
              Container(
                width: coreW,
                height: coreH,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: ink,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRect(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: m,
                            child: Opacity(
                              opacity: ((m - 0.3) / 0.7).clamp(0.0, 1.0),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Text(
                                  'Masuk',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                    color: onInk,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Transform.rotate(
                          angle: angle,
                          child: Icon(
                            Icons.arrow_upward_rounded,
                            size: 24,
                            color: onInk,
                          ),
                        ),
                      ],
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

class _OrbRingPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;
  final double strokeWidth;
  final double radiusFactor; // 0.38 = kotak membulat, 0.5 = pill penuh

  const _OrbRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.radiusFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.shortestSide * radiusFactor),
    );
    final path = Path()..addRRect(rrect);

    // track tipis (1 stroke)
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = color.withOpacity(0.25),
    );

    // bagian yang "terisi"
    final metric = path.computeMetrics().first;
    final filled = metric.extractPath(0, metric.length * progress);
    canvas.drawPath(
      filled,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbRingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.radiusFactor != radiusFactor;
}

// ================================================================
// TOMBOL TRANSPARAN (Daftar akun)
// ================================================================
class _GhostButton extends StatelessWidget {
  final _Palette p;
  final String label;
  final double width;
  final VoidCallback onTap;

  const _GhostButton({
    required this.p,
    required this.label,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 50,
      child: Material(
        color: Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(color: p.ink.withOpacity(0.28), width: 1.2),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          splashColor: kAuthOrange.withOpacity(0.15),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: p.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// INDIKATOR TITIK TIGA (polos, tanpa frame / background)
// Titik aktif memakai warna teks utama supaya tetap terlihat di
// atas latar oranye slide 2.
// ================================================================
class _Dots extends StatelessWidget {
  final double t;
  final _Palette p;
  const _Dots({required this.t, required this.p});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final a = (1 - (t - i).abs()).clamp(0.0, 1.0);
        return Container(
          margin: const EdgeInsets.only(right: 6),
          height: 6,
          width: 6 + 14 * a,
          decoration: BoxDecoration(
            color: Color.lerp(p.ink.withOpacity(0.28), p.ink, a),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ================================================================
// CHIP KACA (dipakai untuk caption di slide 3)
// ================================================================
class _GlassChip extends StatelessWidget {
  final _Palette p;
  final Widget child;
  final bool dense;
  final VoidCallback? onTap;

  const _GlassChip({
    required this.p,
    required this.child,
    this.dense = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 14 : 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: p.glass,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: p.glassBorder),
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

// ================================================================
// PAINTER: arsir diagonal, grid titik, cincin radar
// ================================================================
class _HatchPainter extends CustomPainter {
  final Color color;
  const _HatchPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.8;
    const gap = 6.0;
    for (double x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HatchPainter old) => old.color != color;
}

class _DotGridPainter extends CustomPainter {
  final Color color;
  final double shift;

  /// true  : baris titik dihitung dari tepi bawah (untuk _PeekPanel)
  /// false : baris titik dihitung dari tepi atas (untuk slide 2)
  /// Dengan begitu grid keduanya menyambung tepat di garis pertemuan.
  final bool fromBottom;

  const _DotGridPainter(this.color, this.shift, {this.fromBottom = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const gap = 24.0;
    final dx = shift % gap;
    for (double x = -gap + dx; x < size.width + gap; x += gap) {
      if (fromBottom) {
        for (double y = size.height; y > -gap; y -= gap) {
          canvas.drawCircle(Offset(x, y), 1.3, paint);
        }
      } else {
        for (double y = 0; y < size.height; y += gap) {
          canvas.drawCircle(Offset(x, y), 1.3, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter old) =>
      old.color != color ||
      old.shift != shift ||
      old.fromBottom != fromBottom;
}

class _RingsPainter extends CustomPainter {
  final Color color;
  const _RingsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 1; i <= 5; i++) {
      final r = (size.width / 2) * (i / 5);
      canvas.drawCircle(center, r, paint..color = color.withOpacity(0.55 / i));
    }

    final dot = Paint()..color = color;
    for (int i = 0; i < 6; i++) {
      final a = (i / 6) * 2 * math.pi;
      final r = size.width / 2;
      canvas.drawCircle(
        Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a)),
        2.6,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) => old.color != color;
}