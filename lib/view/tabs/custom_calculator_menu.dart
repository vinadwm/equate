import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:equate/viewmodel/theme_viewmodel.dart';

class CustomCalculatorMenu extends StatelessWidget {
  final List<Map<String, dynamic>> options;
  final Function(String) onCalculatorSelected;

  const CustomCalculatorMenu({
    super.key,
    required this.options,
    required this.onCalculatorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeViewModel.isDarkMode;

    // Warna Latar Soft Clay/Glass
    final cardBgColor = isDarkMode
        ? const Color(0xFF1C1C1E).withOpacity(0.7)
        : Colors.white.withOpacity(0.85);

    final borderColor = isDarkMode
        ? Colors.white.withOpacity(0.12)
        : Colors.white.withOpacity(0.9);

    final primaryTextColor = isDarkMode ? Colors.white : const Color(0xFF2C2D30);
    final secondaryTextColor = isDarkMode ? const Color(0xFF9A9A9E) : const Color(0xFF8A8E9B);
    const primaryOrange = Color(0xFFFF9500);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: primaryOrange.withOpacity(isDarkMode ? 0.08 : 0.06),
                blurRadius: 24,
                spreadRadius: -2,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.asMap().entries.map((entry) {
              final index = entry.key;
              final opt = entry.value;

              return Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: () => onCalculatorSelected(opt['title'] as String),
                      borderRadius: BorderRadius.circular(18),
                      hoverColor: primaryOrange.withOpacity(0.08),
                      splashColor: primaryOrange.withOpacity(0.15),
                      highlightColor: primaryOrange.withOpacity(0.05),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            // Soft Clay Icon Container
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: primaryOrange.withOpacity(isDarkMode ? 0.2 : 0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: primaryOrange.withOpacity(0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryOrange.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                opt['icon'] as IconData,
                                size: 20,
                                color: primaryOrange,
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Text Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    opt['title'] as String,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    opt['description'] as String,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      height: 1.3,
                                      fontWeight: FontWeight.w400,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Small Tag Indicator
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: primaryOrange.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 10,
                                color: primaryOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (index < options.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Divider(
                        height: 1,
                        thickness: 0.6,
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}