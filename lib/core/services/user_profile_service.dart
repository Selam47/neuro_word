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
      _keyUsername,
      name.trim().isEmpty ? 'Kaşif' : name.trim(),
    );
  }

  Set<String> getLearnedWordIds() {
    final list = _prefs?.getStringList(_keyLearnedWords);
    if (list == null) return {};
    return list.where((e) => e.isNotEmpty).toSet();
  }

  Future<void> saveLearnedWordId(String id) async {
    final set = getLearnedWordIds();
    if (set.add(id)) {
      await _prefs?.setStringList(_keyLearnedWords, set.toList());
    }
  }

  Future<void> removeLearnedWordId(String id) async {
    final set = getLearnedWordIds();
    if (set.remove(id)) {
      await _prefs?.setStringList(_keyLearnedWords, set.toList());
    }
  }

  Future<void> saveLearnedWordIdsBatch(List<String> ids) async {
    final set = getLearnedWordIds();
    bool changed = false;
    for (final id in ids) {
      if (set.add(id)) changed = true;
    }
    if (changed) {
      await _prefs?.setStringList(_keyLearnedWords, set.toList());
    }
  }

  Set<String> getFavoriteWordIds() {
    final list = _prefs?.getStringList(_keyFavoriteWords);
    if (list == null) return {};
    return list.where((e) => e.isNotEmpty).toSet();
  }

  Future<void> toggleFavoriteWordId(String id) async {
    final set = getFavoriteWordIds();
    if (set.contains(id)) {
      set.remove(id);
    } else {
      set.add(id);
    }
    await _prefs?.setStringList(_keyFavoriteWords, set.toList());
  }

  bool isFavorite(String id) => getFavoriteWordIds().contains(id);

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

  int get preLearnedCount => _preLearnedCountByLevel[proficiencyLevel] ?? 0;

  Future<void> setProficiencyLevel(String level) async {
    await _prefs?.setString(_keyProficiencyLevel, level);
  }

  Future<void> migrateFromLegacy(
    List<String> learnedIds,
    List<String> favoriteIds,
    int xp,
  ) async {
    if (getLearnedWordIds().isEmpty && learnedIds.isNotEmpty) {
      await _prefs?.setStringList(_keyLearnedWords, learnedIds);
    }
    if (getFavoriteWordIds().isEmpty && favoriteIds.isNotEmpty) {
      await _prefs?.setStringList(_keyFavoriteWords, favoriteIds);
    }
    if (getXp() == 0 && xp > 0) {
      await _prefs?.setInt(_keyXp, xp);
    }
  }
}
