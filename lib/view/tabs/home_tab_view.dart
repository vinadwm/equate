import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:equate/model/user_model.dart';
import 'package:equate/model/gold_price_model.dart';
import 'package:equate/viewmodel/auth_viewmodel.dart';
import 'package:equate/viewmodel/gold_viewmodel.dart';
import 'package:equate/viewmodel/theme_viewmodel.dart';

class HomeTabView extends StatefulWidget {
  const HomeTabView({super.key});

  @override
  State<HomeTabView> createState() => _HomeTabViewState();
}

class _HomeTabViewState extends State<HomeTabView> {
  UserModel? _user;
  bool _isLoadingUser = true;

  final AuthViewModel _authViewModel = AuthViewModel();
  final GoldViewModel _goldViewModel = GoldViewModel();

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    _loadUser();

    // Ambil harga emas
    _goldViewModel.startLivePriceUpdates();

    _goldViewModel.addListener(_onGoldPriceChanged);
  }

  void _onGoldPriceChanged() {
    if (!mounted) return;

    setState(() {});
  }

  @override
  void dispose() {
    _goldViewModel.removeListener(_onGoldPriceChanged);
    super.dispose();
  }

  // ============================================================
  // LOAD USER
  // ============================================================

  Future<void> _loadUser() async {
    try {
      final user = await _authViewModel.getUserData();

      if (!mounted) return;

      setState(() {
        _user = user;
        _isLoadingUser = false;
      });
    } catch (e) {
      debugPrint('LOAD USER ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingUser = false;
      });
    }
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

        final primaryTextColor = isDarkMode ? Colors.white : Colors.black;

        final secondaryTextColor = isDarkMode
            ? Colors.grey[400]!
            : Colors.grey[600]!;

        final borderColor = isDarkMode
            ? Colors.grey[800]!
            : const Color(0xFFE0E0E0);

        final gold = _goldViewModel.goldPrice;

        return Scaffold(
          backgroundColor: bgColor,

          body: SafeArea(
            child: RefreshIndicator(
              color: primaryOrange,

              onRefresh: () async {
                await _goldViewModel.startLivePriceUpdates();
              },

              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),

                padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // HEADER USER
                    // ==================================================
                    _buildUserHeader(primaryOrange: primaryOrange),

                    const SizedBox(height: 24),

                    // ==================================================
                    // LAST PRICE
                    // ==================================================
                    _buildLastPriceCard(
                      gold: gold,
                      isLoading: _goldViewModel.isLoading,
                      isDarkMode: isDarkMode,
                      cardBgColor: cardBgColor,
                      borderColor: borderColor,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // DATE
                    // ==================================================
                    _buildDatePicker(
                      primaryOrange: primaryOrange,
                      cardBgColor: cardBgColor,
                      borderColor: borderColor,
                      textColor: primaryTextColor,
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // OPEN / CLOSE
                    // ==================================================
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Open',
                            value: gold != null
                                ? gold.open.toStringAsFixed(2)
                                : '---',
                            icon: Icons.wb_sunny_outlined,
                            iconBgColor: isDarkMode
                                ? const Color(0xFF332A00)
                                : const Color(0xFFFFFDE7),
                            iconColor: Colors.amber[700]!,
                            valueColor: primaryTextColor,
                            cardBgColor: cardBgColor,
                            borderColor: borderColor,
                            secondaryTextColor: secondaryTextColor,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: _buildMetricCard(
                            title: 'Close',
                            value: gold != null
                                ? gold.close.toStringAsFixed(2)
                                : '---',
                            icon: Icons.nightlight_round_outlined,
                            iconBgColor: isDarkMode
                                ? const Color(0xFF2C3E50)
                                : const Color(0xFF1E293B),
                            iconColor: Colors.amber,
                            valueColor: primaryTextColor,
                            cardBgColor: cardBgColor,
                            borderColor: borderColor,
                            secondaryTextColor: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // HIGH / LOW
                    // ==================================================
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: 'High',
                            value: gold != null
                                ? gold.high.toStringAsFixed(2)
                                : '---',
                            icon: Icons.trending_up,
                            iconBgColor: isDarkMode
                                ? const Color(0xFF1B3E20)
                                : const Color(0xFFE8F5E9),
                            iconColor: const Color(0xFF4CAF50),
                            valueColor: const Color(0xFF4CAF50),
                            cardBgColor: cardBgColor,
                            borderColor: borderColor,
                            secondaryTextColor: secondaryTextColor,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: _buildMetricCard(
                            title: 'Low',
                            value: gold != null
                                ? gold.low.toStringAsFixed(2)
                                : '---',
                            icon: Icons.trending_down,
                            iconBgColor: isDarkMode
                                ? const Color(0xFF3E1A1A)
                                : const Color(0xFFFFEBEE),
                            iconColor: const Color(0xFFEF5350),
                            valueColor: const Color(0xFFEF5350),
                            cardBgColor: cardBgColor,
                            borderColor: borderColor,
                            secondaryTextColor: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // INFO SUMBER DATA
                    // ==================================================
                    _buildSourceInfo(
                      isDarkMode: isDarkMode,
                      secondaryTextColor: secondaryTextColor,
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

  // ============================================================
  // USER HEADER
  // ============================================================

  Widget _buildUserHeader({required Color primaryOrange}) {
    final String firstName = _user?.firstName.trim() ?? '';

    final String greeting = _isLoadingUser
        ? 'Hai, ...'
        : firstName.isNotEmpty
        ? 'Halo, $firstName'
        : 'Halo, Pengguna';

    return Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: Colors.grey[200],

          backgroundImage:
              _user?.photo != null && _user!.photo!.trim().isNotEmpty
              ? NetworkImage(_user!.photo!)
              : null,

          child: _user?.photo == null || _user!.photo!.trim().isEmpty
              ? Icon(Icons.person_rounded, color: Colors.grey[500], size: 22)
              : null,
        ),

        const SizedBox(width: 12),

        Text(
          greeting,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: primaryOrange,
          ),
        ),
      ],
    );
  }

 // ============================================================
  // LAST PRICE CARD
  // ============================================================

  Widget _buildLastPriceCard({
    required GoldPriceModel? gold,
    required bool isLoading,
    required bool isDarkMode,
    required Color cardBgColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    final double change = gold?.changePercentage ?? 0;
    final bool isPositive = change >= 0;
    final Color changeColor = isPositive
        ? const Color(0xFF4CAF50)
        : const Color(0xFFEF5350);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TITLE & PERCENTAGE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HARGA EMAS GLOBAL',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: secondaryTextColor,
                ),
              ),
              if (gold != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: changeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${isPositive ? '↑' : '↓'} ${change.abs().toStringAsFixed(2)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: changeColor,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // PRICE
          if (isLoading)
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: changeColor,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Memuat harga...',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  gold != null ? '\$${gold.close.toStringAsFixed(2)}' : '---',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'USD / oz',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 6),

          Text(
            'Harga emas dunia per troy ounce',
            style: GoogleFonts.poppins(fontSize: 11, color: secondaryTextColor),
          ),

          const Divider(height: 28),

          // DATE & STATUS BADGE
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 16,
                color: secondaryTextColor,
              ),
              const SizedBox(width: 6),
              Text(
                gold?.formattedDate ?? gold?.date.toString() ?? 'Belum tersedia',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: secondaryTextColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'DATA TERBARU',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Widget _buildDatePicker({
    required Color primaryOrange,
    required Color cardBgColor,
    required Color borderColor,
    required Color textColor,
  }) {
    final dateFormatted = DateFormat(
      'dd MMMM yyyy',
      'id_ID',
    ).format(_selectedDate);

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );

        if (picked != null) {
          setState(() {
            _selectedDate = picked;
          });
        }
      },

      child: Container(
        width: double.infinity,

        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),

        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 20, color: primaryOrange),

            const SizedBox(width: 12),

            Text(
              dateFormatted,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),

            const Spacer(),

            Container(
              width: 32,
              height: 32,

              decoration: BoxDecoration(
                color: primaryOrange,
                borderRadius: BorderRadius.circular(8),
              ),

              child: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // METRIC CARD
  // ============================================================

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required Color valueColor,
    required Color cardBgColor,
    required Color borderColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,

                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),

                child: Icon(icon, size: 18, color: iconColor),
              ),

              const Spacer(),

              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            'USD / oz',
            style: GoogleFonts.poppins(fontSize: 9, color: secondaryTextColor),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SOURCE INFO
  // ============================================================

  Widget _buildSourceInfo({
    required bool isDarkMode,
    required Color secondaryTextColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 16, color: secondaryTextColor),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            'Data harga emas global bersumber dari Newsmaker.id. '
            'Harga ditampilkan dalam USD per troy ounce.',
            style: GoogleFonts.poppins(
              fontSize: 10,
              height: 1.5,
              color: secondaryTextColor,
            ),
          ),
        ),
      ],
    );
  }
}