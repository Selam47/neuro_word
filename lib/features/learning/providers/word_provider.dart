import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuro_word/core/services/supabase_service.dart';
import 'package:neuro_word/core/services/user_profile_service.dart';
import 'package:neuro_word/features/learning/models/rank_model.dart';
import 'package:neuro_word/features/learning/models/word_model.dart';
import 'package:neuro_word/features/learning/providers/word_sets_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WordState {
  const WordState({
    this.allWords = const [],
    this.filteredWords = const [],
    this.allLevelCounts = const {},
    this.activeLevel,
    this.searchQuery = '',
    this.onlySaved = false,
    this.isLoading = false,
    this.error,
    this.userXp = 0,
  });

  final List<WordModel> allWords;
  final List<WordModel> filteredWords;
  final Map<String, int> allLevelCounts;
  final String? activeLevel;
  final String searchQuery;
  final bool onlySaved;
  final bool isLoading;
  final String? error;
  final int userXp;

  int get dbTotalWordCount => allLevelCounts.values.fold(0, (a, b) => a + b);

  WordState copyWith({
    List<WordModel>? allWords,
    List<WordModel>? filteredWords,
    Map<String, int>? allLevelCounts,
    String? activeLevel,
    String? searchQuery,
    bool? onlySaved,
    bool? isLoading,
    String? error,
    int? userXp,
    bool clearLevel = false,
    bool clearError = false,
  }) {
    return WordState(
      allWords: allWords ?? this.allWords,
      filteredWords: filteredWords ?? this.filteredWords,
      allLevelCounts: allLevelCounts ?? this.allLevelCounts,
      activeLevel: clearLevel ? null : (activeLevel ?? this.activeLevel),
      searchQuery: searchQuery ?? this.searchQuery,
      onlySaved: onlySaved ?? this.onlySaved,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      userXp: userXp ?? this.userXp,
    );
  }

  List<String> get availableLevels =>
      allWords.map((w) => w.level).toSet().toList()..sort();
}

class WordNotifier extends Notifier<WordState> {
  final _service = SupabaseService();
  final _profile = UserProfileService();
  final _random = Random();

  static const _wordCacheKey = 'cached_words_json';
  static const _levelCountsCacheKey = 'cached_level_counts_json';

  static const List<String> _levelHierarchy = ['A1', 'A2', 'B1', 'B2', 'C1'];

  static List<String> _levelsFromMinimum(String minLevel) {
    final idx = _levelHierarchy.indexOf(minLevel);
    if (idx < 0) return List<String>.from(_levelHierarchy);
    return _levelHierarchy.sublist(idx);
  }

  @override
  WordState build() {
    ref.listen<UserProgressState>(userProgressProvider, (prev, next) {
      if (state.onlySaved && state.allWords.isNotEmpty) {
        final prevFavs = prev?.favoriteIds ?? const {};
        if (prevFavs != next.favoriteIds) Future.microtask(_applyFilters);
      }
    });
    Future.microtask(_loadWords);
    return const WordState(isLoading: true);
  }

  Future<void> _loadWords() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      List<WordModel> words;
      Map<String, int> levelCounts;

      final minLevel = _profile.proficiencyLevel;

      try {
        final levelsToFetch = _levelsFromMinimum(minLevel);
        final results = await Future.wait([
          _service.fetchWords(levels: levelsToFetch),
          _service.fetchAllLevelCounts(),
        ]);
        words = results[0] as List<WordModel>;
        levelCounts = results[1] as Map<String, int>;
        await _saveWordsToCache(words);
        await _saveLevelCountsToCache(levelCounts);
      } catch (e) {
        debugPrint('[WordProvider] Supabase failed, trying cache: $e');
        words = await _loadWordsFromCache();
        levelCounts = await _loadLevelCountsFromCache();
        if (words.isEmpty) rethrow;
      }

      final minIdx = _levelHierarchy.indexOf(minLevel);
      int preLearnedOffset = 0;
      for (var i = 0; i < minIdx; i++) {
        final lvl = _levelHierarchy[i];
        preLearnedOffset += levelCounts[lvl]
            ?? UserProfileService.estimatedWordsPerLevel[lvl]
            ?? 300;
      }
      await _profile.setPreLearnedOffset(preLearnedOffset);

      final xp = _profile.getXp();

      if (_service.currentUserId != null) {
        ref.read(userProgressProvider.notifier).loadFromSupabase();
      } else {
        final learnedIds = _profile.getLearnedWordIds();
        final favoriteIds = _profile.getFavoriteWordIds();
        ref.read(userProgressProvider.notifier).init(
          learnedIds: learnedIds,
          favoriteIds: favoriteIds,
        );
      }

      state = state.copyWith(
        allWords: words,
        filteredWords: words,
        allLevelCounts: levelCounts,
        isLoading: false,
        userXp: xp,
      );
      _applyFilters();
    } catch (e) {
      debugPrint('[WordProvider] fatal error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _saveWordsToCache(List<WordModel> words) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(words.map((w) => w.toJson()).toList());
      await prefs.setString(_wordCacheKey, json);
    } catch (e) {
      debugPrint('[WordProvider] cache save failed: $e');
    }
  }

  Future<List<WordModel>> _loadWordsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_wordCacheKey);
      if (json == null) return [];
      final List<dynamic> decoded = jsonDecode(json);
      return decoded
          .map((e) => WordModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[WordProvider] cache load failed: $e');
      return [];
    }
  }

  Future<void> _saveLevelCountsToCache(Map<String, int> counts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(counts);
      await prefs.setString(_levelCountsCacheKey, json);
    } catch (e) {
      debugPrint('[WordProvider] level counts cache save failed: $e');
    }
  }

  Future<Map<String, int>> _loadLevelCountsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_levelCountsCacheKey);
      if (json == null) return {};
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as int));
    } catch (e) {
      debugPrint('[WordProvider] level counts cache load failed: $e');
      return {};
    }
  }

  Future<void> reload() => _loadWords();

  void search(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void filterByLevel(String? level) {
    if (level == null || level.isEmpty) {
      state = state.copyWith(clearLevel: true);
    } else {
      state = state.copyWith(activeLevel: level);
    }
    _applyFilters();
  }

  void toggleSaved(bool enabled) {
    state = state.copyWith(onlySaved: enabled);
    _applyFilters();
  }

  void _applyFilters() {
    var result = state.allWords;

    if (state.activeLevel != null) {
      result = result.where((w) => w.level == state.activeLevel).toList();
    }

    if (state.onlySaved) {
      final favIds = ref.read(userProgressProvider).favoriteIds;
      result = result.where((w) => favIds.contains(w.id)).toList();
    }

    if (state.searchQuery.isNotEmpty) {
      final q = state.searchQuery.toLowerCase();
      result = result.where((w) {
        return w.english.toLowerCase().contains(q) ||
            w.turkish.toLowerCase().contains(q);
      }).toList();
    }

    state = state.copyWith(filteredWords: result);
  }

  List<WordModel> getRandomWords(int count, {String? level}) {
    final progress = ref.read(userProgressProvider);
    var pool = state.allWords.where((w) => !progress.learnedIds.contains(w.id));
    if (level != null && level.isNotEmpty) {
      pool = pool.where((w) => w.level == level);
    }
    var list = pool.toList()..shuffle(_random);

    if (list.length < count) {
      var extra = state.allWords
          .where((w) => progress.learnedIds.contains(w.id))
          .toList()
        ..shuffle(_random);
      if (level != null && level.isNotEmpty) {
        extra = extra.where((w) => w.level == level).toList();
      }
      list.addAll(extra);
    }

    return list.take(count).toList();
  }

  List<WordModel> getDistractors(int count, {required Set<String> excludeIds}) {
    final pool =
        state.allWords.where((w) => !excludeIds.contains(w.id)).toList()
          ..shuffle(_random);
    return pool.take(count).toList();
  }

  Future<void> addXp(int amount) async {
    await _profile.addXp(amount);
    state = state.copyWith(userXp: _profile.getXp());
  }
}

final wordProvider = NotifierProvider<WordNotifier, WordState>(
  WordNotifier.new,
);

class LevelStat {
  const LevelStat({
    required this.learned,
    required this.total,
    required this.pct,
    this.mastered = false,
  });
  final int learned;
  final int total;
  final double pct;
  final bool mastered;
  int get pctInt => (pct * 100).toInt();
}

class WordStatistics {
  const WordStatistics({
    this.overallProgress = 0.0,
    this.totalLearned = 0,
    this.totalWords = 0,
    this.levelBreakdown = const {},
    this.autoMasteredCount = 0,
  });
  final double overallProgress;
  final int totalLearned;
  final int totalWords;
  final Map<String, LevelStat> levelBreakdown;
  final int autoMasteredCount;
}

final wordStatisticsProvider = Provider<WordStatistics>((ref) {
  final ws = ref.watch(wordProvider);
  final learnedIds = ref.watch(
    userProgressProvider.select((s) => s.learnedIds),
  );

  if (ws.allWords.isEmpty) return const WordStatistics();

  final profile = UserProfileService();
  final userLevel = profile.proficiencyLevel;
  final userLevelIdx = levelIndex(userLevel);

  final levelTotals = <String, int>{};
  final levelLearned = <String, int>{};

  for (final w in ws.allWords) {
    levelTotals[w.level] = (levelTotals[w.level] ?? 0) + 1;
    if (learnedIds.contains(w.id)) {
      levelLearned[w.level] = (levelLearned[w.level] ?? 0) + 1;
    }
  }

  final breakdown = <String, LevelStat>{};
  int totalWords = 0;
  int totalLearned = 0;
  int autoMasteredCount = 0;

  for (final level in kLevelHierarchy) {
    final idx = levelIndex(level);

    if (idx < userLevelIdx) {
      final realCount = ws.allLevelCounts[level]
          ?? UserProfileService.estimatedWordsPerLevel[level]
          ?? 300;
      breakdown[level] = LevelStat(
        learned: realCount,
        total: realCount,
        pct: 1.0,
        mastered: true,
      );
      totalWords += realCount;
      totalLearned += realCount;
      autoMasteredCount += realCount;
    } else if (levelTotals.containsKey(level)) {
      final total = levelTotals[level]!;
      final learned = levelLearned[level] ?? 0;
      breakdown[level] = LevelStat(
        learned: learned,
        total: total,
        pct: total > 0 ? learned / total : 0.0,
        mastered: false,
      );
      totalWords += total;
      totalLearned += learned;
    }
  }

  final overallProgress =
      totalWords > 0 ? (totalLearned / totalWords).clamp(0.0, 1.0) : 0.0;

  return WordStatistics(
    overallProgress: overallProgress,
    totalLearned: totalLearned,
    totalWords: totalWords,
    levelBreakdown: breakdown,
    autoMasteredCount: autoMasteredCount,
  );
});
