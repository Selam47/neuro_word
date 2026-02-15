import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:neuro_word/core/constants/app_colors.dart';
import 'package:neuro_word/core/constants/app_strings.dart';
import 'package:neuro_word/features/learning/models/word_model.dart';
import 'package:neuro_word/features/learning/providers/word_provider.dart';
import 'package:neuro_word/shared/widgets/futuristic_background.dart';
import 'package:neuro_word/shared/widgets/glass_card.dart';
import 'package:neuro_word/shared/widgets/neon_icon_box.dart';

/// Dashboard screen with live word data, level filter chips,
/// and shimmer loading — wired to the Riverpod word provider.

Color _getLevelColor(String level) {
  switch (level) {
    case 'A1':
      return const Color(0xFF4CAF50);
    case 'A2':
      return const Color(0xFF8BC34A);
    case 'B1':
      return const Color(0xFFFFEB3B);
    case 'B2':
      return const Color(0xFFFF9800);
    case 'C1':
      return const Color(0xFFFF5722);
    case 'C2':
      return const Color(0xFFF44336);
    default:
      return AppColors.electricBlue;
  }
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _featureCardsKey = GlobalKey();
  final _scrollController = ScrollController();

  void _scrollToFeatureCards() {
    final ctx = _featureCardsKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Auto-refresh data if empty on launch (Fix for startup issue)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(wordProvider);
      if (state.allWords.isEmpty && !state.isLoading) {
        ref.read(wordProvider.notifier).reload();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wordState = ref.watch(wordProvider);

    return Scaffold(
      body: FuturisticBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Bar ─────────────────────────────────────────
                _TopBar(
                  onProfileTap: () => context.push('/profile'),
                  onMenuAction: (action) {
                    switch (action) {
                      case 'explore':
                        _scrollToFeatureCards();
                      case 'supporters':
                        context.push('/supporters');
                      case 'contact':
                        context.push('/contact');
                    }
                  },
                ),
                const SizedBox(height: 28),

                // ── Hero Section ────────────────────────────────────
                _HeroSection(
                  learnedCount: wordState.learnedCount,
                  onStartLearning: () => context.push('/flashcards'),
                ),
                const SizedBox(height: 32),

                // ── Quick Stats Row (now live) ──────────────────────
                _QuickStatsRow(wordState: wordState),
                const SizedBox(height: 32),

                // ── Feature Cards ───────────────────────────────────
                Container(
                  key: _featureCardsKey,
                  child: Text(
                    AppStrings.learningModules,
                    style: GoogleFonts.orbitron(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.learningModulesSubtitle,
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                const _FeatureCardsGrid(),
                const SizedBox(height: 32),

                // ── Kelime Veritabanı (word list) ──────────────────
                _buildSectionHeader(
                  AppStrings.neuralDataStream,
                  AppStrings.dataStreamSubtitle,
                ),
                const SizedBox(height: 12),

                // Level filter chips
                _LevelFilterChips(wordState: wordState),
                const SizedBox(height: 16),

                // Action buttons
                _DataActionBar(wordState: wordState),
                const SizedBox(height: 16),

                // Word list / shimmer / error
                if (wordState.isLoading)
                  const _ShimmerWordList()
                else if (wordState.error != null)
                  _ErrorCard(error: wordState.error!)
                else
                  _LiveWordList(
                    words: wordState.filteredWords,
                    isFiltered: wordState.activeLevel != null,
                  ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
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
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.rajdhani(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ═════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  const _TopBar({this.onProfileTap, this.onMenuAction});
  final VoidCallback? onProfileTap;
  final ValueChanged<String>? onMenuAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.electricBlue.withValues(alpha: 0.4),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox(
            height: 48,
            width: 140, // Increased width for the animation
            child: Lottie.asset(
              'assets/animations/logo_animation.json',
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.electricBlue, AppColors.cyberPurple],
              ),
              border: Border.all(
                color: AppColors.electricBlue.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          onSelected: onMenuAction,
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceMedium,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          color: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          itemBuilder: (_) => [
            _menuItem(
              'explore',
              Icons.explore_rounded,
              AppStrings.exploreModules,
            ),
            _menuItem(
              'supporters',
              Icons.favorite_rounded,
              AppStrings.supporters,
            ),
            _menuItem('contact', Icons.mail_rounded, AppStrings.contact),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: AppColors.electricBlue, size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.rajdhani(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.learnedCount,
    required this.onStartLearning,
  });
  final int learnedCount;
  final VoidCallback onStartLearning;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.welcomeBack,
            style: GoogleFonts.rajdhani(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.electricBlue, AppColors.cyberPurple],
            ).createShader(bounds),
            child: Text(
              AppStrings.appTitle,
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.heroDescription,
            style: GoogleFonts.rajdhani(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onStartLearning,
            child: Text(
              AppStrings.startLearning,
              style: GoogleFonts.rajdhani(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({required this.wordState});
  final WordState wordState;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStat(
          '${wordState.learnedCount}',
          AppStrings.wordsLearned,
          AppColors.electricBlue,
        ),
        const SizedBox(width: 12),
        _buildStat(
          '${wordState.allWords.length}',
          AppStrings.totalWords,
          AppColors.neonGreen,
        ),
        const SizedBox(width: 12),
        _buildStat(
          '${wordState.availableLevels.length}',
          AppStrings.levelsAvailable,
          AppColors.cyberPurple,
        ),
      ],
    );
  }

  Widget _buildStat(String value, String label, Color accent) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        accentColor: accent,
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.orbitron(
                color: accent,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.rajdhani(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Level Filter Chips ──────────────────────────────────────────────────

class _LevelFilterChips extends ConsumerWidget {
  const _LevelFilterChips({required this.wordState});
  final WordState wordState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levels = wordState.availableLevels;

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // "All" chip
          _buildChip(
            context,
            ref,
            label: AppStrings.all,
            isSelected: wordState.activeLevel == null,
            color: AppColors.electricBlue,
            onTap: () => ref.read(wordProvider.notifier).filterByLevel(null),
          ),
          const SizedBox(width: 8),
          ...levels.map(
            (level) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildChip(
                context,
                ref,
                label: level,
                isSelected: wordState.activeLevel == level,
                color: _getLevelColor(level),
                onTap: () =>
                    ref.read(wordProvider.notifier).filterByLevel(level),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : AppColors.surfaceMedium,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.cardBorder,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.orbitron(
            color: isSelected ? color : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

// ── Data Action Bar ─────────────────────────────────────────────────────

class _DataActionBar extends ConsumerWidget {
  const _DataActionBar({required this.wordState});
  final WordState wordState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // Shuffle button
        _buildAction(
          icon: Icons.shuffle_rounded,
          label: AppStrings.shuffle,
          onTap: () => ref.read(wordProvider.notifier).shuffle(),
        ),
        const SizedBox(width: 12),
        // Reload button
        _buildAction(
          icon: Icons.refresh_rounded,
          label: AppStrings.reload,
          onTap: () => ref.read(wordProvider.notifier).reload(),
        ),
        const Spacer(),
        // Count badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.electricBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.electricBlue.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            '${wordState.filteredWords.length} ${AppStrings.entries}',
            style: GoogleFonts.rajdhani(
              color: AppColors.electricBlue,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceMedium,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.rajdhani(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer Loading List ────────────────────────────────────────────────

class _ShimmerWordList extends StatelessWidget {
  const _ShimmerWordList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: AppColors.surfaceMedium,
            highlightColor: AppColors.cardBorder,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceMedium,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Error Card ──────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      accentColor: AppColors.warningRed,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const NeonIconBox(
            icon: Icons.error_outline_rounded,
            color: AppColors.warningRed,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.dataStreamError,
                  style: GoogleFonts.orbitron(
                    color: AppColors.warningRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Live Word List (lazy loading) ───────────────────────────────────────

class _LiveWordList extends ConsumerStatefulWidget {
  const _LiveWordList({required this.words, required this.isFiltered});
  final List<WordModel> words;
  final bool isFiltered;

  @override
  ConsumerState<_LiveWordList> createState() => _LiveWordListState();
}

class _LiveWordListState extends ConsumerState<_LiveWordList> {
  static const _pageSize = 50;
  int _visibleCount = _pageSize;

  @override
  void didUpdateWidget(covariant _LiveWordList old) {
    super.didUpdateWidget(old);
    if (old.words.length != widget.words.length) {
      _visibleCount = _pageSize;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.words.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Icon(
                Icons.search_off_rounded,
                color: AppColors.textMuted,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.noWordsFound,
                style: GoogleFonts.rajdhani(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If filtered by specific level, show flat list.
    // If showing all, group by Level.
    if (widget.isFiltered) {
      return _buildFlatList();
    } else {
      return _buildGroupedList();
    }
  }

  Widget _buildFlatList() {
    final visible = widget.words.length > _visibleCount
        ? _visibleCount
        : widget.words.length;
    final hasMore = widget.words.length > _visibleCount;

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visible,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final word = widget.words[index];
            return _WordTile(word: word);
          },
        ),
        if (hasMore) _buildLoadMore(),
      ],
    );
  }

  Widget _buildGroupedList() {
    // 1. Group words by level
    final grouped = <String, List<WordModel>>{};
    for (final w in widget.words) {
      grouped.putIfAbsent(w.level, () => []).add(w);
    }

    // 2. Sort levels (A1, A2, B1, B2, C1, C2)
    final levels = grouped.keys.toList()..sort();

    // 3. Build linear list of items (headers + words)
    final items = <dynamic>[];
    for (final level in levels) {
      items.add('HEADER:$level');
      items.addAll(grouped[level]!);
    }

    final visible = items.length > _visibleCount ? _visibleCount : items.length;
    final hasMore = items.length > _visibleCount;

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visible,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = items[index];
            if (item is String && item.startsWith('HEADER:')) {
              return _buildLevelHeader(item.substring(7));
            } else if (item is WordModel) {
              return _WordTile(word: item);
            }
            return const SizedBox.shrink();
          },
        ),
        if (hasMore) _buildLoadMore(remaining: items.length - _visibleCount),
      ],
    );
  }

  Widget _buildLevelHeader(String level) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceMedium,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: _getLevelColor(level), width: 3),
        ),
      ),
      child: Text(
        '${AppStrings.level} $level',
        style: GoogleFonts.orbitron(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildLoadMore({int? remaining}) {
    final count = remaining ?? (widget.words.length - _visibleCount);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: GestureDetector(
        onTap: () => setState(() => _visibleCount += _pageSize),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.electricBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.electricBlue.withValues(alpha: 0.3),
            ),
          ),
          child: Center(
            child: Text(
              '${AppStrings.loadMore}  ($count ${AppStrings.remaining})',
              style: GoogleFonts.orbitron(
                color: AppColors.electricBlue,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WordTile extends ConsumerWidget {
  const _WordTile({required this.word});
  final WordModel word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelColor = _getLevelColor(word.level);

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      accentColor: word.isLearned ? AppColors.neonGreen : levelColor,
      onTap: () {
        if (word.isLearned) {
          ref.read(wordProvider.notifier).markUnlearned(word.id);
        } else {
          ref.read(wordProvider.notifier).markLearned(word.id);
        }
      },
      child: Row(
        children: [
          // Level badge
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: levelColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: levelColor.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                word.level,
                style: GoogleFonts.orbitron(
                  color: levelColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Word content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word.english,
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  word.turkish,
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Category tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceMedium,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              word.category,
              style: GoogleFonts.rajdhani(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Learned indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: word.isLearned
                  ? AppColors.neonGreen.withValues(alpha: 0.15)
                  : AppColors.surfaceMedium,
              border: Border.all(
                color: word.isLearned
                    ? AppColors.neonGreen
                    : AppColors.cardBorder,
                width: 1.5,
              ),
            ),
            child: word.isLearned
                ? const Icon(
                    Icons.check_rounded,
                    color: AppColors.neonGreen,
                    size: 16,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

// ── Feature Cards Grid (from Phase 1) ───────────────────────────────────

class _FeatureCardsGrid extends StatelessWidget {
  const _FeatureCardsGrid();

  static const _features = [
    _FeatureItem(
      Icons.style_rounded,
      AppStrings.flashcards,
      AppStrings.flashcardsDesc,
      AppColors.electricBlue,
      '/flashcards',
    ),
    _FeatureItem(
      Icons.link_rounded,
      AppStrings.cyberMatch,
      AppStrings.cyberMatchDesc,
      AppColors.cyberPurple,
      '/cyber-match',
    ),
    _FeatureItem(
      Icons.bolt_rounded,
      AppStrings.neonPulse,
      AppStrings.neonPulseDesc,
      AppColors.neonGreen,
      '/neon-pulse',
    ),
    _FeatureItem(
      Icons.menu_book_rounded,
      AppStrings.grammar,
      AppStrings.grammarDesc,
      AppColors.accentOrange,
      null,
    ),
    _FeatureItem(
      Icons.hearing_rounded,
      AppStrings.listening,
      AppStrings.listeningDesc,
      AppColors.electricBlue,
      null,
    ),
    _FeatureItem(
      Icons.insights_rounded,
      AppStrings.progress,
      AppStrings.progressDesc,
      AppColors.cyberPurple,
      null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: _features.length,
      itemBuilder: (context, index) {
        final f = _features[index];
        return GlassCard(
          padding: const EdgeInsets.all(16),
          accentColor: f.color,
          onTap: f.route != null ? () => context.push(f.route!) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  NeonIconBox(icon: f.icon, color: f.color),
                  if (f.route == null) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMedium,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        AppStrings.soon,
                        style: GoogleFonts.orbitron(
                          color: AppColors.textMuted,
                          fontSize: 8,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Text(
                f.title,
                style: GoogleFonts.rajdhani(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  f.description,
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FeatureItem {
  const _FeatureItem(
    this.icon,
    this.title,
    this.description,
    this.color,
    this.route,
  );
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String? route;
}

