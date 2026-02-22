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

import 'package:neuro_word/features/auth/providers/auth_provider.dart';
import 'package:neuro_word/shared/widgets/neon_search_bar.dart';

// ... (imports)

// ── Level Filter Logic ───────────────────────────────────────────────

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
                      case 'logout':
                        await ref.read(authServiceProvider).signOut();
                        if (context.mounted) context.go('/login');
                        break;
                      default:
                        break;
                    }
                  },
                ),
                const SizedBox(height: 28),

                const SizedBox(height: 32),

                _QuickStatsRow(wordState: wordState),
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
                  hintText: 'Ara (Kelime veya Anlam)...',
                ),
                const SizedBox(height: 8),

                _AdvancedFilterBar(wordState: wordState),
                const SizedBox(height: 16),


                if (wordState.isLoading)
                  const _ShimmerWordList()
                else if (wordState.error != null)
                  _ErrorCard(error: wordState.error!)
                else
                  _LiveWordList(
                    words: wordState.filteredWords,
                    isFiltered:
                        wordState.activeLevel != null ||
                        wordState.searchQuery.isNotEmpty ||
                        wordState.onlySaved ||
                        wordState.activeCategory != null,
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


// ── Advanced Filter Bar ──────────────────────────────────────────────────

class _AdvancedFilterBar extends ConsumerWidget {
  const _AdvancedFilterBar({required this.wordState});
  final WordState wordState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levels = wordState.availableLevels;
    final notifier = ref.read(wordProvider.notifier);

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildChip(
            label: 'Tümü', // All
            isSelected:
                wordState.activeLevel == null &&
                !wordState.onlySaved &&
                wordState.activeCategory == null,
            color: AppColors.electricBlue,
            onTap: () {
              notifier.filterByLevel(null);
              notifier.toggleSaved(false);
              notifier.filterByCategory(null);
              // Note: This logic resets all specific filters but keeps search query if any
            },
          ),
          const SizedBox(width: 8),

          _buildChip(
            label: 'Kaydedilenler', // Saved
            isSelected: wordState.onlySaved,
            color: AppColors.neonPink,
            onTap: () => notifier.toggleSaved(!wordState.onlySaved),
            icon: Icons.bookmark_rounded,
          ),
          const SizedBox(width: 8),

          _buildChip(
            label: 'Akademik',
            isSelected: wordState.activeCategory == 'Academic',
            color: AppColors.electricBlue,
            onTap: () {
              final newCat = wordState.activeCategory == 'Academic'
                  ? null
                  : 'Academic';
              notifier.filterByCategory(newCat);
            },
            icon: Icons.school_rounded,
          ),
          const SizedBox(width: 8),

          ...levels.map(
            (level) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildChip(
                label: level,
                isSelected: wordState.activeLevel == level,
                color: _getLevelColor(level),
                onTap: () {
                  final newLevel = wordState.activeLevel == level
                      ? null
                      : level;
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

// ... (DataActionBar, ShimmerWordList, ErrorCard remain unchanged)

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
                'Sistemde böyle bir veri bulunamadı',
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
            return _WordTile(
              word: word,
            ); // Assuming _WordTile is defined later in the file
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
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      // Restore card tap to toggle learned status
      onTap: () {
        if (word.isLearned) {
          ref.read(wordProvider.notifier).markUnlearned(word.id);
        } else {
          ref.read(wordProvider.notifier).markLearned(word.id);
        }
      },
      child: Row(
        children: [
          // Level Badge (New Style)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _getLevelColor(word.level).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getLevelColor(word.level).withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getLevelColor(word.level).withValues(alpha: 0.1),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Text(
              word.level,
              style: GoogleFonts.orbitron(
                color: _getLevelColor(word.level),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Word Info
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
                // Category Tag (Restored)
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

          // Actions Row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Favorite Button (New)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // Prevent card tap
                    ref.read(wordProvider.notifier).toggleFavorite(word.id);
                  },
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: word.isFavorite
                          ? AppColors.neonPink.withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                    child: Icon(
                      word.isFavorite
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: word.isFavorite
                          ? AppColors.neonPink
                          : AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Learned Indicator (Restored visual)
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
        ],
      ),
    );
  }
}

// ── Feature Cards Grid (from Phase 1) ───────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onProfileTap, required this.onMenuAction});

  final VoidCallback onProfileTap;
  final Function(String) onMenuAction;

  Null get style => null;

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
                    'Destek Verenler',
                    Icons.favorite,
                  ),
                  _buildPopupMenuItem('contact', 'İletişim', Icons.mail),
                  _buildPopupMenuItem('explore', 'Keşfet', Icons.explore),
                  const PopupMenuItem<String>(
                    height: 0,
                    child: Divider(color: AppColors.cardBorder),
                  ),
                  _buildPopupMenuItem(
                    'logout',
                    'Çıkış Yap',
                    Icons.logout,
                    color: AppColors.error,
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

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({required this.wordState});

  final WordState wordState;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Toplam',
            value: wordState.allWords.length.toString(),
            icon: Icons.data_usage_rounded,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Öğrenilen',
            value: wordState.learnedCount.toString(),
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.neonGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Favori',
            value: wordState.favoriteCount.toString(),
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
            'Veri Akış Hatası',
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
              'YENİDEN DENE',
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
