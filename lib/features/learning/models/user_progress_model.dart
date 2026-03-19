class UserProgressModel {
  const UserProgressModel({
    required this.id,
    required this.userId,
    required this.wordId,
    this.isLearned = false,
    this.isFavorite = false,
    this.learnedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String wordId;
  final bool isLearned;
  final bool isFavorite;
  final DateTime? learnedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserProgressModel.fromSupabase(Map<String, dynamic> data) {
    return UserProgressModel(
      id: data['id']?.toString() ?? '',
      userId: data['user_id']?.toString() ?? '',
      wordId: data['word_id']?.toString() ?? '',
      isLearned: data['is_learned'] as bool? ?? false,
      isFavorite: data['is_favorite'] as bool? ?? false,
      learnedAt: data['learned_at'] != null
          ? DateTime.tryParse(data['learned_at'].toString())
          : null,
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString())
          : null,
      updatedAt: data['updated_at'] != null
          ? DateTime.tryParse(data['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toUpsertMap() {
    return {
      'user_id': userId,
      'word_id': wordId,
      'is_learned': isLearned,
      'is_favorite': isFavorite,
      if (isLearned && learnedAt == null)
        'learned_at': DateTime.now().toIso8601String(),
      if (!isLearned) 'learned_at': null,
    };
  }

  UserProgressModel copyWith({
    String? id,
    String? userId,
    String? wordId,
    bool? isLearned,
    bool? isFavorite,
    DateTime? learnedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProgressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      wordId: wordId ?? this.wordId,
      isLearned: isLearned ?? this.isLearned,
      isFavorite: isFavorite ?? this.isFavorite,
      learnedAt: learnedAt ?? this.learnedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProgressModel &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          wordId == other.wordId;

  @override
  int get hashCode => userId.hashCode ^ wordId.hashCode;

  @override
  String toString() =>
      'UserProgress(wordId: $wordId, learned: $isLearned, fav: $isFavorite)';
}
