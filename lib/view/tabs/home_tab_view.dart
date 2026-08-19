import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeTabView extends StatelessWidget {
  const HomeTabView({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFFF9800);

    return Scaffold(
      backgroundColor: Colors.white,
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
              _buildLastPriceCard(),

              const SizedBox(height: 16),

              // ================= DATE PICKER =================
              _buildDatePicker(primaryOrange),

              const SizedBox(height: 16),

              // ================= METRICS GRID =================
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Open',
                      value: '4410.76',
                      icon: Icons.wb_sunny_outlined,
                      iconBgColor: const Color(0xFFFFFDE7),
                      iconColor: Colors.amber[700]!,
                      valueColor: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Close',
                      value: '4415.10',
                      icon: Icons.nightlight_round_outlined,
                      iconBgColor: const Color(0xFF1E293B),
                      iconColor: Colors.amber,
                      valueColor: Colors.black87,
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
                      iconBgColor: const Color(0xFFE8F5E9),
                      iconColor: const Color(0xFF4CAF50),
                      valueColor: const Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Low',
                      value: '4386.03',
                      icon: Icons.trending_down,
                      iconBgColor: const Color(0xFFFFEBEE),
                      iconColor: const Color(0xFFEF5350),
                      valueColor: const Color(0xFFEF5350),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ================= TREND ANALYSIS =================
              _buildTrendAnalysisCard(primaryOrange),

              const SizedBox(height: 100), // Spasi agar tidak tertutup floating navbar
            ],
          ),
        ),
      ),
    );
  }

  // Card Last Price dengan Soft Gradient di pojok kanan atas
  Widget _buildLastPriceCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        gradient: const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Colors.white,
            Colors.white,
            Color(0xFFFFF8E1), // Soft Amber Gradient
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '4396.43',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
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
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text('Bid', style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12)),
                  const SizedBox(height: 2),
                  Text('4396.43', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
                ],
              ),
              const Icon(Icons.trending_down, color: Color(0xFFEF5350), size: 18),
              Container(width: 1, height: 24, color: const Color(0xFFEEEEEE)),
              const Icon(Icons.trending_up, color: Color(0xFF4CAF50), size: 18),
              Column(
                children: [
                  Text('Ask', style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12)),
                  const SizedBox(height: 2),
                  Text('4396.81', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Button Date Picker
  Widget _buildDatePicker(Color primaryOrange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, color: Colors.black87, size: 18),
              const SizedBox(width: 12),
              Text(
                '18 Agustus 2026',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
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
  }) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0F0F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
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

  // Card Trend Analysis dengan Grafik Area Gradient
  Widget _buildTrendAnalysisCard(Color primaryOrange) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildTimeFilter('1D', false, primaryOrange),
                    _buildTimeFilter('1W', true, primaryOrange),
                    _buildTimeFilter('1M', false, primaryOrange),
                    _buildTimeFilter('1Y', false, primaryOrange),
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
              painter: AreaChartPainter(primaryOrange: primaryOrange),
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
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilter(String label, bool isSelected, Color primaryOrange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]
            : [],
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? primaryOrange : Colors.grey[600],
        ),
      ),
    );
  }
}

// Custom Painter untuk Menggambar Kurva dan Area Fill Gradient (Grafik)
class AreaChartPainter extends CustomPainter {
  final Color primaryOrange;

  AreaChartPainter({required this.primaryOrange});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Gambar Garis Grid Horizontal Tipis
    final gridPaint = Paint()
      ..color = const Color(0xFFEEEEEE)
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

    // 3. Path Isian Gradient (Area bawah grafik)
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

    // 4. Gambar Garis Utama Kurva Oranye
    final strokePaint = Paint()
      ..color = primaryOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}