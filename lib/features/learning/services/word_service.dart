import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;
import 'package:neuro_word/features/learning/models/word_model.dart';

/// Service responsible for loading word data from local JSON assets.
/// Uses `compute()` to parse large JSON payloads on a background isolate
/// and keep the UI thread buttery smooth.
class WordService {
  const WordService();

  static const _assetPath = 'assets/data/words.json';

  /// Reads and parses [_assetPath] into a list of [WordModel].
  /// The JSON decoding happens in a separate isolate via `compute()`.
  Future<List<WordModel>> fetchWords() async {
    final jsonString = await rootBundle.loadString(_assetPath);
    return compute(parseWords, jsonString);
  }
}

