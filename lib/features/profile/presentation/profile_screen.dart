import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:neuro_word/core/constants/app_colors.dart';
import 'package:neuro_word/core/constants/app_strings.dart';
import 'package:neuro_word/core/services/user_profile_service.dart';
import 'package:neuro_word/features/learning/models/rank_model.dart';
import 'package:neuro_word/features/learning/providers/rank_provider.dart';
import 'package:neuro_word/features/learning/providers/word_provider.dart';
import 'package:neuro_word/features/learning/providers/word_sets_providers.dart';
import 'package:neuro_word/shared/widgets/futuristic_background.dart';
import 'package:neuro_word/shared/widgets/glass_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ws = ref.watch(wordProvider);
    final progress_ = ref.watch(userProgressProvider);
    final learnedIds = progress_.learnedIds;
    final savedIds = progress_.favoriteIds;
    final rankState = ref.watch(rankProvider);
    final profile = UserProfileService();
    final learnedInPool = learnedIds.length;
    final preLearnedCount = profile.preLearnedCount;
    final effectiveLearned = learnedInPool + preLearnedCount;
    final poolTotal = ws.allWords.length;
    final effectiveTotal = poolTotal + preLearnedCount;
    final progress = effectiveTotal > 0
        ? (effectiveLearned / effectiveTotal).clamp(0.0, 1.0)
        : 0.0;
    final username = profile.username.toUpperCase();

    const levelOrder = ['A1', 'A2', 'B1', 'B2', 'C1'];
    final levelMap = <String, int>{};
    final learnedLevelMap = <String, int>{};
    for (final w in ws.allWords) {
      levelMap[w.level] = (levelMap[w.level] ?? 0) + 1;
      if (learnedIds.contains(w.id)) {
        learnedLevelMap[w.level] = (learnedLevelMap[w.level] ?? 0) + 1;
      }
    }
    final orderedLevels = levelOrder
        .where((lv) => levelMap.containsKey(lv))
        .toList();
    final savedWords = ws.allWords.where((w) => savedIds.contains(w.id)).toList();
    final learnedWords = ws.allWords.where((w) => learnedIds.contains(w.id)).toList();

    return Scaffold(
      body: FuturisticBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                _buildTopBar(context),
                const SizedBox(height: 28),

                _ProgressRing(
                  progress: progress,
                  learned: effectiveLearned,
                  total: effectiveTotal,
                ),
                const SizedBox(height: 16),

                Text(
                  username,
                  style: GoogleFonts.orbitron(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                _RankBadge(rankState: rankState),
                const SizedBox(height: 28),

                Row(
                  children: [
                    _StatCard(
                      value: '$effectiveLearned',
                      label: AppStrings.learned,
                      color: AppColors.neonGreen,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      value: '$effectiveTotal',
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

                const _RankInfoCard(),
                const SizedBox(height: 28),

                _buildSectionTitle(AppStrings.levelBreakdown),
                const SizedBox(height: 12),
                ...orderedLevels.map((lv) {
                  final tot = levelMap[lv]!;
                  final lea = learnedLevelMap[lv] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LevelProgressBar(
                      level: lv,
                      learned: lea,
                      total: tot,
                      color: AppColors.forLevel(lv),
                    ),
                  );
                }),
                const SizedBox(height: 20),

                _buildSectionTitle('SAVED COLLECTION'),
                const SizedBox(height: 12),
                if (savedWords.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No saved words yet.\nTap the bookmark icon on words to save.',
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
                    height: 140,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: savedWords.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final word = savedWords[index];
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
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      word.english,
                                      style: GoogleFonts.orbitron(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      ref
                                          .read(userProgressProvider.notifier)
                                          .toggleFavorite(word.id);
                                    },
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: AppColors.textSecondary,
                                      size: 16,
                                    ),
                                  ),
                                ],
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
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

                _buildSectionTitle('${AppStrings.learned.toUpperCase()} COLLECTION'),
                const SizedBox(height: 12),
                if (learnedWords.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Henüz öğrenilen kelime yok.\nKelimelere tıklayarak öğrenildi olarak işaretle.',
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
                    height: 140,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: learnedWords.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final word = learnedWords[index];
                        return Container(
                          width: 160,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMedium,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.neonGreen.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      word.english,
                                      style: GoogleFonts.orbitron(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      ref
                                          .read(userProgressProvider.notifier)
                                          .toggleLearned(word.id);
                                    },
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: AppColors.textSecondary,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                word.turkish,
                                style: GoogleFonts.rajdhani(
                                  color: AppColors.neonGreen,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.neonGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  word.level,
                                  style: GoogleFonts.orbitron(
                                    color: AppColors.neonGreen,
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

                _buildSectionTitle('RANK HİYERARŞİSİ'),
                const SizedBox(height: 16),
                const _RankHierarchySection(),
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

}


class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.progress,
    required this.learned,
    required this.total,
  });
  final double progress;
  final int learned;
  final int total;

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
                      color: AppColors.electricBlue.withValues(alpha: 0.3),
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
                '$learned / $total',
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

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.surfaceMedium
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

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
    final pctInt = (pct * 100).toInt();
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    level,
                    style: GoogleFonts.orbitron(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '%$pctInt',
                      style: GoogleFonts.orbitron(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
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


class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rankState});
  final RankState rankState;

  @override
  Widget build(BuildContext context) {
    final isPremium = rankState.isPremiumRank;
    final color = isPremium ? AppColors.accentOrange : AppColors.electricBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: isPremium
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Text(
        rankState.currentTitle.toUpperCase(),
        style: GoogleFonts.orbitron(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
        ),
      ),
    );
  }
}


class _RankInfoCard extends ConsumerWidget {
  const _RankInfoCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankState = ref.watch(rankProvider);
    final isPremium = rankState.isPremiumRank;
    final accentColor =
        isPremium ? AppColors.accentOrange : AppColors.electricBlue;
    final nextRank = rankState.nextRank;

    return GlassCard(
      accentColor: accentColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (isPremium)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.auto_awesome,
                        color: accentColor,
                        size: 18,
                      ),
                    ),
                  Text(
                    'ÜNVAN',
                    style: GoogleFonts.orbitron(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isPremium
                      ? [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'DİL PUANI: ${rankState.levelScore}',
                  style: GoogleFonts.orbitron(
                    color: accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            rankState.currentTitle,
            style: GoogleFonts.orbitron(
              color: accentColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              shadows: isPremium
                  ? [
                      Shadow(
                        color: accentColor.withValues(alpha: 0.6),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
          ),
          if (nextRank != null) ...[
            const SizedBox(height: 10),
            Builder(builder: (context) {
              final currentMastery =
                  rankState.levelMastery[nextRank.requiredLevel] ?? 0.0;
              final target = nextRank.requiredMastery;
              final masteryProgress =
                  target > 0 ? (currentMastery / target).clamp(0.0, 1.0) : 0.0;
              final nextColor =
                  AppColors.forLevel(nextRank.requiredLevel);

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMedium,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.cardBorder.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: nextColor,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sonraki Ünvan: ${nextRank.title}',
                            style: GoogleFonts.rajdhani(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${nextRank.requiredLevel} %${(currentMastery * 100).toInt()}',
                          style: GoogleFonts.orbitron(
                            color: nextColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '%${(target * 100).toInt()} gerekli',
                          style: GoogleFonts.rajdhani(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: masteryProgress,
                        backgroundColor:
                            AppColors.cardBorder.withValues(alpha: 0.5),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(nextColor),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: AppColors.neonGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'En yüksek ünvana ulaştınız!',
                    style: GoogleFonts.rajdhani(
                      color: AppColors.neonGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}


class _RankHierarchySection extends ConsumerWidget {
  const _RankHierarchySection();

  static const Map<int, IconData> _rankIcons = {
    1: Icons.bolt_rounded,
    2: Icons.search_rounded,
    3: Icons.analytics_rounded,
    4: Icons.memory_rounded,
    5: Icons.auto_awesome_rounded,
    6: Icons.workspace_premium_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankState = ref.watch(rankProvider);
    final effectiveId = rankState.effectiveRankId;

    return Column(
      children: List.generate(kRanks.length, (index) {
        final rank = kRanks[index];
        final isAchieved = effectiveId > rank.id;
        final isCurrent = effectiveId == rank.id;
        final isLocked = effectiveId < rank.id;
        final isLast = index == kRanks.length - 1;
        final levelColor = AppColors.forLevel(rank.requiredLevel);

        Color nodeColor;
        if (isCurrent) {
          nodeColor = levelColor;
        } else if (isAchieved) {
          nodeColor = AppColors.neonGreen;
        } else {
          nodeColor = AppColors.textMuted;
        }

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: nodeColor.withValues(alpha: isCurrent ? 0.18 : 0.1),
                        border: Border.all(
                          color: nodeColor.withValues(alpha: isCurrent ? 1.0 : 0.4),
                          width: isCurrent ? 2 : 1,
                        ),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: nodeColor.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        isAchieved
                            ? Icons.check_rounded
                            : (_rankIcons[rank.id] ?? Icons.star_rounded),
                        color: nodeColor,
                        size: 18,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              nodeColor.withValues(alpha: isAchieved ? 0.6 : 0.2),
                              isLocked
                                  ? AppColors.textMuted.withValues(alpha: 0.1)
                                  : nodeColor.withValues(alpha: 0.2),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? levelColor.withValues(alpha: 0.08)
                          : AppColors.surfaceMedium.withValues(
                              alpha: isLocked ? 0.5 : 1.0,
                            ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent
                            ? levelColor.withValues(alpha: 0.5)
                            : isAchieved
                                ? AppColors.neonGreen.withValues(alpha: 0.25)
                                : AppColors.cardBorder.withValues(alpha: 0.4),
                        width: isCurrent ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rank.title.toUpperCase(),
                                    style: GoogleFonts.orbitron(
                                      color: isLocked
                                          ? AppColors.textMuted
                                          : isCurrent
                                              ? levelColor
                                              : AppColors.textPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    rank.titleTr,
                                    style: GoogleFonts.rajdhani(
                                      color: isLocked
                                          ? AppColors.textMuted
                                          : nodeColor.withValues(alpha: 0.8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: levelColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: levelColor.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  'AKTİF',
                                  style: GoogleFonts.orbitron(
                                    color: levelColor,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              )
                            else if (isAchieved)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.neonGreen.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.neonGreen.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  'KİLİT AÇIK',
                                  style: GoogleFonts.orbitron(
                                    color: AppColors.neonGreen,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: levelColor.withValues(
                                  alpha: isLocked ? 0.05 : 0.12,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                rank.requiredLevel,
                                style: GoogleFonts.orbitron(
                                  color: isLocked ? AppColors.textMuted : levelColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '%${(rank.requiredMastery * 100).toInt()} ustalık gerekli',
                              style: GoogleFonts.rajdhani(
                                color: isLocked
                                    ? AppColors.textMuted
                                    : AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isCurrent || isAchieved) ...[
                              const Spacer(),
                              Text(
                                '%${((rankState.levelMastery[rank.requiredLevel] ?? 0.0) * 100).toInt()}',
                                style: GoogleFonts.orbitron(
                                  color: isCurrent ? levelColor : AppColors.neonGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}
