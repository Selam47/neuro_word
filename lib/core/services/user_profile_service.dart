import 'package:shared_preferences/shared_preferences.dart';

class UserProfileService {
  static const String _keyUsername = 'profile_username';
  static const String _keyLearnedWords = 'profile_learned_words';
  static const String _keyFavoriteWords = 'profile_favorite_words';
  static const String _keyXp = 'profile_xp';
  static const String _keyLevelScore = 'profile_level_score';
  static const String _keyRankId = 'profile_rank_id';
  static const String _keyProficiencyLevel = 'profile_proficiency_level';

  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get isFirstLaunch => _prefs?.getString(_keyUsername) == null;

  String get username => _prefs?.getString(_keyUsername) ?? 'Kaşif';

  Future<void> setUsername(String name) async {
    await _prefs?.setString(
        _keyUsername, name.trim().isEmpty ? 'Kaşif' : name.trim());
  }

  List<int> getLearnedWords() {
    final list = _prefs?.getStringList(_keyLearnedWords);
    if (list == null) return [];
    return list
        .map((e) => int.tryParse(e) ?? -1)
        .where((e) => e >= 0)
        .toList();
  }

  Future<void> saveLearnedWord(int id) async {
    final list = getLearnedWords();
    if (!list.contains(id)) {
      list.add(id);
      await _prefs?.setStringList(
          _keyLearnedWords, list.map((e) => e.toString()).toList());
    }
  }

  Future<void> removeLearnedWord(int id) async {
    final list = getLearnedWords();
    list.remove(id);
    await _prefs?.setStringList(
        _keyLearnedWords, list.map((e) => e.toString()).toList());
  }

  Future<void> saveLearnedWordsBatch(List<int> ids) async {
    final list = getLearnedWords();
    bool changed = false;
    for (final id in ids) {
      if (!list.contains(id)) {
        list.add(id);
        changed = true;
      }
    }
    if (changed) {
      await _prefs?.setStringList(
          _keyLearnedWords, list.map((e) => e.toString()).toList());
    }
  }

  List<int> getFavoriteWords() {
    final list = _prefs?.getStringList(_keyFavoriteWords);
    if (list == null) return [];
    return list
        .map((e) => int.tryParse(e) ?? -1)
        .where((e) => e >= 0)
        .toList();
  }

  Future<void> toggleFavoriteWord(int id) async {
    final list = getFavoriteWords();
    if (list.contains(id)) {
      list.remove(id);
    } else {
      list.add(id);
    }
    await _prefs?.setStringList(
        _keyFavoriteWords, list.map((e) => e.toString()).toList());
  }

  bool isFavorite(int id) => getFavoriteWords().contains(id);

  int getXp() => _prefs?.getInt(_keyXp) ?? 0;

  Future<void> addXp(int amount) async {
    await _prefs?.setInt(_keyXp, getXp() + amount);
  }

  int getLevelScore() => _prefs?.getInt(_keyLevelScore) ?? 0;

  Future<void> saveLevelScore(int score) async {
    await _prefs?.setInt(_keyLevelScore, score);
  }

  int getRankId() => _prefs?.getInt(_keyRankId) ?? 0;

  Future<void> saveRankId(int id) async {
    await _prefs?.setInt(_keyRankId, id);
  }

  static const Map<String, int> _preLearnedCountByLevel = {
    'A1': 0,
    'A2': 300,
    'B1': 700,
    'B2': 1300,
    'C1': 2000,
  };

  String get proficiencyLevel =>
      _prefs?.getString(_keyProficiencyLevel) ?? 'A1';

  int get preLearnedCount =>
      _preLearnedCountByLevel[proficiencyLevel] ?? 0;

  Future<void> setProficiencyLevel(String level) async {
    await _prefs?.setString(_keyProficiencyLevel, level);
  }

  Future<void> migrateFromLegacy(
    List<int> learnedIds,
    List<int> favoriteIds,
    int xp,
  ) async {
    if (getLearnedWords().isEmpty && learnedIds.isNotEmpty) {
      await _prefs?.setStringList(
          _keyLearnedWords, learnedIds.map((e) => e.toString()).toList());
    }
    if (getFavoriteWords().isEmpty && favoriteIds.isNotEmpty) {
      await _prefs?.setStringList(
          _keyFavoriteWords, favoriteIds.map((e) => e.toString()).toList());
    }
    if (getXp() == 0 && xp > 0) {
      await _prefs?.setInt(_keyXp, xp);
    }
  }
}
