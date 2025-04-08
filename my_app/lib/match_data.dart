class MatchType {
  final String category; // e.g., BR, CS, Lone Wolf
  final String mode;     // e.g., 1v1, 2v2, 4v4
  final int entryFee;
  final int? perKillReward;
  final List<int>? topPrizes; // e.g., [20, 10, 5]
  final int? perPlayerPrize;

  MatchType({
    required this.category,
    required this.mode,
    required this.entryFee,
    this.perKillReward,
    this.topPrizes,
    this.perPlayerPrize,
  });
}

List<MatchType> matchTypes = [
  // BR Modes
  MatchType(category: 'BR', mode: '1v1', entryFee: 10, perKillReward: 7, topPrizes: [20, 10, 5]),
  MatchType(category: 'BR', mode: '2v2', entryFee: 10, perKillReward: 7, topPrizes: [20, 10, 5]),

  // CS Modes
  MatchType(category: 'CS', mode: '1v1', entryFee: 20, perPlayerPrize: 30),
  MatchType(category: 'CS', mode: '2v2', entryFee: 20, perPlayerPrize: 30),
  MatchType(category: 'CS', mode: '4v4', entryFee: 20, perPlayerPrize: 30),

  // Lone Wolf Modes
  MatchType(category: 'Lone Wolf', mode: '1v1', entryFee: 20, perPlayerPrize: 30),
  MatchType(category: 'Lone Wolf', mode: '2v2', entryFee: 20, perPlayerPrize: 30),

  // Zone Survival
  MatchType(category: 'Zone Survival', mode: 'Top 10', entryFee: 20, topPrizes: [50, 40, 30, 25, 20, 15, 10, 10, 10, 10]),
];
