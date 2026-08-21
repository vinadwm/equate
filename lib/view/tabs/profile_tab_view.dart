import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:equate/view/tabs/change_password_view.dart'; 
import 'package:equate/view/tabs/edit_profile_view.dart'; 

// 1. Import ThemeViewModel
import 'package:equate/viewmodel/theme_viewmodel.dart'; // Sesuaikan path jika berbeda

class ProfileTabView extends StatefulWidget {
  const ProfileTabView({super.key});

  @override
  State<ProfileTabView> createState() => _ProfileTabViewState();
}

class _ProfileTabViewState extends State<ProfileTabView> {
  final List<Map<String, String>> _calculationHistory = [
    {
      'title': 'Kalkulasi Diskont & Pajak',
      'expression': '250.000 - 15% + 11%',
      'result': '235.875',
      'date': 'Hari ini, 14:20'
    },
    {
      'title': 'Perhitungan Matematika',
      'expression': '(145 * 12) + (500 / 2)',
      'result': '1.990',
      'date': 'Kemarin, 09:15'
    },
    {
      'title': 'Total Belanja Bulanan',
      'expression': '85.000 + 120.000 + 45.000',
      'result': '250.000',
      'date': '17 Aug 2026',
    },
  ];

  void _showLogoutDialog(bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Keluar dari Akun?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          content: Text(
            'Apakah kamu yakin ingin keluar dari akun ini?',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                // TODO: Logika logout
              },
              child: Text(
                'Keluar',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeViewModel.isDarkMode;

    const primaryOrange = Color(0xFFFF9800);
    const orangeAccent = Color(0xFFF57C00);
    const lightOrangeBg = Color(0xFFFFF3E0);

    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final cardBgColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[50];
    final cardBorderColor = isDarkMode ? Colors.grey[800]! : Colors.grey.shade200;
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[500]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ==========================================
            // 1. BAGIAN HEADER & PROFILE
            // ==========================================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  // Foto Profil
                  Center(
                    child: SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: primaryOrange.withOpacity(0.3), width: 3),
                            ),
                            child: const CircleAvatar(
                              radius: 58,
                              backgroundImage: NetworkImage('https://i.pravatar.cc/300?img=5'),
                            ),
                          ),
                          Positioned(
                            left: -4,
                            bottom: 20,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: lightOrangeBg,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                                ],
                              ),
                              child: const Icon(Icons.add_rounded, color: orangeAccent, size: 20),
                            ),
                          ),
                          Positioned(
                            right: 10,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFE0B2),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                                ],
                              ),
                              child: const Icon(Icons.percent_rounded, color: Color(0xFFE65100), size: 18),
                            ),
                          ),
                          Positioned(
                            right: -4,
                            top: 15,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: lightOrangeBg,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                                ],
                              ),
                              child: const Icon(Icons.close_rounded, color: primaryOrange, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Nama User & Informasi
                  Text(
                    'Vina Dwi Maulita',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'vina@equate.com   •   7 Apr 2002',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- TOMBOL ACTION ---
                  Row(
                    children: [
                      // Edit Profile
                      Expanded(
                        flex: 4,
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => EditProfileView()), // FIX: Menggunakan EditProfileView tanpa 'const'
                              );
                            },
                            icon: const Icon(Icons.edit_outlined, size: 13, color: Colors.white),
                            label: Text(
                              'Edit Profil',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryOrange,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Ubah Sandi
                      Expanded(
                        flex: 4,
                        child: SizedBox(
                          height: 40,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ChangePasswordView(),
                                ),
                              );
                            },
                            icon: Icon(Icons.lock_outline_rounded, size: 13, color: primaryTextColor),
                            label: Text(
                              'Ubah Sandi',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: primaryTextColor,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              side: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Tombol Night Mode Toggle
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            ThemeViewModel.toggleTheme();
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFFFFB74D).withOpacity(0.2) : lightOrangeBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDarkMode ? primaryOrange : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                            color: isDarkMode ? primaryOrange : orangeAccent,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ==========================================
            // 2. BAGIAN RIWAYAT & LOGOUT (BISA DI-SCROLL)
            // ==========================================
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RIWAYAT PERHITUNGAN',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: primaryTextColor,
                            ),
                          ),
                          Text(
                            'Aktivitas kalkulasi terbaru kamu',
                            style: GoogleFonts.poppins(fontSize: 11, color: secondaryTextColor),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HistoryDetailPage(historyList: _calculationHistory),
                            ),
                          );
                        },
                        child: Text(
                          'Lihat Semua',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: orangeAccent,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Daftar Kartu Riwayat
                  ..._calculationHistory.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.calculate_outlined,
                                color: primaryOrange,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title']!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: primaryTextColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item['expression']!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: secondaryTextColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  item['date']!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: secondaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '= ${item['result']!}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: primaryOrange,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 24),

                  // Tombol Logout
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: TextButton.icon(
                      onPressed: () => _showLogoutDialog(isDarkMode),
                      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                      label: Text(
                        'Keluar dari Akun',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: isDarkMode ? Colors.red.shade900.withOpacity(0.2) : Colors.red.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// PAGE 3: RIWAYAT LENGKAP
// ==========================================
class HistoryDetailPage extends StatelessWidget {
  final List<Map<String, String>> historyList;

  const HistoryDetailPage({super.key, required this.historyList});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeViewModel.isDarkMode;
    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final cardBgColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[50];
    final cardBorderColor = isDarkMode ? Colors.grey[800]! : Colors.grey.shade200;
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[500]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Semua Riwayat Perhitungan', style: GoogleFonts.poppins(color: primaryTextColor, fontWeight: FontWeight.bold)),
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryTextColor),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: historyList.length,
        itemBuilder: (context, index) {
          final item = historyList[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calculate_outlined,
                      color: Color(0xFFFF9800),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title']!,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['expression']!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item['date']!,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '= ${item['result']!}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}