import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:equate/view/auth/auth_glass_widgets.dart';
import 'package:equate/viewmodel/language_viewmodel.dart';

import 'help_widgets.dart';

class _FaqItem {
  final String qId;
  final String qEn;
  final String aId;
  final String aEn;
  const _FaqItem(this.qId, this.qEn, this.aId, this.aEn);
}

const List<_FaqItem> _faqs = [
  _FaqItem(
    'Apa itu Equate?',
    'What is Equate?',
    'Equate adalah aplikasi kalkulator dan pemantau pasar untuk emas serta Hang Seng. Kamu bisa menghitung profit/loss, pivot point, dan sinyal NEST, sekaligus melihat data historis.',
    'Equate is a calculator and market tracker for gold and Hang Seng. You can calculate profit/loss, pivot points, and NEST signals, and browse historical data.',
  ),
  _FaqItem(
    'Dari mana data harga bersumber?',
    'Where does the price data come from?',
    'Data historis bersumber dari Newsmaker.id. Data yang ditampilkan meliputi Open, High, Low, dan Close berdasarkan tanggal yang dipilih.',
    'Historical data comes from Newsmaker.id, covering Open, High, Low, and Close for the selected date.',
  ),
  _FaqItem(
    'Apa bedanya Emas Digital dan Emas Fisik?',
    'What is the difference between Digital and Physical Gold?',
    'Kalkulator Emas Digital menghitung profit atau loss dari posisi Buy/Sell dalam satuan lot. Emas Fisik menghitung hasil transaksi berdasarkan berat (gram), modal, dan harga posisi.',
    'The Digital Gold calculator computes profit or loss from Buy/Sell positions in lots. Physical Gold computes results from weight (grams), capital, and position price.',
  ),
  _FaqItem(
    'Apa itu Pivot Point dan NEST?',
    'What are Pivot Point and NEST?',
    'Pivot Point menentukan acuan harga (support & resistance) dari harga pembukaan. NEST membantu membaca tren dan sinyal berdasarkan harga penutupan.',
    'Pivot Point sets price references (support & resistance) from the opening price. NEST helps read trends and signals based on the closing price.',
  ),
  _FaqItem(
    'Apakah hasil perhitungan tersimpan?',
    'Are my calculation results saved?',
    'Ya. Hasil perhitungan tersimpan otomatis di akunmu dan bisa dilihat kembali di bagian Riwayat pada halaman Kalkulator.',
    'Yes. Results are saved to your account automatically and can be viewed again in the History section of the Calculator page.',
  ),
  _FaqItem(
    'Saya lupa kata sandi, bagaimana?',
    'I forgot my password. What now?',
    'Di halaman Masuk, ketuk "Lupa?" pada kolom kata sandi, lalu masukkan e-mail akunmu. Kami akan mengirim link untuk membuat kata sandi baru. Cek juga folder spam.',
    'On the Sign in page, tap "Forgot?" in the password field and enter your e-mail. We will send a link to create a new password. Check your spam folder too.',
  ),
  _FaqItem(
    'Bagaimana mengubah foto atau nama profil?',
    'How do I change my photo or name?',
    'Buka tab Profil, lalu ketuk "Edit Profil". Kamu bisa memperbarui nama dan foto di sana.',
    'Open the Profile tab and tap "Edit Profile". You can update your name and photo there.',
  ),
  _FaqItem(
    'Bagaimana mengganti bahasa aplikasi?',
    'How do I change the app language?',
    'Di tab Profil, pada baris "Bahasa", pilih ID untuk Bahasa Indonesia atau EN untuk English.',
    'On the Profile tab, in the "Language" row, choose ID for Indonesian or EN for English.',
  ),
  _FaqItem(
    'Apakah hasil kalkulasi adalah saran investasi?',
    'Is the calculation result investment advice?',
    'Bukan. Hasil di aplikasi hanya estimasi untuk membantu analisis. Keputusan investasi tetap menjadi tanggung jawab masing-masing pengguna.',
    'No. Results are only estimates to help your analysis. Investment decisions remain your own responsibility.',
  ),
];

class FaqView extends StatefulWidget {
  const FaqView({super.key});

  @override
  State<FaqView> createState() => _FaqViewState();
}

class _FaqViewState extends State<FaqView> {
  int? _openIndex;

  @override
  Widget build(BuildContext context) {
    return HelpScaffold(
      titleId: 'FAQ',
      titleEn: 'FAQ',
      subtitleId: 'Pertanyaan yang sering diajukan',
      subtitleEn: 'Frequently asked questions',
      builder: (context, isDark, t) {
        return Column(
          children: List.generate(_faqs.length, (index) {
            final item = _faqs[index];
            final isOpen = _openIndex == index;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: appCardDecoration(
                  isDark,
                  radius: 22,
                  highlighted: isOpen,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () =>
                        setState(() => _openIndex = isOpen ? null : index),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: kAuthOrange.withOpacity(0.12),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: kAuthOrange,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  tr(item.qId, item.qEn),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: t.textPrimary,
                                  ),
                                ),
                              ),
                              AnimatedRotation(
                                turns: isOpen ? 0.5 : 0,
                                duration: const Duration(milliseconds: 250),
                                child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: kAuthOrange,
                                ),
                              ),
                            ],
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                            alignment: Alignment.topCenter,
                            child: isOpen
                                ? Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      42,
                                      10,
                                      8,
                                      4,
                                    ),
                                    child: Text(
                                      tr(item.aId, item.aEn),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        height: 1.6,
                                        color: t.textSecondary,
                                      ),
                                    ),
                                  )
                                : const SizedBox(width: double.infinity),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}