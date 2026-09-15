import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:equate/viewmodel/theme_viewmodel.dart';
import 'package:equate/viewmodel/gold_digital_viewmodel.dart';
import 'package:equate/viewmodel/historical_data_viewmodel.dart';

// IMPORT PATH KE SUB-FOLDER CALCULATOR
import 'calculator/gold_digital_calculator_content.dart';
import 'calculator/gold_physical_calculator_content.dart';
import 'calculator/pivot_gold_calculator_content.dart';

// ==========================================================
// MODEL SEDERHANA UNTUK DATA RIWAYAT
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

class CalculatorTabView extends StatefulWidget {
  // ========================================================
  // HistoricalDataViewModel YANG SAMA DENGAN HOME
  // ========================================================
  final HistoricalDataViewModel historicalDataViewModel;

  const CalculatorTabView({super.key, required this.historicalDataViewModel});

  @override
  State<CalculatorTabView> createState() => _CalculatorTabViewState();
}

class _CalculatorTabViewState extends State<CalculatorTabView> {
  // 0 = Digital
  // 1 = Fisik
  // 2 = Pivot Point
  int _selectedTab = 0;

  // ==========================================================
  // JUDUL KALKULATOR
  // ==========================================================
  String get _calculatorTitle {
    switch (_selectedTab) {
      case 1:
        return 'Kalkulator Emas Fisik';

      case 2:
        return 'Kalkulator Pivot Point Emas';

      case 0:
      default:
        return 'Kalkulator Emas Digital';
    }
  }

  // ==========================================================
  // RIWAYAT PERHITUNGAN
  // ==========================================================
  final List<CalculationHistory> _historyList = [];

  void _addHistory(CalculationHistory item) {
    setState(() {
      _historyList.insert(0, item);
    });
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
  // CALCULATOR SWITCHER
  // ==========================================================
  Widget _buildCalculatorSwitcher({required bool isDarkMode}) {
    const primaryOrange = Color(0xFFFFA800);

    return PopupMenuButton<int>(
      offset: const Offset(0, -150),
      elevation: 8,
      color: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE9E9E9),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

      onSelected: (index) {
        setState(() {
          _selectedTab = index;
        });
      },

      itemBuilder: (context) => [
        // ====================================================
        // EMAS FISIK
        // ====================================================
        PopupMenuItem<int>(
          value: 1,
          child: _buildCalculatorMenuItem(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Emas Fisik',
            selected: _selectedTab == 1,
            isDarkMode: isDarkMode,
          ),
        ),

        // ====================================================
        // EMAS DIGITAL
        // ====================================================
        PopupMenuItem<int>(
          value: 0,
          child: _buildCalculatorMenuItem(
            icon: Icons.show_chart_rounded,
            title: 'Emas Digital',
            selected: _selectedTab == 0,
            isDarkMode: isDarkMode,
          ),
        ),

        // ====================================================
        // PIVOT POINT
        // ====================================================
        PopupMenuItem<int>(
          value: 2,
          child: _buildCalculatorMenuItem(
            icon: Icons.auto_graph_rounded,
            title: 'Pivot Point Emas',
            selected: _selectedTab == 2,
            isDarkMode: isDarkMode,
          ),
        ),
      ],

      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: primaryOrange,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.calculate_rounded,
          color: Colors.white,
          size: 25,
        ),
      ),
    );
  }

  // ==========================================================
  // MENU ITEM
  // ==========================================================
  Widget _buildCalculatorMenuItem({
    required IconData icon,
    required String title,
    required bool selected,
    required bool isDarkMode,
  }) {
    final textColor = isDarkMode ? Colors.white : const Color(0xFF666666);

    return Row(
      children: [
        Icon(icon, size: 17, color: textColor),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),

        if (selected)
          Icon(
            Icons.check_rounded,
            size: 17,
            color: isDarkMode ? Colors.white : const Color(0xFF666666),
          ),
      ],
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFFFA800);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeViewModel.themeMode,
      builder: (context, currentThemeMode, child) {
        final isDarkMode = ThemeViewModel.isDarkMode;

        final bgColor = isDarkMode
            ? const Color(0xFF121212)
            : const Color(0xFFFBFBFB);

        final iconColor = isDarkMode ? Colors.white : Colors.black;

        final primaryTextColor = isDarkMode ? Colors.white : Colors.black;

        final cardBgColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

        final borderColor = isDarkMode
            ? Colors.grey[800]!
            : const Color(0xFFEEEEEE);

        return Scaffold(
          backgroundColor: bgColor,

          // ====================================================
          // APP BAR
          // ====================================================
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,

            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: iconColor),
              onPressed: () {
                Navigator.pop(context);
              },
            ),

            title: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _calculatorTitle,
                style: GoogleFonts.plusJakartaSans(
                  color: primaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 0.2,
                ),
              ),
            ),

            centerTitle: true,
          ),

          // ====================================================
          // FLOATING CALCULATOR SWITCHER
          // ====================================================
          floatingActionButton: _buildCalculatorSwitcher(
            isDarkMode: isDarkMode,
          ),

          // ====================================================
          // BODY
          // ====================================================
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // ==================================================
                // TAB CONTENT
                // ==================================================
                IndexedStack(
                  index: _selectedTab,

                  children: [
                    // =================================================
                    // 0. EMAS DIGITAL
                    // =================================================
                    GoldDigitalCalculatorContent(),

                    // =================================================
                    // 1. EMAS FISIK
                    // =================================================
                    GoldPhysicalCalculatorContent(
                      onCalculate: (data) {
                        _addHistory(data);
                      },
                    ),

                    // =================================================
                    // 2. PIVOT POINT EMAS
                    // =================================================
                    PivotGoldCalculatorContent(
                      historicalDataViewModel: widget.historicalDataViewModel,

                      onCalculate: (data) {
                        _addHistory(data);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // RIWAYAT PERHITUNGAN
  // ==========================================================
  Widget _buildHistorySection({
    required Color cardBgColor,
    required Color primaryTextColor,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
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
                  const Icon(
                    Icons.history_rounded,
                    color: Color(0xFFFFA800),
                    size: 20,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    'Riwayat Perhitungan',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
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
                    'Hapus Semua',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // ======================================================
          // EMPTY STATE
          // ======================================================
          if (_historyList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Belum ada riwayat perhitungan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            )
          // ======================================================
          // HISTORY LIST
          // ======================================================
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _historyList.length,

              separatorBuilder: (context, index) {
                return Divider(color: borderColor, height: 16);
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          item.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
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

                    // =================================================
                    // RESULT
                    // =================================================
                    Text(
                      '${isPositive ? '+Rp ' : '-Rp '}${_formatCurrency(item.result)}',

                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isPositive
                            ? const Color(0xFF00C853)
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
