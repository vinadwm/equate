import 'dart:io';
import 'dart:ui' as ui;
import 'package:pdf/pdf.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:gal/gal.dart';

import '../calculator_tab_view.dart';
import 'package:equate/viewmodel/historical_data_viewmodel.dart';
import 'package:equate/viewmodel/pivot_hangseng_viewmodel.dart';
import 'package:equate/model/pivot_hangseng_model.dart';

class PivotHangsengCalculatorContent extends StatefulWidget {
  final HistoricalDataViewModel historicalDataViewModel;
  final Function(CalculationHistory)? onCalculate;

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
        CalculationHistory(
          title: 'Pivot Point',
          details:
              'H: ${_viewModel.high} | '
              'L: ${_viewModel.low} | '
              'C: ${_viewModel.close} | '
              'O: ${_viewModel.open}',
          result: _viewModel.pp ?? 0,
          timestamp: DateTime.now(),
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
    final success = _viewModel.fillFromPreviousDay();

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
    final referenceData = _viewModel.referenceData;

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
                                ? 'Hangseng pada tanggal ${previousData.dateFormatted}'
                                : 'Menunggu data Hangseng...',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ==================================================
                    // REFRESH
                    // ==================================================
                    IconButton(
                      tooltip: 'Muat data Hangseng hari sebelumnya',
                      visualDensity: VisualDensity.compact,
                      onPressed: _reloadPreviousDay,
                      icon: Icon(
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
                          'High, Low, dan Close otomatis '
                          'diambil dari data Hangseng pada hari perdagangan terakhir. '
                          'Open otomoatis diambil dari data Hangseng pada hari ini. '
                          'Input tetap dapat diedit secara manual.',
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
                    Text(
                      'Sumber Input',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                      ),
                    ),

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
                      child: Text(
                        _viewModel.isAutoFilled ? 'Otomatis' : 'Manual',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _viewModel.isAutoFilled
                              ? primaryOrange
                              : Colors.grey[600],
                        ),
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
              padding: const EdgeInsets.all(16),
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
              child: Stack(
                children: [
                  // ==================================================
                  // LOGO WATERMARK
                  // ==================================================
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
                      // =================================================
                      // HEADER
                      // =================================================
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

                      // =================================================
                      // R4 - R1
                      // =================================================
                      if (_isR4Expanded) ...[
                        _buildResultRow(
                          label: 'R4',
                          value: _viewModel.formatValue(_viewModel.r4),
                          labelColor: resistanceColor,
                          valueColor: primaryTextColor,
                          trailingIcon: Icons.arrow_circle_up,
                          trailingIconColor: resistanceColor,
                          onTrailingIconTap: () {
                            setState(() {
                              _isR4Expanded = false;
                            });
                          },
                        ),

                        if (_viewModel.r4 != null && _viewModel.r3 != null)
                          _buildResultRow(
                            label: 'Midpoint',
                            value: _viewModel.formatValue(
                              _viewModel.midpoint(
                                _viewModel.r4!,
                                _viewModel.r3!,
                              ),
                            ),
                            labelColor: midpointColor,
                            valueColor: primaryTextColor,
                            isMidpoint: true,
                          ),

                        _buildResultRow(
                          label: 'R3',
                          value: _viewModel.formatValue(_viewModel.r3),
                          labelColor: resistanceColor,
                          valueColor: primaryTextColor,
                        ),

                        if (_viewModel.r3 != null && _viewModel.r2 != null)
                          _buildResultRow(
                            label: 'Midpoint',
                            value: _viewModel.formatValue(
                              _viewModel.midpoint(
                                _viewModel.r3!,
                                _viewModel.r2!,
                              ),
                            ),
                            labelColor: midpointColor,
                            valueColor: primaryTextColor,
                            isMidpoint: true,
                          ),

                        _buildResultRow(
                          label: 'R2',
                          value: _viewModel.formatValue(_viewModel.r2),
                          labelColor: resistanceColor,
                          valueColor: primaryTextColor,
                        ),

                        if (_viewModel.r2 != null && _viewModel.r1 != null)
                          _buildResultRow(
                            label: 'Midpoint',
                            value: _viewModel.formatValue(
                              _viewModel.midpoint(
                                _viewModel.r2!,
                                _viewModel.r1!,
                              ),
                            ),
                            labelColor: midpointColor,
                            valueColor: primaryTextColor,
                            isMidpoint: true,
                          ),

                        _buildResultRow(
                          label: 'R1',
                          value: _viewModel.formatValue(_viewModel.r1),
                          labelColor: resistanceColor,
                          valueColor: primaryTextColor,
                        ),

                        if (_viewModel.r1 != null && _viewModel.pp != null)
                          _buildResultRow(
                            label: 'Midpoint',
                            value: _viewModel.formatValue(
                              _viewModel.midpoint(
                                _viewModel.r1!,
                                _viewModel.pp!,
                              ),
                            ),
                            labelColor: midpointColor,
                            valueColor: primaryTextColor,
                            isMidpoint: true,
                          ),
                      ] else
                        _buildResultRow(
                          label: 'R4',
                          value: _viewModel.formatValue(_viewModel.r4),
                          labelColor: resistanceColor,
                          valueColor: primaryTextColor,
                          trailingIcon: Icons.arrow_drop_down_circle,
                          trailingIconColor: resistanceColor,
                          onTrailingIconTap: () {
                            setState(() {
                              _isR4Expanded = true;
                            });
                          },
                        ),

                      // =================================================
                      // PIVOT POINT
                      // =================================================
                      _buildPivotPointRow(
                        value: _viewModel.formatValue(_viewModel.pp),
                        textColor: primaryTextColor,
                        valueColor: pivotValueColor,
                        borderColor: dividerColor,
                      ),

                      // =================================================
                      // SIGNAL BUY / SELL
                      // =================================================
                      _buildSignalCard(
                        primaryTextColor: primaryTextColor,
                        borderColor: dividerColor,
                      ),

                      // =================================================
                      // S1 - S4
                      // =================================================
                      if (_isS4Expanded) ...[
                        if (_viewModel.pp != null && _viewModel.s1 != null)
                          _buildResultRow(
                            label: 'Midpoint',
                            value: _viewModel.formatValue(
                              _viewModel.midpoint(
                                _viewModel.pp!,
                                _viewModel.s1!,
                              ),
                            ),
                            labelColor: midpointColor,
                            valueColor: primaryTextColor,
                            isMidpoint: true,
                          ),

                        _buildResultRow(
                          label: 'S1',
                          value: _viewModel.formatValue(_viewModel.s1),
                          labelColor: supportColor,
                          valueColor: primaryTextColor,
                        ),

                        if (_viewModel.s1 != null && _viewModel.s2 != null)
                          _buildResultRow(
                            label: 'Midpoint',
                            value: _viewModel.formatValue(
                              _viewModel.midpoint(
                                _viewModel.s1!,
                                _viewModel.s2!,
                              ),
                            ),
                            labelColor: midpointColor,
                            valueColor: primaryTextColor,
                            isMidpoint: true,
                          ),

                        _buildResultRow(
                          label: 'S2',
                          value: _viewModel.formatValue(_viewModel.s2),
                          labelColor: supportColor,
                          valueColor: primaryTextColor,
                        ),

                        if (_viewModel.s2 != null && _viewModel.s3 != null)
                          _buildResultRow(
                            label: 'Midpoint',
                            value: _viewModel.formatValue(
                              _viewModel.midpoint(
                                _viewModel.s2!,
                                _viewModel.s3!,
                              ),
                            ),
                            labelColor: midpointColor,
                            valueColor: primaryTextColor,
                            isMidpoint: true,
                          ),

                        _buildResultRow(
                          label: 'S3',
                          value: _viewModel.formatValue(_viewModel.s3),
                          labelColor: supportColor,
                          valueColor: primaryTextColor,
                        ),

                        if (_viewModel.s3 != null && _viewModel.s4 != null)
                          _buildResultRow(
                            label: 'Midpoint',
                            value: _viewModel.formatValue(
                              _viewModel.midpoint(
                                _viewModel.s3!,
                                _viewModel.s4!,
                              ),
                            ),
                            labelColor: midpointColor,
                            valueColor: primaryTextColor,
                            isMidpoint: true,
                          ),

                        _buildResultRow(
                          label: 'S4',
                          value: _viewModel.formatValue(_viewModel.s4),
                          labelColor: supportColor,
                          valueColor: primaryTextColor,
                          trailingIcon: Icons.arrow_circle_up,
                          trailingIconColor: supportColor,
                          onTrailingIconTap: () {
                            setState(() {
                              _isS4Expanded = false;
                            });
                          },
                        ),
                      ] else
                        _buildResultRow(
                          label: 'S4',
                          value: _viewModel.formatValue(_viewModel.s4),
                          labelColor: supportColor,
                          valueColor: primaryTextColor,
                          trailingIcon: Icons.arrow_drop_down_circle,
                          trailingIconColor: supportColor,
                          onTrailingIconTap: () {
                            setState(() {
                              _isS4Expanded = true;
                            });
                          },
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

  // ==========================================================
  // SIGNAL CARD
  // ==========================================================
  Widget _buildSignalCard({
    required Color primaryTextColor,
    required Color borderColor,
  }) {
    final signal = _viewModel.signal;

    Color signalColor;
    String label;

    switch (signal) {
      case PivotSignal.buy:
        signalColor = const Color(0xFF18B85A);
        label = 'BUY';
        break;

      case PivotSignal.sell:
        signalColor = const Color(0xFFFF3B30);
        label = 'SELL';
        break;

      case PivotSignal.neutral:
        signalColor = const Color(0xFFFFA800);
        label = 'BUY/SELL';
        break;

      case PivotSignal.unavailable:
        signalColor = Colors.grey;
        label = 'BELUM TERSEDIA';
        break;
    }

    return Center(
      child: Container(
        width: 206,
        height: 37,
        margin: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: signalColor.withOpacity(0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: signalColor.withOpacity(0.45)),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: signalColor,
          ),
        ),
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
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: textColor,
            fontSize: 11,
          ),
        ),

        const SizedBox(height: 4),

        TextField(
          controller: controller,

          // ====================================================
          // TETAP BISA DIEDIT
          // ====================================================
          readOnly: false,

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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Open',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),

        const SizedBox(height: 4),

        TextField(
          controller: _openController,

          // Open otomatis terisi dari Newsmaker,
          // tetapi user tetap bisa mengedit.
          readOnly: false,

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

            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Color(0xFFFF9E0F), width: 1.5),
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
