import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:equate/view/tabs/change_password_view.dart';
import 'package:equate/view/tabs/edit_profile_view.dart';
import 'package:equate/view/help/help_center_view.dart';
import 'package:equate/view/help/help_widgets.dart';
import 'package:equate/view/auth/login_view.dart';
import 'package:equate/view/auth/auth_glass_widgets.dart';
import 'package:equate/viewmodel/language_viewmodel.dart';
import 'package:equate/viewmodel/theme_viewmodel.dart';
import 'package:equate/viewmodel/profile_viewmodel.dart';

class ProfileTabView extends StatefulWidget {
  const ProfileTabView({super.key});

  @override
  State<ProfileTabView> createState() => _ProfileTabViewState();
}

class _ProfileTabViewState extends State<ProfileTabView> {
  final ProfileViewModel _profileViewModel = ProfileViewModel();

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

  // ==========================================================
  // BUILD
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return AppThemeLang(
      builder: (context, isDark, t) {
        if (_profileViewModel.isLoading) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0D0E12) : Colors.white,
            body: AppPlainBackground(
              isDark: isDark,
              child: const Center(
                child: CircularProgressIndicator(color: kAuthOrange),
              ),
            ),
          );
        }

        final String userPhoto = _profileViewModel.photo;
        final String userName = _profileViewModel.fullName;
        final String userEmail = _profileViewModel.email;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0D0E12) : Colors.white,
          body: AppPlainBackground(
            isDark: isDark,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 130),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      // ==================================================
                      // AVATAR, NAMA, EMAIL
                      // ==================================================
                      _buildAvatar(t, userPhoto),
                      const SizedBox(height: 6),
                      Text(
                        userName.isNotEmpty
                            ? userName
                            : tr('Nama Pengguna', 'User Name'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 25,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.6,
                          color: t.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // E-mail dalam bentuk pil kecil
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: kAuthOrange.withOpacity(isDark ? 0.14 : 0.10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.alternate_email_rounded,
                              size: 13,
                              color: kAuthOrange,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                userEmail.isNotEmpty
                                    ? userEmail
                                    : 'email@domain.com',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: t.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ==================================================
                      // TOMBOL EDIT PROFIL
                      // ==================================================
                      _EditProfileButton(
                        label: tr('Edit Profil', 'Edit Profile'),
                        isDark: isDark,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileView(),
                            ),
                          );
                          await _profileViewModel.refreshProfile();
                        },
                      ),

                      const SizedBox(height: 30),

                      // ==================================================
                      // PENGATURAN (satu kartu)
                      // ==================================================
                      Align(
                        alignment: Alignment.centerLeft,
                        child: AppSectionLabel(
                          text: tr('PENGATURAN', 'SETTINGS'),
                          isDark: isDark,
                        ),
                      ),
                      AppGroupCard(
                        isDark: isDark,
                        children: [
                          AppGroupRow(
                            isDark: isDark,
                            icon: Icons.lock_outline_rounded,
                            title: tr('Ubah Kata Sandi', 'Change Password'),
                            subtitle: tr(
                              'Perbarui keamanan akunmu',
                              'Update your account security',
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ChangePasswordView(),
                              ),
                            ),
                          ),
                          AppGroupRow(
                            isDark: isDark,
                            icon: isDark
                                ? Icons.nightlight_round
                                : Icons.wb_sunny_rounded,
                            title: tr('Mode Gelap', 'Dark Mode'),
                            subtitle: isDark
                                ? tr('Sedang aktif', 'Currently on')
                                : tr('Sedang nonaktif', 'Currently off'),
                            onTap: () => ThemeViewModel.toggleTheme(),
                            trailing: Switch(
                              value: isDark,
                              activeColor: Colors.white,
                              activeTrackColor: kAuthOrange,
                              onChanged: (_) => ThemeViewModel.toggleTheme(),
                            ),
                          ),
                          AppGroupRow(
                            isDark: isDark,
                            icon: Icons.translate_rounded,
                            title: tr('Bahasa', 'Language'),
                            subtitle: tr('Indonesia / English', 'Indonesian / English'),
                            trailing: _LanguageToggle(isDark: isDark),
                          ),
                          AppGroupRow(
                            isDark: isDark,
                            icon: Icons.support_agent_rounded,
                            title: tr('Pusat Bantuan', 'Help Center'),
                            subtitle: tr(
                              'Customer service, FAQ, dan panduan',
                              'Customer service, FAQ, and guide',
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HelpCenterView(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // ==================================================
                      // KELUAR (teks polos, tanpa kotak)
                      // ==================================================
                      TextButton.icon(
                        onPressed: () => _showLogoutDialog(t),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFF3B30),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: const StadiumBorder(),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: Text(
                          tr('Keluar dari Akun', 'Log Out'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFF3B30),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // FOOTER
                      // ==================================================
                      Opacity(
                        opacity: isDark ? 0.55 : 0.7,
                        child: Image.asset(
                          'assets/images/logoEWF.png',
                          width: 40,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Equate',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: t.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // AVATAR + STIKER
  // ==========================================================
  Widget _buildAvatar(AuthTokens t, String userPhoto) {
    return SizedBox(
      height: 160,
      width: 170,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kAuthOrangeSoft, kAuthOrange, kAuthOrangeDeep],
              ),
              boxShadow: [
                BoxShadow(
                  color: kAuthOrange.withOpacity(t.isDark ? 0.30 : 0.35),
                  blurRadius: 22,
                  spreadRadius: -2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(3.5),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.isDark ? const Color(0xFF1C1D22) : Colors.white,
                ),
                child: userPhoto.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          userPhoto,
                          width: 113,
                          height: 113,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person_rounded,
                            size: 58,
                            color: t.textSecondary,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.person_rounded,
                        size: 58,
                        color: t.textSecondary,
                      ),
              ),
            ),
          ),
          Positioned(
            top: 2,
            left: 6,
            child: Transform.rotate(
              angle: -0.18,
              child: _buildBadgeIcon(t, Icons.calculate_outlined),
            ),
          ),
          Positioned(
            top: 4,
            right: 6,
            child: Transform.rotate(
              angle: 0.15,
              child: _buildBadgeIcon(t, Icons.monetization_on_outlined),
            ),
          ),
          Positioned(
            bottom: 6,
            left: 2,
            child: Transform.rotate(
              angle: -0.1,
              child: _buildBadgeIcon(t, Icons.show_chart_rounded),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 4,
            child: Transform.rotate(
              angle: 0.18,
              child: _buildBadgeIcon(t, Icons.percent_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeIcon(AuthTokens t, IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: t.isDark ? const Color(0xFF2A2B31) : Colors.white,
        border: Border.all(color: t.glassBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(t.isDark ? 0.25 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: kAuthOrange, size: 17),
    );
  }

  // ==========================================================
  // DIALOG LOGOUT
  // ==========================================================
  void _showLogoutDialog(AuthTokens t) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AuthGlassCard(
              t: t,
              radius: 30,
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('Keluar dari akun?', 'Log out?'),
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.4,
                      color: t.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr(
                      'Kamu perlu masuk lagi untuk melihat riwayat perhitunganmu.',
                      'You will need to sign in again to see your calculation history.',
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      height: 1.5,
                      color: t.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(
                          tr('Batal', 'Cancel'),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: t.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AuthActionButton(
                        t: t,
                        label: tr('Keluar', 'Log out'),
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          try {
                            await _profileViewModel.logout();
                            if (!mounted) return;
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginView(),
                              ),
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ================================================================
// TOGGLE BAHASA: ID | EN
// ================================================================
class _LanguageToggle extends StatelessWidget {
  final bool isDark;

  const _LanguageToggle({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final t = AuthTokens(isDark);
    final isEn = LanguageViewModel.isEnglish;

    Widget segment(String label, String code, bool selected) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => LanguageViewModel.setLanguage(code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kAuthOrangeSoft, kAuthOrange, kAuthOrangeDeep],
                  )
                : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: kAuthOrange.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : t.textSecondary,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: t.fieldFill,
        border: Border.all(color: t.fieldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          segment('ID', 'id', !isEn),
          segment('EN', 'en', isEn),
        ],
      ),
    );
  }
}

// ================================================================
// TOMBOL EDIT PROFIL (pil gradasi oranye, ukuran tetap di tengah)
// ================================================================
class _EditProfileButton extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _EditProfileButton({
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: kAuthOrange.withOpacity(isDark ? 0.40 : 0.45),
            blurRadius: 22,
            spreadRadius: -2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kAuthOrangeSoft, kAuthOrange, kAuthOrangeDeep],
              stops: [0.0, 0.55, 1.0],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.45), width: 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            splashColor: Colors.white.withOpacity(0.25),
            highlightColor: Colors.white.withOpacity(0.10),
            onTap: onTap,
            child: SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}