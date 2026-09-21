import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:equate/viewmodel/historical_data_viewmodel.dart';
import 'package:equate/viewmodel/nest_gold_viewmodel.dart';
import 'package:equate/model/nest_gold_model.dart';

class NestGoldCalculatorContent extends StatefulWidget {
  final HistoricalDataViewModel historicalDataViewModel;

  const NestGoldCalculatorContent({
    super.key,
    required this.historicalDataViewModel,
  });

  @override
  State<NestGoldCalculatorContent> createState() =>
      _NestGoldCalculatorContentState();
}

class _NestGoldCalculatorContentState extends State<NestGoldCalculatorContent> {
  final TextEditingController _closeController = TextEditingController();

  final TextEditingController _openController = TextEditingController();

  late final NestGoldViewModel _viewModel;

  bool _syncingControllers = false;
  bool _hasInput = false;

  @override
  void initState() {
    super.initState();

    _viewModel = NestGoldViewModel(
      historicalDataViewModel: widget.historicalDataViewModel,
    );

    _viewModel.addListener(_onViewModelChanged);

    _closeController.addListener(_onCloseChanged);
    _openController.addListener(_onOpenChanged);

    _syncControllers();
    _updateInputState();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);

    _closeController.removeListener(_onCloseChanged);
    _openController.removeListener(_onOpenChanged);

    _closeController.dispose();
    _openController.dispose();

    _viewModel.dispose();

    super.dispose();
  }

  // ============================================================
  // VIEWMODEL LISTENER
  // ============================================================

  void _onViewModelChanged() {
    if (!mounted) return;

    _syncControllers();
    _updateInputState();

    setState(() {});
  }

  // ============================================================
  // SYNC CONTROLLER
  // ============================================================

  void _syncControllers() {
    _syncingControllers = true;

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

  // ============================================================
  // INPUT LISTENER
  // ============================================================

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

  // ============================================================
  // INPUT STATE
  // ============================================================

  void _updateInputState() {
    final hasText =
        _closeController.text.trim().isNotEmpty ||
        _openController.text.trim().isNotEmpty;

    if (mounted && hasText != _hasInput) {
      setState(() {
        _hasInput = hasText;
      });
    }
  }

  // ============================================================
  // HITUNG
  // ============================================================

  void _calculateNest() {
    final success = _viewModel.calculateNest();

    if (!success) {
      _showSnackBar(
        _viewModel.errorMessage ?? 'Harap masukkan data yang valid.',
        backgroundColor: Colors.red,
      );

      return;
    }

    setState(() {});
  }

  // ============================================================
  // RESET
  // ============================================================

  void _resetForm() {
    _viewModel.reset();

    _syncControllers();
    _updateInputState();

    setState(() {});
  }

  // ============================================================
  // REFRESH
  // ============================================================

  void _refreshData() {
    final success = _viewModel.refreshData();

    if (success) {
      _showSnackBar(
        'Data Nest Gold berhasil diperbarui.',
        backgroundColor: const Color(0xFF18B85A),
      );
    } else {
      _showSnackBar(
        _viewModel.errorMessage ?? 'Data Nest Gold belum tersedia.',
        backgroundColor: Colors.red,
      );
    }
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFFF9E0F);
    const buyColor = Color(0xFF18B85A);
    const sellColor = Color(0xFFFF3B30);

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

    final signal = _viewModel.signal;

    Color signalColor;

    switch (signal) {
      case NestGoldSignal.buy:
        signalColor = buyColor;
        break;

      case NestGoldSignal.sell:
        signalColor = sellColor;
        break;

      case NestGoldSignal.neutral:
        signalColor = primaryOrange;
        break;

      case NestGoldSignal.unavailable:
        signalColor = Colors.grey;
        break;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // ======================================================
          // PENJELASAN NEST
          // ======================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF252525)
                  : const Color(0xFFFFF8EA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryOrange.withOpacity(0.55)),
            ),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  height: 1.55,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
                children: const [
                  TextSpan(
                    text: 'Nest ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text:
                        'adalah konsep Follow The Trend yang '
                        'mengacu pada harga penutupan (Close).\n',
                  ),
                  TextSpan(
                    text: 'Close > Open ',
                    style: TextStyle(
                      color: primaryOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: '(Buy)\n'),
                  TextSpan(
                    text: 'Close < Open ',
                    style: TextStyle(
                      color: primaryOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: '(Sell)'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ======================================================
          // INPUT CARD
          // ======================================================
          Container(
            width: double.infinity,
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
                // HEADER
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
                            'Data Nest Emas',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: primaryTextColor,
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            _viewModel.yesterdayGoldData != null
                                ? 'Gold • '
                                      '${_viewModel.previousDate.day.toString().padLeft(2, '0')}/'
                                      '${_viewModel.previousDate.month.toString().padLeft(2, '0')}/'
                                      '${_viewModel.previousDate.year}'
                                : 'Menunggu data Gold...',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),

                    TextButton(
                      onPressed: _refreshData,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Refresh',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: primaryOrange,
                        ),
                      ),
                    ),
                  ],
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
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: primaryOrange,
                      ),

                      const SizedBox(width: 7),

                      Expanded(
                        child: Text(
                          'Open otomatis diambil dari data Gold hari ini '
                          'dan Close dari data Gold hari sebelumnya. '
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
                // SUMBER INPUT
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
                // INPUT CLOSE + OPEN
                // ==================================================
                Row(
                  children: [
                    Expanded(
                      child: _buildInput(
                        label: 'Close',
                        subtitle: 'Kemarin',
                        controller: _closeController,
                        textColor: primaryTextColor,
                        fillColor: inputFillColor,
                        borderColor: borderColor,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: _buildInput(
                        label: 'Open',
                        subtitle: 'Hari ini',
                        controller: _openController,
                        textColor: primaryTextColor,
                        fillColor: inputFillColor,
                        borderColor: borderColor,
                      ),
                    ),
                  ],
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
                          onPressed: _hasInput ? _calculateNest : null,
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
          // HASIL
          // ======================================================
          Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: signal == NestGoldSignal.unavailable
                          ? Colors.grey
                          : signalColor,
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

                Divider(height: 1, color: dividerColor),

                const SizedBox(height: 16),

                if (_viewModel.isCalculated) ...[
                  Center(
                    child: Text(
                      _viewModel.signalLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: signalColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Center(
                    child: Text(
                      _viewModel.signalDescription,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ] else ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      child: Text(
                        'Belum ada hasil',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ======================================================
          // STATUS DATA
          // ======================================================
          if (_viewModel.errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.15)),
              ),
              child: Text(
                _viewModel.errorMessage!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // INPUT WIDGET
  // ============================================================

  Widget _buildInput({
    required String label,
    required String subtitle,
    required TextEditingController controller,
    required Color textColor,
    required Color fillColor,
    required Color borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),

            const SizedBox(width: 4),

            Text(
              '($subtitle)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        TextField(
          controller: controller,
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
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 9,
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
}
