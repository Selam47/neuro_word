import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/learning/models/word_model.dart';

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
}
