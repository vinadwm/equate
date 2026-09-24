import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'package:equate/model/pivot_hangseng_model.dart';
import 'package:equate/viewmodel/historical_data_viewmodel.dart';
import 'package:equate/viewmodel/pivot_hangseng_viewmodel.dart';

class PivotHangsengCalculatorContent extends StatefulWidget {
  final HistoricalDataViewModel historicalDataViewModel;
  final Function(dynamic)? onCalculate;

  const PivotHangsengCalculatorContent({
    super.key,
    required this.historicalDataViewModel,
    this.onCalculate,
  });

  @override
  State<PivotHangsengCalculatorContent> createState() => _PivotHangsengCalculatorContentState();
}

class _PivotHangsengCalculatorContentState extends State<PivotHangsengCalculatorContent> {
  // GLOBAL KEY UNTUK EXPORT GAMBAR
  final GlobalKey _globalKey = GlobalKey();

  // CONTROLLER INPUT
  final TextEditingController _highController = TextEditingController();
  final TextEditingController _lowController = TextEditingController();
  final TextEditingController _closeController = TextEditingController();

  late final PivotHangsengViewModel _viewModel;

  // Mencegah listener controller dianggap input manual saat sinkronisasi.
  bool _syncingControllers = false;

  // UI STATE
  bool _hasInput = false;
  bool _isR4Expanded = false;
  bool _isS4Expanded = false;

  @override
  void initState() {
    super.initState();

    _viewModel = PivotHangsengViewModel(
      historicalDataViewModel: widget.historicalDataViewModel,
    );

    _viewModel.addListener(_onViewModelChanged);

    _syncControllers();

    _highController.addListener(_onHighChanged);
    _lowController.addListener(_onLowChanged);
    _closeController.addListener(_onCloseChanged);

    _updateInputState();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();

    _highController.removeListener(_onHighChanged);
    _lowController.removeListener(_onLowChanged);
    _closeController.removeListener(_onCloseChanged);

    _highController.dispose();
    _lowController.dispose();
    _closeController.dispose();

    super.dispose();
  }

  void _onViewModelChanged() {
    if (!mounted) return;

    _syncControllers();
    _updateInputState();

    setState(() {});
  }

  void _syncControllers() {
    _syncingControllers = true;

    if (_highController.text != _viewModel.high) {
      _highController.value = TextEditingValue(
        text: _viewModel.high,
        selection: TextSelection.collapsed(offset: _viewModel.high.length),
      );
    }

    if (_lowController.text != _viewModel.low) {
      _lowController.value = TextEditingValue(
        text: _viewModel.low,
        selection: TextSelection.collapsed(offset: _viewModel.low.length),
      );
    }

    if (_closeController.text != _viewModel.close) {
      _closeController.value = TextEditingValue(
        text: _viewModel.close,
        selection: TextSelection.collapsed(offset: _viewModel.close.length),
      );
    }

    _syncingControllers = false;
  }

  void _onHighChanged() {
    if (_syncingControllers) return;

    _viewModel.setHigh(_highController.text);
    _updateInputState();
  }

  void _onLowChanged() {
    if (_syncingControllers) return;

    _viewModel.setLow(_lowController.text);
    _updateInputState();
  }

  void _onCloseChanged() {
    if (_syncingControllers) return;

    _viewModel.setClose(_closeController.text);
    _updateInputState();
  }

  void _updateInputState() {
    final hasText = _highController.text.trim().isNotEmpty ||
        _lowController.text.trim().isNotEmpty ||
        _closeController.text.trim().isNotEmpty;

    if (mounted && hasText != _hasInput) {
      setState(() {
        _hasInput = hasText;
      });
    }
  }

  // ==========================================================
  // HITUNG
  // ==========================================================
  void _calculatePivot() {
    final success = _viewModel.calculatePivot();

    if (!success) {
      _showSnackBar(
        _viewModel.errorMessage ?? 'Harap masukkan data yang valid.',
        backgroundColor: Colors.red,
      );
      return;
    }

    // SIMPAN KE HISTORY
    if (widget.onCalculate != null) {
      widget.onCalculate!(
        PivotHangsengModel(
          title: 'Pivot Point',
          details: 'H: ${_viewModel.high} | '
              'L: ${_viewModel.low} | '
              'C: ${_viewModel.close}',
          result: _viewModel.pp ?? 0,
          createdAt: DateTime.now(),
          calculationDate: DateTime.now(),
        ),
      );
    }

    setState(() {});
  }

  void _resetForm() {
    _viewModel.reset();

    _isR4Expanded = false;
    _isS4Expanded = false;

    _syncControllers();
    _updateInputState();

    setState(() {});
  }

  // MUAT ULANG DATA (hanya mode Otomatis)
  void _reloadPreviousDay() {
    final success = _viewModel.refreshPreviousDayInput();

    if (success) {
      _showSnackBar(
        'Data Hangseng hari sebelumnya berhasil dimuat.',
        backgroundColor: const Color(0xFF18B85A),
      );
    } else {
      _showSnackBar(
        _viewModel.errorMessage ??
            'Data Hangseng hari sebelumnya belum tersedia.',
        backgroundColor: Colors.red,
      );
    }
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _fmt(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');

    return '$d/$m/${date.year}';
  }

  Color _signalColorOf(PivotSignal signal) {
    switch (signal) {
      case PivotSignal.buy:
        return const Color(0xFF18B85A);

      case PivotSignal.sell:
        return const Color(0xFFFF3B30);

      case PivotSignal.neutral:
        return const Color(0xFFFFA800);

      case PivotSignal.unavailable:
        return Colors.grey;
    }
  }

  // ==========================================================
  // EXPORT IMAGE
  // ==========================================================
  Future<void> _exportAsImage() async {
    try {
      var hasAccess = await Gal.hasAccess();

      if (!hasAccess) {
        await Gal.requestAccess();
        hasAccess = await Gal.hasAccess();
      }

      if (!hasAccess) {
        _showSnackBar(
          'Izin akses galeri ditolak.',
          backgroundColor: Colors.red,
        );
        return;
      }

      final boundary = _globalKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        _showSnackBar(
          'Gagal mengambil hasil kalkulasi.',
          backgroundColor: Colors.red,
        );
        return;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        _showSnackBar('Gagal membuat gambar.', backgroundColor: Colors.red);
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();
      final output = await getTemporaryDirectory();
      final filePath = '${output.path}/pivot_point_'
          '${DateTime.now().millisecondsSinceEpoch}.png';

      final file = File(filePath);
      await file.writeAsBytes(pngBytes);
      await Gal.putImage(filePath);

      _showSnackBar(
        'Gambar berhasil disimpan ke Galeri!',
        backgroundColor: const Color(0xFF18B85A),
      );
    } catch (e) {
      _showSnackBar('Gagal menyimpan gambar: $e', backgroundColor: Colors.red);
    }
  }

  Future<void> _exportAsPdf() async {
    try {
      final pdfBytes = await _viewModel.buildPdf();

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          return pdfBytes;
        },
      );
    } catch (e) {
      _showSnackBar('Gagal membuat PDF: $e', backgroundColor: Colors.red);
    }
  }

  void _showExportModal(BuildContext context) {
    if (!_viewModel.isCalculated) {
      _showSnackBar(
        'Silakan hitung Pivot Point terlebih dahulu.',
        backgroundColor: Colors.red,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.image_rounded,
                  color: Color(0xFFFF9E0F),
                ),
                title: const Text('Export sebagai Gambar (PNG)'),
                onTap: () {
                  Navigator.pop(context);
                  _exportAsImage();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Colors.redAccent,
                ),
                title: const Text('Export sebagai PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _exportAsPdf();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFFF9E0F);
    const resistanceColor = Color(0xFFFFB800);
    const supportColor = Color(0xFF4295FF);
    const pivotColor = Color(0xFF18B85A);
    const midpointColor = Color(0xFF9E9E9E);
    const pivotValueColor = Color(0xFF10B981);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final inputFillColor =
        isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF8F8FA);
    final primaryTextColor =
        isDarkMode ? Colors.white : const Color(0xFF161616);
    final borderColor =
        isDarkMode ? Colors.grey[800]! : const Color(0xFFE7E7E7);
    final dividerColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFEEEEEE);

    final vm = _viewModel;
    final previousData = vm.previousHangsengData;
    final autoMode = vm.autoMode;

    // Baris level (R/S) dan midpoint, dibuat ringkas.
    Widget lvl(
      String label,
      double? value,
      Color color, {
      IconData? icon,
      VoidCallback? onTap,
    }) {
      return _buildResultRow(
        label: label,
        value: vm.formatValue(value),
        labelColor: color,
        valueColor: primaryTextColor,
        trailingIcon: icon,
        trailingIconColor: color,
        onTrailingIconTap: onTap,
      );
    }

    Widget mid(double? a, double? b) {
      if (a == null || b == null) {
        return const SizedBox.shrink();
      }

      return _buildResultRow(
        label: 'Midpoint',
        value: vm.formatValue(vm.midpoint(a, b)),
        labelColor: midpointColor,
        valueColor: primaryTextColor,
        isMidpoint: true,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // ======================================================
          // INPUT CARD
          // ======================================================
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withValues(alpha: isDarkMode ? 0.25 : 0.035),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: primaryOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.auto_graph_rounded,
                        color: primaryOrange,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data Pivot Point Hangseng',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            previousData != null
                                ? 'Hangseng • H/L/C ${previousData.dateFormatted}'
                                : 'Menunggu data Hangseng...',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (autoMode)
                      IconButton(
                        tooltip: 'Muat ulang data Hangseng',
                        visualDensity: VisualDensity.compact,
                        onPressed: _reloadPreviousDay,
                        icon: const Icon(
                          Icons.refresh_rounded,
                          size: 20,
                          color: primaryOrange,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),
                Divider(height: 1, thickness: 1, color: dividerColor),
                const SizedBox(height: 10),

                // Toggle Otomatis / Manual
                _buildModeToggle(
                  isDarkMode: isDarkMode,
                  primaryTextColor: primaryTextColor,
                  borderColor: borderColor,
                ),

                const SizedBox(height: 8),

                // Info Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF252525)
                        : const Color(0xFFFFF8EA),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: primaryOrange,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          autoMode
                              ? 'High, Low, dan Close otomatis diambil dari data Hangseng '
                                  'hari sebelumnya (atau data terakhir yang tersedia jika libur). '
                                  'Matikan mode Otomatis untuk mengisi sendiri.'
                              : 'Mode Manual aktif. Isi High, Low, dan Close sesuai '
                                  'kebutuhan, lalu tekan HITUNG.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            height: 1.4,
                            color: isDarkMode
                                ? Colors.grey[300]
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Catatan fallback
                if (autoMode &&
                    vm.isPreviousDataFallback &&
                    previousData != null) ...[
                  const SizedBox(height: 8),
                  _buildNote(
                    'Data ${_fmt(vm.previousDate)} belum ada (weekend/libur '
                    'newsmaker), jadi dipakai data terakhir yang tersedia: '
                    '${previousData.dateFormatted}.',
                    isDarkMode,
                  ),
                ],

                const SizedBox(height: 10),

                // Inputs
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactInput(
                        'High',
                        _highController,
                        primaryTextColor,
                        inputFillColor,
                        borderColor,
                        autoMode,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactInput(
                        'Low',
                        _lowController,
                        primaryTextColor,
                        inputFillColor,
                        borderColor,
                        autoMode,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactInput(
                        'Close',
                        _closeController,
                        primaryTextColor,
                        inputFillColor,
                        borderColor,
                        autoMode,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _hasInput ? primaryOrange : borderColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _hasInput ? _resetForm : null,
                          child: Text(
                            'HAPUS',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: _hasInput
                                  ? primaryOrange
                                  : Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasInput
                                ? primaryOrange
                                : (isDarkMode
                                    ? const Color(0xFF2A2A2A)
                                    : const Color(0xFFF4F4F4)),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _hasInput ? _calculatePivot : null,
                          child: Text(
                            'HITUNG',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color:
                                  _hasInput ? Colors.white : Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ======================================================
          // HASIL PIVOT
          // ======================================================
          RepaintBoundary(
            key: _globalKey,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isDarkMode ? 0.25 : 0.035),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: 0.08,
                        child: Image.asset(
                          'assets/images/logoEWF.png',
                          width: 260,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: pivotColor,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Hasil',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: primaryTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Divider(height: 1, thickness: 1, color: dividerColor),

                      // Resistance
                      if (_isR4Expanded) ...[
                        lvl(
                          'R4',
                          vm.r4,
                          resistanceColor,
                          icon: Icons.arrow_circle_up,
                          onTap: () => setState(() => _isR4Expanded = false),
                        ),
                        mid(vm.r4, vm.r3),
                        lvl('R3', vm.r3, resistanceColor),
                        mid(vm.r3, vm.r2),
                        lvl('R2', vm.r2, resistanceColor),
                        mid(vm.r2, vm.r1),
                        lvl('R1', vm.r1, resistanceColor),
                        mid(vm.r1, vm.pp),
                      ] else
                        lvl(
                          'R4',
                          vm.r4,
                          resistanceColor,
                          icon: Icons.arrow_drop_down_circle,
                          onTap: () => setState(() => _isR4Expanded = true),
                        ),

                      // Pivot Point
                      _buildResultRow(
                        label: 'Pivot Point',
                        value: vm.formatValue(vm.pp),
                        labelColor: pivotColor,
                        valueColor: pivotValueColor,
                      ),

                      // Signal Card
                      _buildSignalCard(
                        primaryTextColor: primaryTextColor,
                        borderColor: dividerColor,
                      ),

                      // Support
                      if (_isS4Expanded) ...[
                        mid(vm.pp, vm.s1),
                        lvl('S1', vm.s1, supportColor),
                        mid(vm.s1, vm.s2),
                        lvl('S2', vm.s2, supportColor),
                        mid(vm.s2, vm.s3),
                        lvl('S3', vm.s3, supportColor),
                        mid(vm.s3, vm.s4),
                        lvl(
                          'S4',
                          vm.s4,
                          supportColor,
                          icon: Icons.arrow_circle_up,
                          onTap: () => setState(() => _isS4Expanded = false),
                        ),
                      ] else
                        lvl(
                          'S4',
                          vm.s4,
                          supportColor,
                          icon: Icons.arrow_drop_down_circle,
                          onTap: () => setState(() => _isS4Expanded = true),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ======================================================
          // SARAN SETELAH HASIL
          // ======================================================
          if (vm.isCalculated) ...[
            _buildRecommendationCard(
              signalColor: _signalColorOf(vm.signal),
              cardBgColor: cardBgColor,
              borderColor: dividerColor,
              primaryTextColor: primaryTextColor,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 10),
          ],

          if (vm.errorMessage != null) ...[
            _buildErrorBox(vm.errorMessage!),
            const SizedBox(height: 10),
          ],

          // Export Button
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: vm.isCalculated ? primaryOrange : borderColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed:
                  vm.isCalculated ? () => _showExportModal(context) : null,
              icon: Icon(
                Icons.ios_share_rounded,
                color: vm.isCalculated ? primaryOrange : Colors.grey[400],
                size: 16,
              ),
              label: Text(
                'EXPORT HASIL',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: vm.isCalculated ? primaryOrange : Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ============================================================
  // TOGGLE OTOMATIS / MANUAL
  // ============================================================

  Widget _buildModeToggle({
    required bool isDarkMode,
    required Color primaryTextColor,
    required Color borderColor,
  }) {
    const primaryOrange = Color(0xFFFF9E0F);
    final auto = _viewModel.autoMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: auto
            ? primaryOrange.withValues(alpha: 0.08)
            : (isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF8F8FA)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: auto ? primaryOrange.withValues(alpha: 0.4) : borderColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            auto ? Icons.bolt_rounded : Icons.edit_rounded,
            size: 18,
            color: auto ? primaryOrange : Colors.grey[500],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auto ? 'Mode Otomatis' : 'Mode Manual',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  auto
                      ? 'Data diisi otomatis dari historical'
                      : 'Isi data sendiri sesuai kebutuhan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: auto,
            activeTrackColor: primaryOrange,
            thumbColor: WidgetStateProperty.all(Colors.white),
            onChanged: (value) {
              _viewModel.setAutoMode(value);
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CATATAN FALLBACK (LIBUR / WEEKEND)
  // ============================================================

  Widget _buildNote(String text, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFA800).withValues(alpha: isDarkMode ? 0.12 : 0.1),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFFFFA800).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.event_busy_rounded,
            size: 15,
            color: Color(0xFFFFA800),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                height: 1.4,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // KARTU SARAN / REKOMENDASI
  // ============================================================

  Widget _buildRecommendationCard({
    required Color signalColor,
    required Color cardBgColor,
    required Color borderColor,
    required Color primaryTextColor,
    required bool isDarkMode,
  }) {
    final steps = _viewModel.recommendationSteps;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: signalColor.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.25 : 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: signalColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.tips_and_updates_rounded,
                  size: 18,
                  color: signalColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apa yang sebaiknya dilakukan?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _viewModel.recommendationTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: signalColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: signalColor.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: signalColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        height: 1.5,
                        color: primaryTextColor.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 2),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 14,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _viewModel.recommendationDisclaimer,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    height: 1.45,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
      ),
      child: Text(
        message,
        style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.red),
      ),
    );
  }

  // ==========================================================
  // SIGNAL CARD
  // ==========================================================
  Widget _buildSignalCard({
    required Color primaryTextColor,
    required Color borderColor,
  }) {
    final signal = _viewModel.signal;
    final signalColor = _signalColorOf(signal);

    IconData icon;

    switch (signal) {
      case PivotSignal.buy:
        icon = Icons.trending_up_rounded;
        break;

      case PivotSignal.sell:
        icon = Icons.trending_down_rounded;
        break;

      case PivotSignal.neutral:
        icon = Icons.remove_rounded;
        break;

      case PivotSignal.unavailable:
        icon = Icons.help_outline_rounded;
        break;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: signalColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: signalColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: signalColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: signalColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sinyal',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _viewModel.signalLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: signalColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _viewModel.signalDescription,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    height: 1.3,
                    color: primaryTextColor.withValues(alpha: 0.65),
                  ),
                ),
                if (_viewModel.signalComparison != '-')
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      _viewModel.signalComparison,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                if (_viewModel.referenceData != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Open Newsmaker '
                      '${_viewModel.referenceData!.dateFormatted}: '
                      '${_viewModel.referenceData!.openFormatted}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // INPUT FIELD
  // ==========================================================
  Widget _buildCompactInput(
    String label,
    TextEditingController controller,
    Color textColor,
    Color inputFillColor,
    Color borderColor,
    bool readOnly,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: textColor,
                fontSize: 11,
              ),
            ),
            if (readOnly) ...[
              const SizedBox(width: 4),
              Icon(Icons.lock_rounded, size: 10, color: Colors.grey[500]),
            ],
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: '0,00',
            hintStyle: GoogleFonts.plusJakartaSans(
              color: Colors.grey[400],
              fontSize: 12,
            ),
            filled: true,
            fillColor: inputFillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFFF9E0F),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // RESULT ROW
  // ==========================================================
  Widget _buildResultRow({
    required String label,
    required String value,
    required Color labelColor,
    required Color valueColor,
    bool isMidpoint = false,
    IconData? trailingIcon,
    Color? trailingIconColor,
    VoidCallback? onTrailingIconTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final rowBorderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFEEEEEE);

    final displayValueColor = isMidpoint
        ? (isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF757575))
        : valueColor;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: rowBorderColor, width: 1)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 94,
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMidpoint ? 10 : 12,
                  fontWeight: isMidpoint ? FontWeight.w500 : FontWeight.w700,
                  color: labelColor,
                ),
              ),
            ),
          ),
          Container(width: 1, height: 36, color: rowBorderColor),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight:
                            isMidpoint ? FontWeight.w500 : FontWeight.w600,
                        color: displayValueColor,
                      ),
                    ),
                  ),
                ),
                if (trailingIcon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: onTrailingIconTap,
                      child: Icon(
                        trailingIcon,
                        size: 18,
                        color: trailingIconColor ?? labelColor,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}