class RankDefinition {
  const RankDefinition({
    required this.id,
    required this.title,
    required this.requiredLevel,
    required this.requiredMastery,
  });

  final int id;
  final String title;
  final String requiredLevel;
  final double requiredMastery;
}

const kRanks = [
  RankDefinition(id: 1, title: 'Kelime Kaşifi', requiredLevel: 'A1', requiredMastery: 0.60),
  RankDefinition(id: 2, title: 'Sözcük İnşaatçısı', requiredLevel: 'A2', requiredMastery: 0.60),
  RankDefinition(id: 3, title: 'Dil Uygulayıcısı', requiredLevel: 'B1', requiredMastery: 0.50),
  RankDefinition(id: 4, title: 'Yetkin Konuşmacı', requiredLevel: 'B2', requiredMastery: 0.50),
  RankDefinition(id: 5, title: 'İleri Seviye Hatip', requiredLevel: 'C1', requiredMastery: 0.40),
  RankDefinition(id: 6, title: 'Sözlük Hakimi', requiredLevel: 'C1', requiredMastery: 0.70),
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
    this.levelMastery = const {},
  });

  final int levelScore;
  final int currentRankId;
  final Map<String, double> levelMastery;

  String get currentTitle {
    if (currentRankId == 0) return 'Çaylak';
    return kRanks.firstWhere((r) => r.id == currentRankId).title;
  }

  RankDefinition? get nextRank {
    final nextId = currentRankId + 1;
    if (nextId > kRanks.length) return null;
    return kRanks.firstWhere((r) => r.id == nextId);
  }

  bool get isPremiumRank => currentRankId >= 5;
}
