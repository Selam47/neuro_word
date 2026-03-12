import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuro_word/core/services/user_profile_service.dart';

class LearnedWordsNotifier extends Notifier<Set<int>> {
  final _profile = UserProfileService();

  @override
  Set<int> build() => const {};

  void init(Set<int> ids) {
    state = ids;
  }

  Future<void> toggle(int wordId) async {
    if (state.contains(wordId)) {
      await _profile.removeLearnedWord(wordId);
      state = {...state}..remove(wordId);
    } else {
      await _profile.saveLearnedWord(wordId);
      state = {...state, wordId};
    }
  }

  Future<void> addAll(List<int> wordIds) async {
    if (wordIds.isEmpty) return;
    await _profile.saveLearnedWordsBatch(wordIds);
    state = {...state, ...wordIds};
  }
}

class SavedWordsNotifier extends Notifier<Set<int>> {
  final _profile = UserProfileService();

  @override
  Set<int> build() => const {};

  void init(Set<int> ids) {
    state = ids;
  }

  Future<void> toggle(int wordId) async {
    await _profile.toggleFavoriteWord(wordId);
    if (state.contains(wordId)) {
      state = {...state}..remove(wordId);
    } else {
      state = {...state, wordId};
    }
  }
}

final learnedWordsProvider = NotifierProvider<LearnedWordsNotifier, Set<int>>(
  LearnedWordsNotifier.new,
);

final savedWordsProvider = NotifierProvider<SavedWordsNotifier, Set<int>>(
  SavedWordsNotifier.new,
);
