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
        debugPrint('Fetching words for level: $level');
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        return WordModel.fromFirestore(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching words: $e');
      rethrow;
    }
  }

  Future<void> createUserDocument(String uid) async {
    try {
      final userDoc = _firestore.collection('users').doc(uid);
      final snapshot = await userDoc.get();

      if (!snapshot.exists) {
        debugPrint('Creating new user profile for $uid');
        await userDoc.set({
          'learned_words': [],
          'favorite_words': [],
          'xp': 0,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error creating user document: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final snapshot = await _firestore.collection('users').doc(uid).get();
      return snapshot.data();
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }

  Future<void> updateLearnedWord(String uid, int wordId, bool isLearned) async {
    try {
      final userDoc = _firestore.collection('users').doc(uid);
      if (isLearned) {
        await userDoc.update({
          'learned_words': FieldValue.arrayUnion([wordId]),
        });
      } else {
        await userDoc.update({
          'learned_words': FieldValue.arrayRemove([wordId]),
        });
      }
    } catch (e) {
      debugPrint('Error updating learned word: $e');
    }
  }

  Future<void> updateFavoriteWord(
    String uid,
    int wordId,
    bool isFavorite,
  ) async {
    try {
      final userDoc = _firestore.collection('users').doc(uid);
      if (isFavorite) {
        await userDoc.update({
          'favorite_words': FieldValue.arrayUnion([wordId]),
        });
      } else {
        await userDoc.update({
          'favorite_words': FieldValue.arrayRemove([wordId]),
        });
      }
    } catch (e) {
      debugPrint('Error updating favorite word: $e');
    }
  }

  Future<void> updateXp(String uid, int amount) async {
    try {
      final userDoc = _firestore.collection('users').doc(uid);
      await userDoc.update({'xp': FieldValue.increment(amount)});
    } catch (e) {
      debugPrint('Error updating XP: $e');
    }
  }
}
