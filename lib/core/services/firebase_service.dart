import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../features/learning/models/word_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionPath = 'words';

  Future<List<WordModel>> fetchWords({String? level}) async {
    try {
      Query query = _firestore.collection(_collectionPath);

      if (level != null && level.isNotEmpty) {
        query = query.where('level', isEqualTo: level);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        return WordModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          docId: doc.id,
        );
      }).toList();
    } on FirebaseException catch (e) {
      debugPrint('[Firestore ERROR] code: ${e.code} | message: ${e.message}');
      throw Exception('Firestore [${e.code}]: ${e.message}');
    } catch (e) {
      debugPrint('[Firestore ERROR] unexpected: $e');
      rethrow;
    }
  }
}
