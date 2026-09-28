import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:equate/view/tabs/change_password_view.dart';
import 'package:equate/view/tabs/edit_profile_view.dart';
import 'package:equate/view/history/history_view.dart';
import 'package:equate/view/auth/login_view.dart';
import 'package:equate/view/auth/auth_glass_widgets.dart';
import 'package:equate/viewmodel/theme_viewmodel.dart';
import 'package:equate/viewmodel/profile_viewmodel.dart';

// ==========================================================
// IMPORT MODELS (untuk parsing dokumen Firestore riwayat)
// ==========================================================
import 'package:equate/model/digital_gold_model.dart';
import 'package:equate/model/physical_gold_model.dart';
import 'package:equate/model/pivot_gold_model.dart';
import 'package:equate/model/pivot_hangseng_model.dart';
import 'package:equate/model/nest_gold_model.dart';
import 'package:equate/model/nest_hangseng_model.dart';

class ProfileTabView extends StatefulWidget {
  const ProfileTabView({super.key});

  @override
  State<ProfileTabView> createState() => _ProfileTabViewState();
}

class _ProfileTabViewState extends State<ProfileTabView> {
  static const int _kMaxHistoryItems = 6;

  final ProfileViewModel _profileViewModel = ProfileViewModel();

  // ==========================================================
  // RIWAYAT PERHITUNGAN (dari Firestore)
  // ==========================================================
  List<Map<String, dynamic>> _calculationHistory = [];
  bool _isHistoryLoading = true;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _historySub;

  @override
  void initState() {
    super.initState();
    _profileViewModel.addListener(_onProfileChanged);
    _profileViewModel.loadProfile();
    _listenToHistory();
  }

  void _onProfileChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openHistoryView() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final historiesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('histories');

    try {
      final snapshot = await historiesRef
          .orderBy('createdAt', descending: true)
          .get();

      final List<dynamic> historyList = [];

      for (final doc in snapshot.docs) {
        try {
          final model = _parseFirestoreDoc(doc);

          historyList.add(model);
        } catch (e) {
          debugPrint('Gagal parsing history ${doc.id}: $e');
        }
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HistoryView(
            historyList: historyList,
            historyCollection: historiesRef,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil riwayat: $e')));
    }
  }

  // ==========================================================
  // DENGARKAN STATUS LOGIN DULU, BARU subscribe ke Firestore:
  // users/{uid}/histories
  // ==========================================================
  void _listenToHistory() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _historySub?.cancel();
      _historySub = null;

      if (user == null) {
        if (!mounted) return;
        setState(() {
          _calculationHistory = [];
          _isHistoryLoading = false;
        });
        return;
      }

      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('histories')
          .orderBy('createdAt', descending: true);

      _historySub = ref.snapshots().listen(
        (snapshot) {
          if (!mounted) return;

          // Parsing per-dokumen dibungkus try/catch supaya satu dokumen
          // yang gagal tidak menggagalkan seluruh list.
          final mapped = <Map<String, dynamic>>[];
          for (final doc in snapshot.docs) {
            try {
              final model = _parseFirestoreDoc(doc);
              if (model == null) continue;
              mapped.add(_mapToDisplayItem(model));
            } catch (e) {
              debugPrint('❌ Gagal parsing riwayat profil [${doc.id}]: $e');
            }
          }

          setState(() {
            _calculationHistory = mapped;
            _isHistoryLoading = false;
          });
        },
        onError: (e) {
          debugPrint('❌ historySub (profile) stream error: $e');
          if (!mounted) return;
          setState(() => _isHistoryLoading = false);
        },
      );
    });
  }

  // ==========================================================
  // FIRESTORE DOC PARSER HELPER (samakan dengan calculator_tab_view)
  // ==========================================================
  dynamic _parseFirestoreDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final category = (data['category'] ?? '').toString().trim();

    switch (category) {
      case 'NEST Gold':
        return NestGoldModel.fromFirestore(doc);

      case 'Emas Digital':
      case 'Digital Gold':
        return DigitalGoldModel.fromFirestore(doc);

      case 'Emas Fisik':
      case 'Physical Gold':
        return PhysicalGoldModel.fromFirestore(doc);

      case 'Pivot Gold':
        return PivotGoldModel.fromFirestore(doc);

      case 'Pivot Hangseng':
        return PivotHangsengModel.fromFirestore(doc);

      case 'NEST Hangseng':
        return NestHangsengModel.fromFirestore(doc);

      default:
        debugPrint('⚠️ Category history tidak dikenali: $category');
        return null;
    }
  }

  // ==========================================================
  // UBAH MODEL RIWAYAT -> MAP UNTUK TAMPILAN
  // ==========================================================
  Map<String, dynamic> _mapToDisplayItem(dynamic item) {
    String title = 'Riwayat';
    String details = 'Detail Perhitungan';
    double result = 0.0;
    DateTime timestamp = DateTime.now();
    bool isCurrency = true;

    if (item is DigitalGoldModel) {
      title = 'Emas Digital';
      details =
          '${item.weightInGram} Lot | Beli: ${_formatCurrency(item.buyPrice)}';
      result = item.profitLoss;
      timestamp = item.createdAt;
    } else if (item is PhysicalGoldModel) {
      title = 'Emas Fisik';
      details =
          '${item.weightInGram} gram | Rp ${_formatCurrency(item.buyPrice)}/g';
      result = item.profitLoss;
      timestamp = item.createdAt;
    } else if (item is PivotGoldModel) {
      title = 'Pivot Point Emas';
      details = 'PP: ${item.pp} | R1: ${item.r1} | S1: ${item.s1}';
      result = item.pp;
      isCurrency = false;
      timestamp = item.createdAt;
    } else if (item is NestGoldModel) {
      title = 'NEST Emas';
      details = 'Signal: ${item.signalLabel} | Open: ${item.open ?? '-'}';
      result = item.close ?? 0.0;
      isCurrency = false;
      timestamp = item.createdAt;
    } else if (item is PivotHangsengModel) {
      title = 'Pivot Point Hangseng';
      details =
          'PP: ${item.pp ?? '-'} | H: ${item.high ?? '-'} | L: ${item.low ?? '-'}';
      result = item.pp ?? 0.0;
      isCurrency = false;
      timestamp = item.createdAt;
    } else if (item is NestHangsengModel) {
      title = 'NEST Hangseng';
      details = 'Signal: ${item.signalLabel} | Open: ${item.open ?? '-'}';
      result = item.close ?? 0.0;
      isCurrency = false;
      timestamp = item.createdAt;
    } else {
      title = (item.title ?? 'Riwayat').toString();
      details = (item.details ?? 'Detail perhitungan').toString();
      if (item.createdAt is DateTime) timestamp = item.createdAt;
    }

    final isPositive = result >= 0;

    final String resultLabel = isCurrency
        ? '${isPositive ? '+Rp ' : '-Rp '}${_formatCurrency(result)}'
        : result.toStringAsFixed(2);

    return {
      'title': title,
      'details': details,
      'resultLabel': resultLabel,
      'isCurrency': isCurrency,
      'isPositive': isPositive,
      'dateTime': DateFormat('d MMM yyyy • HH:mm', 'id_ID').format(timestamp),
    };
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );
    return formatter.format(amount.abs()).trim();
  }

  @override
  void dispose() {
    _historySub?.cancel();
    _authSub?.cancel();
    _profileViewModel.removeListener(_onProfileChanged);
    _profileViewModel.dispose();
    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeViewModel.themeMode,
      builder: (context, currentThemeMode, child) {
        final isDark = ThemeViewModel.isDarkMode;
        final t = AuthTokens(isDark);

        final primaryTextColor = isDark
            ? Colors.white
            : const Color(0xFF2C2D30);

        final secondaryTextColor = isDark
            ? const Color(0xFF9A9A9E)
            : const Color(0xFF7D828A);

        if (_profileViewModel.isLoading) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0D0E12) : Colors.white,
            body: _ProfileBackground(
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

        final displayHistory = _calculationHistory
            .take(_kMaxHistoryItems)
            .toList();

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0D0E12) : Colors.white,
          body: _ProfileBackground(
            isDark: isDark,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 130),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==================================================
                      // PROFIL (langsung di atas background)
                      // ==================================================
                      Center(child: _buildAvatar(t, userPhoto)),

                      const SizedBox(height: 6),

                      Center(
                        child: Text(
                          userName.isNotEmpty ? userName : 'Nama Pengguna',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: primaryTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Center(
                        child: Text(
                          userEmail.isNotEmpty ? userEmail : 'email@domain.com',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      Row(
                        children: [
                          Expanded(
                            child: _GradientPillButton(
                              label: 'Edit Profil',
                              icon: Icons.edit_outlined,
                              isDark: isDark,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const EditProfileView(),
                                  ),
                                );
                                await _profileViewModel.refreshProfile();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _GlassPillButton(
                              t: t,
                              label: 'Ubah Sandi',
                              icon: Icons.lock_outline_rounded,
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
                          ),
                          const SizedBox(width: 8),
                          _buildThemeToggle(t),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // ---------- HEADER RIWAYAT ----------
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: kAuthOrange.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.history_rounded,
                                    color: kAuthOrange,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FittedBox(
                                    alignment: Alignment.centerLeft,
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Riwayat Perhitungan',
                                      maxLines: 1,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_calculationHistory.isNotEmpty)
                            InkWell(
                              onTap: _openHistoryView,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                child: Text(
                                  'Lihat Semua',
                                  maxLines: 1,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: kAuthOrange,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // ---------- DAFTAR RIWAYAT ----------
                      if (_isHistoryLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: kAuthOrange,
                            ),
                          ),
                        )
                      else if (_calculationHistory.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'Belum ada riwayat perhitungan',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                        )
                      else ...[
                        ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: displayHistory.length,
                          separatorBuilder: (context, index) {
                            return Divider(
                              color: isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.black.withOpacity(0.05),
                              height: 20,
                            );
                          },
                          itemBuilder: (context, index) {
                            return _buildHistoryRow(
                              item: displayHistory[index],
                              primaryTextColor: primaryTextColor,
                            );
                          },
                        ),
                        if (_calculationHistory.length > _kMaxHistoryItems) ...[
                          const SizedBox(height: 14),
                          Center(
                            child: Text(
                              'Klik lihat semua untuk melihat riwayat lebih lengkap',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ],

                      const SizedBox(height: 28),

                      // ==================================================
                      // TOMBOL KELUAR
                      // ==================================================
                      _buildLogoutButton(t),
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
  // BARIS RIWAYAT
  // ==========================================================
  Widget _buildHistoryRow({
    required Map<String, dynamic> item,
    required Color primaryTextColor,
  }) {
    final isCurrency = item['isCurrency'] as bool;
    final isPositive = item['isPositive'] as bool;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['title'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item['details'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
              Text(
                item['dateTime'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          item['resultLabel'] as String,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: !isCurrency
                ? primaryTextColor
                : (isPositive
                      ? const Color(0xFF34C759)
                      : const Color(0xFFFF3B30)),
          ),
        ),
      ],
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
  // TOGGLE TEMA
  // ==========================================================
  Widget _buildThemeToggle(AuthTokens t) {
    return Material(
      color: t.fieldFill,
      shape: CircleBorder(side: BorderSide(color: t.fieldBorder)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => ThemeViewModel.toggleTheme(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            t.isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
            color: kAuthOrange,
            size: 20,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // TOMBOL KELUAR (baris dengan ikon bulat merah + panah kecil)
  // ==========================================================
  Widget _buildLogoutButton(AuthTokens t) {
    const red = Color(0xFFFF3B30);

    return Material(
      color: red.withOpacity(t.isDark ? 0.12 : 0.07),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        splashColor: red.withOpacity(0.12),
        highlightColor: red.withOpacity(0.06),
        onTap: () => _showLogoutDialog(t),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: red.withOpacity(t.isDark ? 0.22 : 0.14),
                ),
                child: const Icon(Icons.logout_rounded, color: red, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Keluar dari akun',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: red,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: red.withOpacity(0.7),
                size: 22,
              ),
            ],
          ),
        ),
      ),
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
                    'Keluar dari akun?',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.4,
                      color: t.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kamu perlu masuk lagi untuk melihat riwayat perhitunganmu.',
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
                          'Batal',
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
                        label: 'Keluar',
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
// BACKGROUND POLOS (sama seperti beranda):
// gradasi lembut + glow oranye tipis + watermark logo (kiri bawah).
// ================================================================
class _ProfileBackground extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const _ProfileBackground({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradasi dasar
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

        // Glow oranye tipis
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

        // Watermark logo (kiri bawah)
        Positioned(
          bottom: 90,
          left: -60,
          child: IgnorePointer(
            child: Opacity(
              opacity: isDark ? 0.10 : 0.06,
              child: Image.asset(
                'assets/images/logoEWF.png',
                width: 260,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
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
// TOMBOL PIL GRADASI ORANYE (untuk "Edit Profil")
// ================================================================
class _GradientPillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _GradientPillButton({
    required this.label,
    required this.icon,
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
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 8),
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
              height: 46,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          maxLines: 1,
                          softWrap: false,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
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
        ),
      ),
    );
  }
}

// ================================================================
// TOMBOL PIL KACA (untuk "Ubah Sandi")
// ================================================================
class _GlassPillButton extends StatelessWidget {
  final AuthTokens t;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GlassPillButton({
    required this.t,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: t.fieldFill,
      shape: StadiumBorder(side: BorderSide(color: t.fieldBorder)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        splashColor: kAuthOrange.withOpacity(0.15),
        onTap: onTap,
        child: SizedBox(
          height: 46,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: kAuthOrange, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: t.textPrimary,
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