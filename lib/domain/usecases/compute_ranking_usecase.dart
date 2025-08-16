class RankingResult {
  final int rank; // 1-based
  final double percentile; // rank / total
  final int surpassedDays; // how many historical days surpassed today

  const RankingResult({
    required this.rank,
    required this.percentile,
    required this.surpassedDays,
  });
}

int rankTodayAmongHistory({
  required List<int> historicalSteps,
  required int todaySteps,
}) {
  final all = [...historicalSteps, todaySteps]..sort((b, a) => a - b);
  return all.indexOf(todaySteps) + 1; // 1-based
}

RankingResult computeRanking({
  required List<int> historicalSteps,
  required int todaySteps,
}) {
  final rank = rankTodayAmongHistory(
    historicalSteps: historicalSteps,
    todaySteps: todaySteps,
  );
  final total = historicalSteps.length + 1;
  final percentile = rank / total;
  final surpassed = historicalSteps.where((e) => todaySteps > e).length;
  return RankingResult(
    rank: rank,
    percentile: percentile,
    surpassedDays: surpassed,
  );
}


