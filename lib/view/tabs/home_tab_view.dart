import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:equate/model/user_model.dart';
import 'package:equate/model/historical_data_model.dart';
import 'package:equate/viewmodel/auth_viewmodel.dart';
import 'package:equate/viewmodel/historical_data_viewmodel.dart';
import 'package:equate/viewmodel/theme_viewmodel.dart';

class HomeTabView extends StatefulWidget {
  const HomeTabView({super.key});

  @override
  HomeTabViewState createState() => HomeTabViewState();
}

class HomeTabViewState extends State<HomeTabView> {
  // ============================================================
  // VIEWMODEL
  // ============================================================

  final AuthViewModel _authViewModel = AuthViewModel();

  final HistoricalDataViewModel _historicalViewModel =
      HistoricalDataViewModel();

  // ============================================================
  // STATE
  // ============================================================

  UserModel? _user;
  bool _isLoadingUser = true;

  // LGD = Gold / Emas
  // HSI = Hang Seng / HKK
  // SNI = Nikkei / JPK

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _historicalViewModel.addListener(_onHistoricalDataChanged);

    _loadUser();

    // Ambil historical data pertama kali
    _loadHistoricalData();
  }

  // ============================================================
  // VIEWMODEL LISTENER
  // ============================================================

  void _onHistoricalDataChanged() {
    if (!mounted) return;

    setState(() {});
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
  // LOAD HISTORICAL DATA
  // ============================================================

  Future<void> _loadHistoricalData() async {
    await _historicalViewModel.loadHistoricalData();
  }

  // ============================================================
  // CHANGE CATEGORY
  // ============================================================

  void _changeCategory(String category) {
    switch (category) {
      case 'LGD Daily':
        _historicalViewModel.changeMarket(HistoricalMarket.gold);
        break;

      case 'HSI Daily':
        _historicalViewModel.changeMarket(HistoricalMarket.hkk);
        break;

      case 'SNI Daily':
        _historicalViewModel.changeMarket(HistoricalMarket.jpk);
        break;
    }
  }

  // ============================================================
  // REFRESH USER
  // ============================================================

  Future<void> refreshUser() async {
    try {
      final user = await _authViewModel.getUserData();

      if (!mounted) return;

      setState(() {
        _user = user;
      });
    } catch (e) {
      debugPrint('REFRESH USER ERROR: $e');
    }
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectDate() async {
    final isDarkMode = ThemeViewModel.isDarkMode;

    final currentDate = _historicalViewModel.selectedDate ?? DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),

      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme(
              brightness: isDarkMode ? Brightness.dark : Brightness.light,
              primary: const Color(0xFFFF9E0F),
              onPrimary: Colors.white,
              secondary: const Color(0xFFFF9E0F),
              onSecondary: Colors.white,
              error: Colors.red,
              onError: Colors.white,
              surface: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              onSurface: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    // Kirim tanggal ke ViewModel
    _historicalViewModel.changeDate(picked);
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    await _loadHistoricalData();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _historicalViewModel.removeListener(_onHistoricalDataChanged);

    _historicalViewModel.dispose();
    _authViewModel.dispose();

    super.dispose();
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

        final historicalData = _historicalViewModel.selectedData;

        return Scaffold(
          backgroundColor: bgColor,

          body: SafeArea(
            child: RefreshIndicator(
              color: primaryOrange,
              onRefresh: _refresh,

              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),

                padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // HEADER
                    // ==================================================
                    _buildUserHeader(primaryOrange: primaryOrange),

                    const SizedBox(height: 24),

                    // ==================================================
                    // MARKET SELECTOR
                    // ==================================================
                    _buildMarketSelector(
                      isDarkMode: isDarkMode,
                      cardBgColor: cardBgColor,
                      borderColor: borderColor,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      primaryOrange: primaryOrange,
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
                      secondaryTextColor: secondaryTextColor,
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // LOADING
                    // ==================================================
                    if (_historicalViewModel.isLoading)
                      _buildLoadingCard(
                        cardBgColor: cardBgColor,
                        borderColor: borderColor,
                        secondaryTextColor: secondaryTextColor,
                      )
                    // ==================================================
                    // ERROR
                    // ==================================================
                    else if (_historicalViewModel.errorMessage != null)
                      _buildErrorCard(
                        cardBgColor: cardBgColor,
                        borderColor: borderColor,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                        primaryOrange: primaryOrange,
                      )
                    // ==================================================
                    // DATA
                    // ==================================================
                    else if (historicalData != null) ...[
                      // ==================================================
                      // INFO DATA
                      // ==================================================
                      _buildDataHeader(
                        data: historicalData,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
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
                              value: historicalData.openFormatted,
                              icon: Icons.wb_sunny_outlined,
                              iconBgColor: isDarkMode
                                  ? const Color(0xFF332A00)
                                  : const Color(0xFFFFF8E1),
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
                              value: historicalData.closeFormatted,
                              icon: Icons.nightlight_round_outlined,
                              iconBgColor: isDarkMode
                                  ? const Color(0xFF2C3E50)
                                  : const Color(0xFFECEFF1),
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
                              value: historicalData.highFormatted,
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
                              value: historicalData.lowFormatted,
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

                      const SizedBox(height: 24),

                      // ==================================================
                      // CHART
                      // ==================================================
                      _buildChartCard(
                        isDarkMode: isDarkMode,
                        cardBgColor: cardBgColor,
                        borderColor: borderColor,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                        primaryOrange: primaryOrange,
                      ),

                      const SizedBox(height: 20),

                      // ==================================================
                      // SOURCE
                      // ==================================================
                      _buildSourceInfo(secondaryTextColor: secondaryTextColor),
                    ],
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
  // MARKET SELECTOR
  // ============================================================

  Widget _buildMarketSelector({
    required bool isDarkMode,
    required Color cardBgColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color primaryOrange,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _historicalViewModel.selectedCategory,

          isExpanded: true,

          icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryOrange),

          dropdownColor: cardBgColor,

          style: GoogleFonts.poppins(fontSize: 13, color: primaryTextColor),

          items: const [
            DropdownMenuItem(
              value: 'LGD Daily',
              child: Text('Emas Global (LGD)'),
            ),
            DropdownMenuItem(
              value: 'HSI Daily',
              child: Text('Hang Seng / HKK (HSI)'),
            ),
            DropdownMenuItem(
              value: 'SNI Daily',
              child: Text('Nikkei / JPK (SNI)'),
            ),
          ],

          onChanged: (value) {
            if (value == null) return;

            _changeCategory(value);
          },
        ),
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
    required Color secondaryTextColor,
  }) {
    final selectedDate = _historicalViewModel.selectedDate;

    final dateFormatted = selectedDate == null
        ? '-'
        : DateFormat('dd MMMM yyyy', 'id_ID').format(selectedDate);
    return GestureDetector(
      onTap: _selectDate,

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

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tanggal Data',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: secondaryTextColor,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  dateFormatted,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
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
  // DATA HEADER
  // ============================================================

  Widget _buildDataHeader({
    required HistoricalDataModel data,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getMarketTitle(),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                data.dateFormatted,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),

          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),

          child: Text(
            'HISTORICAL',
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MARKET TITLE
  // ============================================================

  String _getMarketTitle() {
    switch (_historicalViewModel.selectedCategory) {
      case 'HSI Daily':
        return 'Hang Seng';

      case 'SNI Daily':
        return 'Nikkei';

      case 'LGD Daily':
      default:
        return 'Harga Emas';
    }
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
            _historicalViewModel.selectedCategory == 'LGD Daily'
                ? 'USD / oz'
                : 'Index Point',
            style: GoogleFonts.poppins(fontSize: 9, color: secondaryTextColor),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHART CARD
  // ============================================================

  Widget _buildChartCard({
    required bool isDarkMode,
    required Color cardBgColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color primaryOrange,
  }) {
    final chartData = _historicalViewModel.chartData;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ========================================================
          // CHART HEADER
          // ========================================================
          Row(
            children: [
              Text(
                'Pergerakan Harga',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),

              const Spacer(),

              Text(
                'Close',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ========================================================
          // CHART RANGE SELECTOR
          // ========================================================
          Container(
            padding: const EdgeInsets.all(4),

            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF292929)
                  : const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.circular(12),
            ),

            child: Row(
              children: [
                _buildChartRangeButton(
                  label: '7H',
                  days: 7,
                  primaryOrange: primaryOrange,
                  isDarkMode: isDarkMode,
                ),

                _buildChartRangeButton(
                  label: '30H',
                  days: 30,
                  primaryOrange: primaryOrange,
                  isDarkMode: isDarkMode,
                ),

                _buildChartRangeButton(
                  label: '90H',
                  days: 90,
                  primaryOrange: primaryOrange,
                  isDarkMode: isDarkMode,
                ),

                _buildChartRangeButton(
                  label: '1Y',
                  days: 365,
                  primaryOrange: primaryOrange,
                  isDarkMode: isDarkMode,
                ),

                _buildChartRangeButton(
                  label: 'Semua',
                  days: 99999,
                  primaryOrange: primaryOrange,
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ========================================================
          // CHART
          // ========================================================
          if (chartData.isEmpty)
            SizedBox(
              height: 220,

              child: Center(
                child: Text(
                  'Data chart belum tersedia',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 220,

              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: chartData.length > 1
                      ? (chartData.length - 1).toDouble()
                      : 1,

                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                  ),

                  borderData: FlBorderData(show: false),

                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),

                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),

                    // ==================================================
                    // LEFT AXIS
                    // ==================================================
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,

                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              color: secondaryTextColor,
                            ),
                          );
                        },
                      ),
                    ),

                    // ==================================================
                    // BOTTOM AXIS
                    // ==================================================
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,

                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();

                          if (index < 0 || index >= chartData.length) {
                            return const SizedBox();
                          }

                          final date = chartData[index].date;

                          return Text(
                            DateFormat('dd/MM').format(date),
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              color: secondaryTextColor,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // ==================================================
                  // LINE
                  // ==================================================
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(chartData.length, (index) {
                        return FlSpot(index.toDouble(), chartData[index].close);
                      }),

                      isCurved: true,

                      barWidth: 2.5,

                      dotData: const FlDotData(show: false),

                      belowBarData: BarAreaData(show: true),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // CHART RANGE BUTTON
  // ============================================================

  Widget _buildChartRangeButton({
    required String label,
    required int days,
    required Color primaryOrange,
    required bool isDarkMode,
  }) {
    final isSelected = _historicalViewModel.chartDays == days;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _historicalViewModel.changeChartRange(days);
        },

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),

          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),

          decoration: BoxDecoration(
            color: isSelected ? primaryOrange : Colors.transparent,

            borderRadius: BorderRadius.circular(9),
          ),

          child: Center(
            child: Text(
              label,

              style: GoogleFonts.poppins(
                fontSize: 10,

                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,

                color: isSelected
                    ? Colors.white
                    : isDarkMode
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOADING CARD
  // ============================================================

  Widget _buildLoadingCard({
    required Color cardBgColor,
    required Color borderColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      width: double.infinity,
      height: 180,

      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),

      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const CircularProgressIndicator(color: Color(0xFFFF9E0F)),

            const SizedBox(height: 14),

            Text(
              'Memuat data historical...',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR CARD
  // ============================================================

  Widget _buildErrorCard({
    required Color cardBgColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color primaryOrange,
  }) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),

      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 40, color: Colors.grey[500]),

          const SizedBox(height: 12),

          Text(
            'Data tidak dapat dimuat',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: primaryTextColor,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            _historicalViewModel.errorMessage ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 11, color: secondaryTextColor),
          ),

          const SizedBox(height: 14),

          TextButton(
            onPressed: _loadHistoricalData,
            child: Text(
              'Coba Lagi',
              style: GoogleFonts.poppins(
                color: primaryOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SOURCE INFO
  // ============================================================

  Widget _buildSourceInfo({required Color secondaryTextColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Icon(Icons.info_outline_rounded, size: 16, color: secondaryTextColor),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            'Data historical bersumber dari Newsmaker.id. '
            'Data yang ditampilkan meliputi Open, High, Low, '
            'dan Close berdasarkan tanggal yang dipilih.',
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
