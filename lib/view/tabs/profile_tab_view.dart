import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:equate/view/tabs/change_password_view.dart';
import 'package:equate/view/tabs/edit_profile_view.dart';
import 'package:equate/view/auth/login_view.dart';
import 'package:equate/viewmodel/theme_viewmodel.dart';
import 'package:equate/viewmodel/profile_viewmodel.dart';

class ProfileTabView extends StatefulWidget {
  const ProfileTabView({super.key});

  @override
  State<ProfileTabView> createState() => _ProfileTabViewState();
}

class _ProfileTabViewState extends State<ProfileTabView> {
  // ============================================================
  // VIEWMODEL
  // ============================================================

  final ProfileViewModel _profileViewModel = ProfileViewModel();

  // ============================================================
  // RIWAYAT PERHITUNGAN
  // ============================================================

  final List<Map<String, String>> _calculationHistory = [
    {
      'title': 'Pivot Point',
      'date': '24 Agustus 2026',
      'result': 'Gold / XAUUSD',
    },
    {
      'title': 'Keuntungan Emas',
      'date': '22 Agustus 2026',
      'result': 'Rp 1.250.000',
    },
    {
      'title': 'Pivot Point',
      'date': '20 Agustus 2026',
      'result': 'Gold / XAUUSD',
    },
  ];

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _profileViewModel.addListener(_onProfileChanged);
    _profileViewModel.loadProfile();
  }

  // ============================================================
  // PROFILE LISTENER
  // ============================================================

  void _onProfileChanged() {
    if (!mounted) return;

    setState(() {});
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _profileViewModel.removeListener(_onProfileChanged);
    _profileViewModel.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeViewModel.themeMode,
      builder: (context, currentThemeMode, child) {
        final bool isDarkMode = ThemeViewModel.isDarkMode;

        const primaryOrange = Color(0xFFFF9E0F);

        final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;

        final cardBgColor = isDarkMode
            ? const Color(0xFF1E1E1E)
            : Colors.grey[50]!;

        final primaryTextColor = isDarkMode ? Colors.white : Colors.black87;

        final secondaryTextColor = isDarkMode
            ? Colors.grey[400]!
            : Colors.grey[600]!;

        final borderColor = isDarkMode
            ? Colors.grey[800]!
            : const Color(0xFFE0E0E0);

        // ========================================================
        // LOADING PROFILE
        // ========================================================

        if (_profileViewModel.isLoading) {
          return Scaffold(
            backgroundColor: bgColor,
            body: const Center(
              child: CircularProgressIndicator(color: primaryOrange),
            ),
          );
        }

        // ========================================================
        // DATA USER DARI VIEWMODEL
        // ========================================================

        final String userPhoto = _profileViewModel.photo;
        final String userName = _profileViewModel.fullName;
        final String userEmail = _profileViewModel.email;

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // TITLE
                  // ==================================================
                  Text(
                    'Profil',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // PROFILE CARD
                  // ==================================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        // ==================================================
                        // FOTO PROFIL
                        // ==================================================
                        Container(
                          width: 116,
                          height: 116,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDarkMode
                                ? const Color(0xFF2A2A2A)
                                : const Color(0xFFF1F1F1),
                            border: Border.all(color: primaryOrange, width: 2),
                          ),
                          child: userPhoto.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(58),
                                  child: Image.network(
                                    userPhoto,
                                    width: 116,
                                    height: 116,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }

                                          return const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: primaryOrange,
                                            ),
                                          );
                                        },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.person_rounded,
                                        size: 58,
                                        color: isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.person_rounded,
                                  size: 58,
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                        ),

                        const SizedBox(height: 16),

                        // ==================================================
                        // NAMA
                        // ==================================================
                        Text(
                          userName,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                        ),

                        const SizedBox(height: 2),

                        // ==================================================
                        // EMAIL
                        // ==================================================
                        Text(
                          userEmail,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ==================================================
                        // EDIT PROFILE BUTTON
                        // ==================================================
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditProfileView(),
                                ),
                              );

                              // Ambil ulang data setelah kembali
                              await _profileViewModel.refreshProfile();
                            },
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: Text(
                              'Edit Profil',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryOrange,
                              side: const BorderSide(color: primaryOrange),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // AKUN
                  // ==================================================
                  Text(
                    'Akun',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        // ==================================================
                        // CHANGE PASSWORD
                        // ==================================================
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 4,
                          ),
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: primaryOrange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.lock_outline_rounded,
                              color: primaryOrange,
                              size: 21,
                            ),
                          ),
                          title: Text(
                            'Ubah Kata Sandi',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: primaryTextColor,
                            ),
                          ),
                          subtitle: Text(
                            'Perbarui kata sandi akun',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: secondaryTextColor,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: secondaryTextColor,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ChangePasswordView(),
                              ),
                            );
                          },
                        ),

                        Divider(height: 1, color: borderColor),

                        // ==================================================
                        // LOGOUT
                        // ==================================================
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 4,
                          ),
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: Colors.redAccent,
                              size: 21,
                            ),
                          ),
                          title: Text(
                            'Keluar',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.redAccent,
                            ),
                          ),
                          subtitle: Text(
                            'Keluar dari akun ini',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: secondaryTextColor,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: secondaryTextColor,
                          ),
                          onTap: () {
                            _showLogoutDialog(
                              isDarkMode: isDarkMode,
                              primaryTextColor: primaryTextColor,
                              secondaryTextColor: secondaryTextColor,
                              primaryOrange: primaryOrange,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // RIWAYAT PERHITUNGAN
                  // ==================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Riwayat Perhitungan',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),

                      if (_calculationHistory.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            _showCalculationHistory(
                              isDarkMode: isDarkMode,
                              primaryTextColor: primaryTextColor,
                              secondaryTextColor: secondaryTextColor,
                              cardBgColor: cardBgColor,
                              borderColor: borderColor,
                              primaryOrange: primaryOrange,
                            );
                          },
                          child: Text(
                            'Lihat Semua',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: primaryOrange,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ==================================================
                  // HISTORY CARD
                  // ==================================================
                  if (_calculationHistory.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 40,
                            color: secondaryTextColor,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Belum ada riwayat perhitungan.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: List.generate(_calculationHistory.length, (
                          index,
                        ) {
                          final history = _calculationHistory[index];

                          return Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 5,
                                ),
                                leading: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: primaryOrange.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    history['title'] == 'Pivot Point'
                                        ? Icons.calculate_outlined
                                        : Icons.monetization_on_outlined,
                                    color: primaryOrange,
                                    size: 21,
                                  ),
                                ),
                                title: Text(
                                  history['title'] ?? '-',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: primaryTextColor,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(
                                      history['result'] ?? '-',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                    Text(
                                      history['date'] ?? '-',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Icon(
                                  Icons.chevron_right_rounded,
                                  color: secondaryTextColor,
                                ),
                              ),

                              if (index != _calculationHistory.length - 1)
                                Divider(
                                  height: 1,
                                  color: borderColor,
                                  indent: 78,
                                ),
                            ],
                          );
                        }),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // APP VERSION
                  // ==================================================
                  Center(
                    child: Text(
                      'Equate • Versi 1.0.0',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: secondaryTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // LOGOUT DIALOG
  // ============================================================

  void _showLogoutDialog({
    required bool isDarkMode,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color primaryOrange,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Keluar dari akun?',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          content: Text(
            'Apakah kamu yakin ingin keluar dari akun ini?',
            style: GoogleFonts.poppins(fontSize: 13, color: secondaryTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: secondaryTextColor,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                try {
                  await _profileViewModel.logout();

                  if (!mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginView()),
                    (route) => false,
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceFirst('Exception: ', ''),
                      ),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Keluar',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SHOW CALCULATION HISTORY
  // ============================================================

  void _showCalculationHistory({
    required bool isDarkMode,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color cardBgColor,
    required Color borderColor,
    required Color primaryOrange,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF121212) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),

                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: secondaryTextColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Riwayat Perhitungan',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: _calculationHistory.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final history = _calculationHistory[index];

                      return Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: primaryOrange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                history['title'] == 'Pivot Point'
                                    ? Icons.calculate_outlined
                                    : Icons.monetization_on_outlined,
                                color: primaryOrange,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    history['title'] ?? '-',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    history['result'] ?? '-',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    history['date'] ?? '-',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
