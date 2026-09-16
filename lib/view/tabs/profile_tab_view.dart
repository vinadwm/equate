import 'dart:ui';
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
  final ProfileViewModel _profileViewModel = ProfileViewModel();
  String _selectedCategory = 'Semua';

  final List<Map<String, String>> _calculationHistory = [
    {
      'title': 'Pivot Point',
      'category': 'HangSeng',
      'date': '24 Agustus 2026',
      'result': 'Gold / XAUUSD',
    },
    {
      'title': 'Keuntungan Emas',
      'category': 'Emas',
      'date': '22 Agustus 2026',
      'result': 'Rp 1.250.000',
    },
    {
      'title': 'Pivot Point',
      'category': 'HangSeng',
      'date': '20 Agustus 2026',
      'result': 'Gold / XAUUSD',
    },
  ];

  List<Map<String, String>> get _filteredHistory {
    if (_selectedCategory == 'Semua') {
      return _calculationHistory;
    }
    return _calculationHistory
        .where((item) => item['category'] == _selectedCategory)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _profileViewModel.addListener(_onProfileChanged);
    _profileViewModel.loadProfile();
  }

  void _onProfileChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _profileViewModel.removeListener(_onProfileChanged);
    _profileViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeViewModel.themeMode,
      builder: (context, currentThemeMode, child) {
        final bool isDarkMode = ThemeViewModel.isDarkMode;

        const primaryOrange = Color(0xFFFF9E0F);
        const secondaryOrange = Color(0xFFFFB74D);

        // Background Putih Bersih di Light Mode
        final bgColor = isDarkMode ? const Color(0xFF121214) : Colors.white;

        // Card Background & Border
        final cardBgColor = isDarkMode
            ? const Color(0xFF1C1C1E)
            : const Color(0xFFF8F9FA);

        final borderColor = isDarkMode
            ? Colors.white.withOpacity(0.08)
            : const Color(0xFFEFEFEF);

        final primaryTextColor = isDarkMode ? Colors.white : const Color(0xFF1D1D1F);
        final secondaryTextColor = isDarkMode
            ? const Color(0xFFA1A1AA)
            : const Color(0xFF8E8E93);

        if (_profileViewModel.isLoading) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            color: bgColor,
            child: const Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: CircularProgressIndicator(color: primaryOrange),
              ),
            ),
          );
        }

        final String userPhoto = _profileViewModel.photo;
        final String userName = _profileViewModel.fullName;
        final String userEmail = _profileViewModel.email;

        final displayHistory = _filteredHistory.take(2).toList();

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          color: bgColor,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  children: [
                    // ==================================================
                    // 1. FOTO PROFIL & STIKER ORANYE
                    // ==================================================
                    SizedBox(
                      height: 170,
                      width: 170,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 125,
                            height: 125,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  primaryOrange,
                                  secondaryOrange.withOpacity(0.6),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryOrange.withOpacity(0.2),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDarkMode
                                      ? const Color(0xFF1C1C1E)
                                      : Colors.white,
                                ),
                                child: userPhoto.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(65),
                                        child: Image.network(
                                          userPhoto,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Icon(
                                            Icons.person_rounded,
                                            size: 60,
                                            color: secondaryTextColor,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.person_rounded,
                                        size: 60,
                                        color: secondaryTextColor,
                                      ),
                              ),
                            ),
                          ),

                          // Stiker 1: Kalkulator
                          Positioned(
                            top: 2,
                            left: 2,
                            child: Transform.rotate(
                              angle: -0.18,
                              child: _buildBadgeIcon(
                                icon: Icons.calculate_outlined,
                                iconColor: primaryOrange,
                                cardBgColor: cardBgColor,
                                borderColor: borderColor,
                              ),
                            ),
                          ),

                          // Stiker 2: Emas / Koin
                          Positioned(
                            top: 4,
                            right: 2,
                            child: Transform.rotate(
                              angle: 0.15,
                              child: _buildBadgeIcon(
                                icon: Icons.monetization_on_outlined,
                                iconColor: primaryOrange,
                                cardBgColor: cardBgColor,
                                borderColor: borderColor,
                              ),
                            ),
                          ),

                          // Stiker 3: Grafik
                          Positioned(
                            bottom: 8,
                            left: -2,
                            child: Transform.rotate(
                              angle: -0.1,
                              child: _buildBadgeIcon(
                                icon: Icons.show_chart_rounded,
                                iconColor: primaryOrange,
                                cardBgColor: cardBgColor,
                                borderColor: borderColor,
                              ),
                            ),
                          ),

                          // Stiker 4: Persen
                          Positioned(
                            bottom: 10,
                            right: 0,
                            child: Transform.rotate(
                              angle: 0.18,
                              child: _buildBadgeIcon(
                                icon: Icons.percent_rounded,
                                iconColor: primaryOrange,
                                cardBgColor: cardBgColor,
                                borderColor: borderColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // 2. NAMA DAN EMAIL USER
                    // ==================================================
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: primaryTextColor,
                      ),
                      child: Text(
                        userName.isNotEmpty ? userName : 'Nama Pengguna',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w400,
                      ),
                      child: Text(
                        userEmail.isNotEmpty ? userEmail : 'email@domain.com',
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // 3. ACTION BUTTONS: EDIT PROFIL -> UBAH SANDI -> NIGHT MODE
                    // ==================================================
                    Row(
                      children: [
                        // 1. Edit Profil Button
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryOrange,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ).copyWith(
                                overlayColor: WidgetStateProperty.resolveWith(
                                  (states) {
                                    if (states.contains(WidgetState.hovered) ||
                                        states.contains(WidgetState.pressed)) {
                                      return Colors.white.withOpacity(0.15);
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EditProfileView(),
                                  ),
                                );
                                await _profileViewModel.refreshProfile();
                              },
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.white,
                                size: 16,
                              ),
                              label: Text(
                                'Edit Profil',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // 2. Ubah Kata Sandi Button
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryOrange.withOpacity(0.1),
                                foregroundColor: primaryOrange,
                                shadowColor: Colors.transparent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: primaryOrange.withOpacity(0.3),
                                  ),
                                ),
                              ).copyWith(
                                overlayColor: WidgetStateProperty.resolveWith(
                                  (states) {
                                    if (states.contains(WidgetState.hovered) ||
                                        states.contains(WidgetState.pressed)) {
                                      return primaryOrange.withOpacity(0.12);
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ChangePasswordView(),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.lock_outline_rounded,
                                color: primaryOrange,
                                size: 16,
                              ),
                              label: Text(
                                'Ubah Sandi',
                                style: GoogleFonts.poppins(
                                  color: primaryOrange,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // 3. Night Mode Toggle Button (Rapi & Terisolasi)
                        SizedBox(
                          width: 46,
                          height: 46,
                          child: Material(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              onTap: () {
                                ThemeViewModel.toggleTheme();
                              },
                              borderRadius: BorderRadius.circular(14),
                              hoverColor: primaryOrange.withOpacity(0.1),
                              splashColor: primaryOrange.withOpacity(0.15),
                              highlightColor: primaryOrange.withOpacity(0.08),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Icon(
                                  isDarkMode
                                      ? Icons.wb_sunny_rounded
                                      : Icons.nightlight_round,
                                  color: primaryOrange,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // ==================================================
                    // 4. HEADER & KATEGORI RIWAYAT
                    // ==================================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: primaryTextColor,
                          ),
                          child: const Text('RIWAYAT PERHITUNGAN'),
                        ),
                        if (_calculationHistory.isNotEmpty)
                          GestureDetector(
                            onTap: () {
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

                    const SizedBox(height: 12),

                    // Filter Chips (Hover Presisi)
                    Row(
                      children: ['Semua', 'Emas', 'HangSeng'].map((category) {
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Material(
                            color: isSelected ? primaryOrange : cardBgColor,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              hoverColor: isSelected
                                  ? primaryOrange.withOpacity(0.9)
                                  : primaryOrange.withOpacity(0.1),
                              splashColor: isSelected
                                  ? Colors.white.withOpacity(0.2)
                                  : primaryOrange.withOpacity(0.15),
                              onTap: () {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? primaryOrange
                                        : borderColor,
                                  ),
                                ),
                                child: Text(
                                  category,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : secondaryTextColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // 5. LIST RINGKASAN RIWAYAT
                    // ==================================================
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _filteredHistory.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.history_rounded,
                                      size: 36,
                                      color: secondaryTextColor,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Belum ada riwayat untuk kategori ini.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                children: List.generate(displayHistory.length, (index) {
                                  final history = displayHistory[index];
                                  return Column(
                                    children: [
                                      ListTile(
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 4,
                                        ),
                                        hoverColor: primaryOrange.withOpacity(0.06),
                                        splashColor: primaryOrange.withOpacity(0.1),
                                        leading: Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: primaryOrange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            history['category'] == 'Emas'
                                                ? Icons.monetization_on_outlined
                                                : Icons.calculate_outlined,
                                            color: primaryOrange,
                                            size: 20,
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
                                      if (index != displayHistory.length - 1)
                                        Divider(
                                          height: 1,
                                          color: borderColor,
                                          indent: 72,
                                        ),
                                    ],
                                  );
                                }),
                              ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ==================================================
                    // 6. TOMBOL LOGOUT (AKSEN MERAH Presisi)
                    // ==================================================
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showLogoutDialog(
                            isDarkMode: isDarkMode,
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                            primaryOrange: primaryOrange,
                          );
                        },
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        label: Text(
                          'Keluar dari Akun',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.redAccent,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.redAccent.withOpacity(0.4),
                          ),
                          backgroundColor: Colors.redAccent.withOpacity(0.04),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ).copyWith(
                          overlayColor: WidgetStateProperty.resolveWith(
                            (states) {
                              if (states.contains(WidgetState.hovered) ||
                                  states.contains(WidgetState.pressed)) {
                                return Colors.redAccent.withOpacity(0.1);
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper Stiker Ikon di Sekitar Profil
  Widget _buildBadgeIcon({
    required IconData icon,
    required Color iconColor,
    required Color cardBgColor,
    required Color borderColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }

  // Modal Dialog Logout
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
          backgroundColor: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
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
              onPressed: () => Navigator.pop(dialogContext),
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

  // Modal Bottom Sheet Riwayat
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
            color: isDarkMode ? const Color(0xFF18181B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
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
                    itemCount: _filteredHistory.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final history = _filteredHistory[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: primaryOrange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                history['category'] == 'Emas'
                                    ? Icons.monetization_on_outlined
                                    : Icons.calculate_outlined,
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