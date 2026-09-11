import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:equate/viewmodel/theme_viewmodel.dart';

enum PositionType { buy, sell }

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
  final TextEditingController _lotController = TextEditingController();
  final TextEditingController _hargaOpenController = TextEditingController();
  final TextEditingController _hargaCloseController = TextEditingController();

  static const double _feePajakPerLot = 333000.0;
  static const double _multiplierPerPoint = 1000000.0;

  bool _hasInput = false;
  bool _isAutoPriceEnabled = false;
  PositionType _selectedPosition = PositionType.buy;

  double? _hasilNetto;
  double? _selisihPoint;
  bool _isCalculated = false;

  @override
  void initState() {
    super.initState();
    _lotController.addListener(_checkInputState);
    _hargaOpenController.addListener(_checkInputState);
    _hargaCloseController.addListener(_checkInputState);
  }

  @override
  void dispose() {
    _lotController.removeListener(_checkInputState);
    _hargaOpenController.removeListener(_checkInputState);
    _hargaCloseController.removeListener(_checkInputState);
    _lotController.dispose();
    _hargaOpenController.dispose();
    _hargaCloseController.dispose();
    super.dispose();
  }

  void _checkInputState() {
    final hasText = _lotController.text.isNotEmpty ||
        _hargaOpenController.text.isNotEmpty ||
        _hargaCloseController.text.isNotEmpty;

    if (hasText != _hasInput) {
      setState(() => _hasInput = hasText);
    }
  }

  void _resetForm() {
    _lotController.clear();
    _hargaOpenController.clear();
    _hargaCloseController.clear();
    setState(() {
      _isAutoPriceEnabled = false;
      _selectedPosition = PositionType.buy;
      _hasilNetto = null;
      _selisihPoint = null;
      _isCalculated = false;
      _hasInput = false;
    });
  }

  void _toggleAutoPrice(bool value) {
    setState(() {
      _isAutoPriceEnabled = value;
      if (_isAutoPriceEnabled) {
        _hargaOpenController.text = '2650.50';
        _hargaCloseController.text = '2655.00';
        if (_lotController.text.isEmpty) {
          _lotController.text = '1';
        }
        _calculateGoldDigital();
      } else {
        _hargaOpenController.clear();
        _hargaCloseController.clear();
        _hasilNetto = null;
        _selisihPoint = null;
        _isCalculated = false;
      }
    });
    _checkInputState();
  }

  void _setLotPreset(String lotValue) {
    _lotController.text = lotValue;
    if (_hargaOpenController.text.isNotEmpty &&
        _hargaCloseController.text.isNotEmpty) {
      _calculateGoldDigital();
    }
  }

  void _calculateGoldDigital() {
    final double? lot = double.tryParse(
      _lotController.text.replaceAll(',', '.'),
    );
    final double? hargaOpen = double.tryParse(
      _hargaOpenController.text.replaceAll(',', '.'),
    );
    final double? hargaClose = double.tryParse(
      _hargaCloseController.text.replaceAll(',', '.'),
    );

    if (lot != null && hargaOpen != null && hargaClose != null && lot > 0) {
      final double point = _selectedPosition == PositionType.buy
          ? (hargaClose - hargaOpen)
          : (hargaOpen - hargaClose);

      final double kotor = lot * point * _multiplierPerPoint;
      final double totalFeePajak = lot * _feePajakPerLot;
      final double netto = kotor - totalFeePajak;

      setState(() {
        _selisihPoint = point;
        _hasilNetto = netto;
        _isCalculated = true;
      });

      if (widget.onCalculate != null) {
        final historyData = {
          'title': 'Emas Digital (${_selectedPosition.name.toUpperCase()})',
          'value': '${netto < 0 ? '-Rp ' : 'Rp '}${_formatCurrency(netto)}',
          'date': DateTime.now(),
        };
        widget.onCalculate!(historyData);
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

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFFFA800);
    final isDarkMode = ThemeViewModel.isDarkMode;

    final cardBgColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black87;
    final labelTextColor =
        isDarkMode ? const Color(0xFFD0D0D0) : Colors.grey[700]!;
    final inputFillColor =
        isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF8F8FA);
    final borderColor =
        isDarkMode ? Colors.grey[800]! : const Color(0xFFEEEEEE);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryOrange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.monetization_on_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kalkulator Emas Digital',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Simulasi Trading & Perhitungan Netto',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Form Input Card
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
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.show_chart_rounded,
                        color: primaryOrange,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Parameter Transaksi',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: primaryTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Posisi Transaksi (BUY / SELL)
                _buildLabel('Posisi Transaksi', labelTextColor),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF252525)
                        : const Color(0xFFF1F1F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildPositionSegmentButton(
                          type: PositionType.buy,
                          label: 'BUY (Long)',
                          activeColor: primaryOrange,
                          isDarkMode: isDarkMode,
                        ),
                      ),
                      Expanded(
                        child: _buildPositionSegmentButton(
                          type: PositionType.sell,
                          label: 'SELL (Short)',
                          activeColor: primaryOrange,
                          isDarkMode: isDarkMode,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Input Lot
                _buildLabel('Jumlah Lot', labelTextColor),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _lotController,
                  hintText: 'Contoh: 1',
                  textColor: primaryTextColor,
                  inputFillColor: inputFillColor,
                  borderColor: borderColor,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 8),

                // Preset Lot
                Row(
                  children: [
                    Text(
                      'Pilih Lot: ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildQuickLotButton(
                        '1 Lot', '1', primaryOrange, isDarkMode),
                    const SizedBox(width: 6),
                    _buildQuickLotButton(
                        '5 Lot', '5', primaryOrange, isDarkMode),
                    const SizedBox(width: 6),
                    _buildQuickLotButton(
                        '10 Lot', '10', primaryOrange, isDarkMode),
                  ],
                ),
                const SizedBox(height: 16),

                // Auto Price Switch
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isAutoPriceEnabled
                        ? primaryOrange.withOpacity(0.08)
                        : (isDarkMode
                            ? const Color(0xFF252525)
                            : const Color(0xFFF8F8FA)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isAutoPriceEnabled
                          ? primaryOrange.withOpacity(0.3)
                          : borderColor,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 18,
                            color: _isAutoPriceEnabled
                                ? primaryOrange
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Isi Harga Beli & Jual Otomatis',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _isAutoPriceEnabled
                                  ? primaryTextColor
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isAutoPriceEnabled,
                        onChanged: _toggleAutoPrice,
                        activeColor: primaryOrange,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Harga Open & Close
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Harga Beli / Open', labelTextColor),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _hargaOpenController,
                            hintText: '2650.50',
                            textColor: primaryTextColor,
                            inputFillColor: inputFillColor,
                            borderColor: borderColor,
                            readOnly: _isAutoPriceEnabled,
                            isDarkMode: isDarkMode,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Harga Jual / Close', labelTextColor),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _hargaCloseController,
                            hintText: '2655.00',
                            textColor: primaryTextColor,
                            inputFillColor: inputFillColor,
                            borderColor: borderColor,
                            readOnly: _isAutoPriceEnabled,
                            isDarkMode: isDarkMode,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Fee + Pajak
                _buildLabel('Fee + Pajak (Fixed)', labelTextColor),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF252525)
                        : const Color(0xFFF8F8FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rp 333.000 / Lot',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[700],
                        ),
                      ),
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Tombol Hapus & Hitung
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
                            backgroundColor: Colors.transparent,
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
                                    : const Color(0xFFF1F1F5)),
                            elevation: _hasInput ? 2 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _hasInput ? _calculateGoldDigital : null,
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

          // Result Card
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
                      Icons.check_circle_rounded,
                      color: Color(0xFF00C853),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hasil Akhir (Netto)',
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
                        !_isCalculated || _hasilNetto == null
                            ? 'Rp 0'
                            : '${_hasilNetto! < 0 ? '-Rp ' : 'Rp '}${_formatCurrency(_hasilNetto!)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: _isCalculated && _hasilNetto != null
                              ? (_hasilNetto! >= 0
                                  ? const Color(0xFF00C853)
                                  : const Color(0xFFFF3B30))
                              : primaryTextColor,
                        ),
                      ),
                      if (_isCalculated &&
                          _hasilNetto != null &&
                          _selisihPoint != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Selisih Point: ${_selisihPoint!.toStringAsFixed(2)} pt',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _hasilNetto! >= 0
                                  ? Icons.north_east_rounded
                                  : Icons.south_east_rounded,
                              color: _hasilNetto! >= 0
                                  ? const Color(0xFF00C853)
                                  : const Color(0xFFFF3B30),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _hasilNetto! >= 0 ? 'Profit Netto' : 'Rugi Netto',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _hasilNetto! >= 0
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

  Widget _buildPositionSegmentButton({
    required PositionType type,
    required String label,
    required Color activeColor,
    required bool isDarkMode,
  }) {
    final isSelected = _selectedPosition == type;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPosition = type);
        if (_hargaOpenController.text.isNotEmpty &&
            _hargaCloseController.text.isNotEmpty) {
          _calculateGoldDigital();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? Colors.white
                : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLotButton(
    String label,
    String value,
    Color activeColor,
    bool isDarkMode,
  ) {
    final isSelected = _lotController.text == value;
    return InkWell(
      onTap: () => _setLotPreset(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDarkMode ? Colors.grey[300] : Colors.grey[700]),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color textColor) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
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
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*')),
      ],
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: readOnly ? Colors.grey : textColor,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.plusJakartaSans(
          color: Colors.grey[400],
          fontSize: 14,
        ),
        filled: true,
        fillColor: readOnly
            ? (isDarkMode
                ? const Color(0xFF222222)
                : const Color(0xFFEEEEEE))
            : inputFillColor,
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