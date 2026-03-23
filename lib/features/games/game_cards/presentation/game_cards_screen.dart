import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:neuro_word/core/constants/app_colors.dart';
import 'package:neuro_word/core/constants/app_strings.dart';
import 'package:neuro_word/core/services/user_profile_service.dart';
import 'package:neuro_word/features/learning/models/word_model.dart';
import 'package:neuro_word/features/learning/providers/word_provider.dart';
import 'package:neuro_word/features/learning/providers/word_sets_providers.dart';
import 'package:neuro_word/shared/widgets/futuristic_background.dart';

class GameCardsScreen extends ConsumerStatefulWidget {
  const GameCardsScreen({super.key, this.level});
  final String? level;

  @override
  ConsumerState<GameCardsScreen> createState() => _GameCardsScreenState();
}

class _GameCardsScreenState extends ConsumerState<GameCardsScreen>
    with SingleTickerProviderStateMixin {
  static const int _poolSize = 20;

  late List<WordModel> _words;
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _initialized = false;
  final List<String> _learnedIds = [];

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _loadWords();
      _initialized = true;
    }
  }

  void _loadWords() {
    final notifier = ref.read(wordProvider.notifier);
    final effectiveLevel =
        widget.level?.isNotEmpty == true
            ? widget.level
            : UserProfileService().proficiencyLevel;
    _words = notifier.getRandomWords(_poolSize, level: effectiveLevel);
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  WordModel get _current => _words[_currentIndex];

  bool get _isLearned =>
      ref.read(userProgressProvider).isWordLearned(_current.id);

  bool get _isFavorite =>
      ref.read(userProgressProvider).isWordFavorite(_current.id);

  void _flipCard() {
    HapticFeedback.selectionClick();
    if (_flipController.isAnimating) return;
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  void _toggleLearned() {
    HapticFeedback.lightImpact();
    final id = _current.id;
    if (!_learnedIds.contains(id)) _learnedIds.add(id);
    ref.read(userProgressProvider.notifier).markLearned(id);
    setState(() {});
  }

  void _toggleFavorite() {
    HapticFeedback.lightImpact();
    ref.read(userProgressProvider.notifier).toggleFavorite(_current.id);
    setState(() {});
  }

  void _nextCard() {
    if (_currentIndex >= _words.length - 1) {
      _finishSession();
      return;
    }
    HapticFeedback.selectionClick();
    _flipController.reset();
    setState(() {
      _isFlipped = false;
      _currentIndex++;
    });
  }

  void _previousCard() {
    if (_currentIndex <= 0) return;
    HapticFeedback.selectionClick();
    _flipController.reset();
    setState(() {
      _isFlipped = false;
      _currentIndex--;
    });
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.layers_clear_rounded,
                  color: AppColors.textMuted,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Bu seviyede öğrenilecek kelime yok.',
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _NeonButton(
                  label: 'GERİ',
                  color: AppColors.electricBlue,
                  onTap: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: FuturisticBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              _buildProgressBar(),
              const SizedBox(height: 8),
              _buildCardIndexLabel(),
              const SizedBox(height: 20),
              Expanded(child: _buildCardArea()),
              const SizedBox(height: 20),
              _buildActionRow(),
              const SizedBox(height: 12),
              _buildNavigationRow(),
              const SizedBox(height: 24),
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
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
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
          GestureDetector(
            onTap: _finishSession,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceMedium,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                'BİTİR',
                style: GoogleFonts.orbitron(
                  color: AppColors.electricBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_currentIndex + 1) / _words.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.surfaceMedium,
          valueColor: const AlwaysStoppedAnimation<Color>(
            AppColors.electricBlue,
          ),
          minHeight: 3,
        ),
      ),
    );
  }

  Widget _buildCardIndexLabel() {
    return Text(
      '${_currentIndex + 1} / ${_words.length}',
      style: GoogleFonts.orbitron(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildCardArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: _flipCard,
        child: AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, child) {
            final angle = _flipAnimation.value * pi;
            final showBack = _flipAnimation.value >= 0.5;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: showBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(pi),
                      child: _buildCardBack(),
                    )
                  : _buildCardFront(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardFront() {
    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.electricBlue.withOpacity(0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.electricBlue.withOpacity(0.08),
              blurRadius: 24,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'EN',
              style: GoogleFonts.orbitron(
                color: AppColors.electricBlue.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _current.english,
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.electricBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.electricBlue.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _current.level,
                    style: GoogleFonts.orbitron(
                      color: AppColors.electricBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'çeviriyi görmek için dokun',
              style: GoogleFonts.rajdhani(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack() {
    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF07120A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.neonGreen.withOpacity(0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonGreen.withOpacity(0.08),
              blurRadius: 24,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'TR',
              style: GoogleFonts.orbitron(
                color: AppColors.neonGreen.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _current.english,
                textAlign: TextAlign.center,
                style: GoogleFonts.rajdhani(
                  color: AppColors.textMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 1,
              color: AppColors.neonGreen.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _current.turkish,
                textAlign: TextAlign.center,
                style: GoogleFonts.rajdhani(
                  color: AppColors.neonGreen,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    final learned = _isLearned;
    final favorite = _isFavorite;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              label: 'Favori',
              color: favorite ? AppColors.warningRed : AppColors.textMuted,
              isActive: favorite,
              onTap: _toggleFavorite,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              icon: learned
                  ? Icons.check_circle_rounded
                  : Icons.check_circle_outline_rounded,
              label: 'Öğrendim',
              color: learned ? AppColors.neonGreen : AppColors.textMuted,
              isActive: learned,
              onTap: _toggleLearned,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRow() {
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == _words.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _NavButton(
            icon: Icons.chevron_left_rounded,
            onTap: isFirst ? null : _previousCard,
            enabled: !isFirst,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _nextCard,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.electricBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.electricBlue),
                ),
                child: Center(
                  child: Text(
                    isLast ? 'TAMAMLA' : 'SONRAKİ',
                    style: GoogleFonts.orbitron(
                      color: AppColors.electricBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _NavButton(
            icon: Icons.chevron_right_rounded,
            onTap: isLast ? null : _nextCard,
            enabled: !isLast,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 52,
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : AppColors.cardBorder,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
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

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.surfaceMedium
              : AppColors.surfaceMedium.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? AppColors.cardBorder : AppColors.cardBorder.withOpacity(0.3),
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? AppColors.textSecondary : AppColors.textMuted.withOpacity(0.3),
          size: 24,
        ),
      ),
    );
  }
}

class _NeonButton extends StatelessWidget {
  const _NeonButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: GoogleFonts.orbitron(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
