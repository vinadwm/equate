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
            // ---------------- HERO (hanya teks, tanpa kotak) ----------------
            Stack(
              children: [
                Positioned(
                  right: -10,
                  top: -6,
                  child: Icon(
                    Icons.support_agent_rounded,
                    size: 110,
                    color: kAuthOrange.withOpacity(isDark ? 0.14 : 0.13),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 0, 0),
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
                              text: tr(
                                'Ada yang\nbisa ',
                                'How can\nwe ',
                              ),
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
                            'Pilih salah satu di bawah, atau langsung ngobrol dengan asisten kami.',
                            'Pick one below, or chat with our assistant right away.',
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
              ],
            ),

            const SizedBox(height: 30),

            // ---------------- MENU POLOS ----------------
            AppListRow(
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
            AppRowDivider(isDark: isDark),
            AppListRow(
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
            AppRowDivider(isDark: isDark),
            AppListRow(
              isDark: isDark,
              icon: Icons.menu_book_rounded,
              title: tr('Panduan Penggunaan', 'User Guide'),
              subtitle: tr(
                'Langkah demi langkah memakai Equate',
                'Step by step on using Equate',
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserGuideView()),
              ),
            ),
          ],
        );
      },
    );
  }
}