import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:equate/viewmodel/historical_data_viewmodel.dart';
import 'package:equate/viewmodel/nest_hangseng_viewmodel.dart';
import 'package:equate/model/nest_hangseng_model.dart';
import 'package:equate/model/base_calculation_history.dart';

class NestHangsengCalculatorContent extends StatefulWidget {
  final HistoricalDataViewModel historicalDataViewModel;
  final ValueChanged<CalculationHistory>? onCalculate;

  const NestHangsengCalculatorContent({
    super.key,
    required this.historicalDataViewModel,
    this.onCalculate,
  });

  @override
  State<NestHangsengCalculatorContent> createState() =>
      _NestHangsengCalculatorContentState();
}

class _NestHangsengCalculatorContentState
    extends State<NestHangsengCalculatorContent> {
  final TextEditingController _closeController = TextEditingController();

  final TextEditingController _openController = TextEditingController();

  late final NestHangsengViewModel _viewModel;

  bool _syncingControllers = false;
  bool _hasInput = false;

  @override
  void initState() {
    super.initState();

    _viewModel = NestHangsengViewModel(
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

    final resultModel = _viewModel.buildResultModel();

    if (resultModel != null) {
      widget.onCalculate?.call(resultModel);

      _showSnackBar(
        'Hasil Nest Hangseng tersimpan ke riwayat.',
        backgroundColor: const Color(0xFF18B85A),
      );
    }

    setState(() {});
  }

  void _resetForm() {
    _viewModel.reset();

    _syncControllers();
    _updateInputState();

    setState(() {});
  }

  void _refreshData() {
    final success = _viewModel.refreshData();

    if (success) {
      _showSnackBar(
        'Data Nest Hangseng berhasil diperbarui.',
        backgroundColor: const Color(0xFF18B85A),
      );
    } else {
      _showSnackBar(
        _viewModel.errorMessage ?? 'Data Nest Hangseng belum tersedia.',
        backgroundColor: Colors.red,
      );
    }
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  String _fmt(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');

    return '$d/$m/${date.year}';
  }

  Color _signalColor(NestHangsengSignal signal) {
    switch (signal) {
      case NestHangsengSignal.buy:
        return const Color(0xFF18B85A);

      case NestHangsengSignal.sell:
        return const Color(0xFFFF3B30);

      case NestHangsengSignal.neutral:
        return const Color(0xFFFF9E0F);

      case NestHangsengSignal.unavailable:
        return Colors.grey;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFFF9E0F);

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
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFEEEEEE);

    final signal = _viewModel.signal;
    final signalColor = _signalColor(signal);
    final autoMode = _viewModel.autoMode;

    final closeData = _viewModel.yesterdayHangsengData;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // ======================================================
          // PENJELASAN NEST
          // ======================================================
          _buildExplanationCard(
            isDarkMode: isDarkMode,
            primaryTextColor: primaryTextColor,
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
                  color: Colors.black.withValues(
                    alpha: isDarkMode ? 0.25 : 0.035,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // HEADER
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: primaryOrange.withValues(alpha: 0.12),
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
                            'Data Nest Hangseng',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: primaryTextColor,
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            closeData != null
                                ? 'Hangseng • Close ${_fmt(_viewModel.previousDataDisplayDate)}'
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
                        tooltip: 'Muat ulang data',
                        visualDensity: VisualDensity.compact,
                        onPressed: _refreshData,
                        icon: const Icon(
                          Icons.refresh_rounded,
                          size: 20,
                          color: primaryOrange,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // TOGGLE OTOMATIS / MANUAL
                _buildModeToggle(
                  isDarkMode: isDarkMode,
                  primaryTextColor: primaryTextColor,
                  borderColor: borderColor,
                ),

                const SizedBox(height: 8),

                // INFO
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
                          autoMode
                              ? 'Open diambil dari data Hangseng hari ini dan Close '
                                    'dari data hari sebelumnya. Matikan mode Otomatis '
                                    'jika ingin mengisi sendiri.'
                              : 'Mode Manual aktif. Isi Open dan Close sesuai kebutuhan, '
                                    'lalu tekan HITUNG.',
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

                // INPUT CLOSE + OPEN
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
                        readOnly: autoMode,
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
                        readOnly: autoMode,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // BUTTON
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
                  color: Colors.black.withValues(
                    alpha: isDarkMode ? 0.25 : 0.035,
                  ),
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
                    Icon(Icons.check_circle, color: signalColor, size: 18),

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

          // ======================================================
          // SARAN SETELAH HASIL
          // ======================================================
          if (_viewModel.isCalculated) ...[
            const SizedBox(height: 10),
            _buildRecommendationCard(
              signalColor: signalColor,
              cardBgColor: cardBgColor,
              borderColor: dividerColor,
              primaryTextColor: primaryTextColor,
              isDarkMode: isDarkMode,
            ),
          ],

          // ======================================================
          // STATUS DATA
          // ======================================================
          if (_viewModel.errorMessage != null) ...[
            const SizedBox(height: 8),
            _buildErrorBox(_viewModel.errorMessage!),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ============================================================
  // KARTU PENJELASAN NEST (RAMAH PEMULA)
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
        border: Border.all(color: primaryOrange.withValues(alpha: 0.55)),
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
                      'Apa itu Nest?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                      ),
                    ),
                    Text(
                      'Konsep Follow The Trend',
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
            'Nest adalah konsep Follow The Trend yang mengacu pada harga '
            'penutupan (Close). ',
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
                'Open',
                'Harga pertama saat pasar dibuka hari ini.',
                Icons.wb_sunny_rounded,
              ),
              const SizedBox(width: 8),
              term(
                'Close',
                'Harga terakhir saat pasar ditutup pada hari sebelumnya.',
                Icons.nightlight_round,
              ),
            ],
          ),

          const SizedBox(height: 14),

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
            condition: 'Close lebih tinggi dari Open',
            example:
                'Contoh: Close 18.500 dan Open 18.400 → BUY (harga cenderung naik).',
          ),

          rule(
            icon: Icons.trending_down_rounded,
            color: sellColor,
            label: 'SELL',
            condition: 'Close lebih rendah dari Open',
            example:
                'Contoh: Close 18.300 dan Open 18.400 → SELL (harga cenderung turun).',
          ),

          rule(
            icon: Icons.remove_rounded,
            color: primaryOrange,
            label: 'BUY/SELL',
            condition: 'Close sama dengan Open',
            example: 'Arah belum jelas, sebaiknya tunggu konfirmasi dulu.',
          ),

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
                    'Tips: saat weekend atau libur newsmaker tidak ada data baru, '
                    'jadi aplikasi otomatis memakai data terakhir yang tersedia.',
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
  // TOGGLE OTOMATIS / MANUAL
  // ============================================================

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
  // CATATAN FALLBACK (LIBUR / WEEKEND)
  // ============================================================

  Widget _buildNote(String text, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(
          0xFFFFA800,
        ).withValues(alpha: isDarkMode ? 0.12 : 0.1),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFFFFA800).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.event_busy_rounded,
            size: 15,
            color: Color(0xFFFFA800),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                height: 1.4,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
              ),
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
    final steps = _viewModel.recommendationSteps;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: signalColor.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.25 : 0.035),
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
                  color: signalColor.withValues(alpha: 0.12),
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
                      _viewModel.recommendationTitle,
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
                      color: signalColor.withValues(alpha: 0.14),
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
                        color: primaryTextColor.withValues(alpha: 0.85),
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
                  _viewModel.recommendationDisclaimer,
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

  Widget _buildErrorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
      ),
      child: Text(
        message,
        style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.red),
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
    required bool readOnly,
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
