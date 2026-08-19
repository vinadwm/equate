import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileTabView extends StatefulWidget {
  const ProfileTabView({super.key});

  @override
  State<ProfileTabView> createState() => _ProfileTabViewState();
}

class _ProfileTabViewState extends State<ProfileTabView> {
  // Data Dummy Riwayat Perhitungan
  final List<Map<String, String>> _calculationHistory = [
    {
      'title': 'Kalkulasi Diskon & Pajak',
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
      'title': 'Total BelanjaBulanan',
      'expression': '85.000 + 120.000 + 45.000',
      'result': '250.000',
      'date': '17 Aug 2026',
    },
  ];

  // Fungsi Simulasi Edit Foto
  void _showEditPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Text(
                'Ubah Foto Profil',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Colors.orange),
                title: Text('Pilih dari Galeri', style: GoogleFonts.poppins()),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Colors.orange),
                title: Text('Ambil Foto Baru', style: GoogleFonts.poppins()),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: Text('Hapus Foto Profil', style: GoogleFonts.poppins(color: Colors.redAccent)),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  // Fungsi Dialog Konfirmasi Keluar
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Keluar dari Akun?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          content: Text(
            'Apakah kamu yakin ingin keluar? Kamu perlu login kembali untuk mengakses data kamu.',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(color: Colors.grey[600], fontWeight: FontWeight.w500),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // --- BACKGROUND ESTETIK & DEKORASI BENTUK ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 220,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -20,
                    right: -20,
                    child: CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.white.withOpacity(0.12),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: -30,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  Positioned(
                    right: 30,
                    bottom: 40,
                    child: Icon(
                      Icons.calculate_rounded,
                      size: 90,
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- KONTEN UTAMA ---
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
              child: Column(
                children: [
                  // Header Judul
                  Text(
                    'Profil Saya',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // --- 1. FOTO PROFIL OVERLAY EDIT ---
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const CircleAvatar(
                            radius: 52,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 49,
                              backgroundImage: NetworkImage(
                                'https://i.pravatar.cc/300',
                              ),
                            ),
                          ),
                        ),

                        // Tombol Kamera Edit
                        GestureDetector(
                          onTap: _showEditPhotoOptions,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // --- 2. NAMA DAN EMAIL ---
                  Text(
                    'Vina Dwi Maulita',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'vina@equate.com',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- 3. SEKSI MENU PENGATURAN AKUN ---
                  _buildSectionHeader('Pengaturan Akun'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: _cardDecoration(),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.person_outline_rounded,
                          title: 'Edit Detail Profil',
                          onTap: () {},
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          icon: Icons.lock_outline_rounded,
                          title: 'Ubah Kata Sandi',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- 4. SEKSI LIST RIWAYAT PERHITUNGAN ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('Riwayat Perhitungan'),
                      GestureDetector(
                        onTap: () {
                          // TODO: Pindah ke halaman penuh riwayat
                        },
                        child: Text(
                          'Lihat Semua',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF9800),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // List Kartu Riwayat
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _calculationHistory.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _calculationHistory[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: _cardDecoration(),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9800).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.history_toggle_off_rounded,
                                color: Color(0xFFFF9800),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item['title']!,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF2D3142),
                                        ),
                                      ),
                                      Text(
                                        item['date']!,
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['expression']!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '= ${item['result']!}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFF9800),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // --- 5. TOMBOL KELUAR (LOGOUT) PALING BAWAH ---
                  Container(
                    decoration: _cardDecoration(),
                    child: _buildMenuItem(
                      icon: Icons.logout_rounded,
                      title: 'Keluar dari Akun',
                      textColor: Colors.redAccent,
                      iconColor: Colors.redAccent,
                      hideTrailingIcon: true,
                      onTap: _showLogoutDialog,
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

  // --- WIDGET HELPER BANTUAN UI ---

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color textColor = const Color(0xFF2D3142),
    Color iconColor = const Color(0xFFFF9800),
    bool hideTrailingIcon = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      trailing: hideTrailingIcon
          ? null
          : Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      endIndent: 16,
      color: Colors.grey[100],
    );
  }
}