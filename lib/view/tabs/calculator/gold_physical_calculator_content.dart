import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:gal/gal.dart';

// FIX: import model PhysicalGoldModel agar bisa dibangun & dikirim lewat onCalculate
import 'package:equate/model/physical_gold_model.dart';

class GoldPhysicalCalculatorContent extends StatefulWidget {
  // 1. Tambahkan parameter callback onCalculate di constructor
  final Function(dynamic)? onCalculate;

  const GoldPhysicalCalculatorContent({super.key, this.onCalculate});

  @override
  State<GoldPhysicalCalculatorContent> createState() =>
      _GoldPhysicalCalculatorContentState();
}

class _GoldPhysicalCalculatorContentState
    extends State<GoldPhysicalCalculatorContent>
    with SingleTickerProviderStateMixin {
  final GlobalKey _globalKey = GlobalKey();

  final TextEditingController _modalController = TextEditingController();
  final TextEditingController _kursController = TextEditingController();
  final TextEditingController _hargaBeliController = TextEditingController();
  final TextEditingController _hargaJualController = TextEditingController(
    text: "0,00",
  );

  bool _hasInput = false;
  double? _hasilAkhir;
  bool _isCalculated = false;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _modalController.addListener(_checkInputState);
    _kursController.addListener(_checkInputState);
    _hargaBeliController.addListener(_checkInputState);
    _hargaJualController.addListener(_checkInputState);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _modalController.dispose();
    _kursController.dispose();
    _hargaBeliController.dispose();
    _hargaJualController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  double? _parseFormattedNumber(String text) {
    if (text.trim().isEmpty) return null;
    final cleanText = text.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleanText);
  }

  void _triggerGlowPulse() {
    _glowController.forward(from: 0.0).then((_) {
      if (mounted) _glowController.reverse();
    });
  }

  void _checkInputState() {
    final hasText =
        _modalController.text.isNotEmpty ||
        _kursController.text.isNotEmpty ||
        _hargaBeliController.text.isNotEmpty ||
        _hargaJualController.text.isNotEmpty;

    if (hasText != _hasInput) {
      setState(() => _hasInput = hasText);
    }
  }

  void _resetForm() {
    setState(() {
      _modalController.clear();
      _kursController.clear();
      _hargaBeliController.clear();
      _hargaJualController.clear();
      _hasilAkhir = null;
      _isCalculated = false;
    });
  }

  void _calculateGold() {
    final double? modal = _parseFormattedNumber(_modalController.text);
    final double? hargaBeli = _parseFormattedNumber(_hargaBeliController.text);
    final double? hargaJual = _parseFormattedNumber(_hargaJualController.text);
    final double? kurs = _parseFormattedNumber(_kursController.text);

    const double toz = 31.1;

    if (modal != null &&
        hargaBeli != null &&
        hargaJual != null &&
        kurs != null &&
        hargaBeli > 0 &&
        kurs > 0) {
      final double step1 = (hargaBeli * kurs) / toz; // harga beli per gram
      final double step2 = (hargaJual * kurs) / toz; // harga jual per gram
      final double step3 = step2 - step1; // selisih per gram

      if (step1 > 0) {
        final double step4 = modal / step1; // berat emas (gram)
        final double step5 = step3 * step4; // hasil akhir (profit/loss)

        setState(() {
          _hasilAkhir = step5;
          _isCalculated = true;
        });

        // ==========================================================
        // FIX: bangun PhysicalGoldModel yang LENGKAP dan kirim lewat
        // onCalculate, bukan cuma angka `step5` mentah.
        //
        // Catatan mapping (silakan sesuaikan jika arti fieldnya beda
        // di project kamu):
        //   - weightInGram      -> berat emas hasil hitung (step4)
        //   - karat             -> tidak ada input karat di form ini,
        //                          default 24 (emas murni)
        //   - buyPrice          -> harga beli per gram (step1)
        //   - currentPricePerGram -> harga jual per gram (step2)
        //   - certificateFee    -> tidak ada input di form ini, default 0
        // ==========================================================
        if (widget.onCalculate != null) {
          widget.onCalculate!(
            PhysicalGoldModel(
              title: 'Kalkulasi Emas Fisik',
              result: step5,
              weightInGram: step4,
              karat: 24,
              buyPrice: step1,
              currentPricePerGram: step2,
              certificateFee: 0.0,
              createdAt: DateTime.now(),
            ),
          );
        }
      }
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );
    return formatter.format(amount.abs()).trim();
  }

  Future<void> _exportAsImage() async {
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      final boundary =
          _globalKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      var byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      var pngBytes = byteData.buffer.asUint8List();

      final output = await getTemporaryDirectory();
      final filePath =
          "${output.path}/gold_physical_${DateTime.now().millisecondsSinceEpoch}.png";
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

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

  Future<void> _exportAsPdf() async {
    final pdf = pw.Document();

    final statusText = _hasilAkhir == null
        ? '-'
        : _hasilAkhir! >= 0
        ? 'Untung'
        : 'Rugi';

    final hasilText = _hasilAkhir == null
        ? 'Rp 0'
        : '${_hasilAkhir! < 0 ? '-Rp ' : 'Rp '}${_formatCurrency(_hasilAkhir!)}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context pdfContext) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'KALKULATOR EMAS FISIK',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Table.fromTextArray(
                  headers: ['Parameter', 'Nilai'],
                  data: [
                    ['Modal', 'Rp ${_modalController.text}'],
                    ['Kurs', 'Rp ${_kursController.text}'],
                    ['Harga Beli', _hargaBeliController.text],
                    ['Harga Jual', _hargaJualController.text],
                    ['Status', statusText],
                    ['Hasil Akhir', hasilText],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

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

  bool get _physicalIsProfit => (_hasilAkhir ?? 0) >= 0;

  String get _physicalRecommendationTitle =>
      _physicalIsProfit ? 'Posisi Sedang Untung' : 'Posisi Sedang Rugi';

  List<String> get _physicalRecommendationSteps {
    if (_physicalIsProfit) {
      return [
        'Pertimbangkan untuk menjual sebagian emas untuk mengunci keuntungan '
            'yang sudah terbentuk.',
        'Jika tujuannya investasi jangka panjang, kamu bisa tetap menyimpan '
            'emas dan memantau kurs serta harga emas secara berkala.',
        'Jual emas fisik di tempat resmi dan terpercaya agar harga jual '
            'sesuai standar pasar.',
      ];
    }

    return [
      'Evaluasi kembali harga beli dan kurs saat ini dibanding saat kamu '
          'membeli emas.',
      'Jika masih untuk investasi jangka panjang, kerugian sementara wajar '
          'terjadi karena fluktuasi harga emas dan kurs.',
      'Hindari menjual tergesa-gesa saat harga sedang turun kalau tidak '
          'benar-benar butuh dana mendesak.',
    ];
  }

  String get _physicalRecommendationDisclaimer =>
      'Saran ini bersifat edukasi umum, bukan nasihat atau rekomendasi '
      'finansial. Keputusan jual-beli emas sepenuhnya menjadi tanggung jawab '
      'kamu.';

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFFF9E0F);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final cardBgColor = isDarkMode
        ? const Color(0xFF1E1E24).withOpacity(0.9)
        : Colors.white.withOpacity(0.95);
    final primaryTextColor = isDarkMode
        ? Colors.white
        : const Color(0xFF161616);
    final inputFillColor = isDarkMode
        ? const Color(0xFF262630)
        : const Color(0xFFF4F5F9);
    final borderColor = isDarkMode
        ? Colors.white.withOpacity(0.12)
        : const Color(0xFFE2E4EC);
    final dividerColor = isDarkMode
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFEEEEEE);

    final signalColor = _isCalculated
        ? (_physicalIsProfit
              ? const Color(0xFF18B85A)
              : const Color(0xFFFF3B30))
        : primaryOrange;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 14, top: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryOrange,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: primaryOrange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.grid_goldenratio_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Kalkulator Emas Fisik',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: primaryTextColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // PENJELASAN EMAS FISIK
          // ======================================================
          _buildExplanationCard(
            isDarkMode: isDarkMode,
            primaryTextColor: primaryTextColor,
          ),

          const SizedBox(height: 14),

          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _glowAnimation.value > 0
                        ? primaryOrange
                        : (_hasInput
                              ? primaryOrange.withOpacity(0.5)
                              : borderColor),
                    width: _glowAnimation.value > 0 ? 1.5 : 1.2,
                  ),
                  boxShadow: [
                    if (_glowAnimation.value > 0)
                      BoxShadow(
                        color: primaryOrange.withOpacity(0.35),
                        blurRadius: _glowAnimation.value,
                        spreadRadius: 1,
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          isDarkMode ? 0.3 : 0.03,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: child,
              );
            },
            child: Column(
              children: [
                _buildCompactInput(
                  'Modal',
                  _modalController,
                  primaryTextColor,
                  inputFillColor,
                  borderColor,
                  glowValue: _glowAnimation.value,
                  prefixText: 'Rp ',
                  hintText: '0',
                ),
                const SizedBox(height: 12),
                _buildCompactInput(
                  'Kurs',
                  _kursController,
                  primaryTextColor,
                  inputFillColor,
                  borderColor,
                  glowValue: _glowAnimation.value,
                  prefixText: 'Rp ',
                  hintText: '0',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactInput(
                        'Harga Beli',
                        _hargaBeliController,
                        primaryTextColor,
                        inputFillColor,
                        borderColor,
                        glowValue: _glowAnimation.value,
                        hintText: '0,00',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildCompactInput(
                        'Harga Jual',
                        _hargaJualController,
                        primaryTextColor,
                        inputFillColor,
                        borderColor,
                        glowValue: _glowAnimation.value,
                        hintText: '0,00',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _hasInput ? primaryOrange : borderColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 42,
                        decoration: _hasInput
                            ? BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryOrange.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              )
                            : null,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasInput
                                ? primaryOrange
                                : (isDarkMode
                                      ? const Color(0xFF2A2A34)
                                      : const Color(0xFFF0F0F4)),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _hasInput ? _calculateGold : null,
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
          const SizedBox(height: 14),
          RepaintBoundary(
            key: _globalKey,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isCalculated
                      ? (_hasilAkhir != null && _hasilAkhir! >= 0
                            ? const Color(0xFF18B85A).withOpacity(0.6)
                            : const Color(0xFFFF3B30).withOpacity(0.6))
                      : borderColor,
                  width: 1.2,
                ),
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
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: isDarkMode ? 0.06 : 0.08,
                        child: Image.asset(
                          'assets/images/logoEWF.png',
                          width: 200,
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
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF18B85A).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF18B85A),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Hasil Kalkulasi',
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
                      const SizedBox(height: 18),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              !_isCalculated || _hasilAkhir == null
                                  ? 'Rp 0'
                                  : '${_hasilAkhir! < 0 ? '-Rp ' : 'Rp '}${_formatCurrency(_hasilAkhir!)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: primaryTextColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (_isCalculated && _hasilAkhir != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (_hasilAkhir! >= 0
                                              ? const Color(0xFF18B85A)
                                              : const Color(0xFFFF3B30))
                                          .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        (_hasilAkhir! >= 0
                                                ? const Color(0xFF18B85A)
                                                : const Color(0xFFFF3B30))
                                            .withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _hasilAkhir! >= 0
                                          ? Icons.north_east_rounded
                                          : Icons.south_east_rounded,
                                      color: _hasilAkhir! >= 0
                                          ? const Color(0xFF18B85A)
                                          : const Color(0xFFFF3B30),
                                      size: 15,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _hasilAkhir! >= 0 ? 'Untung' : 'Rugi',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: _hasilAkhir! >= 0
                                            ? const Color(0xFF18B85A)
                                            : const Color(0xFFFF3B30),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ======================================================
          // SARAN SETELAH HASIL
          // ======================================================
          if (_isCalculated) ...[
            const SizedBox(height: 14),
            _buildRecommendationCard(
              signalColor: signalColor,
              cardBgColor: cardBgColor,
              borderColor: dividerColor,
              primaryTextColor: primaryTextColor,
              isDarkMode: isDarkMode,
            ),
          ],

          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryOrange, width: 1.2),
                backgroundColor: cardBgColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _showExportModal(context),
              icon: const Icon(
                Icons.ios_share_rounded,
                color: primaryOrange,
                size: 16,
              ),
              label: Text(
                'EXPORT HASIL',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  color: primaryOrange,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // KARTU PENJELASAN EMAS FISIK (RAMAH PEMULA)
  // ============================================================

  Widget _buildExplanationCard({
    required bool isDarkMode,
    required Color primaryTextColor,
  }) {
    const primaryOrange = Color(0xFFFF9E0F);
    const profitColor = Color(0xFF18B85A);
    const lossColor = Color(0xFFFF3B30);

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
      margin: const EdgeInsets.only(bottom: 0),
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
                      'Apa itu Emas Fisik?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                      ),
                    ),
                    Text(
                      'Investasi emas batangan',
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
            'Emas Fisik adalah investasi emas dalam bentuk batangan nyata. '
            'Keuntungan atau kerugiannya dihitung dari selisih harga jual dan '
            'harga beli per gram, setelah dikonversi dari harga emas '
            'internasional (USD/troy ounce) ke Rupiah menggunakan kurs.',
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
                'Modal & Kurs',
                'Modal adalah dana yang diinvestasikan. Kurs adalah nilai '
                    'tukar USD ke Rupiah saat itu.',
                Icons.account_balance_wallet_rounded,
              ),
              const SizedBox(width: 8),
              term(
                'Harga Beli/Jual',
                'Harga emas internasional (per troy ounce) saat beli dan '
                    'saat dijual kembali.',
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
            color: profitColor,
            label: 'UNTUNG',
            condition: 'Harga Jual lebih tinggi dari Harga Beli',
            example:
                'Selisih harga per gram dikalikan berat emas menghasilkan '
                'keuntungan.',
          ),

          rule(
            icon: Icons.trending_down_rounded,
            color: lossColor,
            label: 'RUGI',
            condition: 'Harga Jual lebih rendah dari Harga Beli',
            example:
                'Selisih harga per gram bernilai negatif, sehingga hasil '
                'akhir menjadi kerugian.',
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
                    'Tips: harga emas fisik biasanya lebih stabil dan cocok '
                    'untuk investasi jangka menengah-panjang dibanding trading '
                    'harian.',
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
    final steps = _physicalRecommendationSteps;

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
                      _physicalRecommendationTitle,
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
                  _physicalRecommendationDisclaimer,
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

  Widget _buildCompactInput(
    String label,
    TextEditingController controller,
    Color textColor,
    Color inputFillColor,
    Color borderColor, {
    double glowValue = 0.0,
    String? prefixText,
    String? hintText,
  }) {
    final isGlowing = glowValue > 0;

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
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          decoration: InputDecoration(
            isDense: true,
            prefixText: prefixText,
            prefixStyle: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            hintText: hintText,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: Colors.grey[400],
              fontSize: 12,
            ),
            filled: true,
            fillColor: isGlowing
                ? const Color(0xFFFF9E0F).withOpacity(0.12)
                : inputFillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isGlowing
                    ? const Color(0xFFFF9E0F).withOpacity(0.7)
                    : borderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFFF9E0F),
                width: 1.8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}