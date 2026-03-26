import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/learning/models/word_model.dart';
import '../../features/learning/models/user_progress_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _wordsTable = 'words';
  static const String _progressTable = 'user_progress';
  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(seconds: 2);

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<T> _withRetry<T>(Future<T> Function() action, {int retries = _maxRetries}) async {
    for (var attempt = 0; attempt <= retries; attempt++) {
      try {
        return await action();
      } catch (e) {
        if (attempt >= retries) rethrow;
        debugPrint('[SupabaseService] retry ${attempt + 1}/$retries after: $e');
        await Future<void>.delayed(_retryDelay);
      }
    }
    throw StateError('Unreachable');
  }

  Future<List<WordModel>> fetchWords({List<String>? levels}) async {
    return _withRetry(() async {
      PostgrestFilterBuilder query = _client.from(_wordsTable).select('*');
      if (levels != null && levels.isNotEmpty) {
        query = query.inFilter('level', levels);
      }
      final List<dynamic> response =
          await query.timeout(const Duration(seconds: 15));
      return response
          .map((row) => WordModel.fromSupabase(row as Map<String, dynamic>))
          .toList();
    });
  }

  Future<List<UserProgressModel>> fetchUserProgress() async {
    final uid = currentUserId;
    if (uid == null) return [];
    try {
      final List<dynamic> response = await _client
          .from(_progressTable)
          .select('*')
          .eq('user_id', uid);
      return response
          .map((row) =>
              UserProgressModel.fromSupabase(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[SupabaseService] fetchUserProgress failed: $e');
      return [];
    }
  }

  Future<void> upsertLearned(String wordId, bool isLearned) async {
    final uid = currentUserId;
    if (uid == null) return;
    try {
      await _client.from(_progressTable).upsert(
        {
          'user_id': uid,
          'word_id': wordId,
          'is_learned': isLearned,
          if (isLearned) 'learned_at': DateTime.now().toIso8601String(),
          if (!isLearned) 'learned_at': null,
        },
        onConflict: 'user_id,word_id',
      );
    } catch (e) {
      debugPrint('[SupabaseService] upsertLearned failed: $e');
      rethrow;
    }
  }

  Future<void> upsertFavorite(String wordId, bool isFavorite) async {
    final uid = currentUserId;
    if (uid == null) return;
    try {
      await _client.from(_progressTable).upsert(
        {
          'user_id': uid,
          'word_id': wordId,
          'is_favorite': isFavorite,
        },
        onConflict: 'user_id,word_id',
      );
    } catch (e) {
      debugPrint('[SupabaseService] upsertFavorite failed: $e');
      rethrow;
    }
  }

  Future<Map<String, int>> fetchAllLevelCounts() async {
    return _withRetry(() async {
      final List<dynamic> response = await _client
          .from(_wordsTable)
          .select('level')
          .timeout(const Duration(seconds: 15));
      final counts = <String, int>{};
      for (final row in response) {
        final level = (row as Map<String, dynamic>)['level'] as String? ?? '';
        if (level.isNotEmpty) counts[level] = (counts[level] ?? 0) + 1;
      }
      return counts;
    }).catchError((Object e) {
      debugPrint('[SupabaseService] fetchAllLevelCounts failed: $e');
      return <String, int>{};
    });
  }

  Future<void> upsertLearnedBatch(List<String> wordIds) async {
    final uid = currentUserId;
    if (uid == null || wordIds.isEmpty) return;
    try {
      final now = DateTime.now().toIso8601String();
      final rows = wordIds
          .map((wid) => {
                'user_id': uid,
                'word_id': wid,
                'is_learned': true,
                'learned_at': now,
              })
          .toList();
      await _client.from(_progressTable).upsert(
        rows,
        onConflict: 'user_id,word_id',
      );
    } catch (e) {
      debugPrint('[SupabaseService] upsertLearnedBatch failed: $e');
      rethrow;
    }
  }
}
