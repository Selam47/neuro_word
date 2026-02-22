import 'dart:async';
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

class NeonPulseScreen extends ConsumerStatefulWidget {
  const NeonPulseScreen({super.key, this.level});
  final String? level;

  @override
  ConsumerState<NeonPulseScreen> createState() => _NeonPulseScreenState();
}

class _NeonPulseScreenState extends ConsumerState<NeonPulseScreen>
    with SingleTickerProviderStateMixin {
  late List<WordModel> _words;
  int _currentIndex = 0;
  int _score = 0;
  final List<int> _learnedIds = [];
  bool _initialized = false;

  late AnimationController _timerController;
  Timer? _countdownTimer;
  int _secondsLeft = 10;

  int? _selectedOptionIndex;
  late List<String> _currentOptions;
  late int _correctOptionIndex;

  static const _totalQuestions = 10;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final notifier = ref.read(wordProvider.notifier);
      _words = notifier.getRandomWords(_totalQuestions, level: widget.level);
      _initialized = true;
      _setupQuestion();
    }
  }

  @override
  void dispose() {
    _timerController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _setupQuestion() {
    if (_currentIndex >= _words.length) {
      _finishSession();
      return;
    }

    final word = _words[_currentIndex];
    final notifier = ref.read(wordProvider.notifier);

    final distractors = notifier.getDistractors(3, excludeIds: {word.id});
    final options = [word.turkish, ...distractors.map((d) => d.turkish)]
      ..shuffle(Random());

    setState(() {
      _currentOptions = options;
      _correctOptionIndex = options.indexOf(word.turkish);
      _selectedOptionIndex = null;
      _secondsLeft = 10;
    });

    _timerController.reset();
    _timerController.forward();
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        timer.cancel();
        _onTimeout();
      }
    });
  }

  void _onTimeout() {
    HapticFeedback.heavyImpact();
    setState(() {
      _selectedOptionIndex = -1; // none selected
    });
    _advanceAfterDelay();
  }

  void _onOptionSelected(int index) {
    if (_selectedOptionIndex != null) return; // already answered

    _countdownTimer?.cancel();
    _timerController.stop();

    final correct = index == _correctOptionIndex;
    if (correct) {
      HapticFeedback.lightImpact();
      _score++;
      _learnedIds.add(_words[_currentIndex].id);
    } else {
      HapticFeedback.heavyImpact();
    }

    setState(() {
      _selectedOptionIndex = index;
    });

    _advanceAfterDelay();
  }

  void _advanceAfterDelay() {
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      _currentIndex++;
      if (_currentIndex < _words.length) {
        _setupQuestion();
      } else {
        _finishSession();
      }
    });
  }

  void _finishSession() {
    context.push(
      '/session-summary',
      extra: {
        'learnedIds': _learnedIds,
        'totalWords': _words.length,
        'mode': AppStrings.neonPulse,
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
              'No words available.',
              style: GoogleFonts.rajdhani(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    if (_currentIndex >= _words.length) {
      return const Scaffold(body: FuturisticBackground(child: SizedBox()));
    }

    final word = _words[_currentIndex];

    return Scaffold(
      body: FuturisticBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${AppStrings.roundOf} ${_currentIndex + 1} / ${_words.length}',
                          style: GoogleFonts.orbitron(
                            color: AppColors.electricBlue,
                            fontSize: 12,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.timer_rounded,
                              color: _secondsLeft <= 3
                                  ? AppColors.warningRed
                                  : AppColors.electricBlue,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_secondsLeft}s',
                              style: GoogleFonts.orbitron(
                                color: _secondsLeft <= 3
                                    ? AppColors.warningRed
                                    : AppColors.electricBlue,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AnimatedBuilder(
                      animation: _timerController,
                      builder: (context, child) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 1.0 - _timerController.value,
                            backgroundColor: AppColors.surfaceMedium,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _secondsLeft <= 3
                                  ? AppColors.warningRed
                                  : AppColors.electricBlue,
                            ),
                            minHeight: 4,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildQuestionCircle(word),
              const SizedBox(height: 32),

              Text(
                '${AppStrings.score}: $_score / $_totalQuestions',
                style: GoogleFonts.rajdhani(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      if (i >= _currentOptions.length) {
                        return const SizedBox();
                      }
                      return _buildOption(i);
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCircle(WordModel word) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.electricBlue.withOpacity(0.08),
            AppColors.cyberPurple.withOpacity(0.04),
            Colors.transparent,
          ],
        ),
        border: Border.all(
          color: AppColors.electricBlue.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.electricBlue.withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ENGLISH',
              style: GoogleFonts.orbitron(
                color: AppColors.electricBlue.withOpacity(0.5),
                fontSize: 10,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  word.english,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.orbitron(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceMedium,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                word.level,
                style: GoogleFonts.orbitron(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(int index) {
    final isSelected = _selectedOptionIndex == index;
    final hasAnswered = _selectedOptionIndex != null;
    final isCorrectOption = index == _correctOptionIndex;

    Color borderColor = AppColors.cardBorder;
    Color bgColor = AppColors.cardDark.withOpacity(0.7);
    Color textColor = AppColors.textPrimary;

    if (hasAnswered) {
      if (isCorrectOption) {
        borderColor = AppColors.neonGreen;
        bgColor = AppColors.neonGreen.withOpacity(0.1);
        textColor = AppColors.neonGreen;
      } else if (isSelected && !isCorrectOption) {
        borderColor = AppColors.warningRed;
        bgColor = AppColors.warningRed.withOpacity(0.1);
        textColor = AppColors.warningRed;
      }
    } else if (isSelected) {
      borderColor = AppColors.electricBlue;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: hasAnswered ? null : () => _onOptionSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: (hasAnswered && isCorrectOption)
                ? [
                    BoxShadow(
                      color: AppColors.neonGreen.withOpacity(0.15),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: borderColor.withOpacity(0.15),
                  border: Border.all(color: borderColor),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index), // A, B, C, D
                    style: GoogleFonts.orbitron(
                      color: borderColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _currentOptions[index],
                  style: GoogleFonts.rajdhani(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (hasAnswered && isCorrectOption)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.neonGreen,
                  size: 22,
                ),
              if (hasAnswered && isSelected && !isCorrectOption)
                const Icon(
                  Icons.cancel_rounded,
                  color: AppColors.warningRed,
                  size: 22,
                ),
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
              AppStrings.neonPulse.toUpperCase(),
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
}

