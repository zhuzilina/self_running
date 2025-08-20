/*
 * Copyright 2025 榆见晴天
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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


