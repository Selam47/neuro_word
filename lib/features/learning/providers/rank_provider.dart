import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuro_word/core/services/user_profile_service.dart';
import 'package:neuro_word/features/learning/models/rank_model.dart';
import 'package:neuro_word/features/learning/providers/word_provider.dart';
import 'package:neuro_word/features/learning/providers/word_sets_providers.dart';

class RankNotifier extends Notifier<RankState> {
  final _profile = UserProfileService();

  @override
  RankState build() {
    final ws = ref.watch(wordProvider);
    final learnedIds = ref.watch(learnedWordsProvider);

    if (ws.allWords.isEmpty) return const RankState();

    final levelTotals = <String, int>{};
    final levelLearned = <String, int>{};

    for (final w in ws.allWords) {
      levelTotals[w.level] = (levelTotals[w.level] ?? 0) + 1;
    }

    int score = 0;
    for (final w in ws.allWords) {
      if (learnedIds.contains(w.id)) {
        levelLearned[w.level] = (levelLearned[w.level] ?? 0) + 1;
        score += kWeights[w.level] ?? 1;
      }
    }

    final mastery = <String, double>{};
    for (final level in levelTotals.keys) {
      final total = levelTotals[level]!;
      final learned = levelLearned[level] ?? 0;
      mastery[level] = total > 0 ? learned / total : 0.0;
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
      levelMastery: mastery,
    );
  }
}

final rankProvider = NotifierProvider<RankNotifier, RankState>(
  RankNotifier.new,
);
