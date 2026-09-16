import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:equate/viewmodel/theme_viewmodel.dart';
import 'package:equate/viewmodel/historical_data_viewmodel.dart';

// ==========================================================
// CALCULATOR CONTENT
// ==========================================================
import 'calculator/gold_digital_calculator_content.dart';
import 'calculator/gold_physical_calculator_content.dart';
import 'calculator/pivot_gold_calculator_content.dart';
import 'calculator/pivot_hangseng_calculator_content.dart';

// ==========================================================
// CUSTOM MENU
// ==========================================================
import 'custom_calculator_menu.dart';

// ==========================================================
// MODEL RIWAYAT
// ==========================================================
class CalculationHistory {
  final String title;
  final String details;
  final double result;
  final DateTime timestamp;

  CalculationHistory({
    required this.title,
    required this.details,
    required this.result,
    required this.timestamp,
  });
}

// ==========================================================
// CALCULATOR TAB VIEW
// ==========================================================
class CalculatorTabView extends StatefulWidget {
  // ========================================================
  // SHARED HISTORICAL VIEWMODEL
  // Dipakai juga oleh HomeTabView
  // ========================================================
  final HistoricalDataViewModel historicalDataViewModel;

  const CalculatorTabView({super.key, required this.historicalDataViewModel});

  @override
  State<CalculatorTabView> createState() => _CalculatorTabViewState();
}

class _CalculatorTabViewState extends State<CalculatorTabView> {
  // ==========================================================
  // CALCULATOR YANG SEDANG DIPILIH
  // ==========================================================
  String? _selectedCalculatorType;

  bool _isGoldDropdownOpen = false;
  bool _isHangsengDropdownOpen = false;

  // ==========================================================
  // OPTION EMAS
  // ==========================================================
  final List<Map<String, dynamic>> _goldOptions = [
    {
      'title': 'Emas Digital',
      'description': 'Kalkulasi transaksi jual beli emas digital/online.',
      'icon': Icons.account_balance_wallet_rounded,
    },
    {
      'title': 'Emas Fisik',
      'description': 'Hitung konversi & biaya cetak batang/perhiasan.',
      'icon': Icons.view_in_ar_rounded,
    },
    {
      'title': 'Pivot Point Emas',
      'description': 'Analisis level Support & Resistance harian.',
      'icon': Icons.analytics_rounded,
    },
  ];

  // ==========================================================
  // OPTION HANGSENG
  // ==========================================================
  final List<Map<String, dynamic>> _hangsengOptions = [
    {
      'title': 'Pivot Point Hangseng',
      'description': 'Analisis Support & Resistance transaksi indeks Hangseng.',
      'icon': Icons.candlestick_chart_rounded,
    },
  ];

  // ==========================================================
  // HISTORY
  // ==========================================================
  final List<CalculationHistory> _historyList = [];

  void _addHistory(dynamic item) {
    if (item is CalculationHistory) {
      setState(() {
        _historyList.insert(0, item);
      });
    }
  }

  // ==========================================================
  // FORMAT CURRENCY
  // ==========================================================
  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );

    return formatter.format(amount.abs()).trim();
  }

  // ==========================================================
  // BUILD
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeViewModel.themeMode,
      builder: (context, currentThemeMode, child) {
        final isDarkMode = ThemeViewModel.isDarkMode;

        final primaryTextColor = isDarkMode
            ? Colors.white
            : const Color(0xFF2C2D30);

        final bgGradientStart = isDarkMode
            ? const Color(0xFF16181F)
            : Colors.white;

        final bgGradientEnd = isDarkMode
            ? const Color(0xFF0D0E12)
            : Colors.white;

        return Scaffold(
          backgroundColor: isDarkMode ? const Color(0xFF0D0E12) : Colors.white,

          body: Stack(
            alignment: Alignment.center,
            children: [
              // ======================================================
              // LAYER 1 - BACKGROUND
              // ======================================================
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [bgGradientStart, bgGradientEnd],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // ======================================================
              // LAYER 2 - DARK MODE GLOW
              // ======================================================
              if (isDarkMode)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.8,
                        colors: [
                          const Color(0xFFFF9500).withOpacity(0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              // ======================================================
              // LAYER 3 - LOGO WATERMARK
              // ======================================================
              Opacity(
                opacity: isDarkMode ? 0.22 : 0.15,
                child: Image.asset(
                  'assets/images/logoEWF.png',
                  width: 310,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),

              // ======================================================
              // LAYER 4 - CONTENT
              // ======================================================
              SafeArea(
                child: Column(
                  children: [
                    // ==================================================
                    // HEADER
                    // ==================================================
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 20,
                              color: primaryTextColor,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              if (_selectedCalculatorType != null) {
                                setState(() {
                                  _selectedCalculatorType = null;
                                });
                              } else {
                                Navigator.pop(context);
                              }
                            },
                          ),

                          Expanded(
                            child: Text(
                              _selectedCalculatorType == null
                                  ? 'Kalkulator'
                                  : _getCalculatorTitle(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                color: primaryTextColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),

                          const SizedBox(width: 20),
                        ],
                      ),
                    ),

                    // ==================================================
                    // CONTENT
                    // ==================================================
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: _selectedCalculatorType == null
                            ? _buildLobbyView(
                                context,
                                isDarkMode,
                                primaryTextColor,
                              )
                            : _buildActiveCalculatorView(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // LOBBY VIEW
  // ==========================================================
  Widget _buildLobbyView(
    BuildContext context,
    bool isDarkMode,
    Color primaryTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        // ======================================================
        // TITLE
        // ======================================================
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Pasar & Instrumen',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: primaryTextColor,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Hitung estimasi profit, margin, dan pivot point transaksi.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDarkMode
                      ? const Color(0xFF9A9A9E)
                      : const Color(0xFF7D828A),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ======================================================
        // MARKET BUTTONS
        // ======================================================
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // ==================================================
              // EMAS
              // ==================================================
              _buildSoftClayButton(
                context,
                title: 'Emas (XUL)',
                subtitle: 'Kalkulator Emas Digital, Fisik & Pivot',
                icon: Icons.monetization_on_rounded,
                isExpanded: _isGoldDropdownOpen,
                onPressed: () {
                  setState(() {
                    _isGoldDropdownOpen = !_isGoldDropdownOpen;

                    if (_isGoldDropdownOpen) {
                      _isHangsengDropdownOpen = false;
                    }
                  });
                },
              ),

              // ==================================================
              // GOLD MENU
              // ==================================================
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                child: _isGoldDropdownOpen
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: CustomCalculatorMenu(
                          options: _goldOptions,
                          onCalculatorSelected: (selectedName) {
                            setState(() {
                              _isGoldDropdownOpen = false;

                              if (selectedName == 'Emas Fisik') {
                                _selectedCalculatorType = 'physical';
                              } else if (selectedName == 'Emas Digital') {
                                _selectedCalculatorType = 'digital';
                              } else if (selectedName == 'Pivot Point Emas') {
                                _selectedCalculatorType = 'pivot';
                              }
                            });
                          },
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // HANGSENG
              // ==================================================
              _buildSoftClayButton(
                context,
                title: 'Hangseng (HKK)',
                subtitle: 'Kalkulator Pivot Point Indeks',
                icon: Icons.trending_up_rounded,
                isExpanded: _isHangsengDropdownOpen,
                onPressed: () {
                  setState(() {
                    _isHangsengDropdownOpen = !_isHangsengDropdownOpen;

                    if (_isHangsengDropdownOpen) {
                      _isGoldDropdownOpen = false;
                    }
                  });
                },
              ),

              // ==================================================
              // HANGSENG MENU
              // ==================================================
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                child: _isHangsengDropdownOpen
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: CustomCalculatorMenu(
                          options: _hangsengOptions,
                          onCalculatorSelected: (selectedName) {
                            setState(() {
                              _isHangsengDropdownOpen = false;

                              if (selectedName == 'Pivot Point Hangseng') {
                                _selectedCalculatorType = 'hangseng_pivot';
                              }
                            });
                          },
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // ======================================================
        // HISTORY
        // ======================================================
        _buildHistorySection(
          isDarkMode: isDarkMode,
          primaryTextColor: primaryTextColor,
        ),

        const SizedBox(height: 28),
      ],
    );
  }

  // ==========================================================
  // ACTIVE CALCULATOR
  // ==========================================================
  Widget _buildActiveCalculatorView() {
    switch (_selectedCalculatorType) {
      // ======================================================
      // EMAS DIGITAL
      // ======================================================
      case 'digital':
        return GoldDigitalCalculatorContent();

      // ======================================================
      // EMAS FISIK
      // ======================================================
      case 'physical':
        return GoldPhysicalCalculatorContent(
          onCalculate: (data) {
            _addHistory(data);
          },
        );

      // ======================================================
      // PIVOT EMAS
      // ======================================================
      case 'pivot':
        return PivotGoldCalculatorContent(
          historicalDataViewModel: widget.historicalDataViewModel,
          onCalculate: (data) {
            _addHistory(data);
          },
        );

      // ======================================================
      // PIVOT HANGSENG
      // ======================================================
      case 'hangseng_pivot':
        return PivotHangsengCalculatorContent(
          historicalDataViewModel: widget.historicalDataViewModel,
          onCalculate: (data) {
            _addHistory(data);
          },
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // ==========================================================
  // TITLE
  // ==========================================================
  String _getCalculatorTitle() {
    switch (_selectedCalculatorType) {
      case 'digital':
        return 'Emas Digital';

      case 'physical':
        return 'Emas Fisik';

      case 'pivot':
        return 'Pivot Point Emas';

      case 'hangseng_pivot':
        return 'Pivot Hangseng';

      default:
        return 'Kalkulator';
    }
  }

  // ==========================================================
  // SOFT CLAY BUTTON
  // ==========================================================
  Widget _buildSoftClayButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onPressed,
  }) {
    final isDarkMode = ThemeViewModel.isDarkMode;

    const primaryOrange = Color(0xFFFF9500);

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1E1F24).withOpacity(0.75)
            : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isExpanded
              ? primaryOrange.withOpacity(0.5)
              : isDarkMode
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.9),
          width: isExpanded ? 0.8 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded
                ? primaryOrange.withOpacity(0.18)
                : Colors.black.withOpacity(isDarkMode ? 0.25 : 0.04),
            blurRadius: isExpanded ? 16 : 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(22),
          splashColor: primaryOrange.withOpacity(0.12),
          highlightColor: primaryOrange.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                // ==================================================
                // ICON
                // ==================================================
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB700), Color(0xFFFF9500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9500).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),

                const SizedBox(width: 16),

                // ==================================================
                // TEXT
                // ==================================================
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF2C2D30),
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: isDarkMode
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF8A8E9B),
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // ARROW
                // ==================================================
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: isExpanded
                      ? primaryOrange
                      : isDarkMode
                      ? Colors.white54
                      : const Color(0xFF8A8E9B),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // HISTORY SECTION
  // ==========================================================
  Widget _buildHistorySection({
    required bool isDarkMode,
    required Color primaryTextColor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1E1F24).withOpacity(0.75)
            : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.9),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // HEADER
          // ======================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9500).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: Color(0xFFFF9500),
                      size: 18,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Text(
                    'Riwayat Perhitungan',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: primaryTextColor,
                    ),
                  ),
                ],
              ),

              if (_historyList.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _historyList.clear();
                    });
                  },
                  child: Text(
                    'Hapus',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // ======================================================
          // EMPTY
          // ======================================================
          if (_historyList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Belum ada riwayat perhitungan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                  ),
                ),
              ),
            )
          // ======================================================
          // LIST
          // ======================================================
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _historyList.length,

              separatorBuilder: (context, index) {
                return Divider(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.04),
                  height: 16,
                );
              },

              itemBuilder: (context, index) {
                final item = _historyList[index];

                final isPositive = item.result >= 0;

                final timeFormatted = DateFormat(
                  'HH:mm - dd MMM',
                ).format(item.timestamp);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // =================================================
                    // DETAIL
                    // =================================================
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: primaryTextColor,
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            item.details,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),

                          Text(
                            timeFormatted,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // =================================================
                    // RESULT
                    // =================================================
                    Text(
                      '${isPositive ? '+Rp ' : '-Rp '}${_formatCurrency(item.result)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isPositive
                            ? const Color(0xFF34C759)
                            : const Color(0xFFFF3B30),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}