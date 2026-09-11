import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:equate/viewmodel/theme_viewmodel.dart';

// IMPORT PATH KE SUB-FOLDER CALCULATOR
import 'calculator/gold_digital_calculator_content.dart';
import 'calculator/gold_physical_calculator_content.dart';
import 'calculator/pivot_point_calculator_content.dart';

// Model Sederhana untuk Data Riwayat
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
  const CalculatorTabView({super.key});

  @override
  State<CalculatorTabView> createState() => _CalculatorTabViewState();
}

class _CalculatorTabViewState extends State<CalculatorTabView> {
  int _selectedTab = 0; // 0: Digital, 1: Fisik, 2: Pivot Point

  // List Global untuk Menampung Riwayat Perhitungan
  final List<CalculationHistory> _historyList = [];

  void _addHistory(CalculationHistory item) {
    setState(() {
      _historyList.insert(0, item); // Menambahkan ke paling atas
    });
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
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFFFA800);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeViewModel.themeMode,
      builder: (context, currentThemeMode, child) {
        final isDarkMode = ThemeViewModel.isDarkMode;

        final bgColor = isDarkMode
            ? const Color(0xFF121212)
            : const Color(0xFFFBFBFB);
        final tabBgColor = isDarkMode
            ? const Color(0xFF1E1E1E)
            : const Color(0xFFF2F2F2);
        final activeTabBgColor = isDarkMode
            ? const Color(0xFF2A2A2A)
            : Colors.white;
        final iconColor = isDarkMode ? Colors.white : Colors.black;
        final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
        final unselectedTextColor = isDarkMode
            ? const Color(0xFFA0A0A0)
            : Colors.grey[600]!;
        final cardBgColor = isDarkMode
            ? const Color(0xFF1E1E1E)
            : Colors.white;
        final borderColor = isDarkMode
            ? Colors.grey[800]!
            : const Color(0xFFEEEEEE);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: iconColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'KALKULATOR',
              style: GoogleFonts.plusJakartaSans(
                color: primaryTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // TAB SWITCHER (3 TOMBOL ATAS)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: tabBgColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton('EMAS DIGITAL', 0, activeTabBgColor,
                          isDarkMode, primaryOrange, unselectedTextColor),
                      _buildTabButton('EMAS FISIK', 1, activeTabBgColor,
                          isDarkMode, primaryOrange, unselectedTextColor),
                      _buildTabButton('PIVOT POINT', 2, activeTabBgColor,
                          isDarkMode, primaryOrange, unselectedTextColor),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // TAB CONTENT
                IndexedStack(
                  index: _selectedTab,
                  children: [
                    GoldDigitalCalculatorContent(
                      onCalculate: (data) => _addHistory(data),
                    ),
                    GoldPhysicalCalculatorContent(
                      onCalculate: (data) => _addHistory(data),
                    ),
                    PivotPointCalculatorContent(
                      onCalculate: (data) => _addHistory(data),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // SECTION RIWAYAT PERHITUNGAN
                _buildHistorySection(
                  cardBgColor: cardBgColor,
                  primaryTextColor: primaryTextColor,
                  borderColor: borderColor,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabButton(
    String label,
    int index,
    Color activeBgColor,
    bool isDarkMode,
    Color activeTextColor,
    Color unselectedTextColor,
  ) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeBgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                      blurRadius: 4,
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? activeTextColor : unselectedTextColor,
            ),
          ),
        ),
      ),
    );
  }

  // Widget Tampilan Riwayat Perhitungan
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
                  onTap: () => setState(() => _historyList.clear()),
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
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _historyList.length,
              separatorBuilder: (context, index) => Divider(
                color: borderColor,
                height: 16,
              ),
              itemBuilder: (context, index) {
                final item = _historyList[index];
                final isPositive = item.result >= 0;
                final timeFormatted =
                    DateFormat('HH:mm - dd MMM').format(item.timestamp);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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