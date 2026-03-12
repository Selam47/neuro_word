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
      learnedWordsProvider.select((s) => s.contains(word.id)),
    );
    final isFavorite = ref.watch(
      savedWordsProvider.select((s) => s.contains(word.id)),
    );
    final levelColor = AppColors.forLevel(word.level);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () {
        ref.read(learnedWordsProvider.notifier).toggle(word.id);
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: levelColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: levelColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: levelColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Text(
              word.level,
              style: GoogleFonts.orbitron(
                color: levelColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
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
                if (word.category.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMedium,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      word.category,
                      style: GoogleFonts.rajdhani(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    ref.read(savedWordsProvider.notifier).toggle(word.id);
                  },
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
                      isFavorite
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: isFavorite
                          ? AppColors.neonPink
                          : AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLearned
                      ? AppColors.neonGreen.withValues(alpha: 0.15)
                      : AppColors.surfaceMedium,
                  border: Border.all(
                    color: isLearned
                        ? AppColors.neonGreen
                        : AppColors.cardBorder,
                    width: 1.5,
                  ),
                ),
                child: isLearned
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.neonGreen,
                        size: 16,
                      )
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
