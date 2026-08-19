import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_name_view.dart';
import 'change_password_view.dart';

class ProfileTabView extends StatelessWidget {
  const ProfileTabView({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFFFA800);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // ==========================================
                // 1. CUSTOM WAVY HEADER WITH AVATAR
                // ==========================================
                // 1. UPDATE KODE WIDGET HEADER KAMU (Ganti bagian SizedBox paling atas)
                SizedBox(
                  height: 250,
                  child: Stack(
                    children: [
                      // Background Orange Melengkung (Height diperbesar jadi 230 agar tidak kepotong)
                      ClipPath(
                        clipper: ProfileHeaderClipper(),
                        child: Container(
                          height: 230,
                          color: const Color(0xFFFFA800),
                          child: Stack(
                            children: [
                              // Ikon Dekoratif
                              Positioned(
                                top: 40,
                                left: 20,
                                child: Icon(
                                  Icons.calculate_outlined,
                                  color: Colors.white.withOpacity(0.3),
                                  size: 36,
                                ),
                              ),
                              Positioned(
                                top: 30,
                                right: 60,
                                child: Icon(
                                  Icons.calculate_rounded,
                                  color: Colors.white.withOpacity(0.3),
                                  size: 42,
                                ),
                              ),
                              Positioned(
                                top: 100,
                                left: 60,
                                child: Icon(
                                  Icons.add_rounded,
                                  color: Colors.white.withOpacity(0.4),
                                  size: 32,
                                ),
                              ),
                              Positioned(
                                top: 120,
                                right: 30,
                                child: Icon(
                                  Icons.close_rounded,
                                  color: Colors.white.withOpacity(0.3),
                                  size: 28,
                                ),
                              ),
                              Positioned(
                                top: 135,
                                left: 20,
                                child: Icon(
                                  Icons.percent_rounded,
                                  color: Colors.white.withOpacity(0.3),
                                  size: 28,
                                ),
                              ),

                              // Judul Header
                              Align(
                                alignment: Alignment.topCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 45.0),
                                  child: Text(
                                    'PROFIL',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Avatar Foto Profil
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 46,
                                backgroundColor: primaryOrange,
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/fotoProfil.png', // Ganti dengan asset gambar kamu
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.person_pin,
                                              size: 46,
                                              color: primaryOrange,
                                            ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                height: 28,
                                width: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFA800),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Nama User
                Text(
                  'Aleesha',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 24),

                // ==========================================
                // 2. MENU OPTIONS CARD
                // ==========================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem('Ubah Nama', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditNameView(),
                            ),
                          );
                        }),
                        const Divider(
                          height: 1,
                          thickness: 0.5,
                          color: Color(0xFFF0F0F0),
                        ),
                        _buildMenuItem('Ubah Kata Sandi', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChangePasswordView(),
                            ),
                          );
                        }),
                        const Divider(
                          height: 1,
                          thickness: 0.5,
                          color: Color(0xFFF0F0F0),
                        ),
                        _buildMenuItem('Riwayat', () {
                          // Ganti HistoryView() sesuai nama kelas halaman riwayatmu
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => const HistoryView(),
                          //   ),
                          // );
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ==========================================
                // 3. LOGOUT CARD
                // ==========================================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      onTap: () {
                        // Tambahkan aksi logout di sini
                      },
                      leading: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFFF4D4D),
                      ),
                      title: Text(
                        'KELUAR',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFFFF4D4D),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 100,
                ), // Spacing agar tidak tertutup Bottom Navigation Bar
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget Reusable Item Menu
  Widget _buildMenuItem(String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.black54,
        size: 20,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}

// ==========================================
// CUSTOM CLIPPER UNTUK HEADER LENGKUNG
// ==========================================
// 2. GANTI KELAS ProfileHeaderClipper DI PALING BAWAH FILE
class ProfileHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    path.lineTo(0, 0);
    path.lineTo(0, size.height - 50);

    // 1. Lengkungan Bulat Kiri
    path.cubicTo(
      size.width * 0.08,
      size.height,
      size.width * 0.28,
      size.height,
      size.width * 0.33,
      size.height - 65,
    );

    // 2. Lengkungan Wadah Foto Profil (Membulat Sesuai Lingkaran Foto)
    path.cubicTo(
      size.width * 0.38,
      size.height - 120,
      size.width * 0.62,
      size.height - 120,
      size.width * 0.67,
      size.height - 65,
    );

    // 3. Lengkungan Bulat Kanan
    path.cubicTo(
      size.width * 0.72,
      size.height,
      size.width * 0.92,
      size.height,
      size.width,
      size.height - 50,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
