import 'dart:async';
import 'dart:ui';

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
  final HistoricalDataViewModel historicalDataViewModel;

  const HomeTabView({super.key, required this.historicalDataViewModel});

  @override
  HomeTabViewState createState() => HomeTabViewState();
}

class HomeTabViewState extends State<HomeTabView> {
  final AuthViewModel _authViewModel = AuthViewModel();

  HistoricalDataViewModel get _historicalViewModel =>
      widget.historicalDataViewModel;

  // ============================================================
  // STATE
  // ============================================================

  UserModel? _user;
  bool _isLoadingUser = true;

  // Tabel data historis: mulai collapsed (15 baris), bisa expand.
  bool _isHistoryTableExpanded = false;

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

    // Load historical data saat pertama kali masuk Home
    // jika data belum tersedia.
    if (_historicalViewModel.marketData.isEmpty &&
        !_historicalViewModel.isLoading) {
      _historicalViewModel.loadHistoricalData();
    }
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
    const primaryOrange = Color(0xFFFF9500);

    // Token kaca (senada dengan glass card di halaman Home) supaya
    // popup kalender terasa "futuristik glass" ala iOS.
    final glassFill = isDarkMode
        ? Colors.white.withOpacity(0.14)
        : Colors.white.withOpacity(0.78);

    final currentDate = _historicalViewModel.selectedDate ?? DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),

      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            // Warna dialog dibuat translucent (bukan solid putih/hitam)
            // supaya terasa seperti kaca.
            dialogBackgroundColor: glassFill,
            colorScheme: ColorScheme(
              brightness: isDarkMode ? Brightness.dark : Brightness.light,
              primary: primaryOrange,
              onPrimary: Colors.white,
              secondary: primaryOrange,
              onSecondary: Colors.white,
              error: Colors.red,
              onError: Colors.white,
              surface: glassFill,
              onSurface: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          // PENTING: tidak ditambah Center/Container pembungkus baru —
          // cukup ClipRRect + BackdropFilter langsung membungkus dialog
          // aslinya, supaya ukuran & posisi popup TETAP persis seperti
          // bawaan Flutter (di tengah layar), cuma tampilannya jadi
          // blur/kaca. Radius 28 mengikuti radius default dialog M3,
          // jadi blur pas mengikuti bentuk bulat dialognya.
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: child,
            ),
          ),
        );
      },
    );

    if (picked == null) return;

    // Kirim tanggal ke ViewModel
    _historicalViewModel.changeDate(picked);
  }

  // ============================================================
  // MARKET LABEL (teks yang tampil di baris pilih pasar)
  // ============================================================

  String _marketLabel(String category) {
    switch (category) {
      case 'HSI Daily':
        return 'Hang Seng / HKK (HSI)';
      case 'SNI Daily':
        return 'Nikkei / JPK (SNI)';
      case 'LGD Daily':
      default:
        return 'Emas Global (LGD)';
    }
  }

  // ============================================================
  // PILIH PASAR — menu kaca ala iOS yang MENEMPEL tepat di bawah
  // tombol (sejajar, sama seperti posisi DropdownButton bawaan
  // sebelumnya), bukan bottom sheet. Cuma tampilannya yang dibuat
  // blur/glass; posisi & lebar mengikuti tombolnya sendiri.
  // ============================================================

  Future<void> _selectMarket(BuildContext anchorContext) async {
    final isDarkMode = ThemeViewModel.isDarkMode;
    const primaryOrange = Color(0xFFFF9500);

    final glassFill = isDarkMode
        ? Colors.white.withOpacity(0.16)
        : Colors.white.withOpacity(0.85);

    final glassBorder = isDarkMode
        ? Colors.white.withOpacity(0.20)
        : Colors.white.withOpacity(0.95);

    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;

    const options = [
      {'value': 'LGD Daily', 'label': 'Emas Global (LGD)'},
      {'value': 'HSI Daily', 'label': 'Hang Seng / HKK (HSI)'},
      {'value': 'SNI Daily', 'label': 'Nikkei / JPK (SNI)'},
    ];

    // Hitung posisi & lebar tombol supaya menu-nya sejajar persis di
    // bawah tombol (mirip perilaku DropdownButton bawaan).
    final RenderBox button = anchorContext.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(anchorContext).overlay!.context.findRenderObject()
            as RenderBox;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(
          Offset(0, button.size.height + 6),
          ancestor: overlay,
        ),
        button.localToGlobal(
          button.size.bottomRight(const Offset(0, 6)),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final String? selected = await showMenu<String>(
      context: anchorContext,
      position: position,
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      constraints: BoxConstraints(
        minWidth: button.size.width,
        maxWidth: button.size.width,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      items: [
        PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                decoration: BoxDecoration(
                  color: glassFill,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: glassBorder, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: options.map((opt) {
                    final isSelected =
                        _historicalViewModel.selectedCategory ==
                        opt['value'];
                    final isLast = opt == options.last;

                    return InkWell(
                      onTap: () =>
                          Navigator.pop(anchorContext, opt['value']),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          border: isLast
                              ? null
                              : Border(
                                  bottom: BorderSide(
                                    color: glassBorder,
                                    width: 1,
                                  ),
                                ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                opt['label']!,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? primaryOrange
                                      : primaryTextColor,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: primaryOrange,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (selected != null) {
      _changeCategory(selected);
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    await _historicalViewModel.loadHistoricalData();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _historicalViewModel.removeListener(_onHistoricalDataChanged);
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

        const primaryOrange = Color(0xFFFF9500);
        const secondaryOrange = Color(0xFFFFB74D);

        // ====================================================
        // GLASS TOKENS (dipakai berulang di semua card)
        // ====================================================
        final glassFill = isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.55);

        final glassBorder = isDarkMode
            ? Colors.white.withOpacity(0.10)
            : Colors.white.withOpacity(0.7);

        final primaryTextColor = isDarkMode ? Colors.white : Colors.black;

        final secondaryTextColor = isDarkMode
            ? Colors.grey[400]!
            : Colors.grey[600]!;

        final historicalData = _historicalViewModel.selectedData;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // ====================================================
              // BACKGROUND GRADIENT (dasar futuristik gelap/terang)
              // ====================================================
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDarkMode
                          ? [const Color(0xFF0D0E12), const Color(0xFF16181F)]
                          : [const Color(0xFFFFF8F0), Colors.white],
                    ),
                  ),
                ),
              ),

              // ====================================================
              // RADIAL GLOW ORANYE (aksen "futuristik")
              // ====================================================
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.9),
                        radius: 1.1,
                        colors: [
                          primaryOrange.withOpacity(isDarkMode ? 0.14 : 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ====================================================
              // WATERMARK LOGO EWF DI BACKGROUND
              // ====================================================
              Positioned(
                top: 60,
                right: -60,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: isDarkMode ? 0.10 : 0.06,
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

              // ====================================================
              // KONTEN
              // ====================================================
              SafeArea(
                child: RefreshIndicator(
                  color: primaryOrange,
                  backgroundColor: isDarkMode
                      ? const Color(0xFF1E1F24)
                      : Colors.white,
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 130),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ==========================================
                        // HEADER (glass pill)
                        // ==========================================
                        _buildUserHeader(
                          isDarkMode: isDarkMode,
                          primaryOrange: primaryOrange,
                          secondaryOrange: secondaryOrange,
                          glassFill: glassFill,
                          glassBorder: glassBorder,
                          primaryTextColor: primaryTextColor,
                          secondaryTextColor: secondaryTextColor,
                        ),

                        const SizedBox(height: 24),

                        // ==========================================
                        // FILTER (Market + Tanggal digabung 1 card)
                        // ==========================================
                        _buildFilterCard(
                          isDarkMode: isDarkMode,
                          primaryOrange: primaryOrange,
                          glassFill: glassFill,
                          glassBorder: glassBorder,
                          primaryTextColor: primaryTextColor,
                          secondaryTextColor: secondaryTextColor,
                        ),

                        const SizedBox(height: 20),

                        // ==========================================
                        // LOADING
                        // ==========================================
                        if (_historicalViewModel.isLoading)
                          _buildLoadingCard(
                            isDarkMode: isDarkMode,
                            glassFill: glassFill,
                            glassBorder: glassBorder,
                            secondaryTextColor: secondaryTextColor,
                          )
                        // ==========================================
                        // ERROR
                        // ==========================================
                        else if (_historicalViewModel.errorMessage != null)
                          _buildErrorCard(
                            isDarkMode: isDarkMode,
                            glassFill: glassFill,
                            glassBorder: glassBorder,
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                            primaryOrange: primaryOrange,
                          )
                        // ==========================================
                        // DATA
                        // ==========================================
                        else if (historicalData != null) ...[
                          _buildDataHeader(
                            data: historicalData,
                            primaryOrange: primaryOrange,
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                          ),

                          const SizedBox(height: 16),

                          // OPEN / CLOSE
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  isDarkMode: isDarkMode,
                                  glassFill: glassFill,
                                  glassBorder: glassBorder,
                                  title: 'Open',
                                  value: historicalData.openFormatted,
                                  icon: Icons.wb_sunny_outlined,
                                  accentColor: const Color(0xFFFFB700),
                                  valueColor: primaryTextColor,
                                  secondaryTextColor: secondaryTextColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCard(
                                  isDarkMode: isDarkMode,
                                  glassFill: glassFill,
                                  glassBorder: glassBorder,
                                  title: 'Close',
                                  value: historicalData.closeFormatted,
                                  icon: Icons.nightlight_round_outlined,
                                  accentColor: const Color(0xFFFF9500),
                                  valueColor: primaryTextColor,
                                  secondaryTextColor: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // HIGH / LOW
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  isDarkMode: isDarkMode,
                                  glassFill: glassFill,
                                  glassBorder: glassBorder,
                                  title: 'High',
                                  value: historicalData.highFormatted,
                                  icon: Icons.trending_up_rounded,
                                  accentColor: const Color(0xFF4CAF50),
                                  valueColor: const Color(0xFF4CAF50),
                                  secondaryTextColor: secondaryTextColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCard(
                                  isDarkMode: isDarkMode,
                                  glassFill: glassFill,
                                  glassBorder: glassBorder,
                                  title: 'Low',
                                  value: historicalData.lowFormatted,
                                  icon: Icons.trending_down_rounded,
                                  accentColor: const Color(0xFFEF5350),
                                  valueColor: const Color(0xFFEF5350),
                                  secondaryTextColor: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // CHART
                          _buildChartCard(
                            isDarkMode: isDarkMode,
                            glassFill: glassFill,
                            glassBorder: glassBorder,
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                            primaryOrange: primaryOrange,
                          ),

                          const SizedBox(height: 24),

                          // ======================================
                          // TABEL DATA HISTORIS (BARU)
                          // ======================================
                          _buildHistoricalTable(
                            isDarkMode: isDarkMode,
                            glassFill: glassFill,
                            glassBorder: glassBorder,
                            primaryOrange: primaryOrange,
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                          ),

                          const SizedBox(height: 20),

                          // SOURCE
                          _buildSourceInfo(
                            secondaryTextColor: secondaryTextColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // GLASS CARD WRAPPER (reusable, ini yang bikin efek iOS blur)
  // ============================================================
  Widget _glassCard({
    required bool isDarkMode,
    required Color glassFill,
    required Color glassBorder,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
    double radius = 22,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: glassFill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: glassBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.28 : 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // ============================================================
  // USER HEADER (tanpa kotak/wadah — cuma avatar + teks polos)
  // ============================================================

  Widget _buildUserHeader({
    required bool isDarkMode,
    required Color primaryOrange,
    required Color secondaryOrange,
    required Color glassFill,
    required Color glassBorder,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    final String firstName = _user?.firstName.trim() ?? '';

    final String greeting = _isLoadingUser
        ? 'Hai, ...'
        : firstName.isNotEmpty
        ? 'Halo, $firstName'
        : 'Halo, Pengguna';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [primaryOrange, secondaryOrange.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: CircleAvatar(
            radius: 19,
            backgroundColor: isDarkMode
                ? const Color(0xFF1E1F24)
                : Colors.grey[200],
            backgroundImage:
                _user?.photo != null && _user!.photo!.trim().isNotEmpty
                ? NetworkImage(_user!.photo!)
                : null,
            child: _user?.photo == null || _user!.photo!.trim().isEmpty
                ? Icon(
                    Icons.person_rounded,
                    color: secondaryTextColor,
                    size: 20,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Pantau pasar emas & indeks hari ini',
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FILTER CARD (Market selector + Date picker jadi 1 card)
  // ============================================================

  Widget _buildFilterCard({
    required bool isDarkMode,
    required Color primaryOrange,
    required Color glassFill,
    required Color glassBorder,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    final selectedDate = _historicalViewModel.selectedDate;

    final dateFormatted = selectedDate == null
        ? '-'
        : DateFormat('dd MMMM yyyy', 'id_ID').format(selectedDate);

    return _glassCard(
      isDarkMode: isDarkMode,
      glassFill: glassFill,
      glassBorder: glassBorder,
      radius: 20,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // ==================================================
          // BARIS 1: PILIH PASAR (LGD / HSI / SNI)
          // ==================================================
          // Diganti dari DropdownButton bawaan (popup-nya tidak bisa
          // di-glass-kan) menjadi tombol biasa yang membuka menu kaca
          // lewat _selectMarket() — posisinya tetap menempel/sejajar
          // tepat di bawah tombol ini, sama seperti dropdown biasa.
          Builder(
            builder: (buttonContext) {
              return InkWell(
                onTap: () => _selectMarket(buttonContext),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: primaryOrange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _marketLabel(_historicalViewModel.selectedCategory),
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                        ),
                      ),
                      // Panah ini sengaja dibuat SAMA dengan panah di
                      // baris tanggal di bawah (tanpa kotak/gradient).
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: primaryOrange,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Divider tipis pemisah antara filter pasar & tanggal
          Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: glassBorder,
          ),

          // ==================================================
          // BARIS 2: PILIH TANGGAL
          // ==================================================
          InkWell(
            onTap: _selectDate,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 17,
                    color: primaryOrange,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tanggal Data',
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateFormatted,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Panah ini sengaja dibuat SAMA persis dengan panah di
                  // baris pemilihan pasar di atas (tanpa kotak/background).
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: primaryOrange,
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
  // DATA HEADER
  // ============================================================

  Widget _buildDataHeader({
    required HistoricalDataModel data,
    required Color primaryOrange,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [primaryOrange, const Color(0xFFFFB74D)],
                ).createShader(bounds),
                child: Text(
                  _getMarketTitle(),
                  style: GoogleFonts.poppins(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
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
              const SizedBox(height: 6),
              // ================================================
              // JAM DIGITAL LIVE (widget terpisah, self-ticking)
              // ================================================
              _LiveClock(
                accentColor: primaryOrange,
                textColor: primaryTextColor,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            // Sengaja dibuat netral & kotak (bukan pill oranye + dot
            // berkedip) supaya tidak mirip dengan widget jam live.
            color: secondaryTextColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: secondaryTextColor.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history_rounded,
                size: 12,
                color: secondaryTextColor,
              ),
              const SizedBox(width: 5),
              Text(
                'HISTORICAL',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: secondaryTextColor,
                ),
              ),
            ],
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
  // METRIC CARD (glass + badge gradasi warna semantik)
  // ============================================================

  Widget _buildMetricCard({
    required bool isDarkMode,
    required Color glassFill,
    required Color glassBorder,
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required Color valueColor,
    required Color secondaryTextColor,
  }) {
    return _glassCard(
      isDarkMode: isDarkMode,
      glassFill: glassFill,
      glassBorder: glassBorder,
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withOpacity(0.9),
                      accentColor.withOpacity(0.55),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, size: 18, color: Colors.white),
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
    required Color glassFill,
    required Color glassBorder,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color primaryOrange,
  }) {
    final chartData = _historicalViewModel.chartData;
    double minPrice = double.infinity;
    double maxPrice = double.negativeInfinity;

    for (final item in chartData) {
      if (item.close < minPrice) minPrice = item.close;
      if (item.close > maxPrice) maxPrice = item.close;
    }

    if (minPrice == double.infinity || maxPrice == double.negativeInfinity) {
      minPrice = 0;
      maxPrice = 100;
    }

    final priceRange = maxPrice - minPrice;

    final double gridInterval;

    if (priceRange <= 50) {
      gridInterval = 10;
    } else if (priceRange <= 200) {
      gridInterval = 25;
    } else if (priceRange <= 500) {
      gridInterval = 50;
    } else {
      gridInterval = 100;
    }

    return _glassCard(
      isDarkMode: isDarkMode,
      glassFill: glassFill,
      glassBorder: glassBorder,
      radius: 22,
      padding: const EdgeInsets.all(18),
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
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05),
              ),
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
                  days: -1,
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
                    horizontalInterval: gridInterval,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.05),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
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
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: chartData.length <= 30
                            ? 5
                            : chartData.length <= 90
                            ? 15
                            : 30,
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
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(chartData.length, (index) {
                        return FlSpot(index.toDouble(), chartData[index].close);
                      }),
                      isCurved: true,
                      curveSmoothness: 0.2,
                      color: primaryOrange,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            primaryOrange.withOpacity(0.22),
                            primaryOrange.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                duration: Duration.zero,
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
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFFFB700), Color(0xFFFF9500)],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryOrange.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
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
  // TABEL DATA HISTORIS (BARU)
  // ============================================================
  //
  // Sumber data: _historicalViewModel.chartData — list yang sama
  // dipakai untuk grafik di atas, jadi tabel ini otomatis ikut
  // range yang sedang dipilih (7H/30H/90H/1Y/Semua).
  //
  // Field yang dipakai (dateFormatted/openFormatted/highFormatted/
  // lowFormatted/closeFormatted) sudah terbukti ada di model ini
  // karena dipakai juga oleh `historicalData` (selectedData) di
  // bagian metric card di atas.
  // ============================================================

  // Jumlah baris saat collapsed & batas maksimal saat expanded.
  // Dibatasi (bukan unlimited) supaya page tetap ringan walau user
  // pilih range "Semua"/1Y yang datanya bisa ratusan baris.
  static const int _kCollapsedRows = 15;
  static const int _kExpandedRows = 60;

  Widget _buildHistoricalTable({
    required bool isDarkMode,
    required Color glassFill,
    required Color glassBorder,
    required Color primaryOrange,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    // Terbaru di atas.
    // REVISI: sebelumnya tabel dirender pakai ListView.separated
    // shrinkWrap di dalam SingleChildScrollView horizontal, di dalam
    // SingleChildScrollView vertical utama (nested scrollable). Pola
    // ini berisiko memicu error layout ("_debugDoingThisLayout",
    // "RelayoutBoundaryAlreadyMarkedNeedsLayout", dll). Sekarang
    // diganti Column biasa (tanpa scroll bersarang) + jumlah baris
    // dibatasi & bisa di-expand manual lewat tombol, biar page tetap
    // ringan meski data historis banyak.
    final allRows = _historicalViewModel.chartData.reversed.toList();

    final int displayLimit = _isHistoryTableExpanded
        ? _kExpandedRows
        : _kCollapsedRows;

    final rows = allRows.length > displayLimit
        ? allRows.sublist(0, displayLimit)
        : allRows;

    final bool hasMore = allRows.length > _kCollapsedRows;

    return _glassCard(
      isDarkMode: isDarkMode,
      glassFill: glassFill,
      glassBorder: glassBorder,
      radius: 22,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB700), Color(0xFFFF9500)],
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.table_rows_rounded,
                  size: 15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tabel Data Historis',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                  ),
                ),
              ),
              Text(
                allRows.length > rows.length
                    ? '${rows.length} dari ${allRows.length} data'
                    : '${rows.length} data',
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Belum ada data untuk ditampilkan',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
              ),
            )
          else ...[
            // ==================================================
            // HEADER ROW
            // ==================================================
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryOrange.withOpacity(0.16),
                    primaryOrange.withOpacity(0.04),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _tableCell('Tanggal', flex: 3, isHeader: true, color: primaryOrange),
                  _tableCell('Open', flex: 2, isHeader: true, color: primaryOrange),
                  _tableCell('High', flex: 2, isHeader: true, color: primaryOrange),
                  _tableCell('Low', flex: 2, isHeader: true, color: primaryOrange),
                  _tableCell('Close', flex: 2, isHeader: true, color: primaryOrange),
                ],
              ),
            ),

            // ==================================================
            // BODY ROWS — Column biasa, tanpa scroll bersarang.
            // ==================================================
            ...List.generate(rows.length, (index) {
              final item = rows[index];
              final isEven = index % 2 == 0;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isEven
                      ? Colors.transparent
                      : (isDarkMode
                            ? Colors.white.withOpacity(0.03)
                            : Colors.black.withOpacity(0.02)),
                  border: Border(
                    bottom: BorderSide(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _tableCell(
                      item.dateFormatted,
                      flex: 3,
                      color: secondaryTextColor,
                    ),
                    _tableCell(
                      item.openFormatted,
                      flex: 2,
                      color: primaryTextColor,
                    ),
                    _tableCell(
                      item.highFormatted,
                      flex: 2,
                      color: const Color(0xFF4CAF50),
                    ),
                    _tableCell(
                      item.lowFormatted,
                      flex: 2,
                      color: const Color(0xFFEF5350),
                    ),
                    _tableCell(
                      item.closeFormatted,
                      flex: 2,
                      color: primaryTextColor,
                      bold: true,
                    ),
                  ],
                ),
              );
            }),

            // ==================================================
            // TOMBOL LIHAT SELENGKAPNYA / SEMBUNYIKAN
            // ==================================================
            if (hasMore) ...[
              const SizedBox(height: 4),
              InkWell(
                onTap: () {
                  setState(() {
                    _isHistoryTableExpanded = !_isHistoryTableExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryOrange.withOpacity(0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isHistoryTableExpanded
                            ? 'Sembunyikan'
                            : 'Lihat Selengkapnya',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primaryOrange,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isHistoryTableExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: primaryOrange,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _tableCell(
    String text, {
    required int flex,
    required Color color,
    bool isHeader = false,
    bool bold = false,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: isHeader ? 10.5 : 11.5,
          fontWeight: isHeader || bold ? FontWeight.w700 : FontWeight.w500,
          color: color,
          letterSpacing: isHeader ? 0.3 : 0,
        ),
      ),
    );
  }

  // ============================================================
  // LOADING CARD
  // ============================================================

  Widget _buildLoadingCard({
    required bool isDarkMode,
    required Color glassFill,
    required Color glassBorder,
    required Color secondaryTextColor,
  }) {
    return _glassCard(
      isDarkMode: isDarkMode,
      glassFill: glassFill,
      glassBorder: glassBorder,
      radius: 22,
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFFFF9500)),
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
    required bool isDarkMode,
    required Color glassFill,
    required Color glassBorder,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color primaryOrange,
  }) {
    return _glassCard(
      isDarkMode: isDarkMode,
      glassFill: glassFill,
      glassBorder: glassBorder,
      radius: 22,
      padding: const EdgeInsets.all(20),
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
            onPressed: () => _historicalViewModel.loadHistoricalData(),
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

// ================================================================
// LIVE CLOCK — jam digital real-time (jam:menit:detik)
// ================================================================
// Sengaja dibuat sebagai StatefulWidget TERPISAH (bukan setState di
// HomeTabViewState) supaya yang re-render tiap detik CUMA widget
// jam ini sendiri, bukan seluruh halaman Home (yang berat karena
// banyak BackdropFilter/glass). Ini penting biar page tetap ringan
// walau jamnya live-update tiap detik.
// ================================================================
class _LiveClock extends StatefulWidget {
  final Color accentColor;
  final Color textColor;

  const _LiveClock({required this.accentColor, required this.textColor});

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBlink = _now.second % 2 == 0;
    final hh = _now.hour.toString().padLeft(2, '0');
    final mm = _now.minute.toString().padLeft(2, '0');
    final ss = _now.second.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.accentColor.withOpacity(0.16),
            widget.accentColor.withOpacity(0.03),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.accentColor.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dot "LIVE" berkedip
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.accentColor.withOpacity(isBlink ? 1 : 0.35),
              boxShadow: isBlink
                  ? [
                      BoxShadow(
                        color: widget.accentColor.withOpacity(0.6),
                        blurRadius: 5,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            '$hh:$mm:$ss',
            style: GoogleFonts.robotoMono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: widget.textColor,
              letterSpacing: 0.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'WIB',
            style: GoogleFonts.poppins(
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              color: widget.accentColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}