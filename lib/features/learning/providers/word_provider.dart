import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuro_word/core/services/storage_service.dart';
import 'package:neuro_word/core/services/firebase_service.dart';
import 'package:neuro_word/features/auth/providers/auth_provider.dart';
import 'package:neuro_word/features/learning/models/word_model.dart';

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

  int get learnedCount => allWords.where((w) => w.isLearned).length;

  int get favoriteCount => allWords.where((w) => w.isFavorite).length;

  List<String> get availableLevels =>
      allWords.map((w) => w.level).toSet().toList()..sort();
}

class WordNotifier extends Notifier<WordState> {
  final _service = FirebaseService();
  StorageService? _storageInstance;
  StorageService get _storage => _storageInstance ??= StorageService();

  final _random = Random();

  @override
  WordState build() {
    ref.watch(authStateProvider);
    _loadWords();
    return const WordState(isLoading: true);
  }

  Future<void> _loadWords() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _storage.init();

      final words = await _service.fetchWords();

      final authService = ref.read(authServiceProvider);
      final userId = authService.userId;

      Set<int> learnedIds = {};
      Set<int> favoriteIds = {};
      int xp = 0;

      if (userId.isNotEmpty) {
        final userData = await _service.getUserData(userId);
        if (userData != null) {
          learnedIds = Set<int>.from(
            userData['learned_words']?.cast<int>() ?? [],
          );
          favoriteIds = Set<int>.from(
            userData['favorite_words']?.cast<int>() ?? [],
          );
          xp = userData['xp'] ?? 0;
        }
      } else {
        learnedIds = _storage.getLearnedWords().toSet();
        favoriteIds = _storage.getFavoriteWords().toSet();
        xp = _storage.getXp();
      }

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
      state = state.copyWith(isLoading: false, error: e.toString());
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
      result = result.where((w) => w.isFavorite).toList();
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

  void markLearned(int wordId) {
    final userId = ref.read(authServiceProvider).userId;
    if (userId.isNotEmpty) {
      _service.updateLearnedWord(userId, wordId, true);
    } else {
      _storage.saveLearnedWord(wordId);
    }

    final updated = state.allWords
        .map((w) {
          return w.id == wordId ? w.copyWith(isLearned: true) : w;
        })
        .toList()
        .cast<WordModel>();
    state = state.copyWith(allWords: updated);
    _applyFilters();
  }

  void markUnlearned(int wordId) {
    final userId = ref.read(authServiceProvider).userId;
    if (userId.isNotEmpty) {
      _service.updateLearnedWord(userId, wordId, false);
    }

    final updated = state.allWords
        .map((w) {
          return w.id == wordId ? w.copyWith(isLearned: false) : w;
        })
        .toList()
        .cast<WordModel>();
    state = state.copyWith(allWords: updated);
    _applyFilters();
  }

  void markLearnedBatch(List<int> wordIds) {
    if (wordIds.isEmpty) return;

    final userId = ref.read(authServiceProvider).userId;
    if (userId.isNotEmpty) {
      for (final id in wordIds) {
        _service.updateLearnedWord(userId, id, true);
      }
    } else {
      _storage.saveLearnedWordsBatch(wordIds);
    }

    final idSet = wordIds.toSet();
    final updated = state.allWords
        .map((w) {
          return idSet.contains(w.id) ? w.copyWith(isLearned: true) : w;
        })
        .toList()
        .cast<WordModel>();

    state = state.copyWith(allWords: updated);
    _applyFilters();
  }

  void toggleFavorite(int wordId) {
    final userId = ref.read(authServiceProvider).userId;
    final isFavorite = !state.allWords
        .firstWhere((w) => w.id == wordId)
        .isFavorite;

    if (userId.isNotEmpty) {
      _service.updateFavoriteWord(userId, wordId, isFavorite);
    } else {
      _storage.toggleFavoriteWord(wordId);
    }

    final updated = state.allWords
        .map((w) {
          return w.id == wordId ? w.copyWith(isFavorite: isFavorite) : w;
        })
        .toList()
        .cast<WordModel>();
    state = state.copyWith(allWords: updated);
    _applyFilters();
  }

  void shuffle() {
    final shuffled = List<WordModel>.from(state.filteredWords)
      ..shuffle(_random);
    state = state.copyWith(filteredWords: shuffled);
  }

  List<WordModel> getRandomWords(int count, {String? level}) {
    var pool = state.allWords.where((w) => !w.isLearned);
    if (level != null && level.isNotEmpty) {
      pool = pool.where((w) => w.level == level);
    }
    var list = pool.toList()..shuffle(_random);

    if (list.length < count) {
      var extra = state.allWords.where((w) => w.isLearned).toList()
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
    final userId = ref.read(authServiceProvider).userId;
    if (userId.isNotEmpty) {
      await _service.updateXp(userId, amount);
      state = state.copyWith(userXp: state.userXp + amount);
    } else {
      await _storage.addXp(amount);
      state = state.copyWith(userXp: _storage.getXp());
    }
  }
}

final wordProvider = NotifierProvider<WordNotifier, WordState>(
  WordNotifier.new,
);
