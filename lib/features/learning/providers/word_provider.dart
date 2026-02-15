import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuro_word/core/services/storage_service.dart';
import 'package:neuro_word/features/learning/models/word_model.dart';
import 'package:neuro_word/features/learning/services/word_service.dart';

// ── State ───────────────────────────────────────────────────────────────

/// Immutable state container for the word engine.
class WordState {
  const WordState({
    this.allWords = const [],
    this.filteredWords = const [],
    this.activeLevel,
    this.isLoading = false,
    this.error,
  });

  final List<WordModel> allWords;
  final List<WordModel> filteredWords;
  final String? activeLevel;
  final bool isLoading;
  final String? error;

  WordState copyWith({
    List<WordModel>? allWords,
    List<WordModel>? filteredWords,
    String? activeLevel,
    bool? isLoading,
    String? error,
    bool clearLevel = false,
    bool clearError = false,
  }) {
    return WordState(
      allWords: allWords ?? this.allWords,
      filteredWords: filteredWords ?? this.filteredWords,
      activeLevel: clearLevel ? null : (activeLevel ?? this.activeLevel),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Count of learned words.
  int get learnedCount => allWords.where((w) => w.isLearned).length;

  /// Count of favorite words.
  int get favoriteCount => allWords.where((w) => w.isFavorite).length;

  /// Distinct level tags present in the data.
  List<String> get availableLevels =>
      allWords.map((w) => w.level).toSet().toList()..sort();
}

// ── Notifier ────────────────────────────────────────────────────────────

class WordNotifier extends Notifier<WordState> {
  late final WordService _service;
  late final StorageService _storage;
  final _random = Random();

  @override
  WordState build() {
    _service = const WordService();
    _storage = StorageService(); // Initialize storage
    _loadWords();
    return const WordState(isLoading: true);
  }

  // ── Load ──────────────────────────────────────────────────────────

  Future<void> _loadWords() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // 1. Init storage
      await _storage.init();
      
      // 2. Fetch remote/local JSON words
      final words = await _service.fetchWords();

      // 3. Load persisted IDs
      final learnedIds = _storage.getLearnedWords().toSet();
      final favoriteIds = _storage.getFavoriteWords().toSet();

      // 4. Merge
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
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Reload from JSON and re-sync with storage.
  Future<void> reload() => _loadWords();

  // ── Filter by Level ───────────────────────────────────────────────

  void filterByLevel(String? level) {
    if (level == null || level.isEmpty) {
      state = state.copyWith(
        filteredWords: state.allWords,
        clearLevel: true,
      );
    } else {
      state = state.copyWith(
        filteredWords:
            state.allWords.where((w) => w.level == level).toList(),
        activeLevel: level,
      );
    }
  }

  // ── Mark as Learned / Unlearned ───────────────────────────────────

  void markLearned(int wordId) {
    _storage.saveLearnedWord(wordId);
    final updated = state.allWords.map((w) {
      return w.id == wordId ? w.copyWith(isLearned: true) : w;
    }).toList().cast<WordModel>();
    state = state.copyWith(allWords: updated);
    filterByLevel(state.activeLevel);
  }

  void markUnlearned(int wordId) {
    // Note: We don't have a 'removeLearnedWord' in StorageService yet if we strictly follow 'saveLearnedWord'.
    // But typically we just add. If user wants to unlearn, we might need to add that method to StorageService.
    // For now assuming mostly additive learning.
    
    final updated = state.allWords.map((w) {
      return w.id == wordId ? w.copyWith(isLearned: false) : w;
    }).toList().cast<WordModel>();
    state = state.copyWith(allWords: updated);
    filterByLevel(state.activeLevel);
  }

  /// Batch-mark a list of word IDs as learned.
  void markLearnedBatch(List<int> wordIds) {
    if (wordIds.isEmpty) return;
    _storage.saveLearnedWordsBatch(wordIds);
    final idSet = wordIds.toSet();
    final updated = state.allWords.map((w) {
      return idSet.contains(w.id) ? w.copyWith(isLearned: true) : w;
    }).toList().cast<WordModel>();
    state = state.copyWith(allWords: updated);
    filterByLevel(state.activeLevel);
  }

  // ── Toggle Favorite ───────────────────────────────────────────────

  void toggleFavorite(int wordId) {
    _storage.toggleFavoriteWord(wordId);
    final updated = state.allWords.map((w) {
      return w.id == wordId ? w.copyWith(isFavorite: !w.isFavorite) : w;
    }).toList().cast<WordModel>();
    state = state.copyWith(allWords: updated);
    filterByLevel(state.activeLevel);
  }

  // ── Shuffle ───────────────────────────────────────────────────────

  void shuffle() {
    final shuffled = List<WordModel>.from(state.filteredWords)
      ..shuffle(_random);
    state = state.copyWith(filteredWords: shuffled);
  }

  // ── Random Word Selection (for games) ─────────────────────────────

  /// Returns [count] random *unlearned* words for the given [level].
  /// If [level] is null, picks from all levels.
  /// Falls back to learned words if not enough unlearned exist.
  List<WordModel> getRandomWords(int count, {String? level}) {
    var pool = state.allWords.where((w) => !w.isLearned);
    if (level != null && level.isNotEmpty) {
      pool = pool.where((w) => w.level == level);
    }
    var list = pool.toList()..shuffle(_random);

    // If not enough unlearned words, pad with learned ones
    if (list.length < count) {
      var extra = state.allWords
          .where((w) => w.isLearned)
          .toList()
        ..shuffle(_random);
      if (level != null && level.isNotEmpty) {
        extra = extra.where((w) => w.level == level).toList();
      }
      list.addAll(extra);
    }

    return list.take(count).toList();
  }

  /// Returns [count] random words that act as wrong-answer distractors,
  /// excluding the provided [excludeIds].
  List<WordModel> getDistractors(int count, {required Set<int> excludeIds}) {
    final pool = state.allWords
        .where((w) => !excludeIds.contains(w.id))
        .toList()
      ..shuffle(_random);
    return pool.take(count).toList();
  }

  // ── XP Management ─────────────────────────────────────────────────

  Future<void> addXp(int amount) async {
    await _storage.addXp(amount);
  }
}

// ── Provider ────────────────────────────────────────────────────────────

final wordProvider =
    NotifierProvider<WordNotifier, WordState>(WordNotifier.new);

