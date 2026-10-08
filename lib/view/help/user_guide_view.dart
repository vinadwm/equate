import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:equate/view/auth/auth_glass_widgets.dart';
import 'package:equate/viewmodel/theme_viewmodel.dart';

import 'help_widgets.dart';

class _GuideStep {
  final IconData icon;
  final String title;
  final String description;
  const _GuideStep(this.icon, this.title, this.description);
}

const List<_GuideStep> _steps = [
  _GuideStep(
    Icons.person_add_alt_1_rounded,
    'Buat akun & masuk',
    'Daftar dengan e-mail atau akun Google, lalu masuk. Riwayat perhitunganmu akan tersimpan aman di akun.',
  ),
  _GuideStep(
    Icons.home_rounded,
    'Pantau di Beranda',
    'Pilih pasar (Emas, Hang Seng, Nikkei) dan tanggal data. Lihat Open, High, Low, Close, grafik pergerakan, dan tabel data historis.',
  ),
  _GuideStep(
    Icons.calculate_rounded,
    'Hitung di Kalkulator',
    'Pilih instrumen: Emas Digital, Emas Fisik, Pivot Point, atau NEST. Isi data yang diminta lalu tekan hitung untuk melihat hasilnya.',
  ),
  _GuideStep(
    Icons.history_rounded,
    'Lihat Riwayat',
    'Setiap hasil perhitungan tersimpan otomatis. Buka bagian Riwayat di Kalkulator, lalu ketuk "Lihat Semua" untuk detail lengkap.',
  ),
  _GuideStep(
    Icons.manage_accounts_rounded,
    'Atur Profil',
    'Di tab Profil kamu bisa mengubah nama dan foto, mengganti kata sandi, serta beralih antara mode terang dan gelap.',
  ),
  _GuideStep(
    Icons.support_agent_rounded,
    'Butuh bantuan?',
    'Buka Pusat Bantuan untuk membaca FAQ atau menghubungi Customer Service lewat WhatsApp dan telepon.',
  ),
];

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
          children: List.generate(_steps.length, (index) {
            final step = _steps[index];
            final isLast = index == _steps.length - 1;

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
                              colors: [
                                kAuthOrangeSoft,
                                kAuthOrange,
                                kAuthOrangeDeep,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: kAuthOrange.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            step.icon,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: kAuthOrange.withOpacity(0.25),
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
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1F24).withOpacity(0.75)
                              : Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.white.withOpacity(0.9),
                            width: 0.6,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? 0.25 : 0.04,
                              ),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LANGKAH ${index + 1}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: kAuthOrange,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: t.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              step.description,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                height: 1.55,
                                color: t.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}