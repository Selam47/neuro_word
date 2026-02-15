import 'dart:convert';

/// Represents a single English-Turkish word entry.
class WordModel {
  const WordModel({
    required this.id,
    required this.english,
    required this.turkish,
    required this.level,
    required this.category,
    this.isLearned = false,
    this.isFavorite = false,
  });

  final int id;
  final String english;
  final String turkish;
  final String level;
  final String category;
  final bool isLearned;
  final bool isFavorite;

  // ── JSON Serialization ──────────────────────────────────────────────

  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      id: json['id'] as int,
      english: json['english'] as String,
      turkish: json['turkish'] as String,
      level: json['level'] as String,
      category: json['category'] as String,
      isLearned: json['isLearned'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'english': english,
      'turkish': turkish,
      'level': level,
      'category': category,
      'isLearned': isLearned,
      'isFavorite': isFavorite,
    };
  }

  // ── copyWith ────────────────────────────────────────────────────────

  WordModel copyWith({
    int? id,
    String? english,
    String? turkish,
    String? level,
    String? category,
    bool? isLearned,
    bool? isFavorite,
  }) {
    return WordModel(
      id: id ?? this.id,
      english: english ?? this.english,
      turkish: turkish ?? this.turkish,
      level: level ?? this.level,
      category: category ?? this.category,
      isLearned: isLearned ?? this.isLearned,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  // ── Equality & toString ─────────────────────────────────────────────

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

/// Parses a raw JSON string into a list of [WordModel].
List<WordModel> parseWords(String jsonString) {
  final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
  return decoded
      .map((e) => WordModel.fromJson(e as Map<String, dynamic>))
      .toList();
}
