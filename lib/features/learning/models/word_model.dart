class WordModel {
  const WordModel({
    required this.id,
    required this.english,
    required this.turkish,
    required this.level,
    this.wordSource = 'oxford_3000',
    this.difficultyWeight = 1,
    this.cefr,
  });

  final String id;
  final String english;
  final String turkish;
  final String level;
  final String wordSource;
  final int difficultyWeight;
  final String? cefr;

  static const Map<String, int> _levelWeightMap = {
    'A1': 1,
    'A2': 2,
    'B1': 3,
    'B2': 4,
    'C1': 5,
  };

  factory WordModel.fromJson(Map<String, dynamic> json) {
    final String level = json['level']?.toString() ?? 'A1';
    final String source = json['wordSource']?.toString() ?? 'oxford_3000';
    final String english = json['english']?.toString() ?? '';
    final String id = json['id']?.toString() ?? english;
    final int weight =
        int.tryParse(json['difficultyWeight']?.toString() ?? '') ??
        _defaultWeight(level, source);

    return WordModel(
      id: id,
      english: english,
      turkish: json['turkish']?.toString() ?? '',
      level: level,
      wordSource: source,
      difficultyWeight: weight,
      cefr: json['cefr']?.toString(),
    );
  }

  factory WordModel.fromSupabase(Map<String, dynamic> data) {
    final String english =
        data['en']?.toString() ??
        data['english']?.toString() ??
        data['word']?.toString() ??
        '';

    final String level =
        data['level']?.toString() ?? data['cefr']?.toString() ?? 'A1';

    final String source =
        data['source']?.toString() ??
        data['wordSource']?.toString() ??
        'oxford_3000';

    final int? rawWeight =
        int.tryParse(data['difficulty_weight']?.toString() ?? '') ??
        int.tryParse(data['difficultyWeight']?.toString() ?? '');

    final int resolvedWeight;
    if (rawWeight != null && rawWeight != 3) {
      resolvedWeight = rawWeight;
    } else if (rawWeight == 3 && _levelWeightMap.containsKey(level)) {
      resolvedWeight = _levelWeightMap[level]!;
    } else {
      resolvedWeight = _defaultWeight(level, source);
    }

    return WordModel(
      id: english,
      english: english,
      turkish:
          data['tr']?.toString() ??
          data['turkish']?.toString() ??
          data['meaning']?.toString() ??
          '',
      level: level,
      wordSource: source,
      difficultyWeight: resolvedWeight,
      cefr: data['cefr']?.toString() ?? level,
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
            return 4;
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
      'wordSource': wordSource,
      'difficultyWeight': difficultyWeight,
      'cefr': cefr,
    };
  }

  WordModel copyWith({
    String? id,
    String? english,
    String? turkish,
    String? level,
    String? wordSource,
    int? difficultyWeight,
    String? cefr,
  }) {
    return WordModel(
      id: id ?? this.id,
      english: english ?? this.english,
      turkish: turkish ?? this.turkish,
      level: level ?? this.level,
      wordSource: wordSource ?? this.wordSource,
      difficultyWeight: difficultyWeight ?? this.difficultyWeight,
      cefr: cefr ?? this.cefr,
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
