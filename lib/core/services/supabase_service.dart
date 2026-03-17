import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/learning/models/word_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _tableName = 'words';

  Future<List<WordModel>> fetchWords({List<String>? levels}) async {
    try {
      PostgrestFilterBuilder query = _client.from(_tableName).select('*');
      if (levels != null && levels.isNotEmpty) {
        query = query.inFilter('level', levels);
      }
      final List<dynamic> response = await query;
      return response.map((row) {
        return WordModel.fromSupabase(row as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception('Supabase fetch failed: $e');
    }
  }
}
