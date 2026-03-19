import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuro_word/core/services/supabase_service.dart';
import 'package:neuro_word/core/services/user_profile_service.dart';
import 'package:neuro_word/features/learning/models/user_progress_model.dart';

class UserProgressState {
  const UserProgressState({
    this.progressList = const [],
    this.learnedIds = const <String>{},
    this.favoriteIds = const <String>{},
    this.isLoading = false,
    this.error,
  });

  final List<UserProgressModel> progressList;
  final Set<String> learnedIds;
  final Set<String> favoriteIds;
  final bool isLoading;
  final String? error;

  bool isWordLearned(String wordId) => learnedIds.contains(wordId);
  bool isWordFavorite(String wordId) => favoriteIds.contains(wordId);

  UserProgressState copyWith({
    List<UserProgressModel>? progressList,
    Set<String>? learnedIds,
    Set<String>? favoriteIds,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return UserProgressState(
      progressList: progressList ?? this.progressList,
      learnedIds: learnedIds ?? this.learnedIds,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class UserProgressNotifier extends Notifier<UserProgressState> {
  final _supabase = SupabaseService();
  final _profile = UserProfileService();

  @override
  UserProgressState build() => const UserProgressState();

  Future<void> loadFromSupabase() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final progressRows = await _supabase.fetchUserProgress();
      if (progressRows.isNotEmpty) {
        _applyProgressList(progressRows, isLoading: false);
        return;
      }
      await _migrateLocalToCloud();
      final refreshed = await _supabase.fetchUserProgress();
      _applyProgressList(refreshed, isLoading: false);
    } catch (e) {
      debugPrint('[UserProgressNotifier] loadFromSupabase failed: $e');
      _fallbackToLocal();
    }
  }

  void init({
    required Set<String> learnedIds,
    required Set<String> favoriteIds,
  }) {
    if (state.progressList.isNotEmpty) return;

    final uid = _supabase.currentUserId ?? 'local';
    final combined = <UserProgressModel>[];

    for (final wid in learnedIds) {
      combined.add(UserProgressModel(
        id: '',
        userId: uid,
        wordId: wid,
        isLearned: true,
        isFavorite: favoriteIds.contains(wid),
      ));
    }

    for (final wid in favoriteIds) {
      if (!learnedIds.contains(wid)) {
        combined.add(UserProgressModel(
          id: '',
          userId: uid,
          wordId: wid,
          isLearned: false,
          isFavorite: true,
        ));
      }
    }

    state = state.copyWith(
      progressList: combined,
      learnedIds: Set<String>.of(learnedIds),
      favoriteIds: Set<String>.of(favoriteIds),
      isLoading: false,
    );

    if (_supabase.currentUserId != null) {
      unawaited(loadFromSupabase());
    }
  }

  Future<void> toggleLearned(String wordId) async {
    final newValue = !state.learnedIds.contains(wordId);
    _updateLocalProgress(wordId, isLearned: newValue);
    unawaited(_syncLearned(wordId, newValue));
  }

  Future<void> _syncLearned(String wordId, bool isLearned) async {
    try {
      if (isLearned) {
        await _profile.saveLearnedWordId(wordId);
      } else {
        await _profile.removeLearnedWordId(wordId);
      }
      await _supabase.upsertLearned(wordId, isLearned);
    } catch (e) {
      debugPrint('[UserProgressNotifier] syncLearned failed: $e');
    }
  }

  Future<void> addAllLearned(List<String> wordIds) async {
    if (wordIds.isEmpty) return;
    final uid = _supabase.currentUserId ?? 'local';
    final updated = List<UserProgressModel>.of(state.progressList);

    for (final wid in wordIds) {
      final idx = updated.indexWhere((p) => p.wordId == wid);
      if (idx >= 0) {
        updated[idx] = updated[idx].copyWith(isLearned: true);
      } else {
        updated.add(UserProgressModel(
          id: '',
          userId: uid,
          wordId: wid,
          isLearned: true,
        ));
      }
    }

    final newLearned = updated
        .where((p) => p.isLearned)
        .map((p) => p.wordId)
        .toSet();

    state = state.copyWith(
      progressList: updated,
      learnedIds: newLearned,
    );

    unawaited(_profile.saveLearnedWordIdsBatch(wordIds));
    unawaited(_supabase
        .upsertLearnedBatch(wordIds)
        .catchError((Object e) => debugPrint('[UserProgressNotifier] batchSync failed: $e')));
  }

  Future<void> toggleFavorite(String wordId) async {
    final newValue = !state.favoriteIds.contains(wordId);
    _updateLocalProgress(wordId, isFavorite: newValue);
    unawaited(_syncFavorite(wordId, newValue));
  }

  Future<void> _syncFavorite(String wordId, bool isFavorite) async {
    try {
      await _profile.toggleFavoriteWordId(wordId);
      await _supabase.upsertFavorite(wordId, isFavorite);
    } catch (e) {
      debugPrint('[UserProgressNotifier] syncFavorite failed: $e');
    }
  }

  void _updateLocalProgress(
    String wordId, {
    bool? isLearned,
    bool? isFavorite,
  }) {
    final uid = _supabase.currentUserId ?? 'local';
    final updated = List<UserProgressModel>.of(state.progressList);
    final idx = updated.indexWhere((p) => p.wordId == wordId);

    if (idx >= 0) {
      updated[idx] = updated[idx].copyWith(
        isLearned: isLearned ?? updated[idx].isLearned,
        isFavorite: isFavorite ?? updated[idx].isFavorite,
      );
    } else {
      updated.add(UserProgressModel(
        id: '',
        userId: uid,
        wordId: wordId,
        isLearned: isLearned ?? false,
        isFavorite: isFavorite ?? false,
      ));
    }

    final newLearned = updated
        .where((p) => p.isLearned)
        .map((p) => p.wordId)
        .toSet();

    final newFavorites = updated
        .where((p) => p.isFavorite)
        .map((p) => p.wordId)
        .toSet();

    state = state.copyWith(
      progressList: updated,
      learnedIds: newLearned,
      favoriteIds: newFavorites,
    );
  }

  void _applyProgressList(
    List<UserProgressModel> progressList, {
    required bool isLoading,
  }) {
    final learnedIds = progressList
        .where((p) => p.isLearned)
        .map((p) => p.wordId)
        .toSet();
    final favoriteIds = progressList
        .where((p) => p.isFavorite)
        .map((p) => p.wordId)
        .toSet();

    state = state.copyWith(
      progressList: progressList,
      learnedIds: learnedIds,
      favoriteIds: favoriteIds,
      isLoading: isLoading,
    );
  }

  Future<void> _migrateLocalToCloud() async {
    final uid = _supabase.currentUserId;
    if (uid == null) return;

    final localLearned = _profile.getLearnedWordIds();
    final localFavorites = _profile.getFavoriteWordIds();
    if (localLearned.isEmpty && localFavorites.isEmpty) return;

    debugPrint(
        '[UserProgressNotifier] migrating ${localLearned.length} learned, ${localFavorites.length} favorites');

    final allWordIds = {...localLearned, ...localFavorites}.toList();

    try {
      for (var i = 0; i < allWordIds.length; i += 50) {
        final batch = allWordIds.sublist(
            i, (i + 50).clamp(0, allWordIds.length));
        final learnedBatch =
            batch.where((wid) => localLearned.contains(wid)).toList();
        if (learnedBatch.isNotEmpty) {
          await _supabase.upsertLearnedBatch(learnedBatch);
        }
        for (final wid in batch) {
          if (localFavorites.contains(wid)) {
            await _supabase.upsertFavorite(wid, true);
          }
        }
      }
    } catch (e) {
      debugPrint('[UserProgressNotifier] migration failed: $e');
    }
  }

  void _fallbackToLocal() {
    final learnedIds = _profile.getLearnedWordIds();
    final favoriteIds = _profile.getFavoriteWordIds();
    init(learnedIds: learnedIds, favoriteIds: favoriteIds);
  }
}

final userProgressProvider =
    NotifierProvider<UserProgressNotifier, UserProgressState>(
  UserProgressNotifier.new,
);

final learnedCountProvider = Provider<int>((ref) {
  return ref.watch(
    userProgressProvider.select((s) => s.learnedIds.length),
  );
});

final favoriteCountProvider = Provider<int>((ref) {
  return ref.watch(
    userProgressProvider.select((s) => s.favoriteIds.length),
  );
});
