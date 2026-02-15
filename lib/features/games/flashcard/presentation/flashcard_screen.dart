import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:neuro_word/core/constants/app_colors.dart';
import 'package:neuro_word/core/constants/app_strings.dart';
import 'package:neuro_word/features/learning/models/word_model.dart';
import 'package:neuro_word/features/learning/providers/word_provider.dart';
import 'package:neuro_word/shared/widgets/futuristic_background.dart';
import 'package:neuro_word/shared/widgets/glass_card.dart';

/// Mode A — Holographic Flashcards
/// Swipeable cards with a 3D flip animation.
/// Fetches 20 random unlearned words from the provider.
class FlashcardScreen extends ConsumerStatefulWidget {
  const FlashcardScreen({super.key, this.level});
  final String? level;

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen> {
  late List<WordModel> _words;
  int _currentIndex = 0;
  final List<int> _learnedIds = [];
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final notifier = ref.read(wordProvider.notifier);
      _words = notifier.getRandomWords(20, level: widget.level);
      _initialized = true;
    }
  }

  void _onSwipeLeft() {
    // Not learned — move to next
    HapticFeedback.mediumImpact();
    if (_currentIndex < _words.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _finishSession();
    }
  }

  void _onSwipeRight() {
    // Mark as learned
    HapticFeedback.lightImpact();
    _learnedIds.add(_words[_currentIndex].id);
    if (_currentIndex < _words.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _finishSession();
    }
  }

  void _finishSession() {
    context.push(
      '/session-summary',
      extra: {
        'learnedIds': _learnedIds,
        'totalWords': _words.length,
        'mode': AppStrings.flashcards,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_words.isEmpty) {
      return Scaffold(
        body: FuturisticBackground(
          child: Center(
            child: Text(
              'No words available at this level.',
              style: GoogleFonts.rajdhani(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    final word = _words[_currentIndex];
    final progress = (_currentIndex + 1) / _words.length;

    return Scaffold(
      body: FuturisticBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ─────────────────────────────────────────
              _buildTopBar(context),
              const SizedBox(height: 8),

              // ── Progress ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_currentIndex + 1} / ${_words.length}',
                          style: GoogleFonts.orbitron(
                            color: AppColors.electricBlue,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${_learnedIds.length} learned',
                          style: GoogleFonts.rajdhani(
                            color: AppColors.neonGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.surfaceMedium,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.electricBlue,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Flashcard ───────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Stack(
                    children: [
                      GestureDetector(
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity != null) {
                            if (details.primaryVelocity! < -200) {
                              _onSwipeLeft();
                            } else if (details.primaryVelocity! > 200) {
                              _onSwipeRight();
                            }
                          }
                        },
                        child: _FlipCard(word: word),
                      ),
                      // Favorite Button
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _FavoriteButton(word: word),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Swipe hints ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHint(
                      Icons.arrow_back_rounded,
                      'Skip',
                      AppColors.warningRed,
                      _onSwipeLeft,
                    ),
                    _buildHint(
                      Icons.arrow_forward_rounded,
                      'Learned',
                      AppColors.neonGreen,
                      _onSwipeRight,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
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
                Icons.arrow_back_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              AppStrings.flashcards.toUpperCase(),
              style: GoogleFonts.orbitron(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHint(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.rajdhani(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.word});
  final WordModel word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We watch the specific word status from provider to reflect changes
    final isFav = ref.watch(wordProvider.select((s) {
      final updated = s.allWords.firstWhere(
        (w) => w.id == word.id,
        orElse: () => word,
      );
      return updated.isFavorite;
    }));

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(wordProvider.notifier).toggleFavorite(word.id);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.backgroundDark.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(
            color: isFav ? AppColors.neonPink : AppColors.textMuted,
          ),
        ),
        child: Icon(
          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: isFav ? AppColors.neonPink : AppColors.textMuted,
          size: 24,
        ),
      ),
    );
  }
}

/// 3D flip card widget
class _FlipCard extends StatefulWidget {
  const _FlipCard({required this.word});
  final WordModel word;

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );
  }

  @override
  void didUpdateWidget(_FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.word.id != widget.word.id) {
      _controller.reset();
      _showBack = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_showBack) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() => _showBack = !_showBack);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFlip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final isBack = _animation.value >= 0.5;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _buildCardFace(
                      widget.word.turkish,
                      'TURKISH',
                      AppColors.cyberPurple,
                    ),
                  )
                : _buildCardFace(
                    widget.word.english,
                    'ENGLISH',
                    AppColors.electricBlue,
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCardFace(String text, String language, Color accent) {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      accentColor: accent,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Level badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                '${widget.word.level} · ${widget.word.category}',
                style: GoogleFonts.rajdhani(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Language label
            Text(
              language,
              style: GoogleFonts.orbitron(
                color: accent.withValues(alpha: 0.6),
                fontSize: 11,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 12),

            // Word
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Tap hint
            Text(
              'TAP TO FLIP',
              style: GoogleFonts.rajdhani(
                color: AppColors.textMuted,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

