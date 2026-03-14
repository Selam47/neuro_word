import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuro_word/core/services/firebase_service.dart';
import 'package:neuro_word/core/services/user_profile_service.dart';
import 'package:neuro_word/features/learning/models/word_model.dart';
import 'package:neuro_word/features/learning/providers/word_sets_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WordState {
  const WordState({
    this.allWords = const [],
    this.filteredWords = const [],
    this.activeLevel,
    this.activeCategory,
    this.searchQuery = '',
    this.onlySaved = false,
    this.isLoading = false,
    this.error,
    this.userXp = 0,
  });

  final List<WordModel> allWords;
  final List<WordModel> filteredWords;
  final String? activeLevel;
  final String? activeCategory;
  final String searchQuery;
  final bool onlySaved;
  final bool isLoading;
  final String? error;
  final int userXp;

  WordState copyWith({
    List<WordModel>? allWords,
    List<WordModel>? filteredWords,
    String? activeLevel,
    String? activeCategory,
    String? searchQuery,
    bool? onlySaved,
    bool? isLoading,
    String? error,
    int? userXp,
    bool clearLevel = false,
    bool clearCategory = false,
    bool clearError = false,
  }) {
    return WordState(
      allWords: allWords ?? this.allWords,
      filteredWords: filteredWords ?? this.filteredWords,
      activeLevel: clearLevel ? null : (activeLevel ?? this.activeLevel),
      activeCategory: clearCategory
          ? null
          : (activeCategory ?? this.activeCategory),
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
  final _service = FirebaseService();
  final _profile = UserProfileService();
  final _random = Random();

  static const _wordCacheKey = 'cached_words_json';

  static const List<String> _levelHierarchy = ['A1', 'A2', 'B1', 'B2', 'C1'];

  static List<String> _levelsFromMinimum(String minLevel) {
    final idx = _levelHierarchy.indexOf(minLevel);
    if (idx < 0) return List<String>.from(_levelHierarchy);
    return _levelHierarchy.sublist(idx);
  }

  @override
  WordState build() {
    ref.listen<Set<int>>(savedWordsProvider, (_, __) {
      if (state.onlySaved && state.allWords.isNotEmpty) _applyFilters();
    });
    Future.microtask(_loadWords);
    return const WordState(isLoading: true);
  }

  Future<void> _loadWords() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      List<WordModel> words;

      try {
        final minLevel = _profile.proficiencyLevel;
        final levelsToFetch = _levelsFromMinimum(minLevel);
        words = await _service.fetchWords(levels: levelsToFetch);
        await _saveWordsToCache(words);
      } catch (e) {
        debugPrint('[WordProvider] Firestore failed, trying cache: $e');
        words = await _loadWordsFromCache();
        if (words.isEmpty) rethrow;
      }

      final learnedIds = _profile.getLearnedWords().toSet();
      final favoriteIds = _profile.getFavoriteWords().toSet();
      final xp = _profile.getXp();

      ref.read(learnedWordsProvider.notifier).init(learnedIds);
      ref.read(savedWordsProvider.notifier).init(favoriteIds);

      final mergedWords = words.map((w) {
        return w.copyWith(
          isLearned: learnedIds.contains(w.id),
          isFavorite: favoriteIds.contains(w.id),
        );
      }).toList();

      state = state.copyWith(
        allWords: mergedWords,
        filteredWords: mergedWords,
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

  void filterByCategory(String? category) {
    if (category == null || category.isEmpty) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(activeCategory: category);
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

    if (state.activeCategory != null) {
      result = result.where((w) => w.category == state.activeCategory).toList();
    }

    if (state.onlySaved) {
      result = result.where((w) => ref.read(savedWordsProvider).contains(w.id)).toList();
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
    final learned = ref.read(learnedWordsProvider);
    var pool = state.allWords.where((w) => !learned.contains(w.id));
    if (level != null && level.isNotEmpty) {
      pool = pool.where((w) => w.level == level);
    }
    var list = pool.toList()..shuffle(_random);

    if (list.length < count) {
      var extra = state.allWords
          .where((w) => learned.contains(w.id))
          .toList()
        ..shuffle(_random);
      if (level != null && level.isNotEmpty) {
        extra = extra.where((w) => w.level == level).toList();
      }
      list.addAll(extra);
    }

    return list.take(count).toList();
  }

  List<WordModel> getDistractors(int count, {required Set<int> excludeIds}) {
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
