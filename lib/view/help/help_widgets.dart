import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:equate/view/auth/auth_glass_widgets.dart';
import 'package:equate/viewmodel/language_viewmodel.dart';
import 'package:equate/viewmodel/theme_viewmodel.dart';

// ================================================================
// REBUILD OTOMATIS SAAT TEMA ATAU BAHASA BERUBAH
// ================================================================
class AppThemeLang extends StatelessWidget {
  final Widget Function(BuildContext context, bool isDark, AuthTokens t)
  builder;

  const AppThemeLang({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeViewModel.themeMode,
      builder: (context, _, __) {
        return ValueListenableBuilder<String>(
          valueListenable: LanguageViewModel.lang,
          builder: (context, _, __) {
            final isDark = ThemeViewModel.isDarkMode;
            return builder(context, isDark, AuthTokens(isDark));
          },
        );
      },
    );
  }
}

// ================================================================
// BACKGROUND POLOS
// ================================================================
class AppPlainBackground extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const AppPlainBackground({
    super.key,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF0D0E12), const Color(0xFF16181F)]
                    : [const Color(0xFFFFF8F0), Colors.white],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.9),
                  radius: 1.1,
                  colors: [
                    kAuthOrange.withOpacity(isDark ? 0.14 : 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          left: -60,
          child: IgnorePointer(
            child: Opacity(
              opacity: isDark ? 0.10 : 0.06,
              child: Image.asset(
                'assets/images/logoEWF.png',
                width: 260,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        SafeArea(child: child),
      ],
    );
  }
}

// ================================================================
// DEKORASI KARTU (dipakai kartu pengaturan, FAQ, panduan)
// ================================================================
BoxDecoration appCardDecoration(
  bool isDark, {
  double radius = 24,
  bool highlighted = false,
}) {
  return BoxDecoration(
    color: isDark
        ? const Color(0xFF1E1F24).withOpacity(0.75)
        : Colors.white.withOpacity(0.85),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: highlighted
          ? kAuthOrange.withOpacity(0.5)
          : (isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.9)),
      width: highlighted ? 0.9 : 0.6,
    ),
    boxShadow: [
      BoxShadow(
        color: highlighted
            ? kAuthOrange.withOpacity(0.14)
            : Colors.black.withOpacity(isDark ? 0.25 : 0.04),
        blurRadius: 14,
        offset: const Offset(0, 5),
      ),
    ],
  );
}

// ================================================================
// ANIMASI MASUK (fade + geser halus) — dipakai bertahap per item
// ================================================================
class AppFadeIn extends StatelessWidget {
  final Widget child;

  /// Urutan item; makin besar makin lama muncul (efek bertahap).
  final int index;

  const AppFadeIn({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final extra = index.clamp(0, 8) * 90;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 380 + extra),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, v, ch) {
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: ch),
        );
      },
    );
  }
}

// ================================================================
// TOMBOL KEMBALI BULAT
// ================================================================
class AppBackButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onTap;

  const AppBackButton({super.key, required this.isDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AuthTokens(isDark);

    return GestureDetector(
      onTap: onTap ?? () => Navigator.pop(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: t.textPrimary.withOpacity(0.9),
        ),
      ),
    );
  }
}

// ================================================================
// KERANGKA HALAMAN BANTUAN: tombol kembali + judul + isi
// ================================================================
class HelpScaffold extends StatelessWidget {
  final String titleId;
  final String titleEn;
  final String subtitleId;
  final String subtitleEn;
  final Widget Function(BuildContext context, bool isDark, AuthTokens t)
  builder;

  const HelpScaffold({
    super.key,
    required this.titleId,
    required this.titleEn,
    required this.subtitleId,
    required this.subtitleEn,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return AppThemeLang(
      builder: (context, isDark, t) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0D0E12) : Colors.white,
          body: AppPlainBackground(
            isDark: isDark,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 20, 0),
                  child: Row(
                    children: [
                      AppBackButton(isDark: isDark),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr(titleId, titleEn),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: t.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              tr(subtitleId, subtitleEn),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: t.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 40),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: builder(context, isDark, t),
                      ),
                    ),
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

// ================================================================
// KARTU MENU (baru) — kartu kaca yang bisa diketuk, dengan efek ripple
// ================================================================
class AppMenuCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool filledIcon;

  const AppMenuCard({
    super.key,
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.filledIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AuthTokens(isDark);

    return Container(
      decoration: appCardDecoration(isDark, radius: 22, highlighted: filledIcon),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            splashColor: kAuthOrange.withOpacity(0.10),
            highlightColor: kAuthOrange.withOpacity(0.04),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: filledIcon
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                kAuthOrangeSoft,
                                kAuthOrange,
                                kAuthOrangeDeep,
                              ],
                            )
                          : null,
                      color: filledIcon ? null : kAuthOrange.withOpacity(0.12),
                      boxShadow: filledIcon
                          ? [
                              BoxShadow(
                                color: kAuthOrange.withOpacity(0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: filledIcon ? Colors.white : kAuthOrange,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: t.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            height: 1.4,
                            color: t.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kAuthOrange.withOpacity(0.10),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: kAuthOrange,
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

// ================================================================
// BARIS MENU POLOS (tanpa kotak) — tetap dipertahankan agar halaman lain aman
// ================================================================
class AppListRow extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool filledIcon;

  const AppListRow({
    super.key,
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.filledIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AuthTokens(isDark);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      splashColor: kAuthOrange.withOpacity(0.10),
      highlightColor: kAuthOrange.withOpacity(0.04),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: filledIcon
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [kAuthOrangeSoft, kAuthOrange, kAuthOrangeDeep],
                      )
                    : null,
                color: filledIcon ? null : kAuthOrange.withOpacity(0.12),
                boxShadow: filledIcon
                    ? [
                        BoxShadow(
                          color: kAuthOrange.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: 22,
                color: filledIcon ? Colors.white : kAuthOrange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: t.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      height: 1.4,
                      color: t.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              size: 19,
              color: t.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class AppRowDivider extends StatelessWidget {
  final bool isDark;
  final double indent;

  const AppRowDivider({super.key, required this.isDark, this.indent = 70});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: indent,
      color: isDark
          ? Colors.white.withOpacity(0.07)
          : Colors.black.withOpacity(0.06),
    );
  }
}

// ================================================================
// KARTU PENGATURAN: satu kartu berisi beberapa baris
// ================================================================
class AppGroupCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const AppGroupCard({super.key, required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i != children.length - 1) {
        items.add(AppRowDivider(isDark: isDark, indent: 68));
      }
    }

    return Container(
      decoration: appCardDecoration(isDark),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(children: items),
      ),
    );
  }
}

class AppGroupRow extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const AppGroupRow({
    super.key,
    required this.isDark,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final t = AuthTokens(isDark);

    return InkWell(
      splashColor: kAuthOrange.withOpacity(0.10),
      highlightColor: kAuthOrange.withOpacity(0.04),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kAuthOrange.withOpacity(0.12),
              ),
              child: Icon(icon, size: 19, color: kAuthOrange),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: t.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: t.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  size: 23,
                  color: t.textSecondary,
                ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// LABEL SEKSI KECIL
// ================================================================
class AppSectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;

  const AppSectionLabel({super.key, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 0, 10),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.3,
          color: AuthTokens(isDark).textSecondary,
        ),
      ),
    );
  }
}