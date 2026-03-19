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
    // Güvenli String dönüşümleri
    final String level = json['level']?.toString() ?? 'A1';
    final String source = json['wordSource']?.toString() ?? 'oxford_3000';

    // Güvenli Sayı dönüşümü (Hata riskini sıfıra indirir)
    final int id = int.tryParse(json['id']?.toString() ?? '0') ?? 0;
    final int weight =
        int.tryParse(json['difficultyWeight']?.toString() ?? '') ??
        _defaultWeight(level, source);

    return WordModel(
      id: id,
      english: json['english']?.toString() ?? '',
      turkish: json['turkish']?.toString() ?? '',
      level: level,
      category: json['category']?.toString() ?? 'General',
      wordSource: source,
      difficultyWeight: weight,
      cefr: json['cefr']?.toString(),
      isLearned: json['isLearned'] == true,
      isFavorite: json['isFavorite'] == true,
    );
  }

  factory WordModel.fromSupabase(Map<String, dynamic> data) {
    // ID için güvenli parse
    final int rawId =
        int.tryParse(data['id']?.toString() ?? '') ??
        DateTime.now().millisecondsSinceEpoch.abs();

    final String level =
        data['level']?.toString() ?? data['cefr']?.toString() ?? 'A1';
    final String source =
        data['source']?.toString() ??
        data['wordSource']?.toString() ??
        'oxford_3000';

    // Difficulty Weight için güvenli parse (Senin yeni SQL düzenlemeni destekler)
    final int? rawWeight =
        int.tryParse(data['difficulty_weight']?.toString() ?? '') ??
        int.tryParse(data['difficultyWeight']?.toString() ?? '');

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
      english:
          data['en']?.toString() ??
          data['english']?.toString() ??
          data['word']?.toString() ??
          '',
      turkish:
          data['tr']?.toString() ??
          data['turkish']?.toString() ??
          data['meaning']?.toString() ??
          '',
      level: level,
      category: data['category']?.toString() ?? 'General',
      wordSource: source,
      difficultyWeight: resolvedWeight,
      cefr: data['cefr']?.toString() ?? level,
      isLearned: false,
      isFavorite: false,
    );
  }

  static int _defaultWeight(String level, [String source = 'oxford_3000']) {
    switch (source) {
      case 'awl':
        switch (level) {
          case 'A1':
            return 3;
          case 'A2':
            return 4;
          case 'B1':
            return 6;
          case 'B2':
            return 8;
          case 'C1':
            return 10;
          default:
            return 4;
        }
      case 'oxford_5000':
        switch (level) {
          case 'A1':
            return 2;
          case 'A2':
            return 3;
          case 'B1':
            return 5;
          case 'B2':
            return 7;
          case 'C1':
            return 8;
          default:
            return 3;
        }
      default:
        switch (level) {
          case 'A1':
            return 1;
          case 'A2':
            return 2;
          case 'B1':
            return 3;
          case 'B2':
            return 4; // Senin SQL güncellemenle uyumlu
          case 'C1':
            return 5;
          default:
            return 1;
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
      other is WordModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'WordModel(id: $id, en: $english, tr: $turkish, lvl: $level, src: $wordSource, w: $difficultyWeight)';
}
