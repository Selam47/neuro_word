import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuro_word/core/services/user_profile_service.dart';
import 'package:neuro_word/features/learning/models/rank_model.dart';
import 'package:neuro_word/features/learning/providers/word_provider.dart';
import 'package:neuro_word/features/learning/providers/word_sets_providers.dart';

class RankNotifier extends Notifier<RankState> {
  final _profile = UserProfileService();

  static const Map<String, int> _startingRankByLevel = {
    'A1': 1,
    'A2': 2,
    'B1': 3,
    'B2': 4,
    'C1': 5,
  };

  @override
  RankState build() {
    final ws = ref.watch(wordProvider);
    final learnedIds = ref.watch(userProgressProvider.select((s) => s.learnedIds));

    final profLevel = _profile.proficiencyLevel;
    final startRankId = _startingRankByLevel[profLevel] ?? 1;

    if (ws.allWords.isEmpty) {
      return RankState(startingRankId: startRankId);
    }

    final levelTotals = <String, int>{};
    final levelLearned = <String, int>{};

    for (final w in ws.allWords) {
      levelTotals[w.level] = (levelTotals[w.level] ?? 0) + 1;
    }

    int score = 0;
    for (final w in ws.allWords) {
      if (learnedIds.contains(w.id)) {
        levelLearned[w.level] = (levelLearned[w.level] ?? 0) + 1;
        score += w.difficultyWeight > 0
            ? w.difficultyWeight
            : (kWeights[w.level] ?? 1);
      }
    }

    final userLevelIdx = levelIndex(profLevel);

    final mastery = <String, double>{};
    for (final level in kLevelHierarchy) {
      if (levelIndex(level) < userLevelIdx) {
        mastery[level] = 1.0;
      } else {
        final total = levelTotals[level] ?? 0;
        final learned = levelLearned[level] ?? 0;
        mastery[level] = total > 0 ? learned / total : 0.0;
      }
    }

    int achievedRank = 0;
    for (final rank in kRanks) {
      if (rank.id != achievedRank + 1) break;
      final m = mastery[rank.requiredLevel] ?? 0.0;
      if (m >= rank.requiredMastery) {
        achievedRank = rank.id;
      } else {
        break;
      }
    }

    _profile.saveLevelScore(score);
    _profile.saveRankId(achievedRank);

    return RankState(
      levelScore: score,
      currentRankId: achievedRank,
      startingRankId: startRankId,
      levelMastery: mastery,
    );
  }
}

final rankProvider = NotifierProvider<RankNotifier, RankState>(
  RankNotifier.new,
);
