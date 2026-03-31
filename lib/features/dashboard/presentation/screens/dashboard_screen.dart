import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:neuro_word/core/constants/app_colors.dart';
import 'package:neuro_word/core/constants/app_strings.dart';
import 'package:neuro_word/features/learning/models/word_model.dart';
import 'package:neuro_word/features/learning/providers/rank_provider.dart';
import 'package:neuro_word/features/learning/providers/word_provider.dart';
import 'package:neuro_word/features/learning/providers/word_sets_providers.dart';

import 'package:neuro_word/shared/widgets/futuristic_background.dart';
import 'package:neuro_word/shared/widgets/glass_card.dart';
import 'package:neuro_word/shared/widgets/neon_icon_box.dart';
import 'package:neuro_word/shared/widgets/neon_search_bar.dart';
import 'package:neuro_word/shared/widgets/word_tile.dart';

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
    final isLoading = ref.watch(wordProvider.select((s) => s.isLoading));
    final error = ref.watch(wordProvider.select((s) => s.error));
    final filteredWords = ref.watch(wordProvider.select((s) => s.filteredWords));
    final activeLevel = ref.watch(wordProvider.select((s) => s.activeLevel));
    final searchQuery = ref.watch(wordProvider.select((s) => s.searchQuery));
    final onlySaved = ref.watch(wordProvider.select((s) => s.onlySaved));

    return Scaffold(
      body: FuturisticBackground(
        child: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                _TopBar(
                  onProfileTap: () => context.push('/profile'),
                  onMenuAction: (action) async {
                    switch (action) {
                      case 'explore':
                        _scrollToFeatureCards();
                        break;
                      case 'supporters':
                        context.push('/supporters');
                        break;
                      case 'contact':
                        context.push('/contact');
                        break;
                      default:
                        break;
                    }
                  },
                ),
                const SizedBox(height: 28),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Oxford University Press açık listelerinden esinlenmiş ',
                        style: GoogleFonts.rajdhani(
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                          height: 1.4,
                        ),
                      ),
                      const RepaintBoundary(child: _NeonGlitch3500()),
                      Text(
                        ' kelime ile profesyonel bir deneyim.',
                        style: GoogleFonts.rajdhani(
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const SizedBox(height: 12),

                const _QuickStatsRow(),
                const SizedBox(height: 32),

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

                _buildSectionHeader(
                  AppStrings.neuralDataStream,
                  AppStrings.dataStreamSubtitle,
                ),

                NeonSearchBar(
                  onChanged: (query) {
                    ref.read(wordProvider.notifier).search(query);
                  },
                  hintText: AppStrings.searchHint,
                ),
                const SizedBox(height: 8),

                const _AdvancedFilterBar(),
                const SizedBox(height: 16),

                if (isLoading)
                  const _ShimmerWordList()
                else if (error != null)
                  _ErrorCard(error: error)
                else
                  _LiveWordList(
                    words: filteredWords,
                    isFiltered:
                        activeLevel != null ||
                        searchQuery.isNotEmpty ||
                        onlySaved,
                  ),

                const SizedBox(height: 24),
                ],
              ),
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

class _AdvancedFilterBar extends ConsumerWidget {
  const _AdvancedFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLevel = ref.watch(wordProvider.select((s) => s.activeLevel));
    final onlySaved = ref.watch(wordProvider.select((s) => s.onlySaved));
    final levels = ref.watch(wordProvider.select((s) => s.availableLevels));
    final notifier = ref.read(wordProvider.notifier);

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildChip(
            label: AppStrings.allFilter,
            isSelected: activeLevel == null && !onlySaved,
            color: AppColors.electricBlue,
            onTap: () {
              notifier.filterByLevel(null);
              notifier.toggleSaved(false);
            },
          ),
          const SizedBox(width: 8),

          _buildChip(
            label: AppStrings.savedFilter,
            isSelected: onlySaved,
            color: AppColors.neonPink,
            onTap: () => notifier.toggleSaved(!onlySaved),
            icon: Icons.bookmark_rounded,
          ),
          const SizedBox(width: 8),

          ...levels.map(
            (level) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildChip(
                label: level,
                isSelected: activeLevel == level,
                color: AppColors.forLevel(level),
                onTap: () {
                  final newLevel = activeLevel == level ? null : level;
                  notifier.filterByLevel(newLevel);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
    IconData? icon,
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? color : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.orbitron(
                color: isSelected ? color : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceMedium,
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  color: AppColors.textMuted,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.noDataFound,
                style: GoogleFonts.rajdhani(
                  color: AppColors.textMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

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
            return WordTile(key: ValueKey(word.id), word: word);
          },
        ),
        if (hasMore) _buildLoadMore(),
      ],
    );
  }

  Widget _buildGroupedList() {
    final grouped = <String, List<WordModel>>{};
    for (final w in widget.words) {
      grouped.putIfAbsent(w.level, () => []).add(w);
    }

    final levels = grouped.keys.toList()..sort();

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
              return WordTile(key: ValueKey(item.id), word: item);
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
          left: BorderSide(color: AppColors.forLevel(level), width: 3),
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onProfileTap, required this.onMenuAction});

  final VoidCallback onProfileTap;
  final Function(String) onMenuAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Lottie.asset(
              'assets/animations/logo_animation.json',
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              'NEURO WORD',
              style: GoogleFonts.orbitron(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: onProfileTap,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.electricBlue, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surfaceMedium,
                  child: Icon(
                    Icons.person,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.electricBlue),
              color: AppColors.surfaceMedium,
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: onMenuAction,
              itemBuilder: (BuildContext context) {
                return [
                  _buildPopupMenuItem(
                    'supporters',
                    AppStrings.menuAbout,
                    Icons.info_outline_rounded,
                  ),
                  _buildPopupMenuItem(
                    'contact',
                    AppStrings.menuContact,
                    Icons.mail,
                  ),
                  _buildPopupMenuItem(
                    'explore',
                    AppStrings.menuExplore,
                    Icons.explore,
                  ),
                ];
              },
            ),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String value,
    String text,
    IconData icon, {
    Color? color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color ?? AppColors.electricBlue, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.rajdhani(
              color: color ?? AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatsRow extends ConsumerWidget {
  const _QuickStatsRow();

  static String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(wordStatisticsProvider);
    final favoriteCount = ref.watch(favoriteCountProvider);
    final allWordsCount = ref.watch(wordProvider.select((s) => s.allWords.length));

    final totalCount = stats.totalWords > 0
        ? stats.totalWords
        : allWordsCount;
    final learnedCount = stats.totalLearned;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: AppStrings.statsTotal,
            value: _fmt(totalCount),
            icon: Icons.data_usage_rounded,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: AppStrings.statsLearned,
            value: _fmt(learnedCount),
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.neonGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: AppStrings.statsFavorite,
            value: _fmt(favoriteCount),
            icon: Icons.bookmark_border_rounded,
            color: AppColors.neonPink,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.orbitron(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.rajdhani(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCardsGrid extends ConsumerWidget {
  const _FeatureCardsGrid();

  static const _gameRoutes = {'/flashcards', '/cyber-match', '/neon-pulse', '/flash-memory'};

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
      Icons.memory_rounded,
      AppStrings.flashMemory,
      AppStrings.flashMemoryDesc,
      AppColors.accentOrange,
      '/flash-memory',
    ),
  ];

  void _onGameTap(BuildContext context, String route) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LevelSelectorSheet(route: route),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        final isGame = f.route != null && _gameRoutes.contains(f.route);
        return GlassCard(
          padding: const EdgeInsets.all(16),
          accentColor: f.color,
          onTap: f.route != null
              ? () => isGame
                    ? _onGameTap(context, f.route!)
                    : context.push(f.route!)
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  NeonIconBox(icon: f.icon, color: f.color),
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

class _LevelSelectorSheet extends ConsumerWidget {
  const _LevelSelectorSheet({required this.route});
  final String route;

  static const _orderedLevels = ['A1', 'A2', 'B1', 'B2', 'C1'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordState = ref.watch(wordProvider);
    final rankState = ref.watch(rankProvider);

    final b2Mastery = rankState.levelMastery['B2'] ?? 0.0;
    final c1Unlocked = b2Mastery >= 0.60;

    Map<String, int> levelCounts;
    if (wordState.allLevelCounts.isNotEmpty) {
      levelCounts = wordState.allLevelCounts;
    } else {
      levelCounts = <String, int>{};
      for (final w in wordState.allWords) {
        levelCounts[w.level] = (levelCounts[w.level] ?? 0) + 1;
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.electricBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                AppStrings.selectLevelSheet,
                style: GoogleFonts.orbitron(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 13),
            child: Text(
              AppStrings.selectLevelPrompt,
              style: GoogleFonts.rajdhani(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 20),

          _LevelTile(
            label: AppStrings.allLevels,
            sublabel: AppStrings.wordCount(wordState.dbTotalWordCount > 0 ? wordState.dbTotalWordCount : wordState.allWords.length),
            color: AppColors.electricBlue,
            isLocked: false,
            onTap: () {
              Navigator.pop(context);
              context.push(route);
            },
          ),
          const SizedBox(height: 8),

          ...(_orderedLevels.map((level) {
            final count = levelCounts[level] ?? 0;
            final isC1 = level == 'C1';
            final locked = isC1 && !c1Unlocked;
            final b2Pct = (b2Mastery * 100).toStringAsFixed(0);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _LevelTile(
                label: level,
                sublabel: locked
                    ? AppStrings.unlockPrompt(b2Pct)
                    : count > 0
                    ? AppStrings.wordCount(count)
                    : AppStrings.noWordsLoaded,
                color: AppColors.forLevel(level),
                isLocked: locked,
                isDisabled: count == 0 && !locked,
                onTap: locked || count == 0
                    ? null
                    : () {
                        Navigator.pop(context);
                        context.push('$route?level=$level');
                      },
              ),
            );
          })),
        ],
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.isLocked,
    this.isDisabled = false,
    this.onTap,
  });

  final String label;
  final String sublabel;
  final Color color;
  final bool isLocked;
  final bool isDisabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = (isLocked || isDisabled)
        ? AppColors.textMuted
        : color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: (isLocked || isDisabled)
              ? AppColors.surfaceMedium.withValues(alpha: 0.6)
              : effectiveColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (isLocked || isDisabled)
                ? AppColors.cardBorder
                : effectiveColor.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: effectiveColor.withValues(alpha: 0.12),
                border: Border.all(
                  color: effectiveColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: isLocked
                    ? Icon(
                        Icons.lock_rounded,
                        color: AppColors.textMuted,
                        size: 18,
                      )
                    : Text(
                        label.length <= 2 ? label : label[0],
                        style: GoogleFonts.orbitron(
                          color: effectiveColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.orbitron(
                      color: (isLocked || isDisabled)
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: GoogleFonts.rajdhani(
                      color: isLocked
                          ? AppColors.accentOrange.withValues(alpha: 0.8)
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (!isLocked && !isDisabled)
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: effectiveColor.withValues(alpha: 0.6),
                size: 14,
              ),
            if (isLocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.accentOrange.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  AppStrings.locked,
                  style: GoogleFonts.orbitron(
                    color: AppColors.accentOrange,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerWordList extends StatelessWidget {
  const _ShimmerWordList();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceMedium,
      highlightColor: AppColors.surfaceLight,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.surfaceMedium,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends ConsumerWidget {
  const _ErrorCard({required this.error});

  final String error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warningRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warningRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.warningRed,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.dataFlowError,
            style: GoogleFonts.orbitron(
              color: AppColors.warningRed,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: GoogleFonts.rajdhani(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => ref.read(wordProvider.notifier).reload(),
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            label: Text(
              AppStrings.retryButton,
              style: GoogleFonts.orbitron(color: AppColors.textPrimary),
            ),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.warningRed.withValues(alpha: 0.2),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeonGlitch3500 extends StatefulWidget {
  const _NeonGlitch3500();

  @override
  State<_NeonGlitch3500> createState() => _NeonGlitch3500State();
}

class _NeonGlitch3500State extends State<_NeonGlitch3500>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _glitchCtrl;
  late Animation<double> _pulse;
  late Animation<double> _glitch;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _glitchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _glitch = CurvedAnimation(parent: _glitchCtrl, curve: Curves.linear);

    _scheduleGlitch();
  }

  void _scheduleGlitch() {
    Future.delayed(const Duration(milliseconds: 3200), () async {
      if (!mounted) return;
      await _glitchCtrl.forward();
      if (!mounted) return;
      _glitchCtrl.reset();
      await Future.delayed(const Duration(milliseconds: 60));
      if (!mounted) return;
      await _glitchCtrl.forward();
      if (!mounted) return;
      _glitchCtrl.reset();
      _scheduleGlitch();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _glitchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _glitchCtrl]),
      builder: (context, child) {
        final isGlitching = _glitch.value > 0;
        final offsetX = isGlitching ? (_glitch.value * 3) : 0.0;

        return Transform.translate(
          offset: Offset(offsetX, 0),
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: isGlitching
                  ? [
                      AppColors.glitchRed,
                      AppColors.electricBlue,
                      AppColors.neonCyan,
                    ]
                  : [
                      AppColors.electricBlue,
                      AppColors.neonCyan,
                      AppColors.electricBlue,
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              '3000+',
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                height: 1.4,
                shadows: [
                  Shadow(
                    color: isGlitching
                        ? AppColors.glitchRed.withOpacity(0.9)
                        : AppColors.electricBlue.withOpacity(
                            0.5 + 0.4 * _pulse.value,
                          ),
                    blurRadius: isGlitching ? 20 : 10,
                    offset: Offset(isGlitching ? -2 : 0, 0),
                  ),
                  if (isGlitching)
                    Shadow(
                      color: AppColors.electricBlue.withOpacity(0.8),
                      blurRadius: 16,
                      offset: const Offset(2, 0),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
