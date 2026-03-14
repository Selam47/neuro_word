class WordModel {
  const WordModel({
    required this.id,
    required this.english,
    required this.turkish,
    required this.level,
    required this.category,
    this.difficultyWeight = 1,
    this.cefr,
    this.isLearned = false,
    this.isFavorite = false,
  });

  final int id;
  final String english;
  final String turkish;
  final String level;
  final String category;
  final int difficultyWeight;
  final String? cefr;
  final bool isLearned;
  final bool isFavorite;

  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      id: json['id'] as int,
      english: json['english'] as String,
      turkish: json['turkish'] as String,
      level: json['level'] as String,
      category: json['category'] as String,
      difficultyWeight: json['difficultyWeight'] as int? ?? 1,
      cefr: json['cefr'] as String?,
      isLearned: json['isLearned'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  factory WordModel.fromFirestore(Map<String, dynamic> data, {String? docId}) {
    final rawId = (data['id'] as num?)?.toInt()
        ?? int.tryParse(docId ?? '')
        ?? docId?.hashCode.abs()
        ?? Object().hashCode.abs();

    final level = data['level'] as String?
        ?? data['cefr'] as String?
        ?? 'A1';

    return WordModel(
      id: rawId,
      english: data['en'] as String? ?? data['english'] as String? ?? data['word'] as String? ?? '',
      turkish: data['tr'] as String? ?? data['turkish'] as String? ?? data['meaning'] as String? ?? '',
      level: level,
      category: data['category'] as String? ?? 'General',
      difficultyWeight: (data['difficultyWeight'] as num?)?.toInt() ?? _defaultWeight(level),
      cefr: data['cefr'] as String? ?? level,
      isLearned: false,
      isFavorite: false,
    );
  }

  static int _defaultWeight(String level) {
    switch (level) {
      case 'A1': return 1;
      case 'A2': return 2;
      case 'B1': return 3;
      case 'B2': return 4;
      case 'C1': return 5;
      default: return 1;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'english': english,
      'turkish': turkish,
      'level': level,
      'category': category,
      'difficultyWeight': difficultyWeight,
      'cefr': cefr,
      'isLearned': isLearned,
      'isFavorite': isFavorite,
    };
  }

  WordModel copyWith({
    int? id,
    String? english,
    String? turkish,
    String? level,
    String? category,
    int? difficultyWeight,
    String? cefr,
    bool? isLearned,
    bool? isFavorite,
  }) {
    return WordModel(
      id: id ?? this.id,
      english: english ?? this.english,
      turkish: turkish ?? this.turkish,
      level: level ?? this.level,
      category: category ?? this.category,
      difficultyWeight: difficultyWeight ?? this.difficultyWeight,
      cefr: cefr ?? this.cefr,
      isLearned: isLearned ?? this.isLearned,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'WordModel(id: $id, en: $english, tr: $turkish, lvl: $level)';
}
