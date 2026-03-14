import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/learning/models/word_model.dart';
import 'refinery_service.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionPath = 'words';

  Future<List<WordModel>> fetchWords({List<String>? levels}) async {
    try {
      Query query = _firestore.collection(_collectionPath);
      if (levels != null && levels.isNotEmpty) {
        query = query.where('level', whereIn: levels);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        return WordModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          docId: doc.id,
        );
      }).toList();
    } on FirebaseException catch (e) {
      throw Exception('Firestore [${e.code}]: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addWord(Map<String, dynamic> data) async {
    final raw = data['en'] as String? ??
        data['english'] as String? ??
        data['word'] as String? ??
        '';
    final word = raw.toLowerCase().trim();

    if (word.isEmpty) {
      throw Exception('addWord rejected: empty English value');
    }
    if (RefineryService.isGarbage(word)) {
      throw Exception('addWord rejected: "$word" is classified as noise/garbage');
    }

    final level = data['level'] as String? ?? 'A1';
    final source = RefineryService.classifySource(word);
    final weight = RefineryService.computeWeight(word, level);

    await _firestore.collection(_collectionPath).add({
      ...data,
      'source': source,
      'difficultyWeight': weight,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveUserProfile(
    String username,
    String proficiencyLevel,
  ) async {
    await _firestore.collection('users').add({
      'username': username,
      'proficiencyLevel': proficiencyLevel,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
