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

class CyberMatchScreen extends ConsumerStatefulWidget {
  const CyberMatchScreen({super.key, this.level});
  final String? level;

  @override
  ConsumerState<CyberMatchScreen> createState() => _CyberMatchScreenState();
}

class _CyberMatchScreenState extends ConsumerState<CyberMatchScreen>
    with TickerProviderStateMixin {
  late List<WordModel> _words;
  late List<WordModel> _shuffledRight;
  int? _selectedLeftIndex;
  int? _selectedRightIndex;
  final Set<int> _matchedIndices = {};
  int _roundNumber = 1;
  int _totalCorrect = 0;
  final List<int> _learnedIds = [];
  bool _initialized = false;

  static const _wordsPerRound = 5;
  static const _totalRounds = 4; // 4 rounds × 5 = 20 words

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _loadRound();
      _initialized = true;
    }
  }

  void _loadRound() {
    final notifier = ref.read(wordProvider.notifier);
    _words = notifier.getRandomWords(_wordsPerRound, level: widget.level);
    _shuffledRight = List<WordModel>.from(_words)..shuffle(Random());
    _selectedLeftIndex = null;
    _selectedRightIndex = null;
    _matchedIndices.clear();
  }

  void _onLeftTap(int index) {
    if (_matchedIndices.contains(index)) return;
    setState(() {
      _selectedLeftIndex = index;
      _checkMatch();
    });
  }

  void _onRightTap(int index) {
    if (_matchedIndices.contains(
      _words.indexWhere((w) => w.id == _shuffledRight[index].id),
    )) {
      return;
    }
    setState(() {
      _selectedRightIndex = index;
      _checkMatch();
    });
  }

  void _checkMatch() {
    if (_selectedLeftIndex == null || _selectedRightIndex == null) return;

    final leftWord = _words[_selectedLeftIndex!];
    final rightWord = _shuffledRight[_selectedRightIndex!];

    if (leftWord.id == rightWord.id) {
      HapticFeedback.lightImpact();
      _matchedIndices.add(_selectedLeftIndex!);
      _totalCorrect++;
      _learnedIds.add(leftWord.id);
    } else {
      HapticFeedback.heavyImpact();
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _selectedLeftIndex = null;
        _selectedRightIndex = null;

        if (_matchedIndices.length == _wordsPerRound) {
          if (_roundNumber < _totalRounds) {
            _roundNumber++;
            _loadRound();
          } else {
            _finishSession();
          }
        }
      });
    });
  }

  void _finishSession() {
    context.push(
      '/session-summary',
      extra: {
        'learnedIds': _learnedIds,
        'totalWords': _totalRounds * _wordsPerRound,
        'mode': AppStrings.cyberMatch,
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

    return Scaffold(
      body: FuturisticBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${AppStrings.round} $_roundNumber / $_totalRounds',
                      style: GoogleFonts.orbitron(
                        color: AppColors.electricBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$_totalCorrect ${AppStrings.matched}',
                      style: GoogleFonts.rajdhani(
                        color: AppColors.neonGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _roundNumber / _totalRounds,
                    backgroundColor: AppColors.surfaceMedium,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.cyberPurple,
                    ),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_wordsPerRound, (i) {
                            final isMatched = _matchedIndices.contains(i);
                            final isSelected = _selectedLeftIndex == i;
                            return _buildWordTile(
                              text: _words[i].english,
                              isMatched: isMatched,
                              isSelected: isSelected,
                              accentColor: AppColors.electricBlue,
                              onTap: () => _onLeftTap(i),
                            );
                          }),
                        ),
                      ),
                      Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 40,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.electricBlue.withOpacity(0.3),
                              AppColors.cyberPurple.withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_wordsPerRound, (i) {
                            final actualIndex = _words.indexWhere(
                              (w) => w.id == _shuffledRight[i].id,
                            );
                            final isMatched = _matchedIndices.contains(
                              actualIndex,
                            );
                            final isSelected = _selectedRightIndex == i;
                            return _buildWordTile(
                              text: _shuffledRight[i].turkish,
                              isMatched: isMatched,
                              isSelected: isSelected,
                              accentColor: AppColors.cyberPurple,
                              onTap: () => _onRightTap(i),
                            );
                          }),
                        ),
                      ),
                    ],
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

  Widget _buildWordTile({
    required String text,
    required bool isMatched,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: isMatched ? 0.25 : 1.0,
        child: GestureDetector(
          onTap: isMatched ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: isMatched
                  ? AppColors.neonGreen.withOpacity(0.08)
                  : isSelected
                  ? accentColor.withOpacity(0.15)
                  : AppColors.cardDark.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isMatched
                    ? AppColors.neonGreen.withOpacity(0.4)
                    : isSelected
                    ? accentColor
                    : AppColors.cardBorder,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accentColor.withOpacity(0.2),
                        blurRadius: 12,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.rajdhani(
                color: isMatched
                    ? AppColors.neonGreen
                    : isSelected
                    ? accentColor
                    : AppColors.textPrimary,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              AppStrings.cyberMatch.toUpperCase(),
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
