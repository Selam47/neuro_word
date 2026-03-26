import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neuro_word/core/constants/app_strings.dart';
import 'package:neuro_word/features/learning/models/word_model.dart';
import 'package:neuro_word/features/learning/providers/word_provider.dart';
import 'package:neuro_word/features/learning/providers/word_sets_providers.dart';

enum _Phase { idle, flash, typing, feedback, results }

class FlashMemoryScreen extends ConsumerStatefulWidget {
  const FlashMemoryScreen({super.key, this.level});
  final String? level;

  @override
  ConsumerState<FlashMemoryScreen> createState() => _FlashMemoryScreenState();
}

class _FlashMemoryScreenState extends ConsumerState<FlashMemoryScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const int _totalWords = 5;
  static const int _typingSeconds = 10;
  static const Duration _flashDuration = Duration(milliseconds: 1500);
  static const Duration _feedbackDuration = Duration(milliseconds: 700);

  static const _kCyan = Color(0xFF00FFFF);
  static const _kGreen = Color(0xFF00FF41);
  static const _kRed = Color(0xFFFF0040);
  static const _kBg = Color(0xFF050A0E);
  static const _kSurface = Color(0xFF07120A);

  late List<WordModel> _words;
  bool _initialized = false;

  int _currentIndex = 0;
  int _score = 0;
  _Phase _phase = _Phase.idle;
  int _roundId = 0;

  bool _lastAnswerCorrect = false;
  Color _feedbackColor = Colors.transparent;

  late AnimationController _timerController;
  bool _wasTimerRunning = false;

  Timer? _flashTimer;
  Timer? _feedbackTimer;

  final TextEditingController _textController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _typingSeconds),
    )..addStatusListener(_onTimerStatus);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _wasTimerRunning = _timerController.isAnimating;
      _timerController.stop();
    } else if (state == AppLifecycleState.resumed) {
      if (_wasTimerRunning && _phase == _Phase.typing) {
        _timerController.forward();
      }
      _wasTimerRunning = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final notifier = ref.read(wordProvider.notifier);
      _words = notifier.getRandomWords(_totalWords, level: widget.level);
      if (_words.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _beginRound();
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelAllTimers();
    _timerController
      ..removeStatusListener(_onTimerStatus)
      ..stop()
      ..dispose();
    _textController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _cancelAllTimers() {
    _flashTimer?.cancel();
    _flashTimer = null;
    _feedbackTimer?.cancel();
    _feedbackTimer = null;
  }

  void _onTimerStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (!mounted || _phase != _Phase.typing) return;
    final token = _roundId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _roundId != token || _phase != _Phase.typing) return;
      _handleTimeUp();
    });
  }

  void _beginRound() {
    if (!mounted || _phase == _Phase.results) return;

    _cancelAllTimers();
    _timerController.reset();
    _roundId++;
    final token = _roundId;

    _textController.clear();
    setState(() {
      _phase = _Phase.flash;
      _feedbackColor = Colors.transparent;
      _lastAnswerCorrect = false;
    });

    _flashTimer = Timer(_flashDuration, () {
      if (!mounted || _roundId != token) return;
      setState(() => _phase = _Phase.typing);
      _inputFocusNode.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _roundId != token || _phase != _Phase.typing) return;
        _timerController.forward(from: 0.0);
      });
    });
  }

  void _handleTimeUp() {
    if (_phase != _Phase.typing) return;
    HapticFeedback.heavyImpact();
    _timerController.stop();
    setState(() {
      _phase = _Phase.feedback;
      _lastAnswerCorrect = false;
      _feedbackColor = _kRed;
    });
    _scheduleNextRound();
  }

  void _onSubmitted(String value) {
    if (_phase != _Phase.typing) return;
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return;

    _timerController.stop();

    final expected = _words[_currentIndex].english.trim().toLowerCase();
    final correct = trimmed == expected;

    if (correct) {
      HapticFeedback.lightImpact();
      _score++;
      ref.read(userProgressProvider.notifier).addAllLearned([
        _words[_currentIndex].id,
      ]);
    } else {
      HapticFeedback.heavyImpact();
    }

    setState(() {
      _phase = _Phase.feedback;
      _lastAnswerCorrect = correct;
      _feedbackColor = correct ? _kGreen : _kRed;
    });

    _scheduleNextRound();
  }

  void _scheduleNextRound() {
    _cancelAllTimers();
    _timerController.reset();
    final token = _roundId;

    _feedbackTimer = Timer(_feedbackDuration, () {
      if (!mounted || _roundId != token) return;
      _currentIndex++;
      if (_currentIndex >= _totalWords) {
        setState(() => _phase = _Phase.results);
      } else {
        _beginRound();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _words.isEmpty) return _buildEmptyState();
    if (_phase == _Phase.results) return _buildResultsScreen();

    final word = _words[_currentIndex.clamp(0, _words.length - 1)];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _cancelAllTimers();
          _timerController.stop();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: _kBg,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            if (_phase == _Phase.feedback)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    color: _feedbackColor.withOpacity(0.10),
                  ),
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildTopBar(context),
                    const SizedBox(height: 8),
                    _buildProgressDots(),
                    const SizedBox(height: 12),
                    _buildTimerBar(),
                    const SizedBox(height: 8),
                    Expanded(child: _buildWordArea(word)),
                    _buildInputArea(word),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: _kBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.memory_rounded,
              color: _kCyan.withOpacity(0.4),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Kelime bulunamadı.',
              style: GoogleFonts.sourceCodePro(
                color: _kCyan.withOpacity(0.4),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const _NeonButton(label: 'GERİ DÖN', color: _kCyan),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final perfect = _score == _totalWords;
    final headerColor = perfect ? _kGreen : _kCyan;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              _buildResultBadge(perfect, headerColor),
              const SizedBox(height: 32),
              _buildScoreDisplay(headerColor),
              const SizedBox(height: 48),
              _buildScoreBreakdown(),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const _NeonButton(
                  label: 'ANA MENÜYE DÖN',
                  color: _kCyan,
                  fullWidth: true,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultBadge(bool perfect, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        perfect ? 'MÜKEMMEL!' : 'SONUÇ',
        style: GoogleFonts.sourceCodePro(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 4,
        ),
      ),
    );
  }

  Widget _buildScoreDisplay(Color color) {
    return Column(
      children: [
        Text(
          '$_score',
          style: GoogleFonts.sourceCodePro(
            color: color,
            fontSize: 88,
            fontWeight: FontWeight.w700,
            height: 1,
            shadows: [
              Shadow(color: color.withOpacity(0.6), blurRadius: 30),
              Shadow(color: color.withOpacity(0.3), blurRadius: 60),
            ],
          ),
        ),
        Text(
          '/ $_totalWords',
          style: GoogleFonts.sourceCodePro(
            color: color.withOpacity(0.35),
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppStrings.flashMemory,
          style: GoogleFonts.sourceCodePro(
            color: _kCyan.withOpacity(0.15),
            fontSize: 11,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kCyan.withOpacity(0.12)),
      ),
      child: Column(
        children: List.generate(_totalWords, (i) {
          final word = _words[i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Text(
                  '${i + 1}',
                  style: GoogleFonts.sourceCodePro(
                    color: _kCyan.withOpacity(0.25),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    word.english,
                    style: GoogleFonts.sourceCodePro(
                      color: _kCyan.withOpacity(0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  word.turkish,
                  style: GoogleFonts.sourceCodePro(
                    color: _kCyan.withOpacity(0.35),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              _cancelAllTimers();
              _timerController.stop();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kCyan.withOpacity(0.25)),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: _kCyan.withOpacity(0.7),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'FLASH MEMORY',
            style: GoogleFonts.sourceCodePro(
              color: _kCyan,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _kCyan.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kCyan.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, color: _kCyan, size: 14),
                const SizedBox(width: 4),
                Text(
                  '$_score',
                  style: GoogleFonts.sourceCodePro(
                    color: _kCyan,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDots() {
    return Row(
      children: List.generate(_totalWords, (i) {
        final done = i < _currentIndex;
        final active = i == _currentIndex;
        final Color dotColor;
        if (done) {
          dotColor = _kGreen;
        } else if (active) {
          dotColor = _kCyan;
        } else {
          dotColor = _kCyan.withOpacity(0.12);
        }
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              decoration: BoxDecoration(
                color: dotColor,
                borderRadius: BorderRadius.circular(2),
                boxShadow: active
                    ? [BoxShadow(color: _kCyan.withOpacity(0.5), blurRadius: 6)]
                    : null,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTimerBar() {
    if (_phase == _Phase.flash) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MEMORIZE',
                style: GoogleFonts.sourceCodePro(
                  color: _kGreen.withOpacity(0.7),
                  fontSize: 9,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '1.5s',
                style: GoogleFonts.sourceCodePro(
                  color: _kGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.0,
              backgroundColor: Color(0xFF0A1A0A),
              valueColor: AlwaysStoppedAnimation<Color>(_kGreen),
              minHeight: 6,
            ),
          ),
        ],
      );
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _timerController,
        builder: (context, _) {
          final progress = _timerController.value.clamp(0.0, 1.0);
          final isDanger = progress > 0.70;
          final remaining = ((1.0 - progress) * _typingSeconds).ceil().clamp(
            0,
            _typingSeconds,
          );
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isDanger ? 'MEMORY FADING...' : 'RECALL TIME',
                    style: GoogleFonts.sourceCodePro(
                      color: isDanger
                          ? _kRed.withOpacity(0.7)
                          : _kCyan.withOpacity(0.4),
                      fontSize: 9,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${remaining}s',
                    style: GoogleFonts.sourceCodePro(
                      color: isDanger ? _kRed : _kCyan,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFF0A1A0A),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDanger ? _kRed : _kCyan,
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWordArea(WordModel word) {
    return Center(
      child: RepaintBoundary(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: _phase == _Phase.flash
              ? _FlashWordCard(key: const ValueKey('visible'), word: word)
              : const _HiddenWordCard(key: ValueKey('hidden')),
        ),
      ),
    );
  }

  Widget _buildInputArea(WordModel word) {
    final isTyping = _phase == _Phase.typing;
    final showFeedback = _phase == _Phase.feedback;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showFeedback)
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _lastAnswerCorrect
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: _feedbackColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _lastAnswerCorrect ? 'CORRECT' : 'WRONG: ${word.english}',
                  style: GoogleFonts.sourceCodePro(
                    color: _feedbackColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          )
        else
          const SizedBox(height: 40),
        Container(
          decoration: BoxDecoration(
            color: _kSurface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isTyping
                  ? _kCyan.withOpacity(0.5)
                  : _kCyan.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: isTyping
                ? [
                    BoxShadow(
                      color: _kCyan.withOpacity(0.12),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: TextField(
            controller: _textController,
            focusNode: _inputFocusNode,
            enabled: isTyping,
            onSubmitted: _onSubmitted,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            style: GoogleFonts.sourceCodePro(
              color: _kCyan,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: _kCyan,
            decoration: InputDecoration(
              hintText: isTyping ? 'Kelimeyi yaz...' : '',
              hintStyle: GoogleFonts.sourceCodePro(
                color: _kCyan.withOpacity(0.2),
                fontSize: 16,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              suffixIcon: isTyping
                  ? IconButton(
                      icon: Icon(
                        Icons.send_rounded,
                        color: _kCyan.withOpacity(0.6),
                      ),
                      onPressed: () => _onSubmitted(_textController.text),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _FlashWordCard extends StatelessWidget {
  const _FlashWordCard({super.key, required this.word});
  final WordModel word;

  static const _kCyan = Color(0xFF00FFFF);
  static const _kGreen = Color(0xFF00FF41);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFF020A0F).withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kCyan.withOpacity(0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _kCyan.withOpacity(0.4),
            blurRadius: 36,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: _kGreen.withOpacity(0.15),
            blurRadius: 60,
            spreadRadius: 8,
          ),
          BoxShadow(color: Colors.black.withOpacity(0.9), blurRadius: 6),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            word.english,
            style: GoogleFonts.sourceCodePro(
              color: _kCyan,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              shadows: [
                Shadow(color: _kCyan.withOpacity(0.8), blurRadius: 16),
                Shadow(color: _kGreen.withOpacity(0.4), blurRadius: 32),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _kCyan.withOpacity(0.06),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _kCyan.withOpacity(0.2)),
            ),
            child: Text(
              word.level,
              style: GoogleFonts.sourceCodePro(
                color: _kCyan.withOpacity(0.5),
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HiddenWordCard extends StatelessWidget {
  const _HiddenWordCard({super.key});

  static const _kCyan = Color(0xFF00FFFF);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFF050A0E).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kCyan.withOpacity(0.1), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.visibility_off_rounded,
            color: _kCyan.withOpacity(0.15),
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            'RECALL THE WORD',
            style: GoogleFonts.sourceCodePro(
              color: _kCyan.withOpacity(0.2),
              fontSize: 12,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NeonButton extends StatelessWidget {
  const _NeonButton({
    required this.label,
    required this.color,
    this.fullWidth = false,
  });

  final String label;
  final Color color;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.sourceCodePro(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
