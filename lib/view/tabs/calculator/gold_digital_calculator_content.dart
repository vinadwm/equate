import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:gal/gal.dart';

import 'package:equate/viewmodel/theme_viewmodel.dart';
import 'package:equate/viewmodel/gold_digital_viewmodel.dart';
import 'package:equate/viewmodel/history_viewmodel.dart';
import 'package:equate/model/digital_gold_model.dart';
import 'package:equate/model/calculation_history_model.dart';

// ============================================================
// CUSTOM DECIMAL INPUT FORMATTER
// ============================================================
class DecimalTextInputFormatter extends TextInputFormatter {
  final RegExp _regExp = RegExp(r'^\d*[\,\.]?\d{0,2}$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty || _regExp.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}

class GoldDigitalCalculatorContent extends StatefulWidget {
  final Function(dynamic)? onCalculate;

  const GoldDigitalCalculatorContent({
    super.key,
    this.onCalculate,
  });

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
  // HELPER PARSING NUMBER
  // ============================================================

  double _parseFormattedDouble(String text) {
    if (text.isEmpty) return 0;
    if (text.contains(',')) {
      final clean = text.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(clean) ?? 0;
    }
    return double.tryParse(text) ?? 0;
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
    controller.selection = TextSelection.collapsed(offset: value.length);
    controller.addListener(listener);
  }

  // ============================================================
  // CALCULATE & SAVE TO FIRESTORE
  // ============================================================

Future<void> _calculateGoldDigital() async {
  await _viewModel.calculateGoldDigital();

  if (_viewModel.digitalHasilNetto != null) {
    try {
      final historyModel = DigitalGoldModel(
        result: _viewModel.digitalHasilNetto!,
        weightInGram: _parseFormattedDouble(_lotController.text), // lot / gram
        buyPrice: _parseFormattedDouble(_hargaOpenController.text), // harga open/beli
        currentPrice: _parseFormattedDouble(_hargaCloseController.text), // harga close/sekarang
        profitLoss: _viewModel.digitalHasilNetto!,
        createdAt: DateTime.now(),
      );

      if (mounted) {
        await Provider.of<HistoryViewModel>(context, listen: false)
            .addHistory(historyModel);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kalkulasi Emas Digital berhasil disimpan ke Riwayat!'),
            backgroundColor: Color(0xFF18B85A),
          ),
        );
      }
    } catch (e) {
      debugPrint('Gagal menyimpan riwayat ke Firestore: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  if (widget.onCalculate != null) {
    widget.onCalculate!(_viewModel.digitalHasilNetto);
  }
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

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Gagal mengubah hasil menjadi gambar.');
      }

      final pngBytes = byteData.buffer.asUint8List();

      await Gal.putImageBytes(pngBytes);

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
  // SARAN / REKOMENDASI (BERDASARKAN HASIL, TIDAK MENGUBAH LOGIKA HITUNG)
  // ============================================================

  bool get _digitalIsProfit => (_viewModel.digitalHasilNetto ?? 0) >= 0;

  String get _digitalRecommendationTitle =>
      _digitalIsProfit ? 'Posisi Sedang Untung' : 'Posisi Sedang Rugi';

  List<String> get _digitalRecommendationSteps {
    if (_digitalIsProfit) {
      return [
        'Pertimbangkan untuk close posisi sekarang agar keuntungan yang sudah '
            'didapat lebih terjaga.',
        'Jika masih yakin tren harga akan berlanjut, kamu bisa menahan posisi '
            'sambil rutin memantau pergerakan harga.',
        'Tetapkan target profit sejak awal supaya tidak terlambat mengambil '
            'keuntungan.',
      ];
    }

    return [
      'Evaluasi ulang alasan kamu membuka posisi ini dengan kondisi pasar '
          'saat ini.',
      'Pertimbangkan cut loss lebih awal jika potensi kerugian berisiko '
          'semakin membesar.',
      'Hindari menambah posisi (average down) tanpa perhitungan risiko yang '
          'matang.',
    ];
  }

  String get _digitalRecommendationDisclaimer =>
      'Saran ini bersifat edukasi umum, bukan nasihat atau rekomendasi '
      'finansial. Keputusan trading sepenuhnya menjadi tanggung jawab kamu.';

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

    final signalColor = _viewModel.digitalIsCalculated
        ? (_digitalIsProfit
              ? const Color(0xFF22C55E)
              : const Color(0xFFFF3B30))
        : primaryOrange;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // PENJELASAN EMAS DIGITAL
          // ======================================================
          _buildExplanationCard(
            isDarkMode: isDarkMode,
            primaryTextColor: primaryTextColor,
          ),

          const SizedBox(height: 16),

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

                // JUMLAH LOT
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

                // OPEN POSITION
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

                // CLOSE POSITION
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

                // BUTTONS (HAPUS & HITUNG)
                Row(
                  children: [
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

                  Divider(height: 1, color: borderColor),

                  const SizedBox(height: 20),

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
          // SARAN SETELAH HASIL
          // ======================================================
          if (_viewModel.digitalIsCalculated) ...[
            const SizedBox(height: 14),
            _buildRecommendationCard(
              signalColor: signalColor,
              cardBgColor: cardBgColor,
              borderColor: borderColor,
              primaryTextColor: primaryTextColor,
              isDarkMode: isDarkMode,
            ),
          ],

          // EXPORT BUTTON
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
  // KARTU PENJELASAN EMAS DIGITAL (RAMAH PEMULA)
  // ============================================================

  Widget _buildExplanationCard({
    required bool isDarkMode,
    required Color primaryTextColor,
  }) {
    const primaryOrange = Color(0xFFFFA800);
    const buyColor = Color(0xFF22C55E);
    const sellColor = Color(0xFFFF3B30);

    final subText = isDarkMode ? Colors.grey[300] : Colors.grey[700];

    Widget term(String title, String desc, IconData icon) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: primaryOrange),
                  const SizedBox(width: 5),
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: primaryTextColor,
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
          color: color.withOpacity(isDarkMode ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
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

    return Container(
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
        border: Border.all(color: primaryOrange.withOpacity(0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primaryOrange.withOpacity(0.18),
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
                      'Apa itu Emas Digital?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                      ),
                    ),
                    Text(
                      'Investasi emas tanpa fisik',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            'Emas Digital adalah cara transaksi emas secara non-fisik. Kamu '
            'membuka posisi Buy atau Sell pada harga tertentu (Open), lalu '
            'menutupnya di harga lain (Close) untuk mendapatkan selisih '
            'keuntungan atau kerugian dari sejumlah Lot yang dipilih.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              height: 1.55,
              color: subText,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              term(
                'Lot',
                'Jumlah satuan emas digital yang kamu transaksikan.',
                Icons.scale_rounded,
              ),
              const SizedBox(width: 8),
              term(
                'Open / Close',
                'Harga saat posisi dibuka dan saat posisi ditutup.',
                Icons.swap_vert_rounded,
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            'Cara membaca hasil',
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
            condition: 'Untung jika Close lebih tinggi dari Open',
            example:
                'Contoh: Open 1.000 dan Close 1.050 → Untung dari kenaikan harga.',
          ),

          rule(
            icon: Icons.trending_down_rounded,
            color: sellColor,
            label: 'SELL',
            condition: 'Untung jika Close lebih rendah dari Open',
            example:
                'Contoh: Open 1.050 dan Close 1.000 → Untung dari penurunan harga.',
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.75),
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
                    'Tips: pastikan posisi Buy/Sell sesuai analisa arah harga '
                    'sebelum menghitung, karena posisi ini yang menentukan cara '
                    'membaca untung/rugi.',
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
    final steps = _digitalRecommendationSteps;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: signalColor.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.25 : 0.035),
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
                  color: signalColor.withOpacity(0.12),
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
                      _digitalRecommendationTitle,
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
                      color: signalColor.withOpacity(0.14),
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
                        color: primaryTextColor.withOpacity(0.85),
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
                  _digitalRecommendationDisclaimer,
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

  // ============================================================
  // POSITION SELECTOR & BUTTON
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
  // LABEL & TEXTFIELD
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
        DecimalTextInputFormatter(),
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