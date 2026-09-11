import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:gal/gal.dart';

import '../calculator_tab_view.dart';

class PivotPointCalculatorContent extends StatefulWidget {
  final Function(CalculationHistory)? onCalculate;

  const PivotPointCalculatorContent({
    super.key,
    this.onCalculate,
  });

  @override
  State<PivotPointCalculatorContent> createState() =>
      _PivotPointCalculatorContentState();
}

class _PivotPointCalculatorContentState
    extends State<PivotPointCalculatorContent> {
  final GlobalKey _globalKey = GlobalKey();

  final TextEditingController _highController = TextEditingController();
  final TextEditingController _lowController = TextEditingController();
  final TextEditingController _closeController = TextEditingController();

  bool _hasInput = false;
  bool _isR4Expanded = false;
  bool _isS4Expanded = false;
  bool _isAutoFill = false;

  double? _pp, _r1, _r2, _r3, _r4, _s1, _s2, _s3, _s4;

  @override
  void initState() {
    super.initState();
    _highController.addListener(_checkInputState);
    _lowController.addListener(_checkInputState);
    _closeController.addListener(_checkInputState);
  }

  @override
  void dispose() {
    _highController.removeListener(_checkInputState);
    _lowController.removeListener(_checkInputState);
    _closeController.removeListener(_checkInputState);
    _highController.dispose();
    _lowController.dispose();
    _closeController.dispose();
    super.dispose();
  }

  Future<void> _autoFill() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final response = await http.get(
        Uri.parse('https://api.example.com/pivot-data'),
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        _highController.text = data['high'].toString();
        _lowController.text = data['low'].toString();
        _closeController.text = data['close'].toString();

        _showSnackBar('Data berhasil dimuat dari API');
      } else {
        _showSnackBar('Gagal mengambil data: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar('Terjadi kesalahan: $e');
    }
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  void _checkInputState() {
    final hasText = _highController.text.trim().isNotEmpty ||
        _lowController.text.trim().isNotEmpty ||
        _closeController.text.trim().isNotEmpty;

    if (hasText != _hasInput) {
      setState(() => _hasInput = hasText);
    }
  }

  void _resetForm() {
    setState(() {
      _highController.clear();
      _lowController.clear();
      _closeController.clear();
      _pp = _r1 = _r2 = _r3 = _r4 = _s1 = _s2 = _s3 = _s4 = null;
      _isAutoFill = false;
    });
  }

  void _calculatePivot() {
    final double? high = double.tryParse(
      _highController.text.replaceAll(',', '.').trim(),
    );
    final double? low = double.tryParse(
      _lowController.text.replaceAll(',', '.').trim(),
    );
    final double? close = double.tryParse(
      _closeController.text.replaceAll(',', '.').trim(),
    );

    if (high != null && low != null && close != null) {
      if (low > high) {
        _showSnackBar('Nilai Low tidak boleh lebih besar dari High',
            backgroundColor: Colors.red);
        return;
      }

      final double ppVal = (high + low + close) / 3;
      final double diff = high - low;

      setState(() {
        _pp = ppVal;
        _r1 = (2 * ppVal) - low;
        _r2 = ppVal + diff;
        _r3 = ppVal + (diff * 2);
        _r4 = ppVal + (diff * 3);

        _s1 = (2 * ppVal) - high;
        _s2 = ppVal - diff;
        _s3 = ppVal - (diff * 2);
        _s4 = ppVal - (diff * 3);
      });

      if (widget.onCalculate != null) {
        widget.onCalculate!(
          CalculationHistory(
            title: 'Pivot Point',
            details: 'H: $high | L: $low | C: $close',
            result: _pp!,
            timestamp: DateTime.now(),
          ),
        );
      }
    } else {
      _showSnackBar('Harap masukkan format angka yang valid',
          backgroundColor: Colors.red);
    }
  }

  String _formatVal(double? val) {
    if (val == null) return '-';
    return val.toStringAsFixed(2).replaceAll('.', ',');
  }

  double _mid(double a, double b) => (a + b) / 2;

  Future<void> _exportAsImage() async {
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      final boundary = _globalKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      var byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      var pngBytes = byteData.buffer.asUint8List();

      final output = await getTemporaryDirectory();
      final filePath =
          "${output.path}/pivot_point_${DateTime.now().millisecondsSinceEpoch}.png";
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      await Gal.putImage(filePath);

      _showSnackBar('Gambar berhasil disimpan ke Galeri!',
          backgroundColor: const Color(0xFF18B85A));
    } catch (e) {
      _showSnackBar('Gagal menyimpan gambar: $e', backgroundColor: Colors.red);
    }
  }

  Future<void> _exportAsPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'HASIL KALKULASI PIVOT POINT',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 12),
                pw.Table.fromTextArray(
                  headers: ['Tingkat', 'Nilai'],
                  data: [
                    ['Resistance 4 (R4)', _formatVal(_r4)],
                    if (_r4 != null && _r3 != null)
                      ['Midpoint R4-R3', _formatVal(_mid(_r4!, _r3!))],
                    ['Resistance 3 (R3)', _formatVal(_r3)],
                    if (_r3 != null && _r2 != null)
                      ['Midpoint R3-R2', _formatVal(_mid(_r3!, _r2!))],
                    ['Resistance 2 (R2)', _formatVal(_r2)],
                    if (_r2 != null && _r1 != null)
                      ['Midpoint R2-R1', _formatVal(_mid(_r2!, _r1!))],
                    ['Resistance 1 (R1)', _formatVal(_r1)],
                    if (_r1 != null && _pp != null)
                      ['Midpoint R1-PP', _formatVal(_mid(_r1!, _pp!))],
                    ['Pivot Point (PP)', _formatVal(_pp)],
                    if (_pp != null && _s1 != null)
                      ['Midpoint PP-S1', _formatVal(_mid(_pp!, _s1!))],
                    ['Support 1 (S1)', _formatVal(_s1)],
                    if (_s1 != null && _s2 != null)
                      ['Midpoint S1-S2', _formatVal(_mid(_s1!, _s2!))],
                    ['Support 2 (S2)', _formatVal(_s2)],
                    if (_s2 != null && _s3 != null)
                      ['Midpoint S2-S3', _formatVal(_mid(_s3!, _s2!))],
                    ['Support 3 (S3)', _formatVal(_s3)],
                    if (_s3 != null && _s4 != null)
                      ['Midpoint S3-S4', _formatVal(_mid(_s3!, _s4!))],
                    ['Support 4 (S4)', _formatVal(_s4)],
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

  void _showExportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading:
                  const Icon(Icons.image_rounded, color: Color(0xFFFF9E0F)),
              title: const Text('Export sebagai Gambar (PNG)'),
              onTap: () {
                Navigator.pop(context);
                _exportAsImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded,
                  color: Colors.redAccent),
              title: const Text('Export sebagai PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportAsPdf();
              },
            ),
          ],
        ),
      ),
    );
  }

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
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFEEEEEE);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.api_rounded,
                          size: 18,
                          color: _isAutoFill ? primaryOrange : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Isi Otomatis (API)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 24,
                      child: Switch(
                        value: _isAutoFill,
                        activeColor: primaryOrange,
                        activeTrackColor: primaryOrange.withOpacity(0.4),
                        onChanged: (value) async {
                          setState(() {
                            _isAutoFill = value;
                          });

                          if (value) {
                            await _autoFill();
                          } else {
                            _resetForm();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(height: 1, thickness: 1, color: dividerColor),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
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
                          const Icon(Icons.check_circle,
                              color: pivotColor, size: 18),
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
                      if (_isR4Expanded) ...[
                        _buildResultRow(
                          label: 'R4',
                          value: _formatVal(_r4),
                          labelColor: resistanceColor,
                          valueColor: primaryTextColor,
                          trailingIcon: Icons.arrow_circle_up,
                          trailingIconColor: resistanceColor,
                          onTrailingIconTap: () =>
                              setState(() => _isR4Expanded = false),
                        ),
                        if (_r4 != null && _r3 != null)
                          _buildResultRow(
                            label: 'Midpoint',
                            value: _formatVal(_mid(_r4!, _r3!)),
                            labelColor: midpointColor,
                            valueColor: primaryTextColor,
                            isMidpoint: true,
                          ),
                        _buildResultRow(
                          label: 'R3',
                          value: _formatVal(_r3),
                          labelColor: resistanceColor,
                          valueColor: primaryTextColor,
                        ),
                        if (_r3 != null && _r2 != null)
                          _buildResultRow(
                            label: 'Midpoint',
                            value: _formatVal(_mid(_r3!, _r2!)),
                            labelColor: midpointColor,
                            valueColor: primaryTextColor,
                            isMidpoint: true,
                          ),
                        _buildResultRow(
                          label: 'R2',
                          value: _formatVal(_r2),
                          labelColor: resistanceColor,
                          valueColor: primaryTextColor,
                        ),
                        if (_r2 != null && _r1 != null)
                          _buildResultRow(
                            label: 'Midpoint',
                            value: _formatVal(_mid(_r2!, _r1!)),
                            labelColor: midpointColor,
                            valueColor: primaryTextColor,
                            isMidpoint: true,
                          ),
                        _buildResultRow(
                          label: 'R1',
                          value: _formatVal(_r1),
                          labelColor: resistanceColor,
                          valueColor: primaryTextColor,
                        ),
                        if (_r1 != null && _pp != null)
                          _buildResultRow(
                            label: 'Midpoint',
                            value: _formatVal(_mid(_r1!, _pp!)),
                            labelColor: midpointColor,
                            valueColor: primaryTextColor,
                            isMidpoint: true,
                          ),
                      ] else
                        _buildResultRow(
                          label: 'R4',
                          value: _formatVal(_r4),
                          labelColor: resistanceColor,
                          valueColor: primaryTextColor,
                          trailingIcon: Icons.arrow_drop_down_circle,
                          trailingIconColor: resistanceColor,
                          onTrailingIconTap: () =>
                              setState(() => _isR4Expanded = true),
                        ),
                      _buildResultRow(
                        label: 'Pivot Point',
                        value: _formatVal(_pp),
                        labelColor: pivotColor,
                        valueColor: pivotValueColor,
                      ),
                      if (_isS4Expanded) ...[
                        if (_pp != null && _s1 != null)
                          _buildResultRow(
                            label: 'Midpoint',
                            value: _formatVal(_mid(_pp!, _s1!)),
                            labelColor: midpointColor,
                            valueColor: primaryTextColor,
                            isMidpoint: true,
                          ),
                        _buildResultRow(
                          label: 'S1',
                          value: _formatVal(_s1),
                          labelColor: supportColor,
                          valueColor: primaryTextColor,
                        ),
                        if (_s1 != null && _s2 != null)
                          _buildResultRow(
                            label: 'Midpoint',
                            value: _formatVal(_mid(_s1!, _s2!)),
                            labelColor: midpointColor,
                            valueColor: primaryTextColor,
                            isMidpoint: true,
                          ),
                        _buildResultRow(
                          label: 'S2',
                          value: _formatVal(_s2),
                          labelColor: supportColor,
                          valueColor: primaryTextColor,
                        ),
                        if (_s2 != null && _s3 != null)
                          _buildResultRow(
                            label: 'Midpoint',
                            value: _formatVal(_mid(_s3!, _s2!)),
                            labelColor: midpointColor,
                            valueColor: primaryTextColor,
                            isMidpoint: true,
                          ),
                        _buildResultRow(
                          label: 'S3',
                          value: _formatVal(_s3),
                          labelColor: supportColor,
                          valueColor: primaryTextColor,
                        ),
                        if (_s3 != null && _s4 != null)
                          _buildResultRow(
                            label: 'Midpoint',
                            value: _formatVal(_mid(_s3!, _s4!)),
                            labelColor: midpointColor,
                            valueColor: primaryTextColor,
                            isMidpoint: true,
                          ),
                        _buildResultRow(
                          label: 'S4',
                          value: _formatVal(_s4),
                          labelColor: supportColor,
                          valueColor: primaryTextColor,
                          trailingIcon: Icons.arrow_circle_up,
                          trailingIconColor: supportColor,
                          onTrailingIconTap: () =>
                              setState(() => _isS4Expanded = false),
                        ),
                      ] else
                        _buildResultRow(
                          label: 'S4',
                          value: _formatVal(_s4),
                          labelColor: supportColor,
                          valueColor: primaryTextColor,
                          trailingIcon: Icons.arrow_drop_down_circle,
                          trailingIconColor: supportColor,
                          onTrailingIconTap: () =>
                              setState(() => _isS4Expanded = true),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryOrange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _showExportModal(context),
              icon: const Icon(Icons.ios_share_rounded,
                  color: primaryOrange, size: 16),
              label: Text(
                'EXPORT HASIL',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: primaryOrange,
                  fontSize: 12,
                ),
              ),
            ),
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
              borderSide:
                  const BorderSide(color: Color(0xFFFF9E0F), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

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
        border: Border(
          bottom: BorderSide(color: rowBorderColor, width: 1),
        ),
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
          Container(
            width: 1,
            height: 36,
            color: rowBorderColor,
          ),
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