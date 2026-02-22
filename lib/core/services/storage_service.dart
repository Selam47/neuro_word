import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();

  factory StorageService() => _instance;

  StorageService._internal();

  static const String _keyLearnedWords = 'learned_words';
  static const String _keyFavoriteWords = 'favorite_words';
  static const String _keyXp = 'user_xp';
  static const String _keyMigrationV1 = 'migration_v1_done';
  static const String _keyMigrationV2 = 'migration_v2_academic';

  SharedPreferences? _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized && _prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  Future<SharedPreferences> _getPrefs() async {
    if (!_initialized || _prefs == null) {
      await init();
    }
    return _prefs!;
  }

  List<int> getLearnedWords() {
    if (!_initialized || _prefs == null) return [];
    final List<String>? list = _prefs!.getStringList(_keyLearnedWords);
    if (list == null) return [];
    return list.map((e) => int.parse(e)).toList();
  }

  Future<void> saveLearnedWord(int id) async {
    final prefs = await _getPrefs();
    final list = getLearnedWords();
    if (!list.contains(id)) {
      list.add(id);
      await prefs.setStringList(
          _keyLearnedWords, list.map((e) => e.toString()).toList());
    }
  }

  Future<void> saveLearnedWordsBatch(List<int> ids) async {
    final prefs = await _getPrefs();
    final list = getLearnedWords();
    bool changed = false;
    for (final id in ids) {
      if (!list.contains(id)) {
        list.add(id);
        changed = true;
      }
    }
    if (changed) {
      await prefs.setStringList(
          _keyLearnedWords, list.map((e) => e.toString()).toList());
    }
  }

  List<int> getFavoriteWords() {
    if (!_initialized || _prefs == null) return [];
    final List<String>? list = _prefs!.getStringList(_keyFavoriteWords);
    if (list == null) return [];
    return list.map((e) => int.parse(e)).toList();
  }

  Future<void> toggleFavoriteWord(int id) async {
    final prefs = await _getPrefs();
    final list = getFavoriteWords();
    if (list.contains(id)) {
      list.remove(id);
    } else {
      list.add(id);
    }
    await prefs.setStringList(
        _keyFavoriteWords, list.map((e) => e.toString()).toList());
  }

  bool isFavorite(int id) {
    return getFavoriteWords().contains(id);
  }

  int getXp() {
    if (!_initialized || _prefs == null) return 0;
    return _prefs!.getInt(_keyXp) ?? 0;
  }

  Future<void> addXp(int amount) async {
    final prefs = await _getPrefs();
    final current = getXp();
    await prefs.setInt(_keyXp, current + amount);
  }

  bool isMigrationV1Complete() {
    if (!_initialized || _prefs == null) return false;
    return _prefs!.getBool(_keyMigrationV1) ?? false;
  }

  Future<void> setMigrationV1Complete() async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyMigrationV1, true);
  }

  bool isMigrationV2Complete() {
    if (!_initialized || _prefs == null) return false;
    return _prefs!.getBool(_keyMigrationV2) ?? false;
  }

  Future<void> setMigrationV2Complete() async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyMigrationV2, true);
  }
}
