import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:neuro_word/core/constants/app_colors.dart';
import 'package:neuro_word/core/constants/app_strings.dart';
import 'package:neuro_word/shared/widgets/futuristic_background.dart';
import 'package:neuro_word/shared/widgets/glass_card.dart';

/// Supporters/credits screen.
class SupportersScreen extends StatelessWidget {
  const SupportersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FuturisticBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // ── Back bar ──────────────────────────────────────
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMedium,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.textSecondary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppStrings.supportersTitle,
                      style: GoogleFonts.orbitron(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Developer Section ─────────────────────────────
                GlassCard(
                  accentColor: AppColors.electricBlue,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.electricBlue.withOpacity(0.8),
                              AppColors.cyberPurple.withOpacity(0.8),
                            ],
                          ),
                          border: Border.all(
                            color: AppColors.textPrimary,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.electricBlue.withOpacity(0.4),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.code_off_rounded,
                            color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Geliştirici',
                        style: GoogleFonts.rajdhani(
                          color: AppColors.electricBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Abdülselam Kaya',
                        style: GoogleFonts.orbitron(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),

                // ── Animation ─────────────────────────────────────
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 250,
                    maxHeight: 200,
                  ),
                  child: Lottie.asset(
                    'assets/animations/supporters_animation.json',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 30),

                // ── Support Team ──────────────────────────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Destek Verenler",
                    style: GoogleFonts.orbitron(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _buildCategoryCard(
                  'DevOps', 
                  ['Abdullah Kaya'],
                  Icons.cloud_sync_rounded,
                  AppColors.cyberPurple,
                ),
                const SizedBox(height: 16),
                _buildCategoryCard(
                  'Frontend', 
                  ['Melik Kaya', 'Sevgi Kaya'],
                  Icons.web_rounded,
                  AppColors.neonGreen,
                ),
                const SizedBox(height: 16),
                _buildCategoryCard(
                  'Backend', 
                  ['Mehmet Ali Guda', 'Serhat Enes Uçan', 'Adnan Sami'],
                  Icons.dns_rounded,
                  AppColors.electricBlue,
                ),
                const SizedBox(height: 16),
                _buildCategoryCard(
                  'Tasarım', 
                  ['Hasan Düzgör', 'Yusuf Serhat Temel', 'Eren Demir'],
                  Icons.brush_rounded,
                  AppColors.neonPink,
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    String title, 
    List<String> names, 
    IconData icon, 
    Color color,
  ) {
    return GlassCard(
      accentColor: color,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.3),
              ),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.rajdhani(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: names.map((name) => _buildNameChip(name)).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.2),
        ),
      ),
      child: Text(
        name,
        style: GoogleFonts.rajdhani(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

