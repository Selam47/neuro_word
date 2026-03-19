import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neuro_word/core/constants/app_colors.dart';
import 'package:neuro_word/features/learning/models/word_model.dart';
import 'package:neuro_word/features/learning/providers/word_sets_providers.dart';
import 'package:neuro_word/shared/widgets/glass_card.dart';

class WordTile extends ConsumerWidget {
  const WordTile({super.key, required this.word});

  final WordModel word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLearned = ref.watch(
      userProgressProvider.select((s) => s.learnedIds.contains(word.id)),
    );
    final isFavorite = ref.watch(
      userProgressProvider.select((s) => s.favoriteIds.contains(word.id)),
    );
    final levelColor = AppColors.forLevel(word.level);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => ref.read(userProgressProvider.notifier).toggleLearned(word.id),
      child: Row(
        children: [
          _LevelBadge(level: word.level, color: levelColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word.english,
                  style: GoogleFonts.orbitron(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  word.turkish,
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FavoriteButton(
                isFavorite: isFavorite,
                onTap: () =>
                    ref.read(userProgressProvider.notifier).toggleFavorite(word.id),
              ),
              const SizedBox(width: 8),
              _LearnedBadge(isLearned: isLearned),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level, required this.color});

  final String level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8)],
      ),
      child: Text(
        level,
        style: GoogleFonts.orbitron(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, required this.onTap});

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFavorite
                ? AppColors.neonPink.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Icon(
            isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: isFavorite ? AppColors.neonPink : AppColors.textSecondary,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _LearnedBadge extends StatelessWidget {
  const _LearnedBadge({required this.isLearned});

  final bool isLearned;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isLearned
            ? AppColors.neonGreen.withValues(alpha: 0.15)
            : AppColors.surfaceMedium,
        border: Border.all(
          color: isLearned ? AppColors.neonGreen : AppColors.cardBorder,
          width: 1.5,
        ),
        boxShadow: isLearned
            ? [
                BoxShadow(
                  color: AppColors.neonGreen.withValues(alpha: 0.3),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: isLearned
          ? const Icon(Icons.check_rounded, color: AppColors.neonGreen, size: 16)
          : null,
    );
  }
}
