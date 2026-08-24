import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:equate/viewmodel/theme_viewmodel.dart';
import 'home_tab_view.dart';

class CalculatorTabView extends StatefulWidget {
  const CalculatorTabView({super.key});

  @override
  State<CalculatorTabView> createState() => _CalculatorTabViewState();
}

class _CalculatorTabViewState extends State<CalculatorTabView> {
  int _selectedTab = 0; // 0: Emas, 1: Pivot Point

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFFFA800);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeViewModel.themeMode,
      builder: (context, currentThemeMode, child) {
        final isDarkMode = ThemeViewModel.isDarkMode;

        // Penyesuaian Warna Dinamis
        final bgColor = isDarkMode
            ? const Color(0xFF121212)
            : const Color(0xFFFBFBFB);
        final tabBgColor = isDarkMode
            ? const Color(0xFF1E1E1E)
            : const Color(0xFFF2F2F2);
        final activeTabBgColor = isDarkMode
            ? const Color(0xFF2A2A2A)
            : Colors.white;
        final iconColor = isDarkMode ? Colors.white : Colors.black;
        final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
        final unselectedTextColor = isDarkMode
            ? const Color(0xFFA0A0A0)
            : Colors.grey[600]!;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: iconColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeTabView()),
                );
              },
            ),
            title: Text(
              'KALKULATOR',
              style: GoogleFonts.plusJakartaSans(
                color: primaryTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              const SizedBox(height: 10),
              // TAB SWITCHER
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: tabBgColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0
                                ? activeTabBgColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: _selectedTab == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                        isDarkMode ? 0.3 : 0.05,
                                      ),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            'PERHITUNGAN EMAS',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _selectedTab == 0
                                  ? primaryOrange
                                  : unselectedTextColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1
                                ? activeTabBgColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: _selectedTab == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                        isDarkMode ? 0.3 : 0.05,
                                      ),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            'PIVOT POINT',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _selectedTab == 1
                                  ? primaryOrange
                                  : unselectedTextColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // TAB CONTENT
              Expanded(
                child: _selectedTab == 0
                    ? const GoldCalculatorContent()
                    : const PivotPointCalculatorContent(),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// 1. KONTEN KALKULATOR EMAS
// ==========================================
class GoldCalculatorContent extends StatefulWidget {
  const GoldCalculatorContent({super.key});

  @override
  State<GoldCalculatorContent> createState() => _GoldCalculatorContentState();
}

class _GoldCalculatorContentState extends State<GoldCalculatorContent> {
  final TextEditingController _modalController = TextEditingController();
  final TextEditingController _hargaBeliController = TextEditingController();
  final TextEditingController _kursController = TextEditingController();

  final String _hargaJualFixed = "4320.08";
  bool _hasInput = false;
  double? _hasilAkhir;
  bool _isCalculated = false;

  @override
  void initState() {
    super.initState();
    _modalController.addListener(_checkInputState);
    _hargaBeliController.addListener(_checkInputState);
    _kursController.addListener(_checkInputState);
  }

  @override
  void dispose() {
    _modalController.dispose();
    _hargaBeliController.dispose();
    _kursController.dispose();
    super.dispose();
  }

  void _checkInputState() {
    final hasText =
        _modalController.text.isNotEmpty ||
        _hargaBeliController.text.isNotEmpty ||
        _kursController.text.isNotEmpty;

    if (hasText != _hasInput) {
      setState(() => _hasInput = hasText);
    }
  }

  void _resetForm() {
    setState(() {
      _modalController.clear();
      _hargaBeliController.clear();
      _kursController.clear();
      _hasilAkhir = null;
      _isCalculated = false;
    });
  }

  void _calculateGold() {
    final double? modal = double.tryParse(
      _modalController.text.replaceAll(',', '.'),
    );
    final double? hargaBeli = double.tryParse(
      _hargaBeliController.text.replaceAll(',', '.'),
    );
    final double? kurs = double.tryParse(
      _kursController.text.replaceAll(',', '.'),
    );
    final double hargaJual = double.parse(_hargaJualFixed);
    const double toz = 31.1;

    if (modal != null && hargaBeli != null && kurs != null && hargaBeli > 0) {
      final double step1 = (hargaBeli * kurs) / toz;
      final double step2 = (hargaJual * kurs) / toz;
      final double step3 = step2 - step1;
      final double step4 = modal / step1;
      final double step5 = step3 * step4;

      setState(() {
        _hasilAkhir = step5;
        _isCalculated = true;
      });
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
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
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: primaryOrange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.bar_chart,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Masukkan Data',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: primaryTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildLabel('Modal', labelTextColor),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _modalController,
                  prefixText: 'Rp  ',
                  hintText: '0',
                  textColor: primaryTextColor,
                  inputFillColor: inputFillColor,
                  borderColor: borderColor,
                ),
                const SizedBox(height: 16),
                _buildLabel('Harga Beli', labelTextColor),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _hargaBeliController,
                  hintText: '0,00',
                  textColor: primaryTextColor,
                  inputFillColor: inputFillColor,
                  borderColor: borderColor,
                ),
                const SizedBox(height: 16),
                _buildLabel('Kurs', labelTextColor),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _kursController,
                  prefixText: 'Rp  ',
                  hintText: '0',
                  textColor: primaryTextColor,
                  inputFillColor: inputFillColor,
                  borderColor: borderColor,
                ),
                const SizedBox(height: 16),
                _buildLabel('Harga Jual', labelTextColor),
                const SizedBox(height: 6),
                TextField(
                  readOnly: true,
                  enabled: false,
                  controller: TextEditingController(text: '4320,08'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                  decoration: InputDecoration(
                    suffixIcon: const Icon(
                      Icons.lock,
                      size: 20,
                      color: Colors.grey,
                    ),
                    filled: true,
                    fillColor: isDarkMode
                        ? const Color(0xFF222222)
                        : const Color(0xFFF8F8FA),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _hasInput ? primaryOrange : borderColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: cardBgColor,
                          ),
                          onPressed: _hasInput ? _resetForm : null,
                          child: Text(
                            'HAPUS',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _hasInput
                                  ? primaryOrange
                                  : Colors.grey[500],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasInput
                                ? primaryOrange
                                : (isDarkMode
                                      ? const Color(0xFF2A2A2A)
                                      : const Color(0xFFF8F8FA)),
                            elevation: _hasInput ? 2 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _hasInput ? _calculateGold : null,
                          child: Text(
                            'HITUNG',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _hasInput
                                  ? Colors.white
                                  : Colors.grey[500],
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF00C853),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hasil',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: primaryTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                        ),
                      ),
                      if (_isCalculated && _hasilAkhir != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _hasilAkhir! >= 0
                                  ? Icons.north_east_rounded
                                  : Icons.south_east_rounded,
                              color: _hasilAkhir! >= 0
                                  ? const Color(0xFF00C853)
                                  : const Color(0xFFFF3B30),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _hasilAkhir! >= 0 ? 'Untung' : 'Rugi',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _hasilAkhir! >= 0
                                    ? const Color(0xFF00C853)
                                    : const Color(0xFFFF3B30),
                              ),
                            ),
                          ],
                        ),
                      ],
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
    String? prefixText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      decoration: InputDecoration(
        prefixText: prefixText,
        prefixStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        hintText: hintText,
        hintStyle: GoogleFonts.plusJakartaSans(
          color: Colors.grey[500],
          fontSize: 14,
        ),
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
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

// ==========================================
// 2. KONTEN KALKULATOR PIVOT POINT
// ==========================================
class PivotPointCalculatorContent extends StatefulWidget {
  const PivotPointCalculatorContent({super.key});

  @override
  State<PivotPointCalculatorContent> createState() =>
      _PivotPointCalculatorContentState();
}

class _PivotPointCalculatorContentState
    extends State<PivotPointCalculatorContent> {
  final TextEditingController _highController = TextEditingController();
  final TextEditingController _lowController = TextEditingController();
  final TextEditingController _closeController = TextEditingController();

  bool _hasInput = false;
  bool _isR4Expanded = false;
  bool _isS4Expanded = false;

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
    _highController.dispose();
    _lowController.dispose();
    _closeController.dispose();
    super.dispose();
  }

  void _checkInputState() {
    final hasText =
        _highController.text.isNotEmpty ||
        _lowController.text.isNotEmpty ||
        _closeController.text.isNotEmpty;

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
    });
  }

  void _calculatePivot() {
    final double? high = double.tryParse(
      _highController.text.replaceAll(',', '.'),
    );
    final double? low = double.tryParse(
      _lowController.text.replaceAll(',', '.'),
    );
    final double? close = double.tryParse(
      _closeController.text.replaceAll(',', '.'),
    );

    if (high != null && low != null && close != null) {
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
    }
  }

  String _formatVal(double? val) {
    if (val == null) return '';
    return val.toStringAsFixed(2).replaceAll('.', ',');
  }

  double _mid(double a, double b) => (a + b) / 2;

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFFF9E0F);
    const resistanceColor = Color(0xFFFFB800);
    const supportColor = Color(0xFF4295FF);
    const pivotColor = Color(0xFF18B85A);
    const midpointColor = Color(0xFFB5B5B5);

    final isDarkMode = ThemeViewModel.isDarkMode;

    final cardBgColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final inputFillColor = isDarkMode
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF8F8FA);
    final primaryTextColor = isDarkMode
        ? Colors.white
        : const Color(0xFF161616);
    final labelTextColor = isDarkMode
        ? const Color(0xFFD0D0D0)
        : const Color(0xFF626262);
    final borderColor = isDarkMode
        ? Colors.grey[800]!
        : const Color(0xFFE7E7E7);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        children: [
          // ==========================
          // INPUT CARD
          // ==========================
          Container(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.25 : 0.035),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: primaryOrange,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Masukkan Data',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: primaryTextColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                _buildLabel('Harga Tertinggi', labelTextColor),
                const SizedBox(height: 7),
                _buildTextField(
                  controller: _highController,
                  hintText: '0,00',
                  textColor: primaryTextColor,
                  inputFillColor: inputFillColor,
                  borderColor: borderColor,
                ),

                const SizedBox(height: 18),

                _buildLabel('Harga Terendah', labelTextColor),
                const SizedBox(height: 7),
                _buildTextField(
                  controller: _lowController,
                  hintText: '0,00',
                  textColor: primaryTextColor,
                  inputFillColor: inputFillColor,
                  borderColor: borderColor,
                ),

                const SizedBox(height: 18),

                _buildLabel('Harga Penutupan', labelTextColor),
                const SizedBox(height: 7),
                _buildTextField(
                  controller: _closeController,
                  hintText: '0,00',
                  textColor: primaryTextColor,
                  inputFillColor: inputFillColor,
                  borderColor: borderColor,
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _hasInput ? primaryOrange : borderColor,
                            ),
                            backgroundColor: cardBgColor,
                            elevation: _hasInput ? 2 : 0,
                            shadowColor: primaryOrange.withOpacity(0.18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _hasInput ? _resetForm : null,
                          child: Text(
                            'HAPUS',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: _hasInput
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
                            backgroundColor: _hasInput
                                ? primaryOrange
                                : (isDarkMode
                                      ? const Color(0xFF2A2A2A)
                                      : const Color(0xFFF4F4F4)),
                            foregroundColor: Colors.white,
                            elevation: _hasInput ? 2 : 0,
                            shadowColor: primaryOrange.withOpacity(0.25),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _hasInput ? _calculatePivot : null,
                          child: Text(
                            'HITUNG',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
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

          const SizedBox(height: 20),

          // ==========================
          // RESULT CARD
          // ==========================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.25 : 0.035),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: pivotColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Hasil',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: primaryTextColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // RESISTANCE
                if (_isR4Expanded)
                  _buildExpandedLevelCard(
                    children: [
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
                    ],
                  )
                else
                  _buildCollapsedLevelCard(
                    label: 'R4',
                    value: _formatVal(_r4),
                    labelColor: resistanceColor,
                    iconColor: resistanceColor,
                    icon: Icons.arrow_drop_down_circle,
                    onIconTap: () => setState(() => _isR4Expanded = true),
                    valueColor: primaryTextColor,
                  ),

                const SizedBox(height: 14),

                // PIVOT POINT
                _buildPivotPointCard(
                  value: _formatVal(_pp),
                  primaryTextColor: primaryTextColor,
                  pivotColor: pivotColor,
                ),

                const SizedBox(height: 14),

                // SUPPORT
                if (_isS4Expanded)
                  _buildExpandedLevelCard(
                    children: [
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
                          value: _formatVal(_mid(_s2!, _s3!)),
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
                    ],
                  )
                else
                  _buildCollapsedLevelCard(
                    label: 'S4',
                    value: _formatVal(_s4),
                    labelColor: supportColor,
                    iconColor: supportColor,
                    icon: Icons.arrow_drop_down_circle,
                    onIconTap: () => setState(() => _isS4Expanded = true),
                    valueColor: primaryTextColor,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedLevelCard({
    required String label,
    required String value,
    required Color labelColor,
    required Color iconColor,
    required IconData icon,
    required VoidCallback onIconTap,
    required Color valueColor,
  }) {
    return Center(
      child: Container(
        width: 258,
        height: 40,
        decoration: BoxDecoration(
          color: ThemeViewModel.isDarkMode
              ? const Color(0xFF242424)
              : Colors.white,
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                ThemeViewModel.isDarkMode ? 0.28 : 0.10,
              ),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 94,
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                  ),
                ),
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: ThemeViewModel.isDarkMode
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFFF0F0F0),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        value,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: valueColor,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: onIconTap,
                      child: Icon(icon, size: 18, color: iconColor),
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

  Widget _buildExpandedLevelCard({required List<Widget> children}) {
    return Center(
      child: Container(
        width: 258,
        decoration: BoxDecoration(
          color: ThemeViewModel.isDarkMode
              ? const Color(0xFF242424)
              : Colors.white,
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                ThemeViewModel.isDarkMode ? 0.28 : 0.10,
              ),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(children: children),
      ),
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
    return SizedBox(
      height: 37,
      child: Row(
        children: [
          SizedBox(
            width: 94,
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMidpoint ? 11 : 13,
                  fontWeight: isMidpoint ? FontWeight.w500 : FontWeight.w700,
                  color: labelColor,
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 37,
            color: ThemeViewModel.isDarkMode
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFFF1F1F1),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: valueColor,
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

  Widget _buildPivotPointCard({
    required String value,
    required Color primaryTextColor,
    required Color pivotColor,
  }) {
    return Center(
      child: Container(
        width: 192,
        height: 76,
        decoration: BoxDecoration(
          color: ThemeViewModel.isDarkMode
              ? const Color(0xFF242424)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                ThemeViewModel.isDarkMode ? 0.28 : 0.09,
              ),
              blurRadius: 9,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'PIVOT POINT',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: pivotColor,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
          fontWeight: FontWeight.w500,
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
          borderSide: const BorderSide(color: Color(0xFFFF9E0F), width: 1.5),
        ),
      ),
    );
  }
}
