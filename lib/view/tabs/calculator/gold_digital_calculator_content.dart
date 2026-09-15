import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:gal/gal.dart';

import 'package:equate/viewmodel/theme_viewmodel.dart';
import 'package:equate/viewmodel/gold_digital_viewmodel.dart';

class GoldDigitalCalculatorContent extends StatefulWidget {
  const GoldDigitalCalculatorContent({super.key});

  @override
  State<GoldDigitalCalculatorContent> createState() =>
      _GoldDigitalCalculatorContentState();
}

class _GoldDigitalCalculatorContentState
    extends State<GoldDigitalCalculatorContent> {
  // ============================================================
  // VIEWMODEL
  // ============================================================

  late final GoldDigitalViewModel _viewModel;

  // ============================================================
  // REPAINT BOUNDARY
  // Digunakan untuk export hasil sebagai gambar.
  // ============================================================

  final GlobalKey _globalKey = GlobalKey();

  // ============================================================
  // CONTROLLER
  // ============================================================

  final TextEditingController _lotController = TextEditingController(text: '0');

  final TextEditingController _hargaOpenController = TextEditingController(
    text: '0,00',
  );

  final TextEditingController _hargaCloseController = TextEditingController(
    text: '0,00',
  );

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _viewModel = GoldDigitalViewModel();

    _viewModel.addListener(_onViewModelChanged);

    _lotController.addListener(_onLotChanged);
    _hargaOpenController.addListener(_onHargaOpenChanged);
    _hargaCloseController.addListener(_onHargaCloseChanged);
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);

    _lotController.removeListener(_onLotChanged);
    _hargaOpenController.removeListener(_onHargaOpenChanged);
    _hargaCloseController.removeListener(_onHargaCloseChanged);

    _lotController.dispose();
    _hargaOpenController.dispose();
    _hargaCloseController.dispose();

    _viewModel.dispose();

    super.dispose();
  }

  // ============================================================
  // VIEW <-> VIEWMODEL
  // ============================================================

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onLotChanged() {
    _viewModel.setDigitalLot(_lotController.text);
  }

  void _onHargaOpenChanged() {
    _viewModel.setDigitalHargaOpen(_hargaOpenController.text);
  }

  void _onHargaCloseChanged() {
    _viewModel.setDigitalHargaClose(_hargaCloseController.text);
  }

  // ============================================================
  // RESET
  // ============================================================

  void _resetForm() {
    _viewModel.resetGoldDigital();

    _setControllerValue(_lotController, '0');

    _setControllerValue(_hargaOpenController, '0,00');

    _setControllerValue(_hargaCloseController, '0,00');
  }

  void _setControllerValue(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }

    VoidCallback listener;

    if (controller == _lotController) {
      listener = _onLotChanged;
    } else if (controller == _hargaOpenController) {
      listener = _onHargaOpenChanged;
    } else {
      listener = _onHargaCloseChanged;
    }

    controller.removeListener(listener);

    controller.text = value;

    controller.addListener(listener);
  }

  // ============================================================
  // CALCULATE
  // ============================================================

  Future<void> _calculateGoldDigital() async {
    await _viewModel.calculateGoldDigital();
  }

  // ============================================================
  // EXPORT - IMAGE
  // ============================================================

  Future<void> _exportAsImage() async {
    try {
      final hasAccess = await Gal.hasAccess();

      if (!hasAccess) {
        await Gal.requestAccess();
      }

      final boundary =
          _globalKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengambil hasil kalkulasi.')),
        );

        return;
      }

      // ==========================================================
      // CAPTURE WIDGET
      // ==========================================================

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Gagal mengubah hasil menjadi gambar.');
      }

      final pngBytes = byteData.buffer.asUint8List();

      // ==========================================================
      // SIMPAN FILE SEMENTARA
      // ==========================================================

      final output = await getTemporaryDirectory();

      final filePath =
          '${output.path}/gold_digital_${DateTime.now().millisecondsSinceEpoch}.png';

      final file = File(filePath);

      await file.writeAsBytes(pngBytes);

      // ==========================================================
      // SIMPAN KE GALERI
      // ==========================================================

      await Gal.putImage(filePath);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gambar berhasil disimpan ke Galeri!'),
          backgroundColor: Color(0xFF18B85A),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // EXPORT - PDF
  // ============================================================

  Future<void> _exportAsPdf() async {
    try {
      final pdfBytes = await _viewModel.buildDigitalGoldPdf();

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          return pdfBytes;
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // EXPORT MODAL
  // ============================================================

  void _showExportModal(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.image_rounded,
                color: Color(0xFFFF9E0F),
              ),
              title: const Text('Export sebagai Gambar (PNG)'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
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
                Navigator.pop(bottomSheetContext);
                _exportAsPdf();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFFFA800);

    final isDarkMode = ThemeViewModel.isDarkMode;

    final cardBgColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    final primaryTextColor = isDarkMode ? Colors.white : Colors.black87;

    final labelTextColor = isDarkMode
        ? const Color(0xFFD0D0D0)
        : Colors.grey[700]!;

    final inputFillColor = isDarkMode
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF8F8FA);

    final borderColor = isDarkMode
        ? Colors.grey[800]!
        : const Color(0xFFEEEEEE);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // FORM CARD
          // ======================================================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.02),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // TITLE
                // ==================================================
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        color: primaryOrange,
                        size: 18,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Text(
                      'Masukkan Data',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: primaryTextColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                // ==================================================
                // JUMLAH LOT
                // ==================================================
                _buildLabel('Jumlah Lot', labelTextColor),

                const SizedBox(height: 8),

                _buildTextField(
                  controller: _lotController,
                  hintText: '0',
                  textColor: primaryTextColor,
                  inputFillColor: inputFillColor,
                  borderColor: borderColor,
                  isDarkMode: isDarkMode,
                  decimal: true,
                ),

                const SizedBox(height: 22),

                // ==================================================
                // OPEN POSITION
                // ==================================================
                _buildLabel('Open Position', labelTextColor),

                const SizedBox(height: 8),

                _buildPositionSelector(
                  selected: _viewModel.digitalOpenPosition,
                  enabled: _viewModel.digitalPositionButtonsEnabled,
                  onSelected: _viewModel.selectDigitalOpenPosition,
                  primaryOrange: primaryOrange,
                  isDarkMode: isDarkMode,
                ),

                const SizedBox(height: 8),

                _buildTextField(
                  controller: _hargaOpenController,
                  hintText: '0,00',
                  textColor: primaryTextColor,
                  inputFillColor: inputFillColor,
                  borderColor: borderColor,
                  isDarkMode: isDarkMode,
                  decimal: true,
                ),

                const SizedBox(height: 22),

                // ==================================================
                // CLOSE POSITION
                // ==================================================
                _buildLabel('Close Position', labelTextColor),

                const SizedBox(height: 8),

                _buildTextField(
                  controller: _hargaCloseController,
                  hintText: '0,00',
                  textColor: primaryTextColor,
                  inputFillColor: inputFillColor,
                  borderColor: borderColor,
                  isDarkMode: isDarkMode,
                  decimal: true,
                ),

                const SizedBox(height: 24),

                // ==================================================
                // BUTTONS
                // ==================================================
                Row(
                  children: [
                    // ==============================================
                    // HAPUS
                    // ==============================================
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _viewModel.digitalHasInput
                                  ? primaryOrange
                                  : borderColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.transparent,
                          ),
                          onPressed: _viewModel.digitalHasInput
                              ? _resetForm
                              : null,
                          child: Text(
                            'HAPUS',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _viewModel.digitalHasInput
                                  ? primaryOrange
                                  : Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // ==============================================
                    // HITUNG
                    // ==============================================
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _viewModel.digitalCanCalculate
                                ? primaryOrange
                                : (isDarkMode
                                      ? const Color(0xFF2A2A2A)
                                      : const Color(0xFFF1F1F5)),
                            foregroundColor: _viewModel.digitalCanCalculate
                                ? Colors.white
                                : Colors.grey[400],
                            elevation: _viewModel.digitalCanCalculate ? 2 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _viewModel.digitalCanCalculate
                              ? _calculateGoldDigital
                              : null,
                          child: Text(
                            'HITUNG',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _viewModel.digitalCanCalculate
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

          const SizedBox(height: 20),

          // ======================================================
          // RESULT CARD
          // ======================================================
          RepaintBoundary(
            key: _globalKey,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _viewModel.digitalIsCalculated
                      ? (_viewModel.digitalHasilNetto! >= 0
                            ? const Color(0xFF22C55E).withOpacity(0.45)
                            : const Color(0xFFFF3B30).withOpacity(0.45))
                      : borderColor,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.02),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ==================================================
                  // HASIL TITLE
                  // ==================================================
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF22C55E),
                        size: 20,
                      ),

                      const SizedBox(width: 8),

                      Text(
                        'Hasil',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // DIVIDER
                  // ==================================================
                  Divider(height: 1, color: borderColor),

                  const SizedBox(height: 20),

                  // ==================================================
                  // HASIL NOMINAL
                  // ==================================================
                  SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        !_viewModel.digitalIsCalculated ||
                                _viewModel.digitalHasilNetto == null
                            ? 'Rp 0'
                            : '${_viewModel.digitalHasilNetto! < 0 ? '-Rp ' : 'Rp '}${_viewModel.formatDigitalCurrency(_viewModel.digitalHasilNetto!)}',
                        maxLines: 1,
                        softWrap: false,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: primaryTextColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),

                  // ==================================================
                  // UNTUNG / RUGI
                  // ==================================================
                  if (_viewModel.digitalIsCalculated &&
                      _viewModel.digitalHasilNetto != null) ...[
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (_viewModel.digitalHasilNetto! >= 0
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFFFF3B30))
                                .withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              (_viewModel.digitalHasilNetto! >= 0
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFFFF3B30))
                                  .withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _viewModel.digitalHasilNetto! < 0
                                ? Icons.trending_down_rounded
                                : Icons.trending_up_rounded,
                            color: _viewModel.digitalHasilNetto! < 0
                                ? const Color(0xFFFF3B30)
                                : const Color(0xFF22C55E),
                            size: 17,
                          ),

                          const SizedBox(width: 6),

                          Text(
                            _viewModel.digitalHasilNetto! < 0
                                ? 'Rugi'
                                : 'Untung',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _viewModel.digitalHasilNetto! < 0
                                  ? const Color(0xFFFF3B30)
                                  : const Color(0xFF22C55E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ======================================================
          // EXPORT BUTTON
          // ======================================================
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _viewModel.digitalIsCalculated
                      ? primaryOrange
                      : borderColor,
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _viewModel.digitalIsCalculated
                  ? () => _showExportModal(context)
                  : null,
              icon: Icon(
                Icons.ios_share_rounded,
                size: 17,
                color: _viewModel.digitalIsCalculated
                    ? primaryOrange
                    : Colors.grey[400],
              ),
              label: Text(
                'EXPORT HASIL',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.5,
                  color: _viewModel.digitalIsCalculated
                      ? primaryOrange
                      : Colors.grey[400],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // POSITION SELECTOR
  // ============================================================

  Widget _buildPositionSelector({
    required PositionType? selected,
    required bool enabled,
    required ValueChanged<PositionType> onSelected,
    required Color primaryOrange,
    required bool isDarkMode,
  }) {
    final backgroundColor = isDarkMode
        ? const Color(0xFF252525)
        : const Color(0xFFF8F8FA);

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : const Color(0xFFE5E5E7),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPositionButton(
              label: 'Buy',
              selected: selected == PositionType.buy,
              enabled: enabled,
              onTap: () => onSelected(PositionType.buy),
              primaryOrange: primaryOrange,
              isDarkMode: isDarkMode,
            ),
          ),

          const SizedBox(width: 4),

          Expanded(
            child: _buildPositionButton(
              label: 'Sell',
              selected: selected == PositionType.sell,
              enabled: enabled,
              onTap: () => onSelected(PositionType.sell),
              primaryOrange: primaryOrange,
              isDarkMode: isDarkMode,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // POSITION BUTTON
  // ============================================================

  Widget _buildPositionButton({
    required String label,
    required bool selected,
    required bool enabled,
    required VoidCallback onTap,
    required Color primaryOrange,
    required bool isDarkMode,
  }) {
    final disabledText = isDarkMode ? Colors.grey[600]! : Colors.grey[500]!;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: !enabled
              ? (isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF3F3F4))
              : selected
              ? primaryOrange
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: !enabled
                ? disabledText
                : selected
                ? Colors.white
                : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _buildLabel(String text, Color textColor) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w500,
        color: textColor,
        fontSize: 13,
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required Color textColor,
    required Color inputFillColor,
    required Color borderColor,
    required bool isDarkMode,
    bool decimal = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*[\,\.]?\d{0,2}$')),
      ],
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.plusJakartaSans(
          color: Colors.grey[400],
          fontSize: 14,
        ),
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFA800), width: 1.5),
        ),
      ),
    );
  }
}
