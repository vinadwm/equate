import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:equate/model/historical_data_model.dart';
import 'package:equate/viewmodel/historical_data_viewmodel.dart';
import 'package:equate/viewmodel/theme_viewmodel.dart';

class HistoricalDataView extends StatefulWidget {
  final HistoricalDataViewModel? historicalDataViewModel;

  const HistoricalDataView({super.key, this.historicalDataViewModel});

  @override
  State<HistoricalDataView> createState() => _HistoricalDataViewState();
}

class _HistoricalDataViewState extends State<HistoricalDataView> {
  late final HistoricalDataViewModel _historicalViewModel;

  late final bool _isOwnViewModel;

  // ============================================================
  // KONFIGURASI LOGO PDF
  //
  // Pastikan file logo ada di:
  //
  // assets/images/logo_pt_ewf.png
  //
  // Kalau nama/path logo kamu berbeda, cukup ubah baris ini.
  // ============================================================

  static const String _logoAssetPath = 'assets/images/logoEWF.png';

  // ============================================================
  // FORMATTER
  // ============================================================

  final NumberFormat _numberFormat = NumberFormat('#,##0.##', 'id_ID');

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    if (widget.historicalDataViewModel != null) {
      _historicalViewModel = widget.historicalDataViewModel!;

      _isOwnViewModel = false;
    } else {
      _historicalViewModel = HistoricalDataViewModel();

      _isOwnViewModel = true;
    }

    _historicalViewModel.addListener(_onViewModelChanged);

    if (_historicalViewModel.marketData.isEmpty &&
        !_historicalViewModel.isLoading) {
      _historicalViewModel.loadHistoricalData();
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _historicalViewModel.removeListener(_onViewModelChanged);

    if (_isOwnViewModel) {
      _historicalViewModel.dispose();
    }

    super.dispose();
  }

  // ============================================================
  // VIEWMODEL LISTENER
  // ============================================================

  void _onViewModelChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeViewModel.isDarkMode;

    final primaryOrange = const Color(0xFFFF9E0F);

    final backgroundColor = isDarkMode
        ? const Color(0xFF101010)
        : const Color(0xFFF7F7F7);

    final cardColor = isDarkMode ? const Color(0xFF1B1B1B) : Colors.white;

    final primaryTextColor = isDarkMode
        ? Colors.white
        : const Color(0xFF202020);

    final secondaryTextColor = isDarkMode
        ? Colors.grey[400]!
        : Colors.grey[600]!;

    final borderColor = isDarkMode
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
            color: primaryTextColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Data Historis',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: primaryTextColor,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryOrange,
          onRefresh: () {
            return _historicalViewModel.loadHistoricalData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // HEADER
                // ==================================================

                _buildHeader(
                  isDarkMode: isDarkMode,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  primaryOrange: primaryOrange,
                ),

                const SizedBox(height: 18),

                // ==================================================
                // MARKET SELECTOR
                // ==================================================
                _buildMarketSelector(
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  borderColor: borderColor,
                  primaryOrange: primaryOrange,
                ),

                const SizedBox(height: 14),

                // ==================================================
                // RANGE SELECTOR
                // ==================================================
                _buildRangeSelector(
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  borderColor: borderColor,
                  primaryOrange: primaryOrange,
                ),

                const SizedBox(height: 18),

                // ==================================================
                // ERROR
                // ==================================================
                if (_historicalViewModel.errorMessage != null)
                  _buildErrorCard(
                    message: _historicalViewModel.errorMessage!,
                    isDarkMode: isDarkMode,
                    primaryTextColor: primaryTextColor,
                    primaryOrange: primaryOrange,
                  ),

                // ==================================================
                // LOADING
                // ==================================================
                if (_historicalViewModel.isLoading)
                  _buildLoading(
                    primaryOrange: primaryOrange,
                    secondaryTextColor: secondaryTextColor,
                  )
                else
                  _buildHistoricalTable(
                    isDarkMode: isDarkMode,
                    cardColor: cardColor,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    borderColor: borderColor,
                    primaryOrange: primaryOrange,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader({
    required bool isDarkMode,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color primaryOrange,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pergerakan Harga',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Lihat data harga historis berdasarkan periode yang dipilih.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            height: 1.45,
            color: secondaryTextColor,
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
    required Color cardColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color borderColor,
    required Color primaryOrange,
  }) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          _buildMarketButton(
            title: 'Emas',
            market: HistoricalMarket.gold,
            primaryOrange: primaryOrange,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
          ),
          _buildMarketButton(
            title: 'HKK',
            market: HistoricalMarket.hkk,
            primaryOrange: primaryOrange,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
          ),
          _buildMarketButton(
            title: 'JPK',
            market: HistoricalMarket.jpk,
            primaryOrange: primaryOrange,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MARKET BUTTON
  // ============================================================

  Widget _buildMarketButton({
    required String title,
    required HistoricalMarket market,
    required Color primaryOrange,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    final selected = _historicalViewModel.selectedMarket == market;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _historicalViewModel.changeMarket(market);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? primaryOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? Colors.white : secondaryTextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RANGE SELECTOR
  // ============================================================

  Widget _buildRangeSelector({
    required bool isDarkMode,
    required Color cardColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color borderColor,
    required Color primaryOrange,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.date_range_rounded, size: 17, color: primaryOrange),
              const SizedBox(width: 7),
              Text(
                'Periode',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
              const Spacer(),
              Text(
                _historicalViewModel.historyRangeLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: primaryOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              _buildRangeButton(
                label: '7 Hari',
                days: 7,
                primaryOrange: primaryOrange,
                secondaryTextColor: secondaryTextColor,
              ),
              const SizedBox(width: 6),
              _buildRangeButton(
                label: '30 Hari',
                days: 30,
                primaryOrange: primaryOrange,
                secondaryTextColor: secondaryTextColor,
              ),
              const SizedBox(width: 6),
              _buildRangeButton(
                label: '90 Hari',
                days: 90,
                primaryOrange: primaryOrange,
                secondaryTextColor: secondaryTextColor,
              ),
              const SizedBox(width: 6),
              _buildRangeButton(
                label: '1 Tahun',
                days: 365,
                primaryOrange: primaryOrange,
                secondaryTextColor: secondaryTextColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RANGE BUTTON
  // ============================================================

  Widget _buildRangeButton({
    required String label,
    required int days,
    required Color primaryOrange,
    required Color secondaryTextColor,
  }) {
    final selected = _historicalViewModel.historyDays == days;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _historicalViewModel.changeHistoryRange(days);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 3),
          decoration: BoxDecoration(
            color: selected ? primaryOrange : primaryOrange.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? primaryOrange : primaryOrange.withOpacity(0.15),
            ),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? Colors.white : secondaryTextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HISTORICAL TABLE
  // ============================================================

  Widget _buildHistoricalTable({
    required bool isDarkMode,
    required Color cardColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color borderColor,
    required Color primaryOrange,
  }) {
    final data = _historicalViewModel.filteredHistoricalData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ========================================================
        // TABLE HEADER
        // ========================================================

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data ${_historicalViewModel.marketName}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${data.length} data tersedia',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),

            // EXPORT PDF
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: data.isEmpty ? null : _exportAsPdf,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: data.isEmpty
                        ? Colors.grey.withOpacity(0.1)
                        : primaryOrange.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: data.isEmpty
                          ? borderColor
                          : primaryOrange.withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.picture_as_pdf_rounded,
                        size: 16,
                        color: data.isEmpty
                            ? secondaryTextColor
                            : primaryOrange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Ekspor PDF',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: data.isEmpty
                              ? secondaryTextColor
                              : primaryOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 13),

        if (data.isEmpty)
          _buildEmptyState(
            isDarkMode: isDarkMode,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            primaryOrange: primaryOrange,
          )
        else
          _buildTableCard(
            data: data,
            isDarkMode: isDarkMode,
            cardColor: cardColor,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            borderColor: borderColor,
            primaryOrange: primaryOrange,
          ),
      ],
    );
  }

  // ============================================================
  // TABLE CARD
  // ============================================================

  Widget _buildTableCard({
    required List<HistoricalDataModel> data,
    required bool isDarkMode,
    required Color cardColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color borderColor,
    required Color primaryOrange,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // TABLE HEADER
              // ==================================================

              Container(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.04)
                    : Colors.black.withOpacity(0.025),
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                  horizontal: 14,
                ),
                child: Row(
                  children: [
                    _tableHeaderCell('Tanggal', 115, secondaryTextColor),
                    _tableHeaderCell('Open', 90, secondaryTextColor),
                    _tableHeaderCell('High', 90, secondaryTextColor),
                    _tableHeaderCell('Low', 90, secondaryTextColor),
                    _tableHeaderCell('Close', 90, secondaryTextColor),
                  ],
                ),
              ),

              // ==================================================
              // TABLE ROWS
              // ==================================================
              ...List.generate(data.length, (index) {
                final item = data[index];

                final isLast = index == data.length - 1;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    children: [
                      _tableDataCell(
                        item.dateFormatted,
                        115,
                        secondaryTextColor,
                      ),
                      _tableDataCell(item.openFormatted, 90, primaryTextColor),
                      _tableDataCell(
                        item.highFormatted,
                        90,
                        const Color(0xFF35B86B),
                      ),
                      _tableDataCell(
                        item.lowFormatted,
                        90,
                        const Color(0xFFEF5350),
                      ),
                      _tableDataCell(
                        item.closeFormatted,
                        90,
                        primaryTextColor,
                        bold: true,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TABLE HEADER CELL
  // ============================================================

  Widget _tableHeaderCell(String text, double width, Color color) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ============================================================
  // TABLE DATA CELL
  // ============================================================

  Widget _tableDataCell(
    String text,
    double width,
    Color color, {
    bool bold = false,
  }) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.5,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState({
    required bool isDarkMode,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color primaryOrange,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 55, horizontal: 20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1B1B1B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.07)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 42,
            color: primaryOrange.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Data belum tersedia',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Belum ada data untuk periode yang dipilih.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading({
    required Color primaryOrange,
    required Color secondaryTextColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 55),
      child: Column(
        children: [
          SizedBox(
            width: 27,
            height: 27,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: primaryOrange,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            'Memuat data historis...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR CARD
  // ============================================================

  Widget _buildErrorCard({
    required String message,
    required bool isDarkMode,
    required Color primaryTextColor,
    required Color primaryOrange,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                color: primaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EXPORT PDF
  // ============================================================

  Future<void> _exportAsPdf() async {
    final data = _historicalViewModel.filteredHistoricalData;

    if (data.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diekspor.')),
      );

      return;
    }

    // ==========================================================
    // TAMPILKAN LOADING
    // ==========================================================

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF9E0F)),
        );
      },
    );

    try {
      // ========================================================
      // LOAD LOGO
      // ========================================================

      pw.MemoryImage? logoImage;

      try {
        final ByteData logoData = await rootBundle.load(_logoAssetPath);

        final Uint8List logoBytes = logoData.buffer.asUint8List();

        logoImage = pw.MemoryImage(logoBytes);
      } catch (e) {
        debugPrint('Logo PT EWF tidak ditemukan: $e');

        logoImage = null;
      }

      // ========================================================
      // PDF DOCUMENT
      // ========================================================

      final document = pw.Document();

      final marketName = _historicalViewModel.marketName;

      final category = _historicalViewModel.selectedCategory;

      final period = _historicalViewModel.historyRangeLabel;

      final latestDate = data.first.date;

      final oldestDate = data.last.date;

      // ========================================================
      // CHUNK DATA
      //
      // Supaya PDF tidak terlalu panjang dalam satu Table.
      // 25 row per halaman.
      // ========================================================

      const int rowsPerPage = 25;

      final List<List<HistoricalDataModel>> chunks = [];

      for (int i = 0; i < data.length; i += rowsPerPage) {
        final end = (i + rowsPerPage < data.length)
            ? i + rowsPerPage
            : data.length;

        chunks.add(data.sublist(i, end));
      }

      // ========================================================
      // GENERATE PAGE
      // ========================================================

      for (int pageIndex = 0; pageIndex < chunks.length; pageIndex++) {
        final pageData = chunks[pageIndex];

        document.addPage(
          pw.Page(
            pageFormat: pdf.PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(28),
            build: (context) {
              return pw.Stack(
                children: [
                  // ==================================================
                  // WATERMARK LOGO
                  // ==================================================

                  if (logoImage != null)
                    pw.Positioned.fill(
                      child: pw.Center(
                        child: pw.Opacity(
                          opacity: 0.055,
                          child: pw.Image(
                            logoImage!,
                            width: 260,
                            height: 260,
                            fit: pw.BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                  // ==================================================
                  // MAIN CONTENT
                  // ==================================================
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // ==============================================
                      // HEADER
                      // ==============================================

                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (logoImage != null)
                            pw.Container(
                              width: 48,
                              height: 48,
                              margin: const pw.EdgeInsets.only(right: 12),
                              child: pw.Image(
                                logoImage!,
                                fit: pw.BoxFit.contain,
                              ),
                            ),

                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'DATA HISTORIS PASAR',
                                  style: pw.TextStyle(
                                    fontSize: 17,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 3),
                                pw.Text(
                                  'PT EWF',
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    color: pdf.PdfColors.grey700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          pw.Text(
                            '${pageIndex + 1}/${chunks.length}',
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: pdf.PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 18),

                      // ==============================================
                      // INFO
                      // ==============================================
                      pw.Container(
                        padding: const pw.EdgeInsets.all(11),
                        decoration: pw.BoxDecoration(
                          color: pdf.PdfColors.grey100,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              child: _pdfInfoItem('Pasar', marketName),
                            ),
                            pw.Expanded(child: _pdfInfoItem('Periode', period)),
                            pw.Expanded(
                              child: _pdfInfoItem('Kategori', category),
                            ),
                          ],
                        ),
                      ),

                      pw.SizedBox(height: 8),

                      pw.Text(
                        '${_formatPdfDate(oldestDate)} - ${_formatPdfDate(latestDate)}',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          color: pdf.PdfColors.grey600,
                        ),
                      ),

                      pw.SizedBox(height: 15),

                      // ==============================================
                      // TABLE
                      // ==============================================
                      pw.Table(
                        border: pw.TableBorder.all(
                          color: pdf.PdfColors.grey300,
                          width: 0.5,
                        ),
                        columnWidths: const {
                          0: pw.FlexColumnWidth(1.4),
                          1: pw.FlexColumnWidth(1),
                          2: pw.FlexColumnWidth(1),
                          3: pw.FlexColumnWidth(1),
                          4: pw.FlexColumnWidth(1),
                        },
                        children: [
                          // ==========================================
                          // HEADER
                          // ==========================================

                          pw.TableRow(
                            decoration: const pw.BoxDecoration(
                              color: pdf.PdfColors.orange,
                            ),
                            children: [
                              _pdfTableHeader('Tanggal'),
                              _pdfTableHeader('Open'),
                              _pdfTableHeader('High'),
                              _pdfTableHeader('Low'),
                              _pdfTableHeader('Close'),
                            ],
                          ),

                          // ==========================================
                          // ROWS
                          // ==========================================
                          ...pageData.map((item) {
                            return pw.TableRow(
                              children: [
                                _pdfTableCell(item.dateFormatted),
                                _pdfTableCell(item.openFormatted),
                                _pdfTableCell(item.highFormatted),
                                _pdfTableCell(item.lowFormatted),
                                _pdfTableCell(item.closeFormatted, bold: true),
                              ],
                            );
                          }),
                        ],
                      ),

                      pw.Spacer(),

                      // ==============================================
                      // FOOTER
                      // ==============================================
                      pw.Container(
                        padding: const pw.EdgeInsets.only(top: 8),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            top: pw.BorderSide(
                              color: pdf.PdfColors.grey300,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                                'Data historis ${marketName} • PT EWF',
                                style: pw.TextStyle(
                                  fontSize: 7.5,
                                  color: pdf.PdfColors.grey600,
                                ),
                              ),
                            ),
                            pw.Text(
                              'Equate',
                              style: pw.TextStyle(
                                fontSize: 7.5,
                                color: pdf.PdfColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      }

      // ==========================================================
      // SAVE
      // ==========================================================

      final bytes = await document.save();

      // Tutup loading
      if (mounted) {
        Navigator.of(context).pop();
      }

      // ==========================================================
      // SHARE / SAVE PDF
      // ==========================================================

      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'data_historis_${marketName.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      debugPrint('EXPORT PDF ERROR: $e');

      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat PDF: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // ============================================================
  // PDF INFO ITEM
  // ============================================================

  pw.Widget _pdfInfoItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 7.5, color: pdf.PdfColors.grey600),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  // ============================================================
  // PDF TABLE HEADER
  // ============================================================

  pw.Widget _pdfTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: pdf.PdfColors.white,
        ),
      ),
    );
  }

  // ============================================================
  // PDF TABLE CELL
  // ============================================================

  pw.Widget _pdfTableCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // ============================================================
  // PDF DATE
  // ============================================================

  String _formatPdfDate(DateTime date) {
    return _dateFormat.format(date);
  }
}
