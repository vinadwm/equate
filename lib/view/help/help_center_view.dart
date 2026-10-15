import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:equate/view/auth/auth_glass_widgets.dart';
import 'package:equate/viewmodel/language_viewmodel.dart';

import 'customer_service_view.dart';
import 'faq_view.dart';
import 'help_widgets.dart';
import 'user_guide_view.dart';

class HelpCenterView extends StatelessWidget {
  const HelpCenterView({super.key});

  @override
  Widget build(BuildContext context) {
    return HelpScaffold(
      titleId: 'Pusat Bantuan',
      titleEn: 'Help Center',
      subtitleId: 'Kami siap membantu kamu',
      subtitleEn: 'We are here to help',
      builder: (context, isDark, t) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- HERO ----------------
            AppFadeIn(
              index: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.poppins(
                                fontSize: 30,
                                fontWeight: FontWeight.w400,
                                height: 1.2,
                                letterSpacing: -0.8,
                                color: t.textPrimary,
                              ),
                              children: [
                                TextSpan(
                                  text: tr('Ada yang\nbisa ', 'How can\nwe '),
                                ),
                                TextSpan(
                                  text: tr('dibantu?', 'help?'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    fontStyle: FontStyle.italic,
                                    letterSpacing: -0.8,
                                    color: kAuthOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: 250,
                            child: Text(
                              tr(
                                'Kenali Equate lebih dekat, atau pilih bantuan yang kamu butuhkan di bawah.',
                                'Get to know Equate, or pick the help you need below.',
                              ),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                height: 1.55,
                                color: t.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.support_agent_rounded,
                        size: 88,
                        color: kAuthOrange.withOpacity(isDark ? 0.18 : 0.14),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ---------------- APA ITU EQUATE ----------------
            AppFadeIn(index: 1, child: _AboutEquateCard(isDark: isDark)),

            const SizedBox(height: 30),

            // ---------------- MENU BANTUAN ----------------
            AppFadeIn(
              index: 2,
              child: AppSectionLabel(
                text: tr('BANTUAN', 'SUPPORT'),
                isDark: isDark,
              ),
            ),

            AppFadeIn(
              index: 3,
              child: AppMenuCard(
                isDark: isDark,
                icon: Icons.headset_mic_rounded,
                title: 'Customer Service',
                subtitle: tr(
                  'Chat dengan asisten, WhatsApp, atau telepon',
                  'Chat with the assistant, WhatsApp, or call',
                ),
                filledIcon: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomerServiceView(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            AppFadeIn(
              index: 4,
              child: AppMenuCard(
                isDark: isDark,
                icon: Icons.quiz_rounded,
                title: tr('Pertanyaan Umum (FAQ)', 'FAQ'),
                subtitle: tr(
                  'Jawaban untuk pertanyaan yang sering diajukan',
                  'Answers to frequently asked questions',
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FaqView()),
                ),
              ),
            ),
            const SizedBox(height: 12),
            AppFadeIn(
              index: 5,
              child: AppMenuCard(
                isDark: isDark,
                icon: Icons.menu_book_rounded,
                title: tr('Panduan Penggunaan', 'User Guide'),
                subtitle: tr(
                  'Langkah demi langkah memakai Equate',
                  'Step by step on using Equate',
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserGuideView(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ================================================================
// KARTU "APA ITU EQUATE?"
// ================================================================
class _Feature {
  final IconData icon;
  final String titleId;
  final String titleEn;
  final String descId;
  final String descEn;

  const _Feature(this.icon, this.titleId, this.titleEn, this.descId, this.descEn);
}

const List<_Feature> _features = [
  _Feature(
    Icons.show_chart_rounded,
    'Pantau pasar',
    'Market tracking',
    'Harga emas global, Hang Seng, dan Nikkei lengkap dengan grafik dan data historis.',
    'Global gold, Hang Seng, and Nikkei with charts and historical data.',
  ),
  _Feature(
    Icons.currency_exchange_rounded,
    'Kurs rupiah live',
    'Live rupiah rates',
    'Pantau pergerakan kurs rupiah terhadap berbagai mata uang secara langsung.',
    'Follow the rupiah against major currencies in real time.',
  ),
  _Feature(
    Icons.calculate_rounded,
    'Kalkulator trading',
    'Trading calculators',
    'Hitung Emas Digital, Emas Fisik, Pivot Point, dan NEST dengan cepat.',
    'Quickly calculate Digital Gold, Physical Gold, Pivot Point, and NEST.',
  ),
  _Feature(
    Icons.history_rounded,
    'Riwayat tersimpan',
    'Saved history',
    'Setiap hasil perhitungan tersimpan otomatis di akunmu.',
    'Every calculation is saved automatically to your account.',
  ),
];

class _AboutEquateCard extends StatelessWidget {
  final bool isDark;

  const _AboutEquateCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final t = AuthTokens(isDark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: appCardDecoration(isDark, radius: 26, highlighted: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
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
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('TENTANG APLIKASI', 'ABOUT THE APP'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                        color: kAuthOrange,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tr('Apa itu Equate?', 'What is Equate?'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: t.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Pengertian
          Text(
            tr(
              'Equate adalah aplikasi pendamping trading yang menyatukan pemantauan pasar dan kalkulator dalam satu tempat. Kamu bisa melihat pergerakan harga, memantau kurs rupiah, lalu menghitung kebutuhan trading tanpa berpindah-pindah aplikasi.',
              'Equate is a trading companion app that brings market monitoring and calculators together in one place. Check price movements, follow the rupiah rate, and work out your trading numbers without switching between apps.',
            ),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              height: 1.65,
              color: t.textSecondary,
            ),
          ),

          const SizedBox(height: 16),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.black.withOpacity(0.06),
          ),
          const SizedBox(height: 16),

          Text(
            tr('YANG BISA KAMU LAKUKAN', 'WHAT YOU CAN DO'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: t.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Fitur utama
          ...List.generate(_features.length, (i) {
            final f = _features[i];
            return Padding(
              padding: EdgeInsets.only(
                bottom: i == _features.length - 1 ? 0 : 14,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      color: kAuthOrange.withOpacity(0.12),
                    ),
                    child: Icon(f.icon, size: 17, color: kAuthOrange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(f.titleId, f.titleEn),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: t.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr(f.descId, f.descEn),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            height: 1.5,
                            color: t.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 18),

          // Catatan
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: kAuthOrange.withOpacity(isDark ? 0.10 : 0.07),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: kAuthOrange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr(
                      'Data dan hasil perhitungan bersifat informatif dan bukan merupakan saran investasi.',
                      'Data and calculation results are for information only and are not investment advice.',
                    ),
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
      ),
    );
  }
}