import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/learning/models/word_model.dart';
import '../../features/learning/models/user_progress_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _wordsTable = 'words';
  static const String _progressTable = 'user_progress';

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<WordModel>> fetchWords({List<String>? levels}) async {
    try {
      PostgrestFilterBuilder query = _client.from(_wordsTable).select('*');
      if (levels != null && levels.isNotEmpty) {
        query = query.inFilter('level', levels);
      }
      final List<dynamic> response = await query;
      return response
          .map((row) => WordModel.fromSupabase(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Supabase fetchWords failed: $e');
    }
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
