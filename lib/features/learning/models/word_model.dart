class WordModel {
  const WordModel({
    required this.id,
    required this.english,
    required this.turkish,
    required this.level,
    required this.category,
    this.wordSource = 'oxford_3000',
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
  final String wordSource;
  final int difficultyWeight;
  final String? cefr;
  final bool isLearned;
  final bool isFavorite;

  static const Map<String, int> _levelWeightMap = {
    'A1': 1,
    'A2': 2,
    'B1': 3,
    'B2': 4,
    'C1': 5,
  };

  factory WordModel.fromJson(Map<String, dynamic> json) {
    final level = json['level'] as String? ?? 'A1';
    final source = json['wordSource'] as String? ?? 'oxford_3000';
    return WordModel(
      id: json['id'] as int,
      english: json['english'] as String,
      turkish: json['turkish'] as String,
      level: level,
      category: json['category'] as String,
      wordSource: source,
      difficultyWeight:
          json['difficultyWeight'] as int? ?? _defaultWeight(level, source),
      cefr: json['cefr'] as String?,
      isLearned: json['isLearned'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  factory WordModel.fromSupabase(Map<String, dynamic> data) {
    final rawId = (data['id'] as num?)?.toInt() ?? Object().hashCode.abs();

    final level =
        data['level'] as String? ?? data['cefr'] as String? ?? 'A1';

    final source = data['source'] as String? ??
        data['wordSource'] as String? ??
        'oxford_3000';

    final rawWeight = (data['difficulty_weight'] as num?)?.toInt() ??
        (data['difficultyWeight'] as num?)?.toInt();

    int resolvedWeight;
    if (rawWeight != null && rawWeight != 3) {
      resolvedWeight = rawWeight;
    } else if (rawWeight == 3 && _levelWeightMap.containsKey(level)) {
      resolvedWeight = _levelWeightMap[level]!;
    } else {
      resolvedWeight = _defaultWeight(level, source);
    }

    return WordModel(
      id: rawId,
      english: data['en'] as String? ??
          data['english'] as String? ??
          data['word'] as String? ??
          '',
      turkish: data['tr'] as String? ??
          data['turkish'] as String? ??
          data['meaning'] as String? ??
          '',
      level: level,
      category: data['category'] as String? ?? 'General',
      wordSource: source,
      difficultyWeight: resolvedWeight,
      cefr: data['cefr'] as String? ?? level,
      isLearned: false,
      isFavorite: false,
    );
  }

  static int _defaultWeight(String level, [String source = 'oxford_3000']) {
    switch (source) {
      case 'awl':
        switch (level) {
          case 'A1': return 3;
          case 'A2': return 4;
          case 'B1': return 6;
          case 'B2': return 8;
          case 'C1': return 10;
          default: return 4;
        }
      case 'oxford_5000':
        switch (level) {
          case 'A1': return 2;
          case 'A2': return 3;
          case 'B1': return 5;
          case 'B2': return 7;
          case 'C1': return 8;
          default: return 3;
        }
      default:
        switch (level) {
          case 'A1': return 1;
          case 'A2': return 2;
          case 'B1': return 3;
          case 'B2': return 5;
          case 'C1': return 6;
          default: return 1;
        }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'english': english,
      'turkish': turkish,
      'level': level,
      'category': category,
      'wordSource': wordSource,
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
    String? wordSource,
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
      wordSource: wordSource ?? this.wordSource,
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
      'WordModel(id: $id, en: $english, tr: $turkish, lvl: $level, src: $wordSource, w: $difficultyWeight)';
}
