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

const Color _kRed = Color(0xFFFF3B30);

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

  Future<void> _openEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileView()),
    );
    await _profileViewModel.refreshProfile();
  }

  void _openHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HelpCenterView()),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return AppThemeLang(
      builder: (context, isDark, t) {
        final bg = isDark ? const Color(0xFF0D0E12) : Colors.white;

        if (_profileViewModel.isLoading) {
          return Scaffold(
            backgroundColor: bg,
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
          backgroundColor: bg,
          body: AppPlainBackground(
            isDark: isDark,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 130),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ================================================
                      // HEADER
                      // ================================================
                      _buildHeader(t, isDark, userPhoto, userName, userEmail),

                      const SizedBox(height: 34),

                      // ================================================
                      // PENGATURAN
                      // ================================================
                      AppSectionLabel(
                        text: tr('PENGATURAN', 'SETTINGS'),
                        isDark: isDark,
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
                            subtitle: tr(
                              'Indonesia / English',
                              'Indonesian / English',
                            ),
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
                            onTap: _openHelp,
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      _buildLogoutRow(t, isDark),

                      const SizedBox(height: 48),

                      // ================================================
                      // CREDITS
                      // ================================================
                      _buildCredits(t, isDark),
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
  // HEADER: foto kiri, nama & e-mail kanan, tombol edit,
  // dengan dekorasi lingkaran dan titik oranye di belakang.
  // ==========================================================
  Widget _buildHeader(
    AuthTokens t,
    bool isDark,
    String photo,
    String name,
    String email,
  ) {
    Widget dot(double size, double opacity) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kAuthOrange.withOpacity(opacity),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Lingkaran lembut besar (kanan atas)
        Positioned(
          right: -70,
          top: -60,
          child: IgnorePointer(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kAuthOrange.withOpacity(isDark ? 0.24 : 0.22),
                    kAuthOrange.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Lingkaran lembut kecil (kiri bawah)
        Positioned(
          left: -50,
          bottom: -40,
          child: IgnorePointer(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kAuthOrange.withOpacity(isDark ? 0.14 : 0.12),
                    kAuthOrange.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Titik-titik hiasan
        Positioned(right: 28, top: 6, child: IgnorePointer(child: dot(10, 0.5))),
        Positioned(right: 62, top: 34, child: IgnorePointer(child: dot(6, 0.32))),
        Positioned(right: 14, top: 52, child: IgnorePointer(child: dot(5, 0.26))),
        Positioned(right: 84, top: 8, child: IgnorePointer(child: dot(4, 0.22))),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatar(t, photo),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Akun Saya', 'My Account').toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          color: kAuthOrange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name.isNotEmpty
                            ? name
                            : tr('Nama Pengguna', 'User Name'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 21,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                          color: t.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: kAuthOrange.withOpacity(isDark ? 0.14 : 0.10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.alternate_email_rounded,
                              size: 12,
                              color: kAuthOrange,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                email.isNotEmpty ? email : 'email@domain.com',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: t.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _EditProfileButton(
              label: tr('Edit Profil', 'Edit Profile'),
              isDark: isDark,
              onTap: _openEditProfile,
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================================
  // AVATAR KECIL + titik status hijau
  // ==========================================================
  Widget _buildAvatar(AuthTokens t, String userPhoto) {
    return SizedBox(
      width: 82,
      height: 82,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kAuthOrangeSoft, kAuthOrange, kAuthOrangeDeep],
              ),
              boxShadow: [
                BoxShadow(
                  color: kAuthOrange.withOpacity(t.isDark ? 0.28 : 0.35),
                  blurRadius: 16,
                  spreadRadius: -2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.isDark ? const Color(0xFF1C1D22) : Colors.white,
                ),
                child: userPhoto.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          userPhoto,
                          width: 74,
                          height: 74,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person_rounded,
                            size: 38,
                            color: t.textSecondary,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.person_rounded,
                        size: 38,
                        color: t.textSecondary,
                      ),
              ),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF34C759),
                border: Border.all(
                  color: t.isDark ? const Color(0xFF16181F) : Colors.white,
                  width: 2.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BARIS KELUAR
  // ==========================================================
  Widget _buildLogoutRow(AuthTokens t, bool isDark) {
    return Container(
      decoration: appCardDecoration(isDark),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          splashColor: _kRed.withOpacity(0.10),
          highlightColor: _kRed.withOpacity(0.04),
          onTap: () => _showLogoutDialog(t),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kRed.withOpacity(0.12),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    size: 19,
                    color: _kRed,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('Keluar dari Akun', 'Log Out'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kRed,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tr(
                          'Kamu bisa masuk lagi kapan saja',
                          'You can sign in again any time',
                        ),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: t.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 23,
                  color: _kRed.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // CREDITS: tanpa judul, tanpa frame; hanya garis pemisah di tengah
  // ==========================================================
  Widget _buildCredits(AuthTokens t, bool isDark) {
    final lineColor = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.10);

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CreditItem(
                  t: t,
                  caption: 'Powered by',
                  name: 'PT Equityworld\nFutures',
                  logo: Image.asset(
                    'assets/images/logoEWF.png',
                    height: 56,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.business_rounded,
                      size: 40,
                      color: kAuthOrange,
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: lineColor,
              ),
              Expanded(
                child: _CreditItem(
                  t: t,
                  caption: 'Supported by',
                  name: 'Kepompong\nTeam',
                  logo: ClipOval(
                    child: Image.asset(
                      'assets/images/logoKepompong.jpeg',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.groups_rounded,
                        size: 40,
                        color: kAuthOrange,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        Text(
          'Equate © 2026',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: t.textSecondary.withOpacity(0.8),
          ),
        ),
      ],
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
// ITEM CREDIT: logo polos + keterangan + nama
// ================================================================
class _CreditItem extends StatelessWidget {
  final AuthTokens t;
  final String caption;
  final String name;
  final Widget logo;

  const _CreditItem({
    required this.t,
    required this.caption,
    required this.name,
    required this.logo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 56, child: Center(child: logo)),
        const SizedBox(height: 12),
        Text(
          caption.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: kAuthOrange,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: t.textPrimary,
          ),
        ),
      ],
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
// TOMBOL EDIT PROFIL (pil gradasi oranye, selebar layar)
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
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }
}