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
import 'package:neuro_word/features/learning/providers/word_sets_providers.dart';

class NeuralHackScreen extends ConsumerStatefulWidget {
  const NeuralHackScreen({super.key, this.level});
  final String? level;

  @override
  ConsumerState<NeuralHackScreen> createState() => _NeuralHackScreenState();
}

class _NeuralHackScreenState extends ConsumerState<NeuralHackScreen>
    with SingleTickerProviderStateMixin {
  static const int _totalQuestions = 10;

  late List<WordModel> _words;
  bool _initialized = false;
  bool _sessionEnded = false;
  bool _isAdvancing = false;

  int _questionsAnswered = 0;
  int _score = 0;
  int _lives = 3;
  final List<int> _learnedIds = [];

  late AnimationController _fallController;

  List<String> _currentOptions = [];
  int _correctOptionIndex = 0;
  int? _selectedOptionIndex;
  bool _waitingForTap = false;

  Color _flashColor = Colors.transparent;
  bool _flashActive = false;

  final List<_MatrixColumn> _matrixColumns = [];
  final Random _rng = Random();

  static const _kGreen = Color(0xFF00FF41);
  static const _kRed = Color(0xFFFF0040);
  static const _kBg = Color(0xFF050A0E);
  static const _kSurface = Color(0xFF07120A);

  @override
  void initState() {
    super.initState();

    _fallController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _fallController.addStatusListener(_handleFallStatus);
  }

  void _handleFallStatus(AnimationStatus status) {
    if (!mounted || _sessionEnded || _isAdvancing) return;
    if (status == AnimationStatus.completed && _waitingForTap) {
      _onTimerExpired();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final notifier = ref.read(wordProvider.notifier);
      _words = notifier.getRandomWords(_totalQuestions, level: widget.level);
      _initMatrixColumns();
      if (_words.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_sessionEnded) _setupQuestion();
        });
      }
    }
  }

  @override
  void dispose() {
    _fallController.removeStatusListener(_handleFallStatus);
    _fallController.stop();
    _fallController.dispose();
    super.dispose();
  }

  void _initMatrixColumns() {
    final screenWidth = MediaQuery.of(context).size.width;
    final columnCount = (screenWidth / 20).floor();
    _matrixColumns.clear();
    for (int i = 0; i < columnCount; i++) {
      _matrixColumns.add(
        _MatrixColumn(
          x: i * 20.0,
          chars: _randomChars(),
          speed: _rng.nextDouble() * 1.8 + 0.4,
          offset: _rng.nextDouble() * 800,
        ),
      );
    }
  }

  List<String> _randomChars() {
    return List.generate(
      _rng.nextInt(8) + 3,
      (_) => String.fromCharCode(_rng.nextInt(94) + 33),
    );
  }

  void _setupQuestion() {
    if (_sessionEnded || _isAdvancing) return;

    final word = _words[_questionsAnswered];
    final notifier = ref.read(wordProvider.notifier);
    final distractors = notifier.getDistractors(3, excludeIds: {word.id});
    final options = [word.turkish, ...distractors.map((d) => d.turkish)]
      ..shuffle(_rng);

    setState(() {
      _currentOptions = options;
      _correctOptionIndex = options.indexOf(word.turkish);
      _selectedOptionIndex = null;
      _waitingForTap = true;
      _flashColor = Colors.transparent;
      _flashActive = false;
      _isAdvancing = false;
    });

    _fallController.forward(from: 0.0);
  }

  void _showFlash(Color color) {
    setState(() {
      _flashColor = color;
      _flashActive = true;
    });
  }

  void _onTimerExpired() {
    if (_sessionEnded || !_waitingForTap || _isAdvancing) return;
    HapticFeedback.heavyImpact();
    _fallController.stop();
    setState(() {
      _waitingForTap = false;
      _selectedOptionIndex = -1;
      _lives = (_lives - 1).clamp(0, 3);
    });
    _showFlash(_kRed);
    _advanceToNext();
  }

  void _onOptionSelected(int index) {
    if (!_waitingForTap ||
        _selectedOptionIndex != null ||
        _sessionEnded ||
        _isAdvancing) {
      return;
    }
    _fallController.stop();
    final correct = index == _correctOptionIndex;

    setState(() {
      _waitingForTap = false;
      _selectedOptionIndex = index;
    });

    if (correct) {
      HapticFeedback.lightImpact();
      _score++;
      final wordId = _words[_questionsAnswered].id;
      _learnedIds.add(wordId);
      ref.read(learnedWordsProvider.notifier).addAll([wordId]);
      _showFlash(_kGreen);
    } else {
      HapticFeedback.heavyImpact();
      _lives = (_lives - 1).clamp(0, 3);
      _showFlash(_kRed);
    }

    _advanceToNext();
  }

  void _advanceToNext() {
    if (_isAdvancing) return;
    _isAdvancing = true;
    _fallController.reset();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || _sessionEnded) return;
      setState(() {
        _flashActive = false;
        _flashColor = Colors.transparent;
      });
      _questionsAnswered++;
      _isAdvancing = false;
      if (_questionsAnswered >= _totalQuestions || _lives <= 0) {
        _finishSession();
      } else {
        _setupQuestion();
      }
    });
  }

  void _finishSession() {
    if (_sessionEnded) return;
    _sessionEnded = true;
    _fallController.stop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.push(
        '/session-summary',
        extra: {
          'learnedIds': _learnedIds,
          'totalWords': _questionsAnswered.clamp(0, _totalQuestions),
          'mode': AppStrings.neuralHack,
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _words.isEmpty) return _buildEmptyState();

    if (_sessionEnded) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kGreen)),
      );
    }

    final word = _words[_questionsAnswered.clamp(0, _words.length - 1)];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _fallController.stop();
          _sessionEnded = true;
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: _kBg,
        body: Stack(
          children: [
            _buildRainLayer(),
            if (_flashActive)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),

                    color: _flashColor.withOpacity(0.10),
                  ),
                ),
              ),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 4),
                  _buildStatsRow(),
                  const SizedBox(height: 8),
                  Expanded(child: RepaintBoundary(child: _buildGameArea(word))),
                  _buildOptionsPanel(),
                ],
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
              Icons.terminal_rounded,
              color: _kGreen.withOpacity(0.4),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Kelime bulunamadı.',
              style: GoogleFonts.sourceCodePro(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRainLayer() {
    return Positioned.fill(
      child: RepaintBoundary(
        child: _MatrixRainWidget(columns: _matrixColumns, rng: _rng),
      ),
    );
  }

  Widget _buildGameArea(WordModel word) {
    const kCardH = 110.0;
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final areaH = constraints.maxHeight;
              return AnimatedBuilder(
                animation: _fallController,
                builder: (context, child) {
                  final y =
                      -kCardH + _fallController.value * (areaH + 2 * kCardH);
                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned(
                        top: y,
                        left: 16,
                        right: 16,
                        child: child!,
                      ),
                    ],
                  );
                },
                child: _WordCard(word: word),
              );
            },
          ),
        ),
        const _FirewallBar(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              _fallController.stop();
              _sessionEnded = true;
              Navigator.of(context).pop();
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF0A1A0A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kGreen.withOpacity(0.25)),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: _kGreen.withOpacity(0.7),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'NEURAL HACK',
            style: GoogleFonts.sourceCodePro(
              color: _kGreen,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          _buildProgressBadge(),
        ],
      ),
    );
  }

  Widget _buildProgressBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1A0A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kGreen.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_questionsAnswered + 1}',
            style: GoogleFonts.sourceCodePro(
              color: _kGreen,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            ' / $_totalQuestions',
            style: GoogleFonts.sourceCodePro(
              color: _kGreen.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Row(
            children: List.generate(3, (i) {
              final alive = i < _lives;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    key: ValueKey(alive),
                    alive
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: alive ? _kRed : const Color(0xFF1E2A1E),
                    size: 22,
                  ),
                ),
              );
            }),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _kGreen.withOpacity(0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kGreen.withOpacity(0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, color: _kGreen, size: 15),
                const SizedBox(width: 4),
                Text(
                  '$_score',
                  style: GoogleFonts.sourceCodePro(
                    color: _kGreen,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildTimeBar(),
        ],
      ),
    );
  }

  Widget _buildTimeBar() {
    return AnimatedBuilder(
      animation: _fallController,
      builder: (context, _) {
        final progress = _fallController.value.clamp(0.0, 1.0);
        final isDanger = progress > 0.72;
        return SizedBox(
          width: 72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFF0A1A0A),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDanger ? _kRed : _kGreen,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isDanger ? 'DANGER' : 'TIME',
                style: GoogleFonts.sourceCodePro(
                  color: isDanger
                      ? _kRed.withOpacity(0.6)
                      : _kGreen.withOpacity(0.3),
                  fontSize: 7,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionsPanel() {
    if (_currentOptions.isEmpty) return const SizedBox.shrink();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: Padding(
        key: ValueKey(_questionsAnswered),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (i) {
            if (i >= _currentOptions.length) return const SizedBox.shrink();
            return _buildOption(i);
          }),
        ),
      ),
    );
  }

  Widget _buildOption(int index) {
    final bool hasAnswered = _selectedOptionIndex != null;
    final bool isSelected = _selectedOptionIndex == index;
    final bool isCorrectOption = index == _correctOptionIndex;
    final bool canTap = !hasAnswered && _waitingForTap;

    Color borderColor;
    Color bgColor;
    Color textColor;
    Widget? trailingIcon;

    if (!hasAnswered) {
      borderColor = _kGreen.withOpacity(0.18);
      bgColor = _kSurface.withOpacity(0.9);
      textColor = _kGreen.withOpacity(0.85);
    } else if (isCorrectOption) {
      borderColor = _kGreen;
      bgColor = _kGreen.withOpacity(0.12);
      textColor = _kGreen;
      trailingIcon = const Icon(
        Icons.check_circle_rounded,
        color: _kGreen,
        size: 20,
      );
    } else if (isSelected) {
      borderColor = _kRed;
      bgColor = _kRed.withOpacity(0.10);
      textColor = _kRed;
      trailingIcon = const Icon(Icons.cancel_rounded, color: _kRed, size: 20);
    } else {
      borderColor = _kGreen.withOpacity(0.07);
      bgColor = _kSurface.withOpacity(0.35);
      textColor = _kGreen.withOpacity(0.30);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: canTap ? () => _onOptionSelected(index) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1.2),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index),
                    style: GoogleFonts.sourceCodePro(
                      color: borderColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _currentOptions[index],
                  style: GoogleFonts.sourceCodePro(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                trailingIcon,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard({required this.word});
  final WordModel word;

  static const _kGreen = Color(0xFF00FF41);
  static const _kSurfaceDark = Color(0xFF030D03);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: _kSurfaceDark.withOpacity(0.97),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kGreen.withOpacity(0.55), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _kGreen.withOpacity(0.16),
            blurRadius: 28,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.85),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '> ',
                style: GoogleFonts.sourceCodePro(
                  color: _kGreen.withOpacity(0.35),
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Flexible(
                child: Text(
                  word.english,
                  style: GoogleFonts.sourceCodePro(
                    color: _kGreen,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _kGreen.withOpacity(0.06),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _kGreen.withOpacity(0.14)),
            ),
            child: Text(
              word.level,
              style: GoogleFonts.sourceCodePro(
                color: _kGreen.withOpacity(0.42),
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

class _FirewallBar extends StatelessWidget {
  const _FirewallBar();

  static const _kRed = Color(0xFFFF0040);
  static const _kOrange = Color(0xFFFF6600);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                _kRed.withOpacity(0.9),
                _kOrange.withOpacity(0.7),
                _kRed.withOpacity(0.9),
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: _kRed.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 3,
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Center(
          child: Text(
            '[ FIREWALL ]',
            style: GoogleFonts.sourceCodePro(
              color: _kRed.withOpacity(0.42),
              fontSize: 9,
              letterSpacing: 4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MatrixRainWidget extends StatefulWidget {
  const _MatrixRainWidget({required this.columns, required this.rng});
  final List<_MatrixColumn> columns;
  final Random rng;

  @override
  State<_MatrixRainWidget> createState() => _MatrixRainWidgetState();
}

class _MatrixRainWidgetState extends State<_MatrixRainWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _rainController;
  int _lastRainUs = 0;

  @override
  void initState() {
    super.initState();
    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _rainController.addListener(_tickRain);
  }

  void _tickRain() {
    final nowUs = DateTime.now().microsecondsSinceEpoch;
    if (_lastRainUs == 0) {
      _lastRainUs = nowUs;
      return;
    }
    final dtMs = (nowUs - _lastRainUs) / 1000.0;
    _lastRainUs = nowUs;
    for (final col in widget.columns) {
      col.offset += col.speed * dtMs * 0.1;
      if (col.offset > 920) {
        col.offset = -(col.chars.length * 18.0);
        col.chars = List.generate(
          widget.rng.nextInt(8) + 3,
          (_) => String.fromCharCode(widget.rng.nextInt(94) + 33),
        );
      }
    }
  }

  @override
  void dispose() {
    _rainController.removeListener(_tickRain);
    _rainController.stop();
    _rainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MatrixRainPainter(
        columns: widget.columns,
        repaint: _rainController,
      ),
    );
  }
}

class _MatrixColumn {
  double x;
  List<String> chars;
  double speed;
  double offset;

  _MatrixColumn({
    required this.x,
    required this.chars,
    required this.speed,
    required this.offset,
  });
}

class _MatrixRainPainter extends CustomPainter {
  final List<_MatrixColumn> columns;

  _MatrixRainPainter({required this.columns, required Listenable repaint})
    : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    for (final col in columns) {
      for (int i = 0; i < col.chars.length; i++) {
        final y = col.offset + i * 18.0;
        if (y < -18 || y > size.height + 18) continue;
        final opacity = i == 0
            ? 0.55
            : max(0.03, 0.5 * (1.0 - i / col.chars.length));
        final tp = TextPainter(
          text: TextSpan(
            text: col.chars[i],
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Color.fromRGBO(0, 255, 65, opacity),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(col.x, y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MatrixRainPainter old) => false;
}
