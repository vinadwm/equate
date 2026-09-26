import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:equate/viewmodel/theme_viewmodel.dart';
import 'package:equate/viewmodel/historical_data_viewmodel.dart';
import 'package:equate/viewmodel/history_viewmodel.dart';
import 'package:equate/model/base_calculation_history.dart';

// ==========================================================
// IMPORT VIEW HISTORY
// ==========================================================
import 'package:equate/view/history/history_view.dart';

// ==========================================================
// IMPORT MODELS
// ==========================================================
import 'package:equate/model/nest_gold_model.dart';
import 'package:equate/model/digital_gold_model.dart';
import 'package:equate/model/physical_gold_model.dart';
import 'package:equate/model/pivot_gold_model.dart';
import 'package:equate/model/pivot_hangseng_model.dart';
import 'package:equate/model/nest_hangseng_model.dart';

// ==========================================================
// CALCULATOR CONTENT
// ==========================================================
import 'calculator/gold_digital_calculator_content.dart';
import 'calculator/gold_physical_calculator_content.dart';
import 'calculator/pivot_gold_calculator_content.dart';
import 'calculator/pivot_hangseng_calculator_content.dart';
import 'calculator/nest_gold_calculator_content.dart';
import 'calculator/nest_hangseng_calculator_content.dart';

// ==========================================================
// CUSTOM MENU
// ==========================================================
import 'custom_calculator_menu.dart';

// ==========================================================
// CALCULATOR TAB VIEW
// ==========================================================
class CalculatorTabView extends StatefulWidget {
  final HistoricalDataViewModel historicalDataViewModel;

  const CalculatorTabView({super.key, required this.historicalDataViewModel});

  @override
  State<CalculatorTabView> createState() => _CalculatorTabViewState();
}

class _CalculatorTabViewState extends State<CalculatorTabView> {
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
    {
      'title': 'Nest Emas',
      'description': 'Kalkulator strategi Nest untuk transaksi Emas.',
      'icon': Icons.nest_cam_wired_stand_rounded,
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
    {
      'title': 'Nest Hangseng',
      'description': 'Kalkulator strategi Nest untuk transaksi Hangseng.',
      'icon': Icons.nest_cam_wired_stand_rounded,
    },
  ];

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );

    return formatter.format(amount.abs()).trim();
  }

  // ==========================================================
  // FIRESTORE DOC PARSER HELPER
  // ==========================================================
  dynamic _parseFirestoreDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final category = (data['category'] ?? '').toString();

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
        return NestGoldModel.fromFirestore(doc);
    }
  }

  Map<String, dynamic> _parseItemInfo(dynamic item) {
    String title = 'Riwayat';
    String details = 'Detail Perhitungan';
    double result = 0.0;
    DateTime timestamp = DateTime.now();
    bool isCurrency = true;

    if (item is DigitalGoldModel) {
      title = 'Emas Digital';
      details = '${item.weightInGram} Lot | Beli: ${_formatCurrency(item.buyPrice)}';
      result = item.profitLoss;
      timestamp = item.createdAt;
    } else if (item is PhysicalGoldModel) {
      title = 'Emas Fisik';
      details = '${item.weightInGram} gram | Rp ${_formatCurrency(item.buyPrice)}/g';
      result = item.profitLoss;
      timestamp = item.createdAt;
    } else if (item is PivotGoldModel) {
      title = 'Pivot Gold (${item.type})';
      details = 'PP: ${item.pp} | R1: ${item.r1} | S1: ${item.s1}';
      result = item.pp;
      isCurrency = false;
      timestamp = item.createdAt;
    } else if (item is NestGoldModel) {
      title = 'NEST Gold';
      details = 'Signal: ${item.signalLabel} | Open: ${item.open ?? '-'}';
      result = item.close ?? 0.0;
      isCurrency = false;
      timestamp = item.createdAt;
    } else if (item is PivotHangsengModel) {
      title = 'Pivot Hangseng';
      details = 'PP: ${item.pp ?? '-'} | H: ${item.high ?? '-'} | L: ${item.low ?? '-'}';
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
      title = item.title?.toString() ?? 'Riwayat';
      details = item.details?.toString() ?? 'Detail perhitungan';
      result = (item.result is num) ? (item.result as num).toDouble() : 0.0;
      if (item.createdAt is DateTime) timestamp = item.createdAt;
    }

    return {
      'title': title,
      'details': details,
      'result': result,
      'timestamp': timestamp,
      'isCurrency': isCurrency,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeViewModel.themeMode,
      builder: (context, currentThemeMode, child) {
        final isDarkMode = ThemeViewModel.isDarkMode;

        final primaryTextColor =
            isDarkMode ? Colors.white : const Color(0xFF2C2D30);

        final bgGradientStart =
            isDarkMode ? const Color(0xFF16181F) : Colors.white;

        final bgGradientEnd =
            isDarkMode ? const Color(0xFF0D0E12) : Colors.white;

        return Scaffold(
          backgroundColor: isDarkMode ? const Color(0xFF0D0E12) : Colors.white,
          body: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [bgGradientStart, bgGradientEnd],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
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
              SafeArea(
                child: Column(
                  children: [
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

  Widget _buildLobbyView(
    BuildContext context,
    bool isDarkMode,
    Color primaryTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              _buildSoftClayButton(
                context,
                title: 'Emas (XUL)',
                subtitle: 'Kalkulator Emas Digital, Fisik, Pivot & Nest',
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
                              } else if (selectedName == 'Nest Emas') {
                                _selectedCalculatorType = 'nest_gold';
                              }
                            });
                          },
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              _buildSoftClayButton(
                context,
                title: 'Hangseng (HKK)',
                subtitle: 'Kalkulator Pivot Point & Nest Indeks',
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
                              } else if (selectedName == 'Nest Hangseng') {
                                _selectedCalculatorType = 'nest_hangseng';
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
        _buildHistorySection(
          isDarkMode: isDarkMode,
          primaryTextColor: primaryTextColor,
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildActiveCalculatorView() {
    final historyViewModel = Provider.of<HistoryViewModel>(
      context,
      listen: false,
    );

    switch (_selectedCalculatorType) {
      case 'digital':
        // ====================================================
        // REVISI: sebelumnya `onCalculate: (_) {}` — kosong,
        // sehingga hasil kalkulasi Emas Digital TIDAK PERNAH
        // disimpan ke Firestore. Sekarang disamakan dengan
        // kalkulator lain: hasil dikirim ke HistoryViewModel.
        // ====================================================
        return GoldDigitalCalculatorContent(
          onCalculate: (result) {
            if (result is CalculationHistory) {
              historyViewModel.addHistory(result);
            }
          },
        );

      case 'physical':
        return GoldPhysicalCalculatorContent(
          onCalculate: (result) {
            if (result is CalculationHistory) {
              historyViewModel.addHistory(result);
            }
          },
        );

      case 'pivot':
        return PivotGoldCalculatorContent(
          historicalDataViewModel: widget.historicalDataViewModel,
          onCalculate: (result) {
            if (result is CalculationHistory) {
              historyViewModel.addHistory(result);
            }
          },
        );

      case 'hangseng_pivot':
        return PivotHangsengCalculatorContent(
          historicalDataViewModel: widget.historicalDataViewModel,
          onCalculate: (result) {
            if (result is CalculationHistory) {
              historyViewModel.addHistory(result);
            }
          },
        );

      case 'nest_gold':
        return NestGoldCalculatorContent(
          historicalDataViewModel: widget.historicalDataViewModel,
          onCalculate: (result) {
            historyViewModel.addHistory(result);
          },
        );

      case 'nest_hangseng':
        return NestHangsengCalculatorContent(
          historicalDataViewModel: widget.historicalDataViewModel,
          onCalculate: (result) {
            historyViewModel.addHistory(result);
          },
        );

      default:
        return const SizedBox.shrink();
    }
  }

  String _getCalculatorTitle() {
    switch (_selectedCalculatorType) {
      case 'digital':
        return 'Emas Digital';
      case 'physical':
        return 'Emas Fisik';
      case 'pivot':
        return 'Pivot Point Emas';
      case 'nest_gold':
        return 'Nest Emas';
      case 'hangseng_pivot':
        return 'Pivot Hangseng';
      case 'nest_hangseng':
        return 'Nest Hangseng';
      default:
        return 'Kalkulator';
    }
  }

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
  // FIRESTORE REAL-TIME HISTORY SECTION
  // ==========================================================
  Widget _buildHistorySection({
    required bool isDarkMode,
    required Color primaryTextColor,
  }) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Referensi collection riwayat milik user ini: users/{uid}/histories
    final CollectionReference<Map<String, dynamic>> historiesRef =
        FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('histories');

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
      child: StreamBuilder<QuerySnapshot>(
        stream: historiesRef
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFFF9500)),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final allHistoryList =
              docs.map((doc) => _parseFirestoreDoc(doc)).toList();

          // FILTER HARI INI SAJA
          final now = DateTime.now();
          final filteredToday = allHistoryList.where((item) {
            final parsed = _parseItemInfo(item);
            final timestamp = parsed['timestamp'] as DateTime;
            return timestamp.year == now.year &&
                timestamp.month == now.month &&
                timestamp.day == now.day;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER RIWAYAT + TOMBOL LIHAT SEMUANYA DI KANAN
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
                        'Riwayat Hari Ini',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HistoryView(
                            historyList: allHistoryList,
                            // 👇 Ini yang tadinya belum ada — supaya hapus
                            // beneran menghapus dokumen di Firestore, bukan
                            // cuma dari tampilan lokal.
                            historyCollection: historiesRef,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Text(
                        'Lihat semuanya',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFF9500),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // DAFTAR RIWAYAT
              if (filteredToday.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'Belum ada riwayat perhitungan hari ini',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                      ),
                    ),
                  ),
                )
              else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount:
                      filteredToday.length > 5 ? 5 : filteredToday.length,
                  separatorBuilder: (context, index) {
                    return Divider(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.04),
                      height: 16,
                    );
                  },
                  itemBuilder: (context, index) {
                    final rawItem = filteredToday[index];
                    final parsed = _parseItemInfo(rawItem);

                    final title = parsed['title'] as String;
                    final details = parsed['details'] as String;
                    final result = parsed['result'] as double;
                    final timestamp = parsed['timestamp'] as DateTime;
                    final isCurrency = parsed['isCurrency'] as bool;
                    final isPositive = result >= 0;

                    final timeFormatted =
                        DateFormat('HH:mm').format(timestamp);

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: primaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                details,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                        Text(
                          isCurrency
                              ? '${isPositive ? '+Rp ' : '-Rp '}${_formatCurrency(result)}'
                              : result.toStringAsFixed(2),
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
                  },
                ),
                const SizedBox(height: 14),
                // NOTES KECIL DI BAGIAN BAWAH LIST
                Center(
                  child: Text(
                    'klik lihat semuanya untuk melihat riwayat perhitungan lebih lengkap',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}