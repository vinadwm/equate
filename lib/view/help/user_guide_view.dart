import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:equate/view/auth/auth_glass_widgets.dart';
import 'package:equate/viewmodel/language_viewmodel.dart';

import 'customer_service_view.dart';
import 'help_widgets.dart';

// ================================================================
// DATA LANGKAH — semua teks tersedia dalam dua bahasa
// ================================================================
class _GuideStep {
  final IconData icon;
  final String titleId;
  final String titleEn;
  final String descId;
  final String descEn;
  final String? tipId;
  final String? tipEn;

  const _GuideStep({
    required this.icon,
    required this.titleId,
    required this.titleEn,
    required this.descId,
    required this.descEn,
    this.tipId,
    this.tipEn,
  });

  String get title => tr(titleId, titleEn);
  String get description => tr(descId, descEn);
  String? get tip => tipId == null ? null : tr(tipId!, tipEn ?? tipId!);
}

const List<_GuideStep> _steps = [
  _GuideStep(
    icon: Icons.person_add_alt_1_rounded,
    titleId: 'Buat akun & masuk',
    titleEn: 'Create an account & sign in',
    descId:
        'Daftar dengan e-mail atau akun Google, lalu masuk. Riwayat perhitunganmu akan tersimpan aman di akun.',
    descEn:
        'Sign up with your e-mail or Google account, then sign in. Your calculation history is kept safely in your account.',
    tipId: 'Masuk dengan akun yang sama agar riwayatmu ikut di perangkat lain.',
    tipEn: 'Sign in with the same account to keep your history on other devices.',
  ),
  _GuideStep(
    icon: Icons.home_rounded,
    titleId: 'Pantau di Beranda',
    titleEn: 'Track on Home',
    descId:
        'Lihat berita terbaru dan kurs rupiah live, lalu pilih pasar (Emas, Hang Seng, Nikkei) dan tanggal data. Kamu akan melihat Open, High, Low, Close, grafik pergerakan, dan tabel data historis.',
    descEn:
        'See the latest news and live rupiah rates, then choose a market (Gold, Hang Seng, Nikkei) and a data date. You will find Open, High, Low, Close, a price chart, and a historical data table.',
    tipId: 'Tarik layar ke bawah untuk memperbarui data.',
    tipEn: 'Pull the screen down to refresh the data.',
  ),
  _GuideStep(
    icon: Icons.calculate_rounded,
    titleId: 'Hitung di Kalkulator',
    titleEn: 'Calculate with the Calculator',
    descId:
        'Pilih instrumen: Emas Digital, Emas Fisik, Pivot Point, atau NEST. Isi data yang diminta lalu tekan hitung untuk melihat hasilnya.',
    descEn:
        'Pick an instrument: Digital Gold, Physical Gold, Pivot Point, or NEST. Fill in the required data, then tap calculate to see the result.',
  ),
  _GuideStep(
    icon: Icons.history_rounded,
    titleId: 'Lihat Riwayat',
    titleEn: 'View History',
    descId:
        'Setiap hasil perhitungan tersimpan otomatis. Buka bagian Riwayat di Kalkulator, lalu ketuk "Lihat Semua" untuk detail lengkap.',
    descEn:
        'Every calculation is saved automatically. Open the History section in the Calculator, then tap "View All" for the full details.',
  ),
  _GuideStep(
    icon: Icons.manage_accounts_rounded,
    titleId: 'Atur Profil',
    titleEn: 'Manage your Profile',
    descId:
        'Di tab Profil kamu bisa mengubah nama dan foto, mengganti kata sandi, mengatur bahasa, serta beralih antara mode terang dan gelap.',
    descEn:
        'In the Profile tab you can change your name and photo, update your password, switch the language, and toggle between light and dark mode.',
  ),
  _GuideStep(
    icon: Icons.support_agent_rounded,
    titleId: 'Butuh bantuan?',
    titleEn: 'Need help?',
    descId:
        'Buka Pusat Bantuan untuk membaca FAQ atau menghubungi Customer Service lewat chat, WhatsApp, dan telepon.',
    descEn:
        'Open the Help Center to read the FAQ or reach Customer Service via chat, WhatsApp, and phone.',
  ),
];

// ================================================================
// HALAMAN PANDUAN PENGGUNAAN
// ================================================================
class UserGuideView extends StatelessWidget {
  const UserGuideView({super.key});

  @override
  Widget build(BuildContext context) {
    return HelpScaffold(
      titleId: 'Panduan Penggunaan',
      titleEn: 'User Guide',
      subtitleId: '${_steps.length} langkah mudah memakai Equate',
      subtitleEn: '${_steps.length} easy steps to use Equate',
      builder: (context, isDark, t) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Hero banner yang lebih modern & elegan menggantikan _IntroCard kotak biasa
            AppFadeIn(index: 0, child: _HeroWelcomeHeader(isDark: isDark)),
            const SizedBox(height: 28),

            AppFadeIn(
              index: 1,
              child: AppSectionLabel(
                text: tr('LANGKAH DEMI LANGKAH', 'STEP BY STEP'),
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 12),

            ...List.generate(_steps.length, (index) {
              return AppFadeIn(
                index: index + 2,
                child: _StepTile(
                  step: _steps[index],
                  number: index + 1,
                  total: _steps.length,
                  isLast: index == _steps.length - 1,
                  isDark: isDark,
                ),
              );
            }),

            const SizedBox(height: 24),
            AppFadeIn(index: _steps.length + 2, child: _HelpCta(isDark: isDark)),
          ],
        );
      },
    );
  }
}

// ================================================================
// HEADER HERO SELAMAT DATANG (Menggantikan Kotak Lama)
// ================================================================
class _HeroWelcomeHeader extends StatelessWidget {
  final bool isDark;

  const _HeroWelcomeHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final t = AuthTokens(isDark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Eksplorasi Equate', 'Explore Equate'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tr(
                    'Panduan ringkas untuk memaksimalkan analisis pasar & perhitungan trading Anda.',
                    'A quick guide to maximize your market analysis & trading calculations.',
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    height: 1.5,
                    color: t.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kAuthOrange.withOpacity(isDark ? 0.12 : 0.1),
            ),
            child: const Icon(
              Icons.explore_rounded,
              color: kAuthOrange,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// SATU LANGKAH (timeline + kartu)
// ================================================================
class _StepTile extends StatelessWidget {
  final _GuideStep step;
  final int number;
  final int total;
  final bool isLast;
  final bool isDark;

  const _StepTile({
    required this.step,
    required this.number,
    required this.total,
    required this.isLast,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final t = AuthTokens(isDark);
    final tip = step.tip;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Garis timeline + bulatan ikon
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [kAuthOrangeSoft, kAuthOrange, kAuthOrangeDeep],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kAuthOrange.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(step.icon, color: Colors.white, size: 20),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            kAuthOrange.withOpacity(0.35),
                            kAuthOrange.withOpacity(0.08),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Kartu langkah
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: appCardDecoration(isDark, radius: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: kAuthOrange.withOpacity(0.12),
                          ),
                          child: Text(
                            '${tr('LANGKAH', 'STEP')} $number/$total',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: kAuthOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: t.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      step.description,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        height: 1.6,
                        color: t.textSecondary,
                      ),
                    ),
                    if (tip != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: kAuthOrange.withOpacity(isDark ? 0.10 : 0.07),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 14,
                              color: kAuthOrange,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                '${tr('Tips', 'Tip')}: $tip',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  height: 1.5,
                                  color: t.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// AJAKAN MENGHUBUNGI CS DI AKHIR HALAMAN
// ================================================================
class _HelpCta extends StatelessWidget {
  final bool isDark;

  const _HelpCta({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kAuthOrangeSoft, kAuthOrange, kAuthOrangeDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: kAuthOrange.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('Masih ada yang bingung?', 'Still have questions?'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tr(
              'Tim kami siap membantu kamu kapan saja.',
              'Our team is ready to help you anytime.',
            ),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              height: 1.5,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CustomerServiceView()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.white,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.headset_mic_rounded,
                    size: 16,
                    color: kAuthOrangeDeep,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tr('Hubungi Customer Service', 'Contact Customer Service'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: kAuthOrangeDeep,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}