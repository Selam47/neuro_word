import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:neuro_word/core/constants/app_colors.dart';
import 'package:neuro_word/core/constants/app_strings.dart';
import 'package:neuro_word/features/learning/providers/word_provider.dart';
import 'package:neuro_word/shared/widgets/futuristic_background.dart';
import 'package:neuro_word/shared/widgets/glass_card.dart';
import 'package:neuro_word/shared/widgets/neon_icon_box.dart';

/// Session Summary screen shown after completing any game mode.
class SessionSummaryScreen extends ConsumerStatefulWidget {
  const SessionSummaryScreen({
    super.key,
    required this.learnedIds,
    required this.totalWords,
    required this.mode,
  });

  final List<int> learnedIds;
  final int totalWords;
  final String mode;

  @override
  ConsumerState<SessionSummaryScreen> createState() =>
      _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends ConsumerState<SessionSummaryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _persisted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_persisted) {
      _persistData();
      _persisted = true;
    }
  }

  Future<void> _persistData() async {
    try {
      // Mark learned words
      if (widget.learnedIds.isNotEmpty) {
        ref.read(wordProvider.notifier).markLearnedBatch(widget.learnedIds);
      }

      // Award XP (10 per word)
      if (widget.learnedIds.isNotEmpty) {
        final xpEarned = widget.learnedIds.length * 10;
        await ref.read(wordProvider.notifier).addXp(xpEarned);
        debugPrint(
          'SessionSummary: Saved $xpEarned XP and ${widget.learnedIds.length} words.',
        );
      }
    } catch (e) {
      debugPrint('SessionSummary: persist error: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _percentage => widget.totalWords > 0
      ? (widget.learnedIds.length / widget.totalWords) * 100
      : 0;

  String get _grade {
    final p = _percentage;
    if (p >= 90) return 'S';
    if (p >= 80) return 'A';
    if (p >= 70) return 'B';
    if (p >= 50) return 'C';
    return 'D';
  }

  Color get _gradeColor {
    switch (_grade) {
      case 'S':
        return AppColors.neonGreen;
      case 'A':
        return AppColors.electricBlue;
      case 'B':
        return AppColors.cyberPurple;
      case 'C':
        return AppColors.accentOrange;
      default:
        return AppColors.warningRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final wordState = ref.watch(wordProvider);
    final totalLearned = wordState.learnedCount;
    final totalWords = wordState.allWords.length;
    final overallProgress = totalWords > 0 ? totalLearned / totalWords : 0.0;
    final missedCount = widget.totalWords - widget.learnedIds.length;

    return Scaffold(
      body: FuturisticBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // ── Title ─────────────────────────────────────────
                Text(
                  AppStrings.sessionComplete,
                  style: GoogleFonts.orbitron(
                    color: AppColors.electricBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.mode,
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),

                // ── Grade circle ──────────────────────────────────
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _gradeColor.withOpacity(0.08),
                      border: Border.all(
                        color: _gradeColor.withOpacity(0.5),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _gradeColor.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _grade,
                        style: GoogleFonts.orbitron(
                          color: _gradeColor,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Stats ─────────────────────────────────────────
                Row(
                  children: [
                    _buildStatCard(
                      '${widget.learnedIds.length}',
                      AppStrings.correct,
                      AppColors.neonGreen,
                      Icons.check_circle_outline_rounded,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      '$missedCount',
                      AppStrings.missed,
                      AppColors.warningRed,
                      Icons.cancel_outlined,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      '${_percentage.toStringAsFixed(0)}%',
                      AppStrings.accuracyLabel,
                      AppColors.cyberPurple,
                      Icons.analytics_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Overall progress bar ──────────────────────────
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const NeonIconBox(
                            icon: Icons.trending_up_rounded,
                            color: AppColors.cyberPurple,
                            size: 36,
                            iconSize: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.wordJourneyTitle,
                                  style: GoogleFonts.rajdhani(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  AppStrings.progressSubtitle(
                                    totalLearned,
                                    totalWords,
                                  ),
                                  style: GoogleFonts.rajdhani(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: overallProgress,
                          backgroundColor: AppColors.surfaceMedium,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.cyberPurple,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          AppStrings.keepPracticing(overallProgress * 100),
                          style: GoogleFonts.orbitron(
                            color: AppColors.cyberPurple,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── Action buttons ────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.go('/dashboard'),
                        child: Text(
                          AppStrings.dashboard,
                          style: GoogleFonts.rajdhani(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        child: Text(
                          AppStrings.backToDashboard,
                          style: GoogleFonts.rajdhani(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        accentColor: color,
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
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
              style: GoogleFonts.rajdhani(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
