import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:neuro_word/core/constants/app_colors.dart';
import 'package:neuro_word/core/constants/app_strings.dart';
import 'package:neuro_word/features/learning/providers/word_provider.dart';
import 'package:neuro_word/shared/widgets/futuristic_background.dart';
import 'package:neuro_word/shared/widgets/glass_card.dart';

/// Holographic profile & statistics dashboard.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const int _wordGoal = 2000;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ws = ref.watch(wordProvider);
    final learned = ws.learnedCount;
    final total = ws.allWords.length;
    final progress = total > 0 ? learned / _wordGoal : 0.0;

    // Determine user level based on majority of mastered words
    final userLevel = _computeLevel(ws);

    // Category breakdown
    final catMap = <String, int>{};
    for (final w in ws.allWords) {
      catMap[w.category] = (catMap[w.category] ?? 0) + 1;
    }
    final categories = catMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Level breakdown
    final levelMap = <String, int>{};
    final learnedLevelMap = <String, int>{};
    for (final w in ws.allWords) {
      levelMap[w.level] = (levelMap[w.level] ?? 0) + 1;
      if (w.isLearned) {
        learnedLevelMap[w.level] = (learnedLevelMap[w.level] ?? 0) + 1;
      }
    }

    return Scaffold(
      body: FuturisticBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // ── Top Bar ────────────────────────────────────────
                _buildTopBar(context),
                const SizedBox(height: 28),

                // ── Avatar & Progress Ring ─────────────────────────
                _ProgressRing(progress: progress, learned: learned),
                const SizedBox(height: 16),

                Text(
                  AppStrings.learner,
                  style: GoogleFonts.orbitron(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _levelColor(userLevel).withOpacity(0.2),
                        _levelColor(userLevel).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _levelColor(userLevel).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    '${AppStrings.level} $userLevel',
                    style: GoogleFonts.orbitron(
                      color: _levelColor(userLevel),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Stats Cards ────────────────────────────────────
                Row(
                  children: [
                    _StatCard(
                      value: '$learned',
                      label: AppStrings.learned,
                      color: AppColors.neonGreen,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      value: '$total',
                      label: AppStrings.totalWordsLabel,
                      color: AppColors.electricBlue,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      value: '${(progress * 100).toInt()}%',
                      label: AppStrings.progressLabel,
                      color: AppColors.cyberPurple,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Level Breakdown ────────────────────────────────
                _buildSectionTitle(AppStrings.levelBreakdown),
                const SizedBox(height: 12),
                ...levelMap.entries.map((e) {
                  final lv = e.key;
                  final tot = e.value;
                  final lea = learnedLevelMap[lv] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LevelProgressBar(
                      level: lv,
                      learned: lea,
                      total: tot,
                      color: _levelColor(lv),
                    ),
                  );
                }),
                const SizedBox(height: 20),

                // ── Saved Words ────────────────────────────────────
                _buildSectionTitle('SAVED COLLECTION'),
                const SizedBox(height: 12),
                if (ws.favoriteCount == 0)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No saved words yet.\nTap the heart icon on flashcards to save.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.rajdhani(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: ws.allWords.where((w) => w.isFavorite).length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final word = ws.allWords.where((w) => w.isFavorite).toList()[index];
                        return Container(
                          width: 160,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMedium,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.neonPink.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                word.english,
                                style: GoogleFonts.orbitron(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                word.turkish,
                                style: GoogleFonts.rajdhani(
                                  color: AppColors.neonPink,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.neonPink.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  word.level,
                                  style: GoogleFonts.orbitron(
                                    color: AppColors.neonPink,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 28),

                // ── Category Distribution ──────────────────────────
                _buildSectionTitle(AppStrings.categoryDistribution),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.take(12).map((e) {
                    return _CategoryChip(name: e.key, count: e.value);
                  }).toList(),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
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
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          AppStrings.profile,
          style: GoogleFonts.orbitron(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.electricBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.orbitron(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _computeLevel(WordState ws) {
    if (ws.allWords.isEmpty) return 'B2';
    final learnedWords = ws.allWords.where((w) => w.isLearned);
    if (learnedWords.isEmpty) return 'B2';
    final counts = <String, int>{};
    for (final w in learnedWords) {
      counts[w.level] = (counts[w.level] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'C2':
        return AppColors.warningRed;
      case 'C1':
        return AppColors.accentOrange;
      default:
        return AppColors.neonGreen;
    }
  }
}

// ── Progress Ring ───────────────────────────────────────────────────────

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress, required this.learned});
  final double progress;
  final int learned;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: CustomPaint(
        painter: _RingPainter(progress: progress.clamp(0.0, 1.0)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.electricBlue, AppColors.cyberPurple],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.electricBlue.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$learned / 2000',
                style: GoogleFonts.orbitron(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 6.0;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.surfaceMedium
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    final sweepAngle = 2 * pi * progress;
    final gradient = SweepGradient(
      startAngle: -pi / 2,
      endAngle: -pi / 2 + 2 * pi,
      colors: const [
        AppColors.electricBlue,
        AppColors.cyberPurple,
        AppColors.electricBlue,
      ],
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -pi / 2,
      sweepAngle,
      false,
      Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ── Stat Card ──────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        accentColor: color,
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.orbitron(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.rajdhani(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Level Progress Bar ─────────────────────────────────────────────────

class _LevelProgressBar extends StatelessWidget {
  const _LevelProgressBar({
    required this.level,
    required this.learned,
    required this.total,
    required this.color,
  });
  final String level;
  final int learned;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? learned / total : 0.0;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                level,
                style: GoogleFonts.orbitron(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$learned / $total',
                style: GoogleFonts.rajdhani(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.surfaceMedium,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category Chip ──────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.name, required this.count});
  final String name;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceMedium,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: GoogleFonts.rajdhani(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.electricBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.orbitron(
                color: AppColors.electricBlue,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

