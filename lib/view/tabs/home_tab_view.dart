import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:equate/viewmodel/theme_viewmodel.dart';

class HomeTabView extends StatelessWidget {
  const HomeTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeViewModel.themeMode,
      builder: (context, currentThemeMode, child) {
        final isDarkMode = ThemeViewModel.isDarkMode;
        const primaryOrange = Color(0xFFFF9800);

        // Definisi Warna Dinamis
        final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
        final cardBgColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
        final borderColor = isDarkMode ? Colors.grey[800]! : const Color(0xFFF0F0F0);
        final primaryTextColor = isDarkMode ? Colors.white : Colors.black87;
        final secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ================= HEADER =================
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryOrange, width: 1.5),
                        ),
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage('https://i.pravatar.cc/100'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Halo, Aleesha',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: primaryOrange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ================= LAST PRICE CARD =================
                  _buildLastPriceCard(
                    isDarkMode: isDarkMode,
                    cardBgColor: cardBgColor,
                    borderColor: borderColor,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                  ),

                  const SizedBox(height: 16),

                  // ================= DATE PICKER =================
                  _buildDatePicker(
                    primaryOrange: primaryOrange,
                    isDarkMode: isDarkMode,
                    cardBgColor: cardBgColor,
                    borderColor: isDarkMode ? Colors.grey[800]! : const Color(0xFFE0E0E0),
                    textColor: primaryTextColor,
                  ),

                  const SizedBox(height: 16),

                  // ================= METRICS GRID =================
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Open',
                          value: '4410.76',
                          icon: Icons.wb_sunny_outlined,
                          iconBgColor: isDarkMode ? const Color(0xFF332A00) : const Color(0xFFFFFDE7),
                          iconColor: Colors.amber[700]!,
                          valueColor: primaryTextColor,
                          cardBgColor: cardBgColor,
                          borderColor: borderColor,
                          secondaryTextColor: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Close',
                          value: '4415.10',
                          icon: Icons.nightlight_round_outlined,
                          iconBgColor: isDarkMode ? const Color(0xFF2C3E50) : const Color(0xFF1E293B),
                          iconColor: Colors.amber,
                          valueColor: primaryTextColor,
                          cardBgColor: cardBgColor,
                          borderColor: borderColor,
                          secondaryTextColor: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'High',
                          value: '4436.07',
                          icon: Icons.trending_up,
                          iconBgColor: isDarkMode ? const Color(0xFF1B3E20) : const Color(0xFFE8F5E9),
                          iconColor: const Color(0xFF4CAF50),
                          valueColor: const Color(0xFF4CAF50),
                          cardBgColor: cardBgColor,
                          borderColor: borderColor,
                          secondaryTextColor: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Low',
                          value: '4386.03',
                          icon: Icons.trending_down,
                          iconBgColor: isDarkMode ? const Color(0xFF3E1A1A) : const Color(0xFFFFEBEE),
                          iconColor: const Color(0xFFEF5350),
                          valueColor: const Color(0xFFEF5350),
                          cardBgColor: cardBgColor,
                          borderColor: borderColor,
                          secondaryTextColor: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ================= TREND ANALYSIS =================
                  _buildTrendAnalysisCard(
                    primaryOrange: primaryOrange,
                    isDarkMode: isDarkMode,
                    cardBgColor: cardBgColor,
                    borderColor: borderColor,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Card Last Price
  Widget _buildLastPriceCard({
    required bool isDarkMode,
    required Color cardBgColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: isDarkMode
              ? [
                  cardBgColor,
                  cardBgColor,
                  const Color(0xFF332200), // Gradient Oranye Gelap di Dark Mode
                ]
              : [
                  Colors.white,
                  Colors.white,
                  const Color(0xFFFFF8E1),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LAST PRICE',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '4396.43',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1B3E20) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '↑ 1.24%',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: isDarkMode ? Colors.grey[800] : const Color(0xFFEEEEEE)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text('Bid', style: GoogleFonts.poppins(color: secondaryTextColor, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text('4396.43', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: primaryTextColor)),
                ],
              ),
              const Icon(Icons.trending_down, color: Color(0xFFEF5350), size: 18),
              Container(width: 1, height: 24, color: isDarkMode ? Colors.grey[800] : const Color(0xFFEEEEEE)),
              const Icon(Icons.trending_up, color: Color(0xFF4CAF50), size: 18),
              Column(
                children: [
                  Text('Ask', style: GoogleFonts.poppins(color: secondaryTextColor, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text('4396.81', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: primaryTextColor)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Button Date Picker
  Widget _buildDatePicker({
    required Color primaryOrange,
    required bool isDarkMode,
    required Color cardBgColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: textColor, size: 18),
              const SizedBox(width: 12),
              Text(
                '18 Agustus 2026',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: primaryOrange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  // Card Metric (Open, Close, High, Low)
  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required Color valueColor,
    required Color cardBgColor,
    required Color borderColor,
    required Color secondaryTextColor,
  }) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: secondaryTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
        ),
      ],
    );
  }

  // Card Trend Analysis
  Widget _buildTrendAnalysisCard({
    required Color primaryOrange,
    required bool isDarkMode,
    required Color cardBgColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trend Analysis',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryTextColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildTimeFilter('1D', false, primaryOrange, isDarkMode),
                    _buildTimeFilter('1W', true, primaryOrange, isDarkMode),
                    _buildTimeFilter('1M', false, primaryOrange, isDarkMode),
                    _buildTimeFilter('1Y', false, primaryOrange, isDarkMode),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(
              painter: AreaChartPainter(primaryOrange: primaryOrange, isDarkMode: isDarkMode),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
                .map((day) => Text(
                      day,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilter(String label, bool isSelected, Color primaryOrange, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDarkMode ? const Color(0xFF3A3A3A) : Colors.white)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? primaryOrange : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        ),
      ),
    );
  }
}

// Custom Painter Grafik dengan Dukungan Dark Mode
class AreaChartPainter extends CustomPainter {
  final Color primaryOrange;
  final bool isDarkMode;

  AreaChartPainter({required this.primaryOrange, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Gambar Garis Grid Horizontal
    final gridPaint = Paint()
      ..color = isDarkMode ? Colors.grey[800]! : const Color(0xFFEEEEEE)
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(0, size.height * 0.25), Offset(size.width, size.height * 0.25), gridPaint);
    canvas.drawLine(Offset(0, size.height * 0.55), Offset(size.width, size.height * 0.55), gridPaint);
    canvas.drawLine(Offset(0, size.height * 0.85), Offset(size.width, size.height * 0.85), gridPaint);

    // 2. Path Kurva Grafik
    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.cubicTo(
      size.width * 0.25, size.height * 0.8,
      size.width * 0.35, size.height * 0.5,
      size.width * 0.55, size.height * 0.45,
    );
    path.cubicTo(
      size.width * 0.75, size.height * 0.4,
      size.width * 0.8, size.height * 0.1,
      size.width, size.height * 0.12,
    );

    // 3. Area Fill Gradient
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryOrange.withOpacity(0.4),
          primaryOrange.withOpacity(0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // 4. Garis Utama Kurva
    final strokePaint = Paint()
      ..color = primaryOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}