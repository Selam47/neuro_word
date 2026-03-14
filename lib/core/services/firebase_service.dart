import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/learning/models/word_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionPath = 'words';

  Future<List<WordModel>> fetchWords({String? level}) async {
    try {
      final List<WordModel> allWords = [];

      Query query = _firestore.collection(_collectionPath);
      if (level != null && level.isNotEmpty) {
        query = query.where('level', isEqualTo: level);
      }

      final snapshot = await query.get();
      allWords.addAll(
        snapshot.docs.map((doc) {
          return WordModel.fromFirestore(
            doc.data() as Map<String, dynamic>,
            docId: doc.id,
          );
        }),
      );

      return allWords;
    } on FirebaseException catch (e) {
      throw Exception('Firestore [${e.code}]: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }
}
