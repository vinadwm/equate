import 'dart:io';
import 'dart:ui' as ui;
import 'package:pdf/pdf.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:gal/gal.dart';

import 'package:equate/model/base_calculation_history.dart';
import 'package:equate/viewmodel/historical_data_viewmodel.dart';
import 'package:equate/viewmodel/pivot_hangseng_viewmodel.dart';
import 'package:equate/model/pivot_hangseng_model.dart';

class PivotHangsengCalculatorContent extends StatefulWidget {
  final HistoricalDataViewModel historicalDataViewModel;
  final Function(dynamic)? onCalculate;

  const PivotHangsengCalculatorContent({
    super.key,
    required this.historicalDataViewModel,
    this.onCalculate,
  });

  @override
  State<PivotHangsengCalculatorContent> createState() =>
      _PivotHangsengCalculatorContentState();
}

class _PivotHangsengCalculatorContentState
    extends State<PivotHangsengCalculatorContent> {
  // ==========================================================
  // GLOBAL KEY UNTUK EXPORT GAMBAR
  // ==========================================================
  final GlobalKey _globalKey = GlobalKey();

  // ==========================================================
  // CONTROLLER INPUT
  // ==========================================================
  final TextEditingController _highController = TextEditingController();

  final TextEditingController _lowController = TextEditingController();

  final TextEditingController _closeController = TextEditingController();

  final TextEditingController _openController = TextEditingController();

  // ==========================================================
  // VIEWMODEL
  // ==========================================================
  late final PivotHangsengViewModel _viewModel;

  // Mencegah controller listener dianggap sebagai input manual
  // ketika controller sedang disinkronkan dari ViewModel.
  bool _syncingControllers = false;

  // ==========================================================
  // UI STATE
  // ==========================================================
  bool _hasInput = false;

  bool _isR4Expanded = false;
  bool _isS4Expanded = false;
  bool _isExplanationExpanded = false;

  @override
  void initState() {
    super.initState();

    // ========================================================
    // INIT VIEWMODEL
    // ========================================================
    _viewModel = PivotHangsengViewModel(
      historicalDataViewModel: widget.historicalDataViewModel,
    );

    _viewModel.addListener(_onViewModelChanged);

    // ========================================================
    // SINKRONISASI AWAL
    // ========================================================
    _syncControllers();

    // ========================================================
    // LISTENER INPUT
    // ========================================================
    _highController.addListener(_onHighChanged);
    _lowController.addListener(_onLowChanged);
    _closeController.addListener(_onCloseChanged);
    _openController.addListener(_onOpenChanged);

    _updateInputState();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();

    _highController.removeListener(_onHighChanged);
    _lowController.removeListener(_onLowChanged);
    _closeController.removeListener(_onCloseChanged);
    _openController.removeListener(_onOpenChanged);

    _highController.dispose();
    _lowController.dispose();
    _closeController.dispose();
    _openController.dispose();

    super.dispose();
  }

  // ==========================================================
  // VIEWMODEL LISTENER
  // ==========================================================
  void _onViewModelChanged() {
    if (!mounted) return;

    _syncControllers();
    _updateInputState();

    setState(() {});
  }

  // ==========================================================
  // SYNC CONTROLLER DARI VIEWMODEL
  // ==========================================================
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

    if (_openController.text != _viewModel.open) {
      _openController.value = TextEditingValue(
        text: _viewModel.open,
        selection: TextSelection.collapsed(offset: _viewModel.open.length),
      );
    }

    _syncingControllers = false;
  }

  // ==========================================================
  // INPUT LISTENER
  // ==========================================================
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

  void _onOpenChanged() {
    if (_syncingControllers) return;

    _viewModel.setOpen(_openController.text);
    _updateInputState();
  }

  void _updateInputState() {
    final hasText =
        _highController.text.trim().isNotEmpty ||
        _lowController.text.trim().isNotEmpty ||
        _closeController.text.trim().isNotEmpty ||
        _openController.text.trim().isNotEmpty;

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

    // ========================================================
    // SIMPAN KE HISTORY
    // ========================================================
    if (widget.onCalculate != null) {
      widget.onCalculate!(
        PivotHangsengModel(
          calculationDate: _viewModel.calculationDate,
          title: 'Pivot Point',
          details:
              'H: ${_viewModel.high} | '
              'L: ${_viewModel.low} | '
              'C: ${_viewModel.close} | '
              'O: ${_viewModel.open}',
          result: _viewModel.pp ?? 0,
          createdAt: DateTime.now(),
        ),
      );
    }

    setState(() {});
  }

  // ==========================================================
  // RESET
  // ==========================================================
  void _resetForm() {
    _viewModel.reset();

    _isR4Expanded = false;
    _isS4Expanded = false;

    _syncControllers();
    _updateInputState();

    setState(() {});
  }

  // ==========================================================
  // MUAT ULANG DATA HANGSENG HARI SEBELUMNYA
  // ==========================================================
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

  // ==========================================================
  // SNACKBAR
  // ==========================================================
  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
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

      final boundary =
          _globalKey.currentContext?.findRenderObject()
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

      final filePath =
          '${output.path}/pivot_point_'
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

  // ==========================================================
  // EXPORT PDF
  // ==========================================================
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

  // ==========================================================
  // EXPORT MODAL
  // ==========================================================
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

    final inputFillColor = isDarkMode
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF8F8FA);

    final primaryTextColor = isDarkMode
        ? Colors.white
        : const Color(0xFF161616);

    final borderColor = isDarkMode
        ? Colors.grey[800]!
        : const Color(0xFFE7E7E7);

    final dividerColor = isDarkMode
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFEEEEEE);

    final previousData = _viewModel.previousHangsengData;
    final vm = _viewModel;
    final autoMode = vm.autoMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // ======================================================
          // PENJELASAN PIVOT POINT
          // ======================================================
          _buildExplanationCard(
            isDarkMode: isDarkMode,
            primaryTextColor: primaryTextColor,
          ),

          const SizedBox(height: 12),
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
                  color: Colors.black.withOpacity(isDarkMode ? 0.25 : 0.035),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // ==================================================
                // HEADER DATA OTOMATIS
                // ==================================================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: primaryOrange.withOpacity(0.12),
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
                                ? 'High, Low, Close: ${previousData.dateFormatted} • Open: hari ini'
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

                // ==================================================
                // INFO
                // ==================================================
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
                      Icon(
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

                const SizedBox(height: 10),

                // ==================================================
                // STATUS INPUT
                // ==================================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _viewModel.isAutoFilled
                            ? primaryOrange.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ==================================================
                // HIGH / LOW / CLOSE
                // ==================================================
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

                const SizedBox(height: 10),

                // ==================================================
                // OPEN
                // ==================================================
                _buildOpenInput(
                  textColor: primaryTextColor,
                  inputFillColor: inputFillColor,
                  borderColor: borderColor,
                  readOnly: autoMode,
                ),

                const SizedBox(height: 12),

                // ==================================================
                // BUTTON
                // ==================================================
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
                              color: _hasInput
                                  ? Colors.white
                                  : Colors.grey[400],
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
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDarkMode ? 0.25 : 0.035,
                    ),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ====================================================
                      // HEADER HASIL
                      // ====================================================
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF18B85A),
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
                      ),

                      const SizedBox(height: 8),

                      // ====================================================
                      // SIGNAL BADGE
                      // ====================================================
                      _buildSignalBadge(),

                      const SizedBox(height: 10),

                      // ====================================================
                      // KARTU LEVEL PIVOT
                      // ====================================================
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDarkMode ? 0.28 : 0.08,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ==================================================
                            // RESISTANCE
                            // ==================================================

                            if (_isR4Expanded) ...[
                              _buildCompactResultRow(
                                label: 'R4',
                                value: vm.formatValue(vm.r4),
                                labelColor: resistanceColor,
                                valueColor: primaryTextColor,
                                trailingIcon: Icons.keyboard_arrow_down_rounded,
                                trailingIconColor: resistanceColor,
                                onTrailingIconTap: () {
                                  setState(() {
                                    _isR4Expanded = false;
                                  });
                                },
                              ),

                              // R4 → R3
                              if (vm.r4 != null && vm.r3 != null)
                                _buildCompactMidpointRow(
                                  value: vm.formatValue(
                                    vm.midpoint(vm.r4!, vm.r3!),
                                  ),
                                ),

                              _buildCompactResultRow(
                                label: 'R3',
                                value: vm.formatValue(vm.r3),
                                labelColor: resistanceColor,
                                valueColor: primaryTextColor,
                              ),

                              // R3 → R2
                              if (vm.r3 != null && vm.r2 != null)
                                _buildCompactMidpointRow(
                                  value: vm.formatValue(
                                    vm.midpoint(vm.r3!, vm.r2!),
                                  ),
                                ),

                              _buildCompactResultRow(
                                label: 'R2',
                                value: vm.formatValue(vm.r2),
                                labelColor: resistanceColor,
                                valueColor: primaryTextColor,
                              ),

                              // R2 → R1
                              if (vm.r2 != null && vm.r1 != null)
                                _buildCompactMidpointRow(
                                  value: vm.formatValue(
                                    vm.midpoint(vm.r2!, vm.r1!),
                                  ),
                                ),

                              _buildCompactResultRow(
                                label: 'R1',
                                value: vm.formatValue(vm.r1),
                                labelColor: resistanceColor,
                                valueColor: primaryTextColor,
                              ),

                              // R1 → PP
                              if (vm.r1 != null && vm.pp != null)
                                _buildCompactMidpointRow(
                                  value: vm.formatValue(
                                    vm.midpoint(vm.r1!, vm.pp!),
                                  ),
                                ),
                            ] else ...[
                              _buildCompactResultRow(
                                label: 'R4',
                                value: vm.formatValue(vm.r4),
                                labelColor: resistanceColor,
                                valueColor: primaryTextColor,
                                trailingIcon: Icons.keyboard_arrow_down_rounded,
                                trailingIconColor: resistanceColor,
                                onTrailingIconTap: () {
                                  setState(() {
                                    _isR4Expanded = true;
                                  });
                                },
                              ),
                            ],

                            // ==================================================
                            // PIVOT POINT
                            // ==================================================
                            _buildPivotCenterRow(
                              value: vm.formatValue(vm.pp),
                              primaryTextColor: primaryTextColor,
                              pivotColor: pivotColor,
                            ),

                            // ==================================================
                            // SUPPORT
                            // ==================================================
                            if (_isS4Expanded) ...[
                              // PP → S1
                              if (vm.pp != null && vm.s1 != null)
                                _buildCompactMidpointRow(
                                  value: vm.formatValue(
                                    vm.midpoint(vm.pp!, vm.s1!),
                                  ),
                                ),

                              _buildCompactResultRow(
                                label: 'S1',
                                value: vm.formatValue(vm.s1),
                                labelColor: supportColor,
                                valueColor: primaryTextColor,
                              ),

                              // S1 → S2
                              if (vm.s1 != null && vm.s2 != null)
                                _buildCompactMidpointRow(
                                  value: vm.formatValue(
                                    vm.midpoint(vm.s1!, vm.s2!),
                                  ),
                                ),

                              _buildCompactResultRow(
                                label: 'S2',
                                value: vm.formatValue(vm.s2),
                                labelColor: supportColor,
                                valueColor: primaryTextColor,
                              ),

                              // S2 → S3
                              if (vm.s2 != null && vm.s3 != null)
                                _buildCompactMidpointRow(
                                  value: vm.formatValue(
                                    vm.midpoint(vm.s2!, vm.s3!),
                                  ),
                                ),

                              _buildCompactResultRow(
                                label: 'S3',
                                value: vm.formatValue(vm.s3),
                                labelColor: supportColor,
                                valueColor: primaryTextColor,
                              ),

                              // S3 → S4
                              if (vm.s3 != null && vm.s4 != null)
                                _buildCompactMidpointRow(
                                  value: vm.formatValue(
                                    vm.midpoint(vm.s3!, vm.s4!),
                                  ),
                                ),

                              _buildCompactResultRow(
                                label: 'S4',
                                value: vm.formatValue(vm.s4),
                                labelColor: supportColor,
                                valueColor: primaryTextColor,
                                trailingIcon: Icons.keyboard_arrow_up_rounded,
                                trailingIconColor: supportColor,
                                onTrailingIconTap: () {
                                  setState(() {
                                    _isS4Expanded = false;
                                  });
                                },
                              ),
                            ] else ...[
                              _buildCompactResultRow(
                                label: 'S4',
                                value: vm.formatValue(vm.s4),
                                labelColor: supportColor,
                                valueColor: primaryTextColor,
                                trailingIcon: Icons.keyboard_arrow_up_rounded,
                                trailingIconColor: supportColor,
                                onTrailingIconTap: () {
                                  setState(() {
                                    _isS4Expanded = true;
                                  });
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ======================================================
          // EXPORT
          // ======================================================
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _viewModel.isCalculated ? primaryOrange : borderColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _viewModel.isCalculated
                  ? () => _showExportModal(context)
                  : null,
              icon: Icon(
                Icons.ios_share_rounded,
                color: _viewModel.isCalculated
                    ? primaryOrange
                    : Colors.grey[400],
                size: 16,
              ),
              label: Text(
                'EXPORT HASIL',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: _viewModel.isCalculated
                      ? primaryOrange
                      : Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
  // KARTU PENJELASAN PIVOT POINT - EXPANDABLE
  // ============================================================
  Widget _buildExplanationCard({
    required bool isDarkMode,
    required Color primaryTextColor,
  }) {
    const primaryOrange = Color(0xFFFF9E0F);
    const buyColor = Color(0xFF18B85A);
    const sellColor = Color(0xFFFF3B30);

    final subText = isDarkMode ? Colors.grey[300] : Colors.grey[700];

    Widget term(String title, String desc, IconData icon) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: primaryOrange),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5,
                  height: 1.4,
                  color: subText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget rule({
      required IconData icon,
      required Color color,
      required String label,
      required String condition,
      required String example,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDarkMode ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          condition,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    example,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      height: 1.35,
                      color: subText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? const [Color(0xFF2E2718), Color(0xFF1E1E1E)]
              : const [Color(0xFFFFF1D0), Color(0xFFFFFBF3)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryOrange.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // HEADER - BISA DIKLIK
          // ======================================================
          GestureDetector(
            onTap: () {
              setState(() {
                _isExplanationExpanded = !_isExplanationExpanded;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: primaryOrange.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.lightbulb_rounded,
                    size: 20,
                    color: primaryOrange,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apa itu Pivot Point?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Konsep Harga Pasar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: primaryOrange,
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // PANAH EXPAND / COLLAPSE
                // ==================================================
                AnimatedRotation(
                  turns: _isExplanationExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 25,
                    color: primaryOrange,
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // DESKRIPSI UTAMA - SELALU TAMPIL
          // ======================================================
          const SizedBox(height: 12),

          Text(
            'Pivot Point adalah harga wajar atau harga pasaran, '
            'untuk menentukan aksi beli dan jual yang mengacu '
            'pada harga pembukaan (Open).',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              height: 1.55,
              color: subText,
            ),
          ),

          // ======================================================
          // DETAIL - HANYA MUNCUL SAAT EXPAND
          // ======================================================
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _isExplanationExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),

            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),

                // ------------------------------------------------
                // OPEN / HIGH / LOW / CLOSE
                // ------------------------------------------------
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    term(
                      'Open',
                      'Harga pertama saat pasar dibuka hari ini.',
                      Icons.wb_sunny_rounded,
                    ),
                    const SizedBox(width: 8),
                    term(
                      'High',
                      'Harga tertinggi pada hari sebelumnya.',
                      Icons.arrow_upward_rounded,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    term(
                      'Low',
                      'Harga terendah pada hari sebelumnya.',
                      Icons.arrow_downward_rounded,
                    ),
                    const SizedBox(width: 8),
                    term(
                      'Close',
                      'Harga terakhir pada hari sebelumnya.',
                      Icons.nightlight_round,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ------------------------------------------------
                // CARA MEMBACA SINYAL
                // ------------------------------------------------
                Text(
                  'Cara membaca sinyal',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: primaryTextColor,
                  ),
                ),

                const SizedBox(height: 8),

                rule(
                  icon: Icons.trending_up_rounded,
                  color: buyColor,
                  label: 'BUY',
                  condition: 'Pivot Point lebih rendah dari Open',
                  example: 'Contoh: Pivot Point 4.450 dan Open 4.500 → BUY.',
                ),

                rule(
                  icon: Icons.trending_down_rounded,
                  color: sellColor,
                  label: 'SELL',
                  condition: 'Pivot Point lebih tinggi dari Open',
                  example: 'Contoh: Pivot Point 4.550 dan Open 4.500 → SELL.',
                ),

                rule(
                  icon: Icons.remove_rounded,
                  color: primaryOrange,
                  label: 'BUY/SELL',
                  condition: 'Pivot Point sama dengan Open',
                  example: 'Arah belum jelas, sebaiknya tunggu konfirmasi.',
                ),

                // ------------------------------------------------
                // TIPS
                // ------------------------------------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.tips_and_updates_rounded,
                        size: 15,
                        color: primaryOrange,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Tips: saat weekend atau libur Newsmaker '
                          'tidak ada data baru, aplikasi otomatis '
                          'memakai data terakhir yang tersedia.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            height: 1.45,
                            color: subText,
                          ),
                        ),
                      ),
                    ],
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
  // SIGNAL CARD
  // ==========================================================
  Widget _buildSignalBadge() {
    final signal = _viewModel.signal;
    final signalColor = _signalColorOf(signal);

    String label;

    switch (signal) {
      case PivotSignal.buy:
        label = 'BUY';
        break;

      case PivotSignal.sell:
        label = 'SELL';
        break;

      case PivotSignal.neutral:
        label = 'BUY / SELL';
        break;

      case PivotSignal.unavailable:
        label = 'BELUM TERSEDIA';
        break;
    }

    return Center(
      child: Container(
        width: 185,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: signalColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: signalColor.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: signalColor,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // COMPACT RESULT ROW
  // ==========================================================

  Widget _buildCompactResultRow({
    required String label,
    required String value,
    required Color labelColor,
    required Color valueColor,
    IconData? trailingIcon,
    Color? trailingIconColor,
    VoidCallback? onTrailingIconTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.07)
        : const Color(0xFFEEEEEE);

    return SizedBox(
      height: 34,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor, width: 1)),
        ),
        child: Row(
          children: [
            // ==========================================
            // KOLOM LABEL
            // ==========================================
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                  ),
                ),
              ),
            ),

            // ==========================================
            // GARIS PEMISAH
            // ==========================================
            Container(width: 1, height: double.infinity, color: borderColor),

            // ==========================================
            // KOLOM VALUE
            // ==========================================
            Expanded(
              flex: 3,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ANGKA SELALU DI TENGAH KOLOM
                  Center(
                    child: Text(
                      value,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: valueColor,
                      ),
                    ),
                  ),

                  // ICON SELALU DI UJUNG KANAN
                  if (trailingIcon != null)
                    Positioned(
                      right: 7,
                      child: GestureDetector(
                        onTap: onTrailingIconTap,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: trailingIconColor?.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            trailingIcon,
                            size: 12,
                            color: trailingIconColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // PIVOT POINT CENTER ROW
  // ==========================================================

  Widget _buildPivotCenterRow({
    required String value,
    required Color primaryTextColor,
    required Color pivotColor,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE8E8E8);

    return Container(
      height: 69,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'PIVOT POINT',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: pivotColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryTextColor,
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
  // OPEN INPUT - OTOMATIS + BISA DIEDIT
  // ==========================================================
  Widget _buildOpenInput({
    required Color textColor,
    required Color inputFillColor,
    required Color borderColor,
    required bool readOnly,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Open',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),

            // ICON LOCK SAAT MODE OTOMATIS
            if (readOnly) ...[
              const SizedBox(width: 4),
              Icon(Icons.lock_rounded, size: 10, color: Colors.grey[500]),
            ],
          ],
        ),

        const SizedBox(height: 4),

        TextField(
          controller: _openController,

          // Otomatis = terkunci
          // Manual = bisa diedit
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
  // COMPACT MIDPOINT ROW
  // ==========================================================

  Widget _buildCompactMidpointRow({required String value}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.07)
        : const Color(0xFFEEEEEE);

    final midpointColor = isDarkMode
        ? const Color(0xFF8E8E93)
        : const Color(0xFF9E9E9E);

    return SizedBox(
      height: 27,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor, width: 1)),
        ),
        child: Row(
          children: [
            // ==========================================
            // KOLOM LABEL MIDPOINT
            // ==========================================
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  'Midpoint',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: midpointColor,
                  ),
                ),
              ),
            ),

            // ==========================================
            // GARIS PEMISAH
            // ==========================================
            Container(width: 1, height: double.infinity, color: borderColor),

            // ==========================================
            // KOLOM VALUE MIDPOINT
            // ==========================================
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: midpointColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
        ? Colors.white.withOpacity(0.08)
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
                        fontWeight: isMidpoint
                            ? FontWeight.w500
                            : FontWeight.w600,
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

  Widget _buildPivotPointRow({
    required String value,
    required Color textColor,
    required Color valueColor,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Column(
        children: [
          Text(
            'PIVOT POINT',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
