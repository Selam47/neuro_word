class RankDefinition {
  const RankDefinition({
    required this.id,
    required this.title,
    required this.titleTr,
    required this.requiredLevel,
    required this.requiredMastery,
  });

  final int id;
  final String title;
  final String titleTr;
  final String requiredLevel;
  final double requiredMastery;
}

const kRanks = [
  RankDefinition(
    id: 1,
    title: 'Novice Linker',
    titleTr: 'Çaylak',
    requiredLevel: 'A1',
    requiredMastery: 0.60,
  ),
  RankDefinition(
    id: 2,
    title: 'Data Scout',
    titleTr: 'Keşifçi',
    requiredLevel: 'A2',
    requiredMastery: 0.60,
  ),
  RankDefinition(
    id: 3,
    title: 'System Analyst',
    titleTr: 'Dil Uygulayıcısı',
    requiredLevel: 'B1',
    requiredMastery: 0.50,
  ),
  RankDefinition(
    id: 4,
    title: 'Techno-Linguist',
    titleTr: 'Tekno-Dilci',
    requiredLevel: 'B2',
    requiredMastery: 0.50,
  ),
  RankDefinition(
    id: 5,
    title: 'Neuro Master',
    titleTr: 'Neuro Master',
    requiredLevel: 'C1',
    requiredMastery: 0.40,
  ),
  RankDefinition(
    id: 6,
    title: 'Elite Neuro Master',
    titleTr: 'Elit Neuro Master',
    requiredLevel: 'C1',
    requiredMastery: 0.80,
  ),
];

const kWeights = <String, int>{
  'A1': 1,
  'A2': 2,
  'B1': 3,
  'B2': 4,
  'C1': 5,
};

class RankState {
  const RankState({
    this.levelScore = 0,
    this.currentRankId = 0,
    this.startingRankId = 1,
    this.levelMastery = const {},
  });

  final int levelScore;
  final int currentRankId;
  final int startingRankId;
  final Map<String, double> levelMastery;

  int get effectiveRankId =>
      currentRankId < startingRankId ? startingRankId : currentRankId;

  String get currentTitle {
    final eid = effectiveRankId;
    if (eid <= 0) return kRanks.first.title;
    try {
      return kRanks.firstWhere((r) => r.id == eid).title;
    } catch (_) {
      return kRanks.first.title;
    }
  }

  String get currentTitleTr {
    final eid = effectiveRankId;
    if (eid <= 0) return kRanks.first.titleTr;
    try {
      return kRanks.firstWhere((r) => r.id == eid).titleTr;
    } catch (_) {
      return kRanks.first.titleTr;
    }
  }

  RankDefinition? get nextRank {
    final nextId = effectiveRankId + 1;
    if (nextId > kRanks.length) return null;
    try {
      return kRanks.firstWhere((r) => r.id == nextId);
    } catch (_) {
      return null;
    }
  }

  bool get isPremiumRank => effectiveRankId >= 5;
}
