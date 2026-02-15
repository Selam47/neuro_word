import 'package:shared_preferences/shared_preferences.dart';

/// Singleton StorageService with safe initialization.
/// Guarantees SharedPreferences is always available before use.
class StorageService {
  // Singleton instance
  static final StorageService _instance = StorageService._internal();
  
  factory StorageService() => _instance;
  
  StorageService._internal();

  // Storage keys
  static const String _keyLearnedWords = 'learned_words';
  static const String _keyFavoriteWords = 'favorite_words';
  static const String _keyXp = 'user_xp';

  SharedPreferences? _prefs;
  bool _initialized = false;

  /// Idempotent initialization — safe to call multiple times.
  /// Should be called once in main() before runApp().
  Future<void> init() async {
    if (_initialized && _prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  /// Auto-initializing getter for guaranteed safety.
  /// Falls back to init() if not yet initialized.
  Future<SharedPreferences> _getPrefs() async {
    if (!_initialized || _prefs == null) {
      await init();
    }
    return _prefs!;
  }

  // ── Learned Words ───────────────────────────────────────────────────

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

  // ── Favorite Words ──────────────────────────────────────────────────

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

  // ── XP ──────────────────────────────────────────────────────────────

  int getXp() {
    if (!_initialized || _prefs == null) return 0;
    return _prefs!.getInt(_keyXp) ?? 0;
  }

  Future<void> addXp(int amount) async {
    final prefs = await _getPrefs();
    final current = getXp();
    await prefs.setInt(_keyXp, current + amount);
  }
}
