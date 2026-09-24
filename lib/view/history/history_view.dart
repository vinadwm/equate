import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:equate/model/base_calculation_history.dart';

import 'package:equate/model/calculation_history_model.dart';
import 'package:equate/model/digital_gold_model.dart';
import 'package:equate/model/physical_gold_model.dart'; // <--- Titik dua (:) setelah package
import 'package:equate/model/nest_gold_model.dart';
import 'package:equate/model/nest_hangseng_model.dart';
import 'package:equate/model/pivot_gold_model.dart';
import 'package:equate/model/pivot_hangseng_model.dart';
import 'package:equate/viewmodel/theme_viewmodel.dart';
import 'history_detail_sheet.dart';

class HistoryView extends StatefulWidget {
  final List<dynamic> historyList;

  const HistoryView({
    super.key,
    required this.historyList,
  });

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  String _selectedMarket = 'Semua'; // 'Semua', 'Emas', 'Hangseng'
  String _searchQuery = '';
  
  // Filter State
  int? _selectedDaysFilter; // null, 1 (Hari ini), 2, 3, 4, 5, 6, 7
  DateTimeRange? _selectedDateRange;
  String _selectedCalcType = 'Semua'; // 'Semua', 'Emas Digital', 'Emas Fisik', 'Pivot Point', 'NEST'

  final List<String> _markets = ['Semua', 'Emas', 'Hangseng'];

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );
    return formatter.format(amount.abs()).trim();
  }

  // ============================================================
  // HELPER PARSER SETIAP MODEL
  // ============================================================
  Map<String, dynamic> _parseItemInfo(dynamic item) {
    String title = 'Riwayat';
    String details = 'Detail Perhitungan';
    double result = 0.0;
    DateTime timestamp = DateTime.now();
    bool isCurrency = true;
    String marketType = 'Emas';
    String subType = 'Lainnya'; // 'Emas Digital', 'Emas Fisik', 'Pivot Point', 'NEST'

    if (item is CalculationHistory) {
      timestamp = item.createdAt;
      title = item.category.isNotEmpty ? item.category : item.title;
    }

    if (item is DigitalGoldModel) {
      title = 'Emas Digital';
      details = '${item.weightInGram} Lot | Beli: ${_formatCurrency(item.buyPrice)}';
      result = item.profitLoss;
      marketType = 'Emas';
      subType = 'Emas Digital';
    } else if (item is PhysicalGoldModel) {
      title = 'Emas Fisik';
      details = '${item.weightInGram} gram | Rp ${_formatCurrency(item.buyPrice)}/g';
      result = item.profitLoss;
      marketType = 'Emas';
      subType = 'Emas Fisik';
    } else if (item is PivotGoldModel) {
      title = 'Pivot Gold (${item.type})';
      details = 'PP: ${item.pp} | R1: ${item.r1} | S1: ${item.s1}';
      result = item.pp;
      isCurrency = false;
      marketType = 'Emas';
      subType = 'Pivot Point';
    } else if (item is NestGoldModel) {
      title = 'NEST Gold';
      details = 'Signal: ${item.signalLabel} | Open: ${item.open ?? '-'}';
      result = item.close ?? 0.0;
      isCurrency = false;
      marketType = 'Emas';
      subType = 'NEST';
    } else if (item is PivotHangsengModel) {
      title = 'Pivot Hangseng';
      details = 'PP: ${item.pp ?? '-'} | H: ${item.high ?? '-'} | L: ${item.low ?? '-'}';
      result = item.pp ?? 0.0;
      isCurrency = false;
      marketType = 'Hangseng';
      subType = 'Pivot Point';
    } else if (item is NestHangsengModel) {
      title = 'NEST Hangseng';
      details = 'Signal: ${item.signalLabel} | Open: ${item.open ?? '-'}';
      result = item.close ?? 0.0;
      isCurrency = false;
      marketType = 'Hangseng';
      subType = 'NEST';
    } else {
      title = item.title?.toString() ?? 'Riwayat';
      details = item.details?.toString() ?? 'Detail perhitungan';
      result = (item.result is num) ? (item.result as num).toDouble() : 0.0;
      if (item.createdAt is DateTime) timestamp = item.createdAt;

      if (title.toLowerCase().contains('hangseng')) {
        marketType = 'Hangseng';
      } else {
        marketType = 'Emas';
      }

      if (title.toLowerCase().contains('pivot')) subType = 'Pivot Point';
      else if (title.toLowerCase().contains('nest')) subType = 'NEST';
      else if (title.toLowerCase().contains('digital')) subType = 'Emas Digital';
      else if (title.toLowerCase().contains('fisik')) subType = 'Emas Fisik';
    }

    return {
      'title': title,
      'details': details,
      'result': result,
      'timestamp': timestamp,
      'isCurrency': isCurrency,
      'marketType': marketType,
      'subType': subType,
    };
  }

  // ============================================================
  // LOGIKA FILTER & GROUPING DATA
  // ============================================================
  List<dynamic> _getFilteredList() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return widget.historyList.where((item) {
      final parsed = _parseItemInfo(item);
      final marketType = parsed['marketType'] as String;
      final subType = parsed['subType'] as String;
      final title = (parsed['title'] as String).toLowerCase();
      final details = (parsed['details'] as String).toLowerCase();
      final timestamp = parsed['timestamp'] as DateTime;

      // 1. Filter Tab Pasar Utama
      if (_selectedMarket != 'Semua' && marketType != _selectedMarket) {
        return false;
      }

      // 2. Filter Sub Tipe Kalkulator
      if (_selectedCalcType != 'Semua' && subType != _selectedCalcType) {
        return false;
      }

      // 3. Filter Search Query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!title.contains(query) && !details.contains(query)) {
          return false;
        }
      }

      // 4. Filter Berdasarkan Opsi Hari (1 - 7 Hari)
      if (_selectedDaysFilter != null) {
        final limitDate = todayStart.subtract(Duration(days: _selectedDaysFilter! - 1));
        if (timestamp.isBefore(limitDate)) {
          return false;
        }
      }

      // 5. Filter Rentang Tanggal Manual
      if (_selectedDateRange != null) {
        final start = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month,
          _selectedDateRange!.start.day,
        );
        final end = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
          23,
          59,
          59,
        );

        if (timestamp.isBefore(start) || timestamp.isAfter(end)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Mengelompokkan riwayat berdasarkan Tanggal (Hari Ini, Kemarin, Tgl tertentu)
  Map<String, List<dynamic>> _groupHistoryByDate(List<dynamic> list) {
    final Map<String, List<dynamic>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var item in list) {
      final parsed = _parseItemInfo(item);
      final date = parsed['timestamp'] as DateTime;
      final itemDate = DateTime(date.year, date.month, date.day);

      String dateHeader;
      if (itemDate.isAtSameMomentAs(today)) {
        dateHeader = 'Hari Ini';
      } else if (itemDate.isAtSameMomentAs(yesterday)) {
        dateHeader = 'Kemarin';
      } else {
        dateHeader = DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(date);
      }

      if (!grouped.containsKey(dateHeader)) {
        grouped[dateHeader] = [];
      }
      grouped[dateHeader]!.add(item);
    }
    return grouped;
  }

  bool get _hasActiveFilters =>
      _selectedDaysFilter != null ||
      _selectedDateRange != null ||
      _selectedCalcType != 'Semua';

  void _resetFilters() {
    setState(() {
      _selectedDaysFilter = null;
      _selectedDateRange = null;
      _selectedCalcType = 'Semua';
    });
  }

  // ============================================================
  // BOTTOM SHEET FILTER
  // ============================================================
  void _showFilterBottomSheet(BuildContext context, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final primaryTextColor = isDarkMode ? Colors.white : const Color(0xFF2C2D30);
            final secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

            // Sub-tipe dinamis tergantung tab pasar aktif saat ini
            List<String> calcOptions = ['Semua'];
            if (_selectedMarket == 'Emas') {
              calcOptions.addAll(['Emas Digital', 'Emas Fisik', 'Pivot Point', 'NEST']);
            } else if (_selectedMarket == 'Hangseng') {
              calcOptions.addAll(['Pivot Point', 'NEST']);
            } else {
              calcOptions.addAll(['Emas Digital', 'Emas Fisik', 'Pivot Point', 'NEST']);
            }

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1F24) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sheet Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header Sheet
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Riwayat',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: primaryTextColor,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              _selectedDaysFilter = null;
                              _selectedDateRange = null;
                              _selectedCalcType = 'Semua';
                            });
                            setState(() {});
                          },
                          child: Text(
                            'Reset',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFFF9500),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 1. OPSI RENTANG WAKTU (HARI INI s/d 7 HARI)
                    Text(
                      'Rentang Waktu Cepat',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(7, (index) {
                        final days = index + 1;
                        final label = days == 1 ? 'Hari Ini' : '$days Hari';
                        final isSelected = _selectedDaysFilter == days;

                        return ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          selectedColor: const Color(0xFFFF9500),
                          backgroundColor: isDarkMode ? const Color(0xFF2A2B30) : const Color(0xFFF0F1F5),
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDarkMode ? Colors.grey[300] : Colors.black87),
                          ),
                          onSelected: (selected) {
                            setSheetState(() {
                              _selectedDaysFilter = selected ? days : null;
                              _selectedDateRange = null; // Reset custom date range jika pilih quick
                            });
                            setState(() {});
                          },
                        );
                      }),
                    ),

                    const SizedBox(height: 20),

                    // 2. KATEGORI KALKULATOR
                    Text(
                      'Tipe Kalkulator ($_selectedMarket)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: calcOptions.map((opt) {
                        final isSelected = _selectedCalcType == opt;
                        return ChoiceChip(
                          label: Text(opt),
                          selected: isSelected,
                          selectedColor: const Color(0xFFFF9500),
                          backgroundColor: isDarkMode ? const Color(0xFF2A2B30) : const Color(0xFFF0F1F5),
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDarkMode ? Colors.grey[300] : Colors.black87),
                          ),
                          onSelected: (selected) {
                            setSheetState(() {
                              _selectedCalcType = selected ? opt : 'Semua';
                            });
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // 3. RENTANG TANGGAL MANUAL
                    Text(
                      'Atau Pilih Tanggal Manual',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final DateTimeRange? picked = await showDateRangePicker(
                          context: context,
                          initialDateRange: _selectedDateRange,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: isDarkMode
                                    ? const ColorScheme.dark(
                                        primary: Color(0xFFFF9500),
                                        onPrimary: Colors.white,
                                        surface: Color(0xFF1E1F24),
                                        onSurface: Colors.white,
                                      )
                                    : const ColorScheme.light(
                                        primary: Color(0xFFFF9500),
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: Color(0xFF2C2D30),
                                      ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setSheetState(() {
                            _selectedDateRange = picked;
                            _selectedDaysFilter = null; // Clear quick preset
                          });
                          setState(() {});
                        }
                      },
                      icon: const Icon(Icons.date_range_rounded, color: Color(0xFFFF9500), size: 18),
                      label: Text(
                        _selectedDateRange == null
                            ? 'Pilih Tanggal'
                            : '${DateFormat('dd/MM/yy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_selectedDateRange!.end)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: primaryTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDarkMode ? Colors.white24 : Colors.black12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // TOMBOL TERAPKAN
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9500),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Terapkan Filter',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeViewModel.isDarkMode;
    final primaryTextColor = isDarkMode ? Colors.white : const Color(0xFF2C2D30);
    final secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    final filteredList = _getFilteredList();
    final groupedHistory = _groupHistoryByDate(filteredList);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0D0E12) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: primaryTextColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Semua Riwayat',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: primaryTextColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: _hasActiveFilters ? const Color(0xFFFF9500) : primaryTextColor,
                ),
                if (_hasActiveFilters)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF9500),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showFilterBottomSheet(context, isDarkMode),
            tooltip: 'Filter',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),

          // ============================================================
          // SEARCH BAR
          // ============================================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF1E1F24).withOpacity(0.8)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.05),
                ),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: primaryTextColor,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari riwayat...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey[500],
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ============================================================
          // TAB STYLE PASAR (UNDERLINE STYLE)
          // ============================================================
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _markets.map((market) {
                final isSelected = _selectedMarket == market;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedMarket = market;
                      // Reset tipe kalkulator jika pasar berubah agar tidak konflik
                      _selectedCalcType = 'Semua';
                    });
                  },
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected
                              ? const Color(0xFFFF9500) // Warna Garis Bawah Oranye
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Text(
                      market,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                        color: isSelected
                            ? primaryTextColor
                            : (isDarkMode ? Colors.grey[500] : const Color(0xFF7D828A)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ACTIVE FILTER BADGES INFO
          if (_hasActiveFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_selectedDaysFilter != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Chip(
                                label: Text(
                                  _selectedDaysFilter == 1
                                      ? 'Hari Ini'
                                      : '$_selectedDaysFilter Hari Terakhir',
                                ),
                                backgroundColor: const Color(0xFFFF9500).withOpacity(0.15),
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFF9500),
                                ),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          if (_selectedCalcType != 'Semua')
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Chip(
                                label: Text(_selectedCalcType),
                                backgroundColor: const Color(0xFFFF9500).withOpacity(0.15),
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFF9500),
                                ),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _resetFilters,
                    child: Text(
                      'Hapus Filter',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // ============================================================
          // LIST RIWAYAT DENGAN DATE HEADER (Dikelompokkan Berdasarkan Tanggal)
          // ============================================================
          Expanded(
            child: groupedHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 48,
                          color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak Ada Riwayat',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _searchQuery.isNotEmpty || _hasActiveFilters
                              ? 'Coba sesuaikan kata kunci atau filter kamu'
                              : 'Hasil perhitungan kamu akan tampil di sini',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: groupedHistory.keys.length,
                    itemBuilder: (context, dateIndex) {
                      final dateHeader = groupedHistory.keys.elementAt(dateIndex);
                      final itemsForDate = groupedHistory[dateHeader]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // DATE HEADER
                          Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 8, left: 4),
                            child: Text(
                              dateHeader,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: secondaryTextColor,
                              ),
                            ),
                          ),

                          // LIST ITEM DI HARI TERSEBUT
                          ...itemsForDate.map((rawItem) {
                            final parsed = _parseItemInfo(rawItem);

                            final itemTitle = parsed['title'] as String;
                            final itemDetails = parsed['details'] as String;
                            final itemResult = parsed['result'] as double;
                            final itemTimestamp = parsed['timestamp'] as DateTime;
                            final isCurrency = parsed['isCurrency'] as bool;

                            final isPositive = itemResult >= 0;
                            final timeFormatted = DateFormat('HH:mm').format(itemTimestamp);

                            String formattedValue;
                            if (isCurrency) {
                              formattedValue =
                                  '${isPositive ? '+Rp ' : '-Rp '}${_formatCurrency(itemResult)}';
                            } else {
                              formattedValue = itemResult.toStringAsFixed(2);
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? const Color(0xFF1E1F24).withOpacity(0.8)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDarkMode
                                      ? Colors.white.withOpacity(0.08)
                                      : Colors.black.withOpacity(0.04),
                                  width: 0.8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.03),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => HistoryDetailSheet(
                                        item: rawItem,
                                        isDarkMode: isDarkMode,
                                        primaryTextColor: primaryTextColor,
                                        secondaryTextColor: secondaryTextColor,
                                        primaryOrange: const Color(0xFFFF9500),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF9500).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: const Icon(
                                            Icons.calculate_rounded,
                                            color: Color(0xFFFF9500),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                itemTitle,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: primaryTextColor,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                itemDetails,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11,
                                                  color: secondaryTextColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                timeFormatted,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 10,
                                                  color: isDarkMode
                                                      ? Colors.grey[500]
                                                      : Colors.grey[400],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          formattedValue,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: !isCurrency
                                                ? primaryTextColor
                                                : (isPositive
                                                    ? const Color(0xFF34C759)
                                                    : const Color(0xFFFF3B30)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}