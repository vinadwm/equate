import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:equate/model/kurs_model.dart';
import 'package:equate/view/auth/auth_glass_widgets.dart';
import 'package:equate/viewmodel/kurs_viewmodel.dart';
import 'package:equate/viewmodel/language_viewmodel.dart';

class KursCard extends StatefulWidget {
  final bool isDark;

  const KursCard({super.key, required this.isDark});

  @override
  State<KursCard> createState() => _KursCardState();
}

class _KursCardState extends State<KursCard>
    with SingleTickerProviderStateMixin {
  final KursViewModel _vm = KursViewModel();
  late final AnimationController _blink;

  /// false = tampilan ringkas (default), true = pilihan mata uang,
  /// rentang waktu, grafik interaktif & detail ditampilkan.
  bool _expanded = false;

  static const _green = Color(0xFF4CAF50);
  static const _red = Color(0xFFEF5350);

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _vm.start();
  }

  @override
  void dispose() {
    _blink.dispose();
    _vm.dispose();
    super.dispose();
  }

  String get _locale => LanguageViewModel.isEnglish ? 'en_US' : 'id_ID';

  String _fmt(double v) => NumberFormat('#,##0.00', _locale).format(v);

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final t = AuthTokens(isDark);

    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final s = _vm.series;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.10)
                  : Colors.white.withOpacity(0.7),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.20 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(t, s),
                const SizedBox(height: 10),
                if (s == null && _vm.isLoading)
                  _placeholder(
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: kAuthOrange,
                        strokeWidth: 2.2,
                      ),
                    ),
                  )
                else if (s == null)
                  _errorView(t)
                else ...[
                  _rateRow(t, s),
                  if (_expanded) ...[
                    const SizedBox(height: 12),
                    _pairChips(t),
                    const SizedBox(height: 12),
                    SizedBox(height: 96, child: _chart(t, s, interactive: true)),
                    const SizedBox(height: 10),
                    _rangeButtons(t),
                    const SizedBox(height: 10),
                    _footer(t, s),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- HEADER ----------------
  Widget _header(AuthTokens t, KursSeries? s) {
    final live = s?.isLive ?? true;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kAuthOrange.withOpacity(0.12),
          ),
          child: const Icon(
            Icons.currency_exchange_rounded,
            size: 14,
            color: kAuthOrange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            tr('Kurs Rupiah', 'Rupiah Rate'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: t.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: kAuthOrange.withOpacity(0.12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: live
                    ? Tween(begin: 0.25, end: 1.0).animate(_blink)
                    : const AlwaysStoppedAnimation(1.0),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: kAuthOrange,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                live ? 'LIVE' : tr('HARIAN', 'DAILY'),
                style: GoogleFonts.poppins(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: kAuthOrange,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        // Tombol buka / sembunyikan opsi
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _expanded
                  ? kAuthOrange.withOpacity(0.16)
                  : t.fieldFill,
            ),
            child: AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 260),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: _expanded ? kAuthOrange : t.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- PILIH MATA UANG (hanya saat dibuka) ----------------
  Widget _pairChips(AuthTokens t) {
    return SizedBox(
      height: 28,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: kKursBases.map((b) {
          final selected = _vm.base == b;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => _vm.selectBase(b),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: selected
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            kAuthOrangeSoft,
                            kAuthOrange,
                            kAuthOrangeDeep,
                          ],
                        )
                      : null,
                  color: selected ? null : t.fieldFill,
                  border: Border.all(
                    color: selected
                        ? Colors.white.withOpacity(0.45)
                        : t.fieldBorder,
                  ),
                ),
                child: Text(
                  '$b/IDR',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : t.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------- NILAI KURS (+ sparkline saat ringkas) ----------------
  Widget _rateRow(AuthTokens t, KursSeries s) {
    final up = s.change >= 0;
    final color = up ? _green : _red;
    final sign = up ? '+' : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1 ${s.base} =',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: t.textSecondary,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Rp ${_fmt(s.current)}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    height: 1.2,
                    color: t.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: color.withOpacity(0.12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      up
                          ? Icons.arrow_drop_up_rounded
                          : Icons.arrow_drop_down_rounded,
                      size: 16,
                      color: color,
                    ),
                    Text(
                      '$sign${s.changePercent.toStringAsFixed(2)}%',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!_expanded) ...[
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: SizedBox(height: 52, child: _chart(t, s, interactive: false)),
          ),
        ],
      ],
    );
  }

  // ---------------- KURVA ----------------
  Widget _chart(AuthTokens t, KursSeries s, {required bool interactive}) {
    final up = s.change >= 0;
    final color = up ? _green : _red;

    final low = s.low;
    final high = s.high;
    final pad = (high - low) == 0 ? 1.0 : (high - low) * 0.12;

    final spots = List.generate(
      s.points.length,
      (i) => FlSpot(i.toDouble(), s.points[i].rate),
    );

    final timeFmt = s.isLive && _vm.range == KursRange.day
        ? DateFormat('HH:mm')
        : DateFormat('d MMM HH:mm', _locale);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (s.points.length - 1).toDouble(),
        minY: low - pad,
        maxY: high + pad,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: LineTouchData(
          enabled: interactive,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touched) {
              return touched.map((spot) {
                final p = s.points[spot.spotIndex];
                return LineTooltipItem(
                  '${_fmt(p.rate)}\n${timeFmt.format(p.time)}',
                  GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.2,
            color: color,
            barWidth: interactive ? 2.2 : 1.8,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withOpacity(0.22), color.withOpacity(0.0)],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 250),
    );
  }

  // ---------------- PILIHAN RENTANG (hanya saat dibuka) ----------------
  Widget _rangeButtons(AuthTokens t) {
    final options = [
      (KursRange.day, tr('Hari ini', 'Today')),
      (KursRange.week, tr('7H', '7D')),
      (KursRange.month, tr('1B', '1M')),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: options.map((o) {
          final selected = _vm.range == o.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => _vm.selectRange(o.$1),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: selected
                      ? const LinearGradient(
                          colors: [Color(0xFFFFB700), Color(0xFFFF9500)],
                        )
                      : null,
                ),
                child: Center(
                  child: Text(
                    o.$2,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? Colors.white : t.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------- FOOTER (hanya saat dibuka) ----------------
  Widget _footer(AuthTokens t, KursSeries s) {
    final updated = _vm.lastUpdated == null
        ? '-'
        : DateFormat('HH:mm:ss').format(_vm.lastUpdated!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Low ${_fmt(s.low)}',
              style: GoogleFonts.poppins(fontSize: 9.5, color: _red),
            ),
            const SizedBox(width: 12),
            Text(
              'High ${_fmt(s.high)}',
              style: GoogleFonts.poppins(fontSize: 9.5, color: _green),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          tr(
            'Diperbarui $updated • Sumber: ${s.source}',
            'Updated $updated • Source: ${s.source}',
          ),
          style: GoogleFonts.poppins(fontSize: 9, color: t.textSecondary),
        ),
        if (!s.isLive) ...[
          const SizedBox(height: 2),
          Text(
            tr(
              'Data live tidak tersedia, menampilkan kurs referensi harian.',
              'Live data unavailable, showing daily reference rates.',
            ),
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontStyle: FontStyle.italic,
              color: t.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _placeholder(Widget child) {
    return SizedBox(height: 64, child: Center(child: child));
  }

  Widget _errorView(AuthTokens t) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 22, color: t.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tr('Kurs tidak dapat dimuat', 'Rates could not be loaded'),
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: t.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _vm.load(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              tr('Coba Lagi', 'Try Again'),
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: kAuthOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}