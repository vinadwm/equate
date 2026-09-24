import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:equate/model/base_calculation_history.dart';

import '../../model/calculation_history_model.dart';
import '../../model/digital_gold_model.dart';
import '../../model/nest_gold_model.dart';
import '../../model/nest_hangseng_model.dart';
import '../../model/physical_gold_model.dart';
import '../../model/pivot_gold_model.dart';
import '../../model/pivot_hangseng_model.dart';


class HistoryDetailSheet extends StatelessWidget {
  final dynamic item;
  final bool isDarkMode;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color primaryOrange;

  const HistoryDetailSheet({
    super.key,
    required this.item,
    required this.isDarkMode,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.primaryOrange,
  });

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // Helper extractor data header dan ringkasan
  Map<String, dynamic> _getHeaderInfo() {
    String title = 'Detail Riwayat';
    String category = 'Kalkulasi';
    DateTime timestamp = DateTime.now();
    double result = 0.0;
    bool isCurrency = true;

    if (item is DigitalGoldModel) {
      final data = item as DigitalGoldModel;
      title = 'Emas Digital';
      category = 'Emas';
      result = data.profitLoss;
    } else if (item is PhysicalGoldModel) {
      final data = item as PhysicalGoldModel;
      title = 'Emas Fisik';
      category = 'Emas';
      result = data.profitLoss;
    } else if (item is PivotGoldModel) {
      final data = item as PivotGoldModel;
      title = 'Pivot Gold (${data.type})';
      category = 'Pivot';
      result = data.pp;
      isCurrency = false;
    } else if (item is NestGoldModel) {
      final data = item as NestGoldModel;
      title = 'NEST Gold';
      category = 'NEST';
      result = data.close ?? 0.0;
      isCurrency = false;
    } else if (item is PivotHangsengModel) {
      final data = item as PivotHangsengModel;
      title = 'Pivot Hangseng';
      category = 'Pivot';
      result = data.pp ?? 0.0;
      isCurrency = false;
    } else if (item is NestHangsengModel) {
      final data = item as NestHangsengModel;
      title = 'NEST Hangseng';
      category = 'NEST';
      result = data.close ?? 0.0;
      isCurrency = false;
    } else if (item is CalculationHistory) {
      final data = item as CalculationHistory;
      title = data.title;
      category = data.category.isNotEmpty ? data.category : 'Umum';
      timestamp = data.createdAt;
      result = (data.result is num) ? (data.result as num).toDouble() : 0.0;
    } else {
      title = item.title?.toString() ?? 'Riwayat';
      category = item.category?.toString() ?? 'Umum';
      if (item.createdAt is DateTime) timestamp = item.createdAt;
      if (item.timestamp is DateTime) timestamp = item.timestamp;
      result = (item.result is num) ? (item.result as num).toDouble() : 0.0;
    }

    return {
      'title': title,
      'category': category,
      'timestamp': timestamp,
      'result': result,
      'isCurrency': isCurrency,
    };
  }

  @override
  Widget build(BuildContext context) {
    final info = _getHeaderInfo();
    final String title = info['title'];
    final String category = info['category'];
    final DateTime timestamp = info['timestamp'];
    final double result = info['result'];
    final bool isCurrency = info['isCurrency'];

    final formattedDate = DateFormat('dd MMMM yyyy, HH:mm').format(timestamp);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF18181B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Indicator
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: secondaryTextColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header Title & Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: primaryOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            formattedDate,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: secondaryTextColor,
            ),
          ),

          const Divider(height: 28),

          // Dynamic Section berdasarkan jenis Class Model
          if (item is DigitalGoldModel) ...[
            _buildDigitalGoldSection(item as DigitalGoldModel),
          ] else if (item is PhysicalGoldModel) ...[
            _buildPhysicalGoldSection(item as PhysicalGoldModel),
          ] else if (item is PivotGoldModel) ...[
            _buildPivotGoldSection(item as PivotGoldModel),
          ] else if (item is NestGoldModel) ...[
            _buildNestGoldSection(item as NestGoldModel),
          ] else if (item is PivotHangsengModel) ...[
            _buildPivotHangsengSection(item as PivotHangsengModel),
          ] else if (item is NestHangsengModel) ...[
            _buildNestHangsengSection(item as NestHangsengModel),
          ] else if (item is CalculationHistory) ...[
            _buildGenericHistorySection(item as CalculationHistory),
          ],

          const Divider(height: 28),

          // Ringkasan Hasil Akhir / Status Utama
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCurrency ? 'Total Profit/Rugi:' : 'Pivot Point / Nilai Utama:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              Text(
                isCurrency
                    ? _formatCurrency(result)
                    : result.toStringAsFixed(2),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: !isCurrency
                      ? primaryOrange
                      : (result >= 0 ? const Color(0xFF34C759) : const Color(0xFFFF3B30)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // --- SECTION BUILDERS ---

  Widget _buildDigitalGoldSection(DigitalGoldModel data) {
    return Column(
      children: [
        _buildRow('Berat Emas', '${data.weightInGram} Lot/Gram'),
        _buildRow('Harga Beli', _formatCurrency(data.buyPrice)),
        _buildRow('Harga Saat Ini', _formatCurrency(data.currentPrice)),
        _buildRow(
          'Estimasi Profit/Rugi',
          _formatCurrency(data.profitLoss),
          valueColor: data.profitLoss >= 0 ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildPhysicalGoldSection(PhysicalGoldModel data) {
    return Column(
      children: [
        _buildRow('Berat Emas', '${data.weightInGram} gram'),
        _buildRow('Harga Beli / Gram', _formatCurrency(data.buyPrice)),
        _buildRow('Harga Buyback / Gram', _formatCurrency(data.currentPrice)),
        _buildRow(
          'Estimasi Profit/Rugi',
          _formatCurrency(data.profitLoss),
          valueColor: data.profitLoss >= 0 ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildPivotGoldSection(PivotGoldModel data) {
    return Column(
      children: [
        _buildRow('Tipe Calculation', data.type),
        _buildRow('High', data.high.toStringAsFixed(2)),
        _buildRow('Low', data.low.toStringAsFixed(2)),
        _buildRow('Close', data.close.toStringAsFixed(2)),
        const SizedBox(height: 6),
        _buildRow('Pivot Point (PP)', data.pp.toStringAsFixed(2), isBold: true, valueColor: primaryOrange),
        _buildRow('Resistance 1 (R1)', data.r1.toStringAsFixed(2)),
        _buildRow('Support 1 (S1)', data.s1.toStringAsFixed(2)),
        if (data.r2 != null) _buildRow('Resistance 2 (R2)', data.r2!.toStringAsFixed(2)),
        if (data.s2 != null) _buildRow('Support 2 (S2)', data.s2!.toStringAsFixed(2)),
      ],
    );
  }

  Widget _buildNestGoldSection(NestGoldModel data) {
    return Column(
      children: [
        _buildRow('Sinyal', data.signalLabel, isBold: true, valueColor: primaryOrange),
        _buildRow('Harga Open', data.open != null ? data.open!.toStringAsFixed(2) : '-'),
        _buildRow('Harga High', data.high != null ? data.high!.toStringAsFixed(2) : '-'),
        _buildRow('Harga Low', data.low != null ? data.low!.toStringAsFixed(2) : '-'),
        _buildRow('Harga Close', data.close != null ? data.close!.toStringAsFixed(2) : '-'),
      ],
    );
  }

  Widget _buildPivotHangsengSection(PivotHangsengModel data) {
    return Column(
      children: [
        _buildRow('High', data.high != null ? data.high!.toStringAsFixed(2) : '-'),
        _buildRow('Low', data.low != null ? data.low!.toStringAsFixed(2) : '-'),
        _buildRow('Close', data.close != null ? data.close!.toStringAsFixed(2) : '-'),
        const SizedBox(height: 6),
        _buildRow('Pivot Point (PP)', data.pp != null ? data.pp!.toStringAsFixed(2) : '-', isBold: true, valueColor: primaryOrange),
        _buildRow('R1', data.r1 != null ? data.r1!.toStringAsFixed(2) : '-'),
        _buildRow('S1', data.s1 != null ? data.s1!.toStringAsFixed(2) : '-'),
      ],
    );
  }

  Widget _buildNestHangsengSection(NestHangsengModel data) {
    return Column(
      children: [
        _buildRow('Sinyal', data.signalLabel, isBold: true, valueColor: primaryOrange),
        _buildRow('Harga Open', data.open != null ? data.open!.toStringAsFixed(2) : '-'),
        _buildRow('Harga High', data.high != null ? data.high!.toStringAsFixed(2) : '-'),
        _buildRow('Harga Low', data.low != null ? data.low!.toStringAsFixed(2) : '-'),
        _buildRow('Harga Close', data.close != null ? data.close!.toStringAsFixed(2) : '-'),
      ],
    );
  }

  Widget _buildGenericHistorySection(CalculationHistory data) {
    return Column(
      children: data.details.entries.map((entry) {
        return _buildRow(entry.key, entry.value.toString());
      }).toList(),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: secondaryTextColor,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}