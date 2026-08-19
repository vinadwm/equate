import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CalculatorTabView extends StatefulWidget {
  const CalculatorTabView({super.key});

  @override
  State<CalculatorTabView> createState() => _CalculatorTabViewState();
}

class _CalculatorTabViewState extends State<CalculatorTabView> {
  // Index Tab Active (0 = Perhitungan Emas, 1 = Pivot Point)
  int _selectedTabIndex = 0;

  // Controller untuk Perhitungan Emas
  final _modalController = TextEditingController();
  final _hargaBeliController = TextEditingController();
  final _hargaJualController = TextEditingController();

  // Controller untuk Pivot Point
  final _hargaTertinggiController = TextEditingController();
  final _hargaTerendahController = TextEditingController();
  final _hargaPenutupanController = TextEditingController();

  // State Hasil Emas
  bool _hasCalculatedEmas = false;
  double _hasilEmas = 0;

  // State Hasil Pivot
  bool _hasCalculatedPivot = false;
  double _hasilPivot = 0.0;

  // Format Currency (Rupiah)
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Method Hitung Emas
  void _calculateEmas() {
    final modal =
        double.tryParse(
          _modalController.text.replaceAll('.', '').replaceAll(',', '.'),
        ) ??
        0;
    final hargaBeli =
        double.tryParse(
          _hargaBeliController.text.replaceAll('.', '').replaceAll(',', '.'),
        ) ??
        0;
    final hargaJual =
        double.tryParse(
          _hargaJualController.text.replaceAll('.', '').replaceAll(',', '.'),
        ) ??
        0;

    // Logika perhitungan keuntungan/kerugian
    // Contoh sederhana: (Harga Jual - Harga Beli) atau dikalikan gramatur modal
    // Di sini disimulasikan nilai selisih murni
    setState(() {
      _hasilEmas = hargaJual - hargaBeli;
      // Jika menggunakan modal dalam rupiah:
      if (modal > 0 && hargaBeli > 0) {
        double gram = modal / hargaBeli;
        _hasilEmas = (hargaJual - hargaBeli) * gram;
      }
      _hasCalculatedEmas = true;
    });
  }

  // Method Hitung Pivot Point
  void _calculatePivot() {
    final high =
        double.tryParse(_hargaTertinggiController.text.replaceAll(',', '.')) ??
        0;
    final low =
        double.tryParse(_hargaTerendahController.text.replaceAll(',', '.')) ??
        0;
    final close =
        double.tryParse(_hargaPenutupanController.text.replaceAll(',', '.')) ??
        0;

    setState(() {
      // Rumus Standar Pivot Point = (High + Low + Close) / 3
      _hasilPivot = (high + low + close) / 3;
      _hasCalculatedPivot = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFFF9800);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'KALKULATOR',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // ==========================================
            // 1. CUSTOM TAB SWITCHER
            // ==========================================
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 0
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: _selectedTabIndex == 0
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            'PERHITUNGAN EMAS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _selectedTabIndex == 0
                                  ? primaryOrange
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 1
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: _selectedTabIndex == 1
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            'PIVOT POINT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _selectedTabIndex == 1
                                  ? primaryOrange
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ==========================================
            // 2. INPUT FORM CARD
            // ==========================================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header Form
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryOrange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.bar_chart_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Masukkan Data',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Dynamic Fields Based on Selected Tab
                  if (_selectedTabIndex == 0) ...[
                    _buildInputField('Modal', 'Rp 0', _modalController),
                    const SizedBox(height: 14),
                    _buildInputField(
                      'Harga Beli',
                      '0,00',
                      _hargaBeliController,
                    ),
                    const SizedBox(height: 14),
                    _buildInputField(
                      'Harga Jual',
                      '0,00',
                      _hargaJualController,
                    ),
                  ] else ...[
                    _buildInputField(
                      'Harga Tertinggi',
                      '0,00',
                      _hargaTertinggiController,
                    ),
                    const SizedBox(height: 14),
                    _buildInputField(
                      'Harga Terendah',
                      '0,00',
                      _hargaTerendahController,
                    ),
                    const SizedBox(height: 14),
                    _buildInputField(
                      'Harga Penutupan',
                      '0,00',
                      _hargaPenutupanController,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Button Hitung
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _selectedTabIndex == 0
                          ? _calculateEmas
                          : _calculatePivot,
                      child: const Text(
                        'HITUNG',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==========================================
            // 3. RESULT CARD
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _selectedTabIndex == 0
                  ? _buildResultEmas()
                  : _buildResultPivot(),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Reusable Textfield
  Widget _buildInputField(
    String label,
    String placeholder,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: const Color(0xFFF8F8FA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
          ),
        ),
      ],
    );
  }

  // View Hasil - Perhitungan Emas
  Widget _buildResultEmas() {
    bool isUntung = _hasilEmas >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hasil',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              Text(
                !_hasCalculatedEmas
                    ? 'Rp 0'
                    : isUntung
                    ? _currencyFormat.format(_hasilEmas)
                    : '-Rp ${_currencyFormat.format(_hasilEmas.abs()).replaceAll('Rp ', '')}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              if (_hasCalculatedEmas) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isUntung
                            ? const Color(0xFF2EC4B6).withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isUntung
                            ? Icons.north_east_rounded
                            : Icons.south_west_rounded,
                        color: isUntung
                            ? const Color(0xFF2EC4B6)
                            : const Color(0xFFFF4D4D),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isUntung ? 'Untung' : 'Rugi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isUntung
                            ? const Color(0xFF2EC4B6)
                            : const Color(0xFFFF4D4D),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // View Hasil - Pivot Point
  Widget _buildResultPivot() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.check_circle, color: Color(0xFF2EC4B6), size: 20),
            SizedBox(width: 8),
            Text(
              'Hasil',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            !_hasCalculatedPivot
                ? '0,00'
                : _hasilPivot.toStringAsFixed(2).replaceAll('.', ','),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
